import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesLanguageModel

@Suite(
	"Reasoning",
	.enabled(
		if: IntegrationTestConfiguration.isConfigured && IntegrationTestConfiguration.supportsReasoning,
		"Requires endpoint configuration and OPEN_RESPONSES_REASONING_MODEL_ID"
	)
)
struct ReasoningTests {

	@Test(.timeLimit(.minutes(3)))
	func reasoningRespond() async throws {
		let model = IntegrationTestConfiguration.makeReasoningModel()!
		let session = LanguageModelSession(model: model)
		let response = try await session.respond(
			to: "What is 15 * 17?",
			contextOptions: ContextOptions(reasoningLevel: .moderate)
		)
		#expect(!response.content.isEmpty)
		#expect(response.content.contains("255"))
		let reasoningText = response.transcriptEntries.compactMap { entry -> String? in
			guard case .reasoning(let reasoning) = entry else { return nil }
			return reasoning.segments.compactMap { segment -> String? in
				if case .text(let text) = segment { return text.content }
				return nil
			}.joined()
		}.joined()
		#expect(!reasoningText.isEmpty)
	}

	@Test(.timeLimit(.minutes(3)))
	func reasoningStream() async throws {
		let model = IntegrationTestConfiguration.makeReasoningModel()!
		let session = LanguageModelSession(model: model)
		let stream = session.streamResponse(
			to: "What is 15 * 17?",
			contextOptions: ContextOptions(reasoningLevel: .moderate)
		)
		var snapshots = 0
		var lastContent = ""
		for try await snapshot in stream {
			snapshots += 1
			lastContent = snapshot.content
		}
		#expect(snapshots > 0)
		#expect(!lastContent.isEmpty)
	}
}
