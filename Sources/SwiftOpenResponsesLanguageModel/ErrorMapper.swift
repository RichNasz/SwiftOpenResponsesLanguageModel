import Foundation
import FoundationModels
import SwiftOpenResponsesDSL

/// Errors originating from the Open Responses provider or transport layer.
///
/// Some errors from the underlying `LLMClient` are mapped to `LanguageModelError` for
/// framework compatibility (rate limits, context-size exceeded, timeouts). Errors that
/// don't map to a framework type surface as `OpenResponsesError` instead.
public enum OpenResponsesError: Error, Sendable {
	/// The executor could not find a usable API key or auth configuration.
	case missingCredential

	/// The provider returned an error response with a machine-readable code and human-readable message.
	///
	/// - Parameters:
	///   - code: Provider-specific error code (e.g., `"invalid_api_key"`).
	///   - message: Human-readable description from the provider.
	case apiError(code: String, message: String)

	/// The streaming connection failed with a provider-supplied error message.
	case streamError(String)
}

@available(macOS 27.0, iOS 27.0, visionOS 27.0, watchOS 27.0, *)
enum ErrorMapper {
	static func map(_ error: Error) -> Error {
		if let llmError = error as? LLMError {
			return mapLLMError(llmError)
		}
		return error
	}

	private static func mapLLMError(_ error: LLMError) -> Error {
		switch error {
		case .rateLimit:
			return LanguageModelError.rateLimited(
				.init(resetDate: nil, debugDescription: "Rate limit exceeded")
			)
		case .serverError(let statusCode, let message) where statusCode == 413:
			return LanguageModelError.contextSizeExceeded(
				.init(
					contextSize: 0,
					tokenCount: 0,
					debugDescription: message ?? "Request exceeded context size limit"
				)
			)
		case .networkError:
			return LanguageModelError.timeout(.init(debugDescription: "Network error"))
		case .missingBaseURL, .missingModel:
			return OpenResponsesError.missingCredential
		default:
			return error
		}
	}
}
