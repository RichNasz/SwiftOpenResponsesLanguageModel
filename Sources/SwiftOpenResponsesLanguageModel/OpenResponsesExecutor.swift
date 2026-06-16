import Foundation
import FoundationModels
import SwiftOpenResponsesDSL

/// The `LanguageModelExecutor` that bridges FoundationModels generation requests
/// to an Open Responses streaming endpoint via `LLMClient`.
///
/// You do not create this type directly — FoundationModels instantiates it
/// using the ``Configuration`` returned by ``OpenResponsesLanguageModel/executorConfiguration``.
@available(macOS 27.0, iOS 27.0, visionOS 27.0, watchOS 27.0, *)
public struct OpenResponsesExecutor: LanguageModelExecutor {
	public typealias Model = OpenResponsesLanguageModel

	/// Connection parameters for the executor.
	public struct Configuration: Hashable, Sendable {
		/// The model identity and capability flags.
		public let model: OpenResponsesModel

		/// Full URL of the Open Responses endpoint.
		public let baseURL: URL

		/// Authentication strategy.
		public let authMode: AuthMode

		/// Request timeout in seconds.
		public let timeout: TimeInterval

		/// Additional HTTP headers sent with every request.
		public let customHeaders: [String: String]

		/// Creates an executor configuration.
		///
		/// - Parameters:
		///   - model: The model identity and capability flags.
		///   - baseURL: Full URL of the Open Responses endpoint.
		///   - authMode: Authentication strategy.
		///   - timeout: Request timeout in seconds.
		///   - customHeaders: Additional HTTP headers. Default: empty.
		public init(
			model: OpenResponsesModel,
			baseURL: URL,
			authMode: AuthMode,
			timeout: TimeInterval,
			customHeaders: [String: String] = [:]
		) {
			self.model = model
			self.baseURL = baseURL
			self.authMode = authMode
			self.timeout = timeout
			self.customHeaders = customHeaders
		}
	}

	private let configuration: Configuration
	private let client: LLMClient

	/// Creates an executor from the given configuration.
	///
	/// - Parameter configuration: Connection parameters including URL, auth, and model identity.
	/// - Throws: An error if the `LLMClient` cannot be initialized (e.g., invalid base URL).
	public init(configuration: Configuration) throws {
		self.configuration = configuration
		let apiKey = switch configuration.authMode {
		case .apiKey(let key): key.isEmpty ? "lm-studio" : key
		case .proxied: ""
		}
		self.client = try LLMClient(
			baseURL: configuration.baseURL.absoluteString,
			apiKey: apiKey,
			customHeaders: configuration.customHeaders
		)
	}

	/// Streams a generation response from the remote endpoint into the FoundationModels channel.
	///
	/// - Parameters:
	///   - request: The generation request containing transcript, tools, and options.
	///   - model: The language model that owns this executor.
	///   - channel: The channel to stream response actions into.
	/// - Throws: ``OpenResponsesError`` for provider errors, or `LanguageModelError` for
	///   mapped framework errors (rate limits, context size, timeouts).
	public func respond(
		to request: LanguageModelExecutorGenerationRequest,
		model: OpenResponsesLanguageModel,
		streamingInto channel: LanguageModelExecutorGenerationChannel
	) async throws {
		do {
			let built = try RequestBuilder.build(
				from: request,
				model: configuration.model
			)
			let translator = EventTranslator()
			try await translator.translate(
				client.stream(built.request),
				into: channel
			)
		} catch {
			throw ErrorMapper.map(error)
		}
	}
}
