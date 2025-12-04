import AVFoundation
import Foundation
import Speech
import Vision
import UIKit

@MainActor
final class IngredientInputViewModel: NSObject, ObservableObject {
    struct RecognizedIngredient: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let confidence: Double
        let source: String
    }

    enum SpeechState: String {
        case idle = "Idle"
        case requesting = "Requesting Permission"
        case authorized = "Ready"
        case denied = "Permission Denied"
        case recording = "Listening"
        case error = "Error"

        var description: String { rawValue }
    }

    @Published var rawTextInput: String = ""
    @Published private(set) var parsedIngredients: [String] = []
    @Published private(set) var speechState: SpeechState = .idle
    @Published private(set) var speechError: String?
    @Published private(set) var visionStatusMessage: String?
    @Published private(set) var recognizedTextFromImage: String = ""
    @Published private(set) var recognizedIngredients: [RecognizedIngredient] = []
    @Published var selectedSpeechLocale: Locale
    @Published var prefersOnDeviceRecognition: Bool = false

    let supportedSpeechLocales: [Locale]

    private var speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var hasAudioTap = false

    override init() {
        let supportedLocales = Array(SFSpeechRecognizer.supportedLocales()).sorted { lhs, rhs in
            let lhsName = lhs.localizedString(forIdentifier: lhs.identifier) ?? lhs.identifier
            let rhsName = rhs.localizedString(forIdentifier: rhs.identifier) ?? rhs.identifier
            return lhsName < rhsName
        }
        supportedSpeechLocales = supportedLocales
        selectedSpeechLocale = supportedLocales.first { $0.identifier == Locale.current.identifier } ?? Locale(identifier: "en_US")
        super.init()
        updateSpeechRecognizer(with: selectedSpeechLocale)
    }

    func parseIngredients() {
        let separators = CharacterSet(charactersIn: ",\n;•\t")
        let components = rawTextInput
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        parsedIngredients = Array(NSOrderedSet(array: components)) as? [String] ?? components
    }

    func reset() {
        rawTextInput = ""
        parsedIngredients = []
        recognizedTextFromImage = ""
        recognizedIngredients = []
        visionStatusMessage = nil
        speechError = nil
    }

    func updateSpeechRecognizer(with locale: Locale) {
        selectedSpeechLocale = locale
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        speechRecognizer?.defaultTaskHint = .dictation
        speechError = speechRecognizer == nil ? "Selected language is not supported for speech recognition." : nil
    }

    func requestSpeechAuthorization() {
        speechState = .requesting
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self else { return }
            Task { @MainActor in
                switch status {
                case .authorized:
                    self.speechState = .authorized
                    self.speechError = nil
                case .denied, .restricted:
                    self.speechState = .denied
                    self.speechError = "Speech recognition access is required to transcribe your voice."
                case .notDetermined:
                    self.speechState = .idle
                @unknown default:
                    self.speechState = .error
                    self.speechError = "Unknown authorization status."
                }
            }
        }
    }

    func startRecording() {
        guard speechState == .authorized || speechState == .idle else {
            speechError = "Speech access is required to transcribe your voice."
            return
        }

        guard speechRecognizer != nil else {
            speechState = .error
            speechError = "Selected speech language is not available on this device."
            return
        }

        if speechState == .idle {
            requestSpeechAuthorization()
            return
        }

        stopRecording(targetState: .authorized)

        prepareAudioSession()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            speechState = .error
            speechError = "Unable to create recognition request."
            return
        }

        recognitionRequest.requiresOnDeviceRecognition = prefersOnDeviceRecognition
        recognitionRequest.shouldReportPartialResults = true
        speechState = .recording
        speechError = nil

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.rawTextInput = result.bestTranscription.formattedString
                    self.parseIngredients()
                }

                if let error {
                    self.finishRecordingWithError(error.localizedDescription)
                }
            }
        }

        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        hasAudioTap = true

        do {
            try audioEngine.start()
        } catch {
            finishRecordingWithError("Audio engine failed to start: \(error.localizedDescription)")
        }
    }

    func stopRecording(targetState: SpeechState = .authorized) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil

        if hasAudioTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasAudioTap = false
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            speechError = "Audio session deactivation failed: \(error.localizedDescription)"
        }

        speechState = targetState
    }

    func processPickedImage(_ image: UIImage) {
        visionStatusMessage = "Processing image…"
        recognizedTextFromImage = ""
        recognizedIngredients = []

        guard let cgImage = image.cgImage else {
            visionStatusMessage = "Unable to read image."
            return
        }

        Task {
            await performImageAnalysis(on: cgImage)
        }
    }

    private func makeTextRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.visionStatusMessage = "OCR failed: \(error.localizedDescription)"
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let strings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let consolidated = strings.joined(separator: "\n")
                self.recognizedTextFromImage = consolidated

                if !consolidated.isEmpty {
                    if !self.rawTextInput.isEmpty {
                        self.rawTextInput += "\n"
                    }
                    self.rawTextInput += consolidated
                    self.parseIngredients()
                    self.visionStatusMessage = "Extracted text from image."
                } else {
                    self.visionStatusMessage = "No text detected in image."
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        return request
    }

    private func performImageAnalysis(on cgImage: CGImage) async {
        let textRequest = makeTextRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([textRequest])
        } catch {
            await MainActor.run {
                self.visionStatusMessage = "Vision processing failed: \(error.localizedDescription)"
            }
        }

        guard #available(iOS 17.0, *) else {
            await MainActor.run {
                self.visionStatusMessage = "Text extracted. Object suggestions require iOS 17+."
            }
            return
        }

        await runFoodRecognition(for: cgImage)
    }

    @available(iOS 17.0, *)
    private func runFoodRecognition(for cgImage: CGImage) async {
        visionStatusMessage = "Identifying ingredients…"

        do {
            async let fullImageResults = classifyFood(in: cgImage, source: "Whole photo")
            async let regionResults = classifySalientRegions(in: cgImage)
            let combined = deduplicateIngredients(try await (fullImageResults + regionResults))

            await MainActor.run {
                self.recognizedIngredients = combined
                if combined.isEmpty {
                    self.visionStatusMessage = "No obvious food items detected."
                } else {
                    self.visionStatusMessage = "Identified possible ingredients."
                }
            }
        } catch {
            await MainActor.run {
                self.visionStatusMessage = "Classification failed: \(error.localizedDescription)"
            }
        }
    }

    @available(iOS 17.0, *)
    private func classifyFood(in cgImage: CGImage, source: String, region: CGRect? = nil) async throws -> [RecognizedIngredient] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let ingredients = results
                    .filter { $0.confidence > 0.18 }
                    .prefix(8)
                    .map { RecognizedIngredient(name: $0.identifier, confidence: Double($0.confidence), source: source) }

                continuation.resume(returning: Array(ingredients))
            }

            request.preferBackgroundProcessing = true

            do {
                let handler: VNImageRequestHandler
                if let region {
                    let croppingRect = VNImageRectForNormalizedRect(region, cgImage.width, cgImage.height)
                    guard let cropped = cgImage.cropping(to: croppingRect) else {
                        continuation.resume(returning: [])
                        return
                    }
                    handler = VNImageRequestHandler(cgImage: cropped, options: [:])
                } else {
                    handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                }

                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    @available(iOS 17.0, *)
    private func classifySalientRegions(in cgImage: CGImage) async throws -> [RecognizedIngredient] {
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([saliencyRequest])

        guard let results = saliencyRequest.results?.first as? VNSaliencyImageObservation else {
            return []
        }

        let regions = results.salientObjects?.prefix(4) ?? []

        return try await withThrowingTaskGroup(of: [RecognizedIngredient].self) { group in
            for (index, region) in regions.enumerated() {
                let boundingBox = region.boundingBox
                group.addTask { [cgImage] in
                    try await self.classifyFood(in: cgImage, source: "Region \(index + 1)", region: boundingBox)
                }
            }

            var regionIngredients: [RecognizedIngredient] = []
            for try await items in group {
                regionIngredients.append(contentsOf: items)
            }

            return regionIngredients
        }
    }

    private func deduplicateIngredients(_ items: [RecognizedIngredient]) -> [RecognizedIngredient] {
        var bestByName: [String: RecognizedIngredient] = [:]

        for item in items {
            let key = item.name.lowercased()
            if let current = bestByName[key] {
                if item.confidence > current.confidence {
                    bestByName[key] = item
                }
            } else {
                bestByName[key] = item
            }
        }

        return bestByName.values.sorted { $0.confidence > $1.confidence }
    }

    func addRecognizedIngredientsToList(_ items: [RecognizedIngredient]? = nil) {
        let additions = (items ?? recognizedIngredients).map { $0.name }
        appendIngredientsToInput(additions)
    }

    private func appendIngredientsToInput(_ names: [String]) {
        guard !names.isEmpty else { return }
        let newLines = names.joined(separator: "\n")

        if !rawTextInput.isEmpty && !rawTextInput.hasSuffix("\n") {
            rawTextInput += "\n"
        }

        rawTextInput += newLines
        parseIngredients()
    }

    private func prepareAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            finishRecordingWithError("Audio session configuration failed: \(error.localizedDescription)")
        }
    }

    private func finishRecordingWithError(_ message: String) {
        speechError = message
        stopRecording(targetState: .error)
    }
}
