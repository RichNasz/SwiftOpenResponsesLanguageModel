import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

// structuredOutput: true causes RequestBuilder to attach a JSON schema constraint to the
// request. The model must return JSON matching the MovieRecommendation schema; the session
// decodes and type-checks the response before returning it.
@Generable
struct MovieRecommendation {
    @Guide(description: "The film title") var title: String
    @Guide(description: "The release year as a four-digit integer, e.g. 1977") var year: Int
    @Guide(description: "One sentence explaining why this film is recommended") var reason: String
}

struct StructuredOutputView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var prompt = "Recommend a classic science fiction film."
    @State private var result: MovieRecommendation?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Prompt") {
                TextEditor(text: $prompt)
                    .frame(minHeight: 60)
                Button(isGenerating ? "Generating…" : "Send") {
                    send()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating || !canSend)
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if let result {
                Section("Result") {
                    LabeledContent("Title", value: result.title)
                    LabeledContent("Year", value: String(result.year))
                    LabeledContent("Reason", value: result.reason)
                }
            }
        }
        .navigationTitle("Structured Output")
    }

    private var canSend: Bool {
        !settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        Task { @MainActor in
            isGenerating = true
            result = nil
            errorMessage = nil

            guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                errorMessage = "Invalid base URL"
                isGenerating = false
                return
            }

            let model = OpenResponsesModel(
                id: settings.modelID,
                capabilities: .init(structuredOutput: true)
            )
            let lm = OpenResponsesLanguageModel(
                name: model,
                auth: .apiKey(settings.apiKey),
                baseURL: url
            )

            do {
                let session = LanguageModelSession(model: lm)
                let response = try await session.respond(to: prompt, generating: MovieRecommendation.self)
                result = response.content
            } catch {
                errorMessage = String(reflecting: error)
            }

            isGenerating = false
        }
    }
}
