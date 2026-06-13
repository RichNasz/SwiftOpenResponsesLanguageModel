import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesLanguageModel

@Suite(
	"Basic Generation",
	.enabled(if: IntegrationTestConfiguration.isConfigured, "Requires OPEN_RESPONSES_BASE_URL and OPEN_RESPONSES_API_KEY")
)
struct BasicGenerationTests {

	@Test(.timeLimit(.minutes(3)))
	func textGeneration() async throws {
		let session = IntegrationTestConfiguration.makeSession()
		let response = try await session.respond(to: "Reply with exactly the word 'hello' and nothing else.")
		#expect(!response.content.isEmpty)
	}

	@Test(.timeLimit(.minutes(3)))
	func streamingTextGeneration() async throws {
		let session = IntegrationTestConfiguration.makeSession()
		let stream = session.streamResponse(to: "Count from 1 to 5, one number per line.")
		var snapshots = 0
		var lastContent = ""
		for try await snapshot in stream {
			snapshots += 1
			lastContent = snapshot.content
		}
		#expect(snapshots > 0)
		#expect(!lastContent.isEmpty)
	}

	@Test(.timeLimit(.minutes(3)))
	func streamCollect() async throws {
		let session = IntegrationTestConfiguration.makeSession()
		let stream = session.streamResponse(to: "Reply with exactly the word 'hello' and nothing else.")
		let response = try await stream.collect()
		#expect(!response.content.isEmpty)
	}

	@Test(.timeLimit(.minutes(3)))
	func multiTurnConversation() async throws {
		let session = IntegrationTestConfiguration.makeSession()
		let first = try await session.respond(to: "My name is IntegrationTestBot. Reply with just OK.")
		#expect(!first.content.isEmpty)

		let second = try await session.respond(to: "What is my name? Reply with just the name, nothing else.")
		#expect(second.content.localizedStandardContains("IntegrationTestBot"))
	}

	@Test(.timeLimit(.minutes(3)))
	func systemInstructions() async throws {
		let session = IntegrationTestConfiguration.makeSession(
			instructions: "You are a calculator. You only respond with numbers, no words or explanation."
		)
		let response = try await session.respond(to: "What is 2 + 2?")
		#expect(response.content.contains("4"))
	}
}
