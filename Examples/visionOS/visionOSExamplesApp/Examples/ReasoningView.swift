import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct ReasoningView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var prompt = "How many prime numbers are there between 1 and 100? Show your work."
    @State private var reasoningLevel: ReasoningLevelOption = .moderate
    @State private var reasoningText = ""
    @State private var answerText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var currentTask: Task<Void, Never>?
    @State private var reasoningExpanded = false
    @State private var answerExpanded = true

    var body: some View {
        Form {
            Section("Reasoning Level") {
                Picker("Level", selection: $reasoningLevel) {
                    ForEach(ReasoningLevelOption.allCases) { level in
                        Text(level.label).tag(level)
                    }
                }
                .pickerStyle(.segmented)
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

            if !reasoningText.isEmpty || !answerText.isEmpty {
                Section {
                    DisclosureGroup("Reasoning", isExpanded: $reasoningExpanded) {
                        Text(reasoningText.isEmpty ? "No reasoning summary available." : reasoningText)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    DisclosureGroup("Answer", isExpanded: $answerExpanded) {
                        Text(answerText)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle("Reasoning")
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
        reasoningText = ""
        answerText = ""
        errorMessage = nil

        guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "Invalid base URL"
            isGenerating = false
            return
        }

        let model = OpenResponsesModel(
            id: settings.modelID,
            capabilities: .init(reasoning: true)
        )
        let lm = OpenResponsesLanguageModel(
            name: model,
            auth: .apiKey(settings.apiKey),
            baseURL: url
        )

        do {
            let session = LanguageModelSession(model: lm)
            // Pass the reasoning level via ContextOptions — the FoundationModels-exposed API
            // for controlling reasoning effort. ContextOptions.ReasoningLevel has .light,
            // .moderate, and .deep cases. These map internally to OpenAI reasoning_effort values
            // low / medium / high via the package's RequestBuilder.
            let ctxOptions = ContextOptions(reasoningLevel: reasoningLevel.foundationModelsLevel)
            let result = try await session.respond(
                to: prompt,
                contextOptions: ctxOptions
            )
            answerText = result.content

            // Reasoning text is not a dedicated property on Response<String>. Instead it is
            // captured as Transcript.Entry.reasoning entries. Extract and concatenate their
            // text segments from the transcript slice the response carries.
            let reasoningSegments = result.transcriptEntries.compactMap { entry -> String? in
                guard case .reasoning(let r) = entry else { return nil }
                return r.description
            }
            reasoningText = reasoningSegments.joined(separator: "\n\n")

            answerExpanded = true
            reasoningExpanded = !reasoningText.isEmpty
        } catch is CancellationError {
            // user tapped Stop
        } catch {
            errorMessage = String(reflecting: error)
        }

        isGenerating = false
        currentTask = nil
    }
}

// MARK: - Supporting types

private enum ReasoningLevelOption: String, CaseIterable, Identifiable {
    case light, moderate, deep
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var foundationModelsLevel: ContextOptions.ReasoningLevel {
        switch self {
        case .light: return .light
        case .moderate: return .moderate
        case .deep: return .deep
        }
    }
}
