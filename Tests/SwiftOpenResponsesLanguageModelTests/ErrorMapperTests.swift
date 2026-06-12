import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesDSL
@testable import SwiftOpenResponsesLanguageModel

@Suite("ErrorMapper")
struct ErrorMapperTests {

	@Test func rateLimitMapsToRateLimited() {
		let mapped = ErrorMapper.map(LLMError.rateLimit)
		#expect(mapped is LanguageModelError)
	}

	@Test func serverError413MapsToContextSizeExceeded() {
		let mapped = ErrorMapper.map(LLMError.serverError(statusCode: 413, message: "too big"))
		#expect(mapped is LanguageModelError)
	}

	@Test func serverError413NilMessageUsesDefault() {
		let mapped = ErrorMapper.map(LLMError.serverError(statusCode: 413, message: nil))
		#expect(mapped is LanguageModelError)
	}

	@Test func networkErrorMapsToTimeout() {
		let mapped = ErrorMapper.map(LLMError.networkError("connection lost"))
		#expect(mapped is LanguageModelError)
	}

	@Test func missingBaseURLMapsToBadCredential() {
		let mapped = ErrorMapper.map(LLMError.missingBaseURL)
		#expect(mapped is OpenResponsesError)
	}

	@Test func missingModelMapsToBadCredential() {
		let mapped = ErrorMapper.map(LLMError.missingModel)
		#expect(mapped is OpenResponsesError)
	}

	@Test func otherLLMErrorPassesThrough() {
		let mapped = ErrorMapper.map(LLMError.invalidURL)
		#expect(mapped is LLMError)
	}

	@Test func nonLLMErrorPassesThrough() {
		struct CustomError: Error {}
		let error = CustomError()
		let mapped = ErrorMapper.map(error)
		#expect(mapped is CustomError)
	}
}
