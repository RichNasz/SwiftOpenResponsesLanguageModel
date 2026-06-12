import Foundation
import FoundationModels

@available(macOS 27.0, iOS 27.0, visionOS 27.0, watchOS 27.0, *)
public struct OpenResponsesLanguageModel: Sendable {
	public let model: OpenResponsesModel
	public let baseURL: URL
	public let timeout: TimeInterval
	let authMode: AuthMode

	public init(
		name: OpenResponsesModel,
		auth: AuthMode,
		baseURL: URL,
		timeout: TimeInterval = 60
	) {
		self.model = name
		self.authMode = auth
		self.baseURL = baseURL
		self.timeout = timeout
	}
}

@available(macOS 27.0, iOS 27.0, visionOS 27.0, watchOS 27.0, *)
extension OpenResponsesLanguageModel: LanguageModel {
	public typealias Executor = OpenResponsesExecutor

	public var capabilities: LanguageModelCapabilities {
		var caps: [LanguageModelCapabilities.Capability] = []
		if model.capabilities.toolCalling { caps.append(.toolCalling) }
		if model.capabilities.imageInput { caps.append(.vision) }
		if model.capabilities.reasoning { caps.append(.reasoning) }
		if model.capabilities.structuredOutput { caps.append(.guidedGeneration) }
		return LanguageModelCapabilities(capabilities: caps)
	}

	public var executorConfiguration: OpenResponsesExecutor.Configuration {
		let headers: [String: String] = switch authMode {
		case .apiKey: [:]
		case .proxied(let h): h
		}
		return .init(
			model: model,
			baseURL: baseURL,
			authMode: authMode,
			timeout: timeout,
			customHeaders: headers
		)
	}
}
