import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct StreamingView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var prompt = ""
    @State private var response = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var currentTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("Prompt") {
                TextEditor(text: $prompt)
                    .frame(minHeight: 80)
                Button(isGenerating ? "Stop" : "Send") {
                    isGenerating ? cancel() : send()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isGenerating && !canSend)
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            if !response.isEmpty {
                Section("Response") {
                    Text(response)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Streaming")
    }

    // samplingParams: false (default) omits temperature and top-P from the request.
    // Set samplingParams: true on the model to pass GenerationOptions values through.
    private func makeModel() -> OpenResponsesModel {
        OpenResponsesModel(id: settings.modelID, capabilities: .init())
    }

    private var canSend: Bool {
        !settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        isGenerating = true
        response = ""
        errorMessage = nil

        guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "Invalid base URL"
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
            let stream = session.streamResponse(to: prompt)
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
