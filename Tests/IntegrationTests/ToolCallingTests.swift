import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct GetCurrentDateTool: Tool {
	let description = "Returns today's date in YYYY-MM-DD format"

	@Generable
	struct Arguments {}

	@concurrent
	func call(arguments: Arguments) async throws -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		return formatter.string(from: Date())
	}
}

struct EchoTool: Tool {
	let description = "Echoes back the input message exactly as received"

	@Generable
	struct Arguments {
		@Guide(description: "The message to echo back")
		var message: String
	}

	@concurrent
	func call(arguments: Arguments) async throws -> String {
		"ECHO: \(arguments.message)"
	}
}

@Suite(
	"Tool Calling",
	.enabled(
		if: IntegrationTestConfiguration.isConfigured && IntegrationTestConfiguration.supportsToolCalling,
		"Requires endpoint configuration and tool calling support"
	)
)
struct ToolCallingTests {

	@Test(.timeLimit(.minutes(3)))
	func toolCallRoundTrip() async throws {
		let session = IntegrationTestConfiguration.makeSession(
			capabilities: .init(toolCalling: true),
			tools: [GetCurrentDateTool()]
		)
		let response = try await session.respond(
			to: "What is today's date? You MUST use the get_current_date tool to answer."
		)
		#expect(!response.content.isEmpty)
	}

	@Test(
		.timeLimit(.minutes(3)),
		.enabled(if: IntegrationTestConfiguration.supportsStructuredOutput, "Requires structured output for argument decoding")
	)
	func toolCallWithArguments() async throws {
		let session = IntegrationTestConfiguration.makeSession(
			capabilities: .init(toolCalling: true),
			tools: [EchoTool()]
		)
		let response = try await session.respond(
			to: "Use the echo tool to echo the message 'integration test'. You MUST call the echo tool."
		)
		let toolOutput = response.transcriptEntries.compactMap { entry -> String? in
			guard case .toolOutput(let output) = entry else { return nil }
			return output.segments.compactMap { segment -> String? in
				if case .text(let text) = segment { return text.content }
				return nil
			}.joined()
		}.joined()
		#expect(toolOutput.contains("ECHO: integration test"))
	}

	@Test(.timeLimit(.minutes(3)))
	func toolCallRequired() async throws {
		let session = IntegrationTestConfiguration.makeSession(
			capabilities: .init(toolCalling: true),
			tools: [GetCurrentDateTool()]
		)
		let response = try await session.respond(
			to: "What is today's date?",
			options: GenerationOptions(toolCallingMode: .required)
		)
		#expect(response.transcriptEntries.contains { entry in
			if case .toolCalls = entry { return true }
			return false
		})
	}

	@Test(.timeLimit(.minutes(3)))
	func toolCallDisallowed() async throws {
		let session = IntegrationTestConfiguration.makeSession(
			capabilities: .init(toolCalling: true),
			tools: [GetCurrentDateTool()]
		)
		let response = try await session.respond(
			to: "Name a weekday. Do not call any tools.",
			options: GenerationOptions(toolCallingMode: .disallowed)
		)
		#expect(!response.content.isEmpty)
		#expect(!response.transcriptEntries.contains { entry in
			if case .toolCalls = entry { return true }
			return false
		})
	}
}
