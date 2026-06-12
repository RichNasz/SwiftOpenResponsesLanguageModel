import Foundation
import FoundationModels
import SwiftOpenResponsesDSL

public enum OpenResponsesError: Error, Sendable {
	case missingCredential
	case apiError(code: String, message: String)
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
