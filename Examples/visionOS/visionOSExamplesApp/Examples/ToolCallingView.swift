import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct ToolCallingView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var prompt = "What day is it today, and how many days until the end of the year?"
    @State private var events: [EventEntry] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var currentTask: Task<Void, Never>?

    var body: some View {
        Form {
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

            if !events.isEmpty {
                Section("Event Log") {
                    ForEach(events) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: entry.icon)
                                .foregroundStyle(entry.color)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.label).font(.caption).foregroundStyle(.secondary)
                                Text(entry.value).textSelection(.enabled)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Tool Calling")
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
        events = []
        errorMessage = nil

        guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "Invalid base URL"
            isGenerating = false
            return
        }

        let model = OpenResponsesModel(
            id: settings.modelID,
            capabilities: .init(toolCalling: true)
        )
        let lm = OpenResponsesLanguageModel(
            name: model,
            auth: .apiKey(settings.apiKey),
            baseURL: url
        )

        // The closure is @Sendable and @MainActor so appending to @State is safe.
        let onEvent: @Sendable @MainActor (String, String) -> Void = { [self] label, value in
            events.append(EventEntry(label: label, value: value))
        }

        let tool = GetCurrentDateTool(onEvent: onEvent)

        do {
            let session = LanguageModelSession(model: lm, tools: [tool])
            let result = try await session.respond(to: prompt)
            events.append(EventEntry(label: "Response", value: result.content))
        } catch is CancellationError {
            // user tapped Stop
        } catch {
            errorMessage = String(reflecting: error)
        }

        isGenerating = false
        currentTask = nil
    }
}

// MARK: - Tool

private struct GetCurrentDateTool: Tool {
    // Tool protocol requires instance properties (not static)
    let name: String = "get_current_date"
    let description: String = "Returns today's date as an ISO 8601 string (YYYY-MM-DD). Use this when asked about the current date."

    @Generable struct Arguments {}

    // @Sendable closure lets the tool report events without shared mutable state.
    // The closure is @MainActor so it can safely mutate the view's @State.
    let onEvent: @Sendable @MainActor (String, String) -> Void

    @concurrent func call(arguments: Arguments) async throws -> String {
        let date = ISO8601DateFormatter().string(from: Date())
        await onEvent("Tool called", name)
        await onEvent("Tool returned", date)
        return date
    }
}

// MARK: - Supporting types

private struct EventEntry: Identifiable {
    let id = UUID()
    let label: String
    let value: String

    var icon: String {
        switch label {
        case "Tool called": return "wrench"
        case "Tool returned": return "checkmark.circle"
        default: return "text.bubble"
        }
    }

    var color: Color {
        switch label {
        case "Tool called": return .orange
        case "Tool returned": return .green
        default: return .primary
        }
    }
}
