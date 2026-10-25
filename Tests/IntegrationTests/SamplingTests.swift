import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesLanguageModel

@Suite(
	"Sampling",
	.enabled(if: IntegrationTestConfiguration.isConfigured, "Requires OPEN_RESPONSES_BASE_URL and OPEN_RESPONSES_API_KEY")
)
struct SamplingTests {

	@Test(.timeLimit(.minutes(3)))
	func greedyRespectsMaxTokens() async throws {
		let session = IntegrationTestConfiguration.makeSession(
			capabilities: .init(samplingParams: true)
		)
		let response = try await session.respond(
			to: "Count from 1 to 50, separated by spaces.",
			options: GenerationOptions(samplingMode: .greedy, maximumResponseTokens: 64)
		)
		#expect(!response.content.isEmpty)
		let outputTokens = response.usage.output.totalTokenCount
		#expect(outputTokens > 0)
		#expect(outputTokens <= 64)
	}
}
