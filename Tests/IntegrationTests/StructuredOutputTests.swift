import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesLanguageModel

@Generable(description: "A simple answer to a question")
struct SimpleAnswer {
	@Guide(description: "The answer to the question")
	var answer: String
}

@Suite(
	"Structured Output",
	.enabled(
		if: IntegrationTestConfiguration.isConfigured && IntegrationTestConfiguration.supportsStructuredOutput,
		"Requires endpoint configuration and structured output support"
	)
)
struct StructuredOutputTests {

	@Test(.timeLimit(.minutes(3)))
	func generableStructDecoding() async throws {
		let session = IntegrationTestConfiguration.makeSession(
			capabilities: .init(structuredOutput: true)
		)
		let response = try await session.respond(
			to: "What is the capital of France? Reply with just the city name.",
			generating: SimpleAnswer.self
		)
		#expect(!response.content.answer.isEmpty)
	}
}
