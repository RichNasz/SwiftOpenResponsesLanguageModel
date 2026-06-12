import SwiftUI
import PhotosUI
import UIKit
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct ImageInputView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var displayImage: Image?
    @State private var prompt = "Describe what you see in this image."
    @State private var response = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var currentTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("Image") {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    if let displayImage {
                        displayImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Label("Select Image", systemImage: "photo")
                    }
                }
                .onChange(of: pickerItem) { _, newItem in
                    Task { @MainActor in
                        guard let newItem else { return }
                        imageData = try? await newItem.loadTransferable(type: Data.self)
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            displayImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }

            Section("Prompt") {
                TextEditor(text: $prompt)
                    .frame(minHeight: 60)
                Button(isGenerating ? "Stop" : "Send") {
                    isGenerating ? cancel() : send()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isGenerating && !canSend)
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if !response.isEmpty {
                Section("Response") {
                    Text(response).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Image Input")
    }

    private func makeModel() -> OpenResponsesModel {
        OpenResponsesModel(id: settings.modelID, capabilities: .init(imageInput: true))
    }

    private var canSend: Bool {
        imageData != nil
            && !settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        currentTask = Task { @MainActor in await generate() }
    }

    private func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isGenerating = false
    }

    @MainActor
    private func generate() async {
        guard let imageData else { return }
        isGenerating = true
        response = ""
        errorMessage = nil

        guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "Invalid base URL"
            isGenerating = false
            return
        }

        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            errorMessage = "Could not decode image."
            isGenerating = false
            return
        }

        do {
            let lm = OpenResponsesLanguageModel(
                name: makeModel(),
                auth: .apiKey(settings.apiKey),
                baseURL: url
            )
            let session = LanguageModelSession(model: lm)
            let imageAttachment = Attachment<ImageAttachmentContent>(cgImage)
            let stream = session.streamResponse {
                imageAttachment
                prompt
            }
            for try await partial in stream {
                guard !Task.isCancelled else { break }
                response = partial.content
            }
        } catch is CancellationError {
            // user tapped Stop
        } catch {
            errorMessage = String(reflecting: error)
        }

        isGenerating = false
        currentTask = nil
    }
}
