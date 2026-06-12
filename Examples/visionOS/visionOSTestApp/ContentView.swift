import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct ContentView: View {
	@AppStorage("api_key") private var apiKey = ""
	@AppStorage("base_url") private var baseURL = ""
	@AppStorage("model_id") private var modelID = ""
	@State private var prompt = ""
	@State private var response = ""
	@State private var isGenerating = false
	@State private var errorMessage: String?
	@State private var currentTask: Task<Void, Never>?
	@State private var effectiveURL: String = ""

	private var resolvedModel: OpenResponsesModel {
		OpenResponsesModel(id: modelID, capabilities: .init(toolCalling: false))
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Endpoint") {
					TextField("Base URL", text: $baseURL)
						.autocorrectionDisabled()
					TextField("Model ID", text: $modelID)
						.autocorrectionDisabled()
					SecureField("API Key (optional)", text: $apiKey)
						.autocorrectionDisabled()
				}

				Section {
					TextEditor(text: $prompt)
						.frame(minHeight: 80)
					HStack {
						Button(isGenerating ? "Stop" : "Send") {
							isGenerating ? cancelGeneration() : startGeneration()
						}
						.buttonStyle(.borderedProminent)
						.disabled(!isGenerating && !canSend)

						if isGenerating && !effectiveURL.isEmpty {
							Text(effectiveURL)
								.font(.caption2)
								.foregroundStyle(.secondary)
								.lineLimit(1)
								.truncationMode(.middle)
						}
					}
				} header: {
					Text("Prompt")
				}

				if let errorMessage {
					Section("Error") {
						Text(errorMessage)
							.foregroundStyle(.red)
							.font(.callout)
					}
				}

				if !response.isEmpty {
					Section("Response") {
						Text(response)
							.textSelection(.enabled)
							.font(.body)
					}
				}
			}
			.navigationTitle("OpenResponses")
		}
	}

	private var canSend: Bool {
		!modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
			&& !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	private func startGeneration() {
		currentTask = Task { @MainActor in
			await generate()
		}
	}

	private func cancelGeneration() {
		currentTask?.cancel()
		currentTask = nil
		isGenerating = false
	}

	@MainActor
	private func generate() async {
		isGenerating = true
		response = ""
		errorMessage = nil

		let cleaned = baseURL.filter { !$0.isWhitespace }
		guard !cleaned.isEmpty, let url = URL(string: cleaned) else {
			errorMessage = "Invalid base URL"
			isGenerating = false
			return
		}
		effectiveURL = url.absoluteString

		do {
			let lm = OpenResponsesLanguageModel(
				name: resolvedModel,
				auth: .apiKey(apiKey),
				baseURL: url
			)
			let session = LanguageModelSession(model: lm)
			let stream = session.streamResponse(to: prompt)
			for try await partial in stream {
				guard !Task.isCancelled else { break }
				response = partial.content
			}
		} catch is CancellationError {
			// User tapped Stop
		} catch {
			errorMessage = String(reflecting: error)
		}

		isGenerating = false
		currentTask = nil
	}
}
