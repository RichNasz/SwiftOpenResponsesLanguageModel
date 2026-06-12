import Foundation
import FoundationModels
import SwiftOpenResponsesDSL

@available(macOS 27.0, iOS 27.0, visionOS 27.0, watchOS 27.0, *)
public struct OpenResponsesExecutor: LanguageModelExecutor {
	public typealias Model = OpenResponsesLanguageModel

	public struct Configuration: Hashable, Sendable {
		public let model: OpenResponsesModel
		public let baseURL: URL
		public let authMode: AuthMode
		public let timeout: TimeInterval
		public let customHeaders: [String: String]

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
