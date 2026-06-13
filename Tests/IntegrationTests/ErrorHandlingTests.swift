import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesLanguageModel

@Suite(
	"Error Handling",
	.enabled(if: IntegrationTestConfiguration.isConfigured, "Requires OPEN_RESPONSES_BASE_URL and OPEN_RESPONSES_API_KEY")
)
struct ErrorHandlingTests {

	@Test(.timeLimit(.minutes(1)))
	func invalidBaseURLThrows() async {
		let model = OpenResponsesLanguageModel(
			name: OpenResponsesModel(id: IntegrationTestConfiguration.modelID, capabilities: .init()),
			auth: .apiKey(IntegrationTestConfiguration.apiKey!),
			baseURL: URL(string: "http://localhost:1/v1/responses")!,
			timeout: 10
		)
		let session = LanguageModelSession(model: model)
		await #expect(throws: (any Error).self) {
			try await session.respond(to: "Hello")
		}
	}

	@Test(.timeLimit(.minutes(1)))
	func invalidEndpointPathThrows() async {
		let model = OpenResponsesLanguageModel(
			name: OpenResponsesModel(id: IntegrationTestConfiguration.modelID, capabilities: .init()),
			auth: .apiKey(IntegrationTestConfiguration.apiKey!),
			baseURL: URL(string: IntegrationTestConfiguration.baseURL!.absoluteString + "/nonexistent")!,
			timeout: 30
		)
		let session = LanguageModelSession(model: model)
		await #expect(throws: (any Error).self) {
			try await session.respond(to: "Hello")
		}
	}
}
