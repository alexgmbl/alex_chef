import PhotosUI
import SwiftUI
import UIKit

struct IngredientInputView: View {
    @StateObject private var viewModel = IngredientInputViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                textInputSection
                voiceInputSection
                photoInputSection
            }
            .padding()
        }
        .navigationTitle("Ingredients")
        .toolbar { toolbarButtons }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            loadImage(from: newValue)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Capture Ingredients")
                .font(.largeTitle.weight(.bold))
            Text("Type, speak, or scan to build your shopping list and recipe ideas.")
                .foregroundStyle(.secondary)
        }
    }

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Text Input", systemImage: "text.alignleft")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Parse") {
                    viewModel.parseIngredients()
                }
                .buttonStyle(.borderedProminent)
            }

            TextEditor(text: $viewModel.rawTextInput)
                .frame(minHeight: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 4)

            parsedIngredientsSection
        }
    }

    private var parsedIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Parsed Ingredients")
                    .font(.headline)
                if !viewModel.parsedIngredients.isEmpty {
                    Text("\(viewModel.parsedIngredients.count)")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                }
            }

            if viewModel.parsedIngredients.isEmpty {
                Text("We’ll break out individual ingredients as you type or after parsing a photo or transcript.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.parsedIngredients, id: \.self) { ingredient in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.accentColor)
                            Text(ingredient)
                            Spacer()
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
                    }
                }
            }
        }
    }

    private var voiceInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Voice Input", systemImage: "mic")
                .font(.title3.weight(.semibold))

            HStack(spacing: 12) {
                statusBadge
                if let error = viewModel.speechError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }

            languagePicker

            HStack(spacing: 16) {
                Button(action: handleMicrophoneTap) {
                    Label(viewModel.speechState == .recording ? "Stop" : "Start Recording", systemImage: viewModel.speechState == .recording ? "stop.circle" : "mic.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("Request Access") {
                    viewModel.requestSpeechAuthorization()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.speechState == .authorized || viewModel.speechState == .recording)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Language & Accent", systemImage: "globe")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Toggle("On-device", isOn: $viewModel.prefersOnDeviceRecognition)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .accessibilityLabel("Prefer on-device speech recognition")
            }

            Picker("Speech Language", selection: Binding(
                get: { viewModel.selectedSpeechLocale.identifier },
                set: { identifier in
                    if let locale = viewModel.supportedSpeechLocales.first(where: { $0.identifier == identifier }) {
                        viewModel.updateSpeechRecognizer(with: locale)
                    }
                }
            )) {
                ForEach(viewModel.supportedSpeechLocales, id: \.identifier) { locale in
                    Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                        .tag(locale.identifier)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(viewModel.speechState.description)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(statusColor.opacity(0.1)))
    }

    private var statusColor: Color {
        switch viewModel.speechState {
        case .authorized:
            return .green
        case .recording:
            return .orange
        case .denied, .error:
            return .red
        case .requesting:
            return .yellow
        case .idle:
            return .secondary
        }
    }

    private var photoInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Photo Input", systemImage: "camera")
                .font(.title3.weight(.semibold))

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Pick Photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2)))
                }
            }

            if let status = viewModel.visionStatusMessage {
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.recognizedTextFromImage.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Extracted Text")
                        .font(.headline)
                    Text(viewModel.recognizedTextFromImage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
                }
            }

            if !viewModel.recognizedIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Suggested Ingredients from Photo")
                            .font(.headline)
                        Spacer()
                        Button("Add All to List") {
                            viewModel.addRecognizedIngredientsToList()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)], spacing: 8) {
                        ForEach(viewModel.recognizedIngredients) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                HStack {
                                    Text("\(Int(item.confidence * 100))% confidence")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Add") {
                                        viewModel.addRecognizedIngredientsToList([item])
                                    }
                                    .buttonStyle(.bordered)
                                }
                                if !item.source.isEmpty {
                                    Text(item.source)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.08)))
                        }
                    }
                }
            }
        }
    }

    private var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Clear") {
                viewModel.reset()
            }
        }
    }

    private func handleMicrophoneTap() {
        if viewModel.speechState == .recording {
            viewModel.stopRecording()
        } else if viewModel.speechState == .authorized || viewModel.speechState == .idle {
            viewModel.startRecording()
        } else {
            viewModel.requestSpeechAuthorization()
        }
    }

    private func loadImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                viewModel.processPickedImage(image)
            }
        }
    }
}

#Preview {
    NavigationStack {
        IngredientInputView()
    }
}
