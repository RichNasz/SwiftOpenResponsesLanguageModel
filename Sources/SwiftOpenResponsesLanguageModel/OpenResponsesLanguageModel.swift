import Foundation
import FoundationModels

/// A `LanguageModel` implementation that connects Apple's FoundationModels to any
/// Open Responses specification-compliant inference endpoint.
///
/// Pass an instance to `LanguageModelSession(model:)` and use the standard
/// FoundationModels session API — streaming, tool calling, structured output,
/// and reasoning all work transparently.
///
/// ```swift
/// import FoundationModels
/// import SwiftOpenResponsesLanguageModel
///
/// let model = OpenResponsesModel(
///     id: "gpt-4o",
///     capabilities: .init(structuredOutput: true, imageInput: true)
/// )
/// let lm = OpenResponsesLanguageModel(
///     name: model,
///     auth: .apiKey("sk-your-key"),
///     baseURL: URL(string: "https://api.openai.com/v1/responses")!
/// )
///
/// let session = LanguageModelSession(model: lm)
/// let stream = session.streamResponse(to: "Explain Swift concurrency.")
/// for try await partial in stream {
///     print(partial.content)
/// }
/// ```
///
/// - Important: The `name:` parameter takes an ``OpenResponsesModel``, not a plain string.
@available(macOS 27.0, iOS 27.0, visionOS 27.0, watchOS 27.0, *)
public struct OpenResponsesLanguageModel: Sendable {
	/// The model identity and capability flags for this endpoint.
	public let model: OpenResponsesModel

	/// The full URL of the Open Responses endpoint, including path
	/// (e.g., `https://api.openai.com/v1/responses`).
	public let baseURL: URL

	/// Request timeout interval in seconds. Default: `60`.
	public let timeout: TimeInterval

	let authMode: AuthMode

	/// Creates a language model targeting a remote Open Responses endpoint.
	///
	/// - Parameters:
	///   - name: The model identity and capability flags.
	///   - auth: Authentication strategy — API key or proxied headers.
	///   - baseURL: Full URL of the Open Responses endpoint, including path.
	///   - timeout: Request timeout in seconds. Default: `60`.
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

	/// The FoundationModels capabilities derived from this model's capability flags.
	public var capabilities: LanguageModelCapabilities {
		var caps: [LanguageModelCapabilities.Capability] = []
		if model.capabilities.toolCalling { caps.append(.toolCalling) }
		if model.capabilities.imageInput { caps.append(.vision) }
		if model.capabilities.reasoning { caps.append(.reasoning) }
		if model.capabilities.structuredOutput { caps.append(.guidedGeneration) }
		return LanguageModelCapabilities(caps)
	}

	/// The configuration used to construct the executor for each generation request.
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
