import Foundation
import FoundationModels
import SwiftOpenResponsesLanguageModel

enum IntegrationTestConfiguration {

	static let baseURL: URL? = {
		guard let string = ProcessInfo.processInfo.environment["OPEN_RESPONSES_BASE_URL"],
			  let url = URL(string: string) else { return nil }
		return url
	}()

	static let apiKey: String? = {
		ProcessInfo.processInfo.environment["OPEN_RESPONSES_API_KEY"]
	}()

	static let modelID: String = {
		ProcessInfo.processInfo.environment["OPEN_RESPONSES_MODEL_ID"] ?? "gpt-4o-mini"
	}()

	static let reasoningModelID: String? = {
		ProcessInfo.processInfo.environment["OPEN_RESPONSES_REASONING_MODEL_ID"]
	}()

	static let isConfigured: Bool = {
		baseURL != nil && apiKey != nil
	}()

	static let supportsStructuredOutput: Bool = {
		ProcessInfo.processInfo.environment["OPEN_RESPONSES_STRUCTURED_OUTPUT"] != "false"
	}()

	static let supportsToolCalling: Bool = {
		ProcessInfo.processInfo.environment["OPEN_RESPONSES_TOOL_CALLING"] != "false"
	}()

	static let supportsReasoning: Bool = {
		reasoningModelID != nil
	}()

	static func makeModel(
		capabilities: OpenResponsesModel.Capabilities = .init()
	) -> OpenResponsesLanguageModel {
		OpenResponsesLanguageModel(
			name: OpenResponsesModel(id: modelID, capabilities: capabilities),
			auth: .apiKey(apiKey!),
			baseURL: baseURL!,
			timeout: 120
		)
	}

	static func makeReasoningModel() -> OpenResponsesLanguageModel? {
		guard let reasoningID = reasoningModelID else { return nil }
		return OpenResponsesLanguageModel(
			name: OpenResponsesModel(id: reasoningID, capabilities: .init(reasoning: true)),
			auth: .apiKey(apiKey!),
			baseURL: baseURL!,
			timeout: 120
		)
	}

	static func makeSession(
		capabilities: OpenResponsesModel.Capabilities = .init(),
		instructions: String? = nil,
		tools: [any Tool] = []
	) -> LanguageModelSession {
		let model = makeModel(capabilities: capabilities)
		return LanguageModelSession(model: model, tools: tools, instructions: instructions)
	}
}
