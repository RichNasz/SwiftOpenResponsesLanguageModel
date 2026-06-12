import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct MultiTurnView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var session: LanguageModelSession?
    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if isGenerating {
                            HStack {
                                Text("···")
                                    .padding(10)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Spacer()
                            }
                            .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Message…", text: $input)
                    .textFieldStyle(.plain)
                    .padding(.leading)
                    .disabled(isGenerating)
                    .onSubmit { if canSend { sendMessage() } }
                Button("Send", action: sendMessage)
                    .buttonStyle(.borderedProminent)
                    .padding(.trailing)
                    .disabled(!canSend)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Multi-turn Conversation")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Conversation") { reset() }
                    .disabled(isGenerating)
            }
        }
        .onAppear { buildSession() }
        .onChange(of: settings.baseURL) { _, _ in buildSession() }
        .onChange(of: settings.modelID) { _, _ in buildSession() }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var canSend: Bool {
        !isGenerating
            && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && session != nil
    }

    private func buildSession() {
        let trimmedURL = settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedID = settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty, let url = URL(string: trimmedURL) else { session = nil; return }
        let model = OpenResponsesModel(id: trimmedID, capabilities: .init())
        let lm = OpenResponsesLanguageModel(name: model, auth: .apiKey(settings.apiKey), baseURL: url)
        session = LanguageModelSession(model: lm)
    }

    private func reset() {
        messages = []
        errorMessage = nil
        buildSession()
    }

    private func sendMessage() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let session else { return }
        input = ""
        messages.append(ChatMessage(role: .user, text: text))

        Task { @MainActor in
            isGenerating = true
            do {
                // The session holds transcript history across all calls — no manual
                // history management needed. Each respond() continues the conversation.
                let result = try await session.respond(to: text)
                messages.append(ChatMessage(role: .assistant, text: result.content))
            } catch {
                errorMessage = String(reflecting: error)
            }
            isGenerating = false
        }
    }
}

private struct ChatMessage: Identifiable {
    let id = UUID()
    enum Role { case user, assistant }
    let role: Role
    let text: String
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .padding(10)
                .background(message.role == .user
                    ? Color.accentColor.opacity(0.2)
                    : Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .textSelection(.enabled)
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}
