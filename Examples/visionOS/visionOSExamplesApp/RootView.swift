import SwiftUI

enum Example: String, CaseIterable, Identifiable {
    case streaming = "Streaming"
    case multiTurn = "Multi-turn Conversation"
    case toolCalling = "Tool Calling"
    case structuredOutput = "Structured Output"
    case imageInput = "Image Input"
    case reasoning = "Reasoning"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .streaming: return "text.word.spacing"
        case .multiTurn: return "bubble.left.and.bubble.right"
        case .toolCalling: return "wrench.and.screwdriver"
        case .structuredOutput: return "list.bullet.rectangle"
        case .imageInput: return "photo"
        case .reasoning: return "brain"
        }
    }
}

struct RootView: View {
    @State private var selectedExample: Example?
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            List(Example.allCases, selection: $selectedExample) { example in
                Label(example.rawValue, systemImage: example.systemImage)
                    .tag(example)
            }
            .navigationTitle("Examples")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        } detail: {
            if let example = selectedExample {
                switch example {
                case .streaming: StreamingView()
                case .multiTurn: MultiTurnView()
                case .toolCalling: ToolCallingView()
                case .structuredOutput: StructuredOutputView()
                case .imageInput: ImageInputView()
                case .reasoning: ReasoningView()
                }
            } else {
                ContentUnavailableView("Select an Example", systemImage: "sidebar.left")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
    }
}
