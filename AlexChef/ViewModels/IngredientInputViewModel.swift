import AVFoundation
import Foundation
import Speech
import Vision
import UIKit

@MainActor
final class IngredientInputViewModel: NSObject, ObservableObject {
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
    @Published private(set) var recognizedObjects: [String] = []

    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var hasAudioTap = false

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
        recognizedObjects = []
        visionStatusMessage = nil
        speechError = nil
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
        let classificationRequest = makeClassificationRequest()
        visionStatusMessage = classificationRequest == nil ? "Scanning text (object suggestions require iOS 17+)." : "Processing image…"
        recognizedTextFromImage = ""
        recognizedObjects = []

        guard let cgImage = image.cgImage else {
            visionStatusMessage = "Unable to read image."
            return
        }

        let requests = [makeTextRequest(), classificationRequest].compactMap { $0 }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        Task {
            do {
                try handler.perform(requests)
            } catch {
                self.visionStatusMessage = "Vision processing failed: \(error.localizedDescription)"
            }
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

    private func makeClassificationRequest() -> VNImageBasedRequest? {
        if #available(iOS 17.0, *) {
            let request = VNClassifyImageRequest { [weak self] request, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error {
                        self.visionStatusMessage = "Classification failed: \(error.localizedDescription)"
                        return
                    }

                    guard let results = request.results as? [VNClassificationObservation] else { return }
                    let probableIngredients = results
                        .filter { $0.confidence > 0.25 }
                        .prefix(5)
                        .map { "\($0.identifier) \(Int($0.confidence * 100))%" }

                    if !probableIngredients.isEmpty {
                        self.recognizedObjects = probableIngredients
                        self.visionStatusMessage = "Identified possible ingredients."
                    }
                }
            }
            //request.maximumObservations = 8
            //return request
        }

        return nil
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
