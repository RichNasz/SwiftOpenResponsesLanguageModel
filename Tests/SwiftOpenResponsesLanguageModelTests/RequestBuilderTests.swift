import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesDSL
@testable import SwiftOpenResponsesLanguageModel

@Suite("RequestBuilder")
struct RequestBuilderTests {

	// MARK: - Helpers

	private func buildRequest(
		entries: [Transcript.Entry] = [],
		tools: [Transcript.ToolDefinition] = [],
		schema: GenerationSchema? = nil,
		options: GenerationOptions = GenerationOptions(),
		contextOptions: ContextOptions = ContextOptions(),
		capabilities: OpenResponsesModel.Capabilities = .init()
	) throws -> ResponseRequest {
		let transcript = Transcript(entries: entries)
		let request = LanguageModelExecutorGenerationRequest(
			id: UUID(),
			transcript: transcript,
			enabledTools: tools,
			schema: schema,
			generationOptions: options,
			contextOptions: contextOptions,
			metadata: [:]
		)
		let model = OpenResponsesModel(id: "test-model", capabilities: capabilities)
		return try RequestBuilder.build(from: request, model: model).request
	}

	private func textSegment(_ text: String) -> Transcript.Segment {
		.text(.init(content: text))
	}

	private func items(from request: ResponseRequest) -> [InputItem] {
		if case .items(let items) = request.input { return items }
		return []
	}

	// MARK: - Transcript Entry Translation

	@Test func instructionsSetsInstructions() throws {
		let entry = Transcript.Entry.instructions(
			Transcript.Instructions(segments: [textSegment("Be helpful.")], toolDefinitions: [])
		)
		let request = try buildRequest(entries: [entry])
		#expect(request.instructions == "Be helpful.")
	}

	@Test func multipleInstructionsJoinedWithDoubleNewline() throws {
		let entry1 = Transcript.Entry.instructions(
			Transcript.Instructions(segments: [textSegment("Be helpful.")], toolDefinitions: [])
		)
		let entry2 = Transcript.Entry.instructions(
			Transcript.Instructions(segments: [textSegment("Be concise.")], toolDefinitions: [])
		)
		let request = try buildRequest(entries: [entry1, entry2])
		#expect(request.instructions == "Be helpful.\n\nBe concise.")
	}

	@Test func promptSingleTextProducesUserMessage() throws {
		let entry = Transcript.Entry.prompt(
			Transcript.Prompt(segments: [textSegment("Hello")])
		)
		let request = try buildRequest(entries: [entry])
		let inputItems = items(from: request)
		#expect(inputItems.count == 1)

		if case .message(let msg) = inputItems[0] {
			#expect(msg.role == .user)
			if case .text(let text) = msg.content {
				#expect(text == "Hello")
			} else {
				Issue.record("Expected .text content")
			}
		} else {
			Issue.record("Expected .message item")
		}
	}

	@Test func promptMultipleSegmentsProducesParts() throws {
		let entry = Transcript.Entry.prompt(
			Transcript.Prompt(segments: [textSegment("Hello"), textSegment("World")])
		)
		let request = try buildRequest(entries: [entry])
		let inputItems = items(from: request)

		if case .message(let msg) = inputItems[0] {
			#expect(msg.role == .user)
			if case .parts(let parts) = msg.content {
				#expect(parts.count == 2)
			} else {
				Issue.record("Expected .parts content for multi-segment prompt")
			}
		} else {
			Issue.record("Expected .message item")
		}
	}

	@Test func responseProducesAssistantMessage() throws {
		let entry = Transcript.Entry.response(
			Transcript.Response(assetIDs: [], segments: [textSegment("Answer")])
		)
		let request = try buildRequest(entries: [entry])
		let inputItems = items(from: request)
		#expect(inputItems.count == 1)

		if case .message(let msg) = inputItems[0] {
			#expect(msg.role == .assistant)
			if case .text(let text) = msg.content {
				#expect(text == "Answer")
			} else {
				Issue.record("Expected .text content")
			}
		} else {
			Issue.record("Expected .message item")
		}
	}

	@Test func emptyResponseSkipped() throws {
		let entry = Transcript.Entry.response(
			Transcript.Response(assetIDs: [], segments: [textSegment("")])
		)
		let request = try buildRequest(entries: [entry])
		let inputItems = items(from: request)
		#expect(inputItems.isEmpty)
	}

	@Test func toolOutputProducesFunctionCallOutput() throws {
		let entry = Transcript.Entry.toolOutput(
			Transcript.ToolOutput(id: "call-1", toolName: "get_date", segments: [textSegment("2026-06-12")])
		)
		let request = try buildRequest(entries: [entry])
		let inputItems = items(from: request)
		#expect(inputItems.count == 1)

		if case .functionCallOutput(let output) = inputItems[0] {
			#expect(output.callId == "call-1")
			#expect(output.output == "2026-06-12")
		} else {
			Issue.record("Expected .functionCallOutput item")
		}
	}

	@Test func emptyToolOutputFallsBackToEmptyJSON() throws {
		let entry = Transcript.Entry.toolOutput(
			Transcript.ToolOutput(id: "call-1", toolName: "get_date", segments: [textSegment("")])
		)
		let request = try buildRequest(entries: [entry])
		let inputItems = items(from: request)

		if case .functionCallOutput(let output) = inputItems[0] {
			#expect(output.output == "{}")
		} else {
			Issue.record("Expected .functionCallOutput item")
		}
	}

	// MARK: - Generation Options

	@Test func maxTokensForwarded() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			options: GenerationOptions(maximumResponseTokens: 500)
		)
		#expect(request.maxOutputTokens == 500)
	}

	@Test func maxTokensNilNotSet() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))]
		)
		#expect(request.maxOutputTokens == nil)
	}

	@Test func toolCallingModeRequired() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			options: GenerationOptions(toolCallingMode: .required)
		)
		#expect(request.toolChoice == .required)
	}

	@Test func toolCallingModeDisallowed() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			options: GenerationOptions(toolCallingMode: .disallowed)
		)
		#expect(request.toolChoice == ToolChoice.none)
	}

	@Test func toolCallingModeAllowed() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			options: GenerationOptions(toolCallingMode: .allowed)
		)
		#expect(request.toolChoice == .auto)
	}

	@Test func toolCallingModeNilNotSet() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))]
		)
		#expect(request.toolChoice == nil)
	}

	// MARK: - Sampling (capability-gated)

	@Test func samplingGreedySetsTemperatureZero() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			options: GenerationOptions(samplingMode: .greedy),
			capabilities: .init(samplingParams: true)
		)
		#expect(request.temperature == 0)
	}

	@Test func samplingNucleusSetsTopP() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			options: GenerationOptions(samplingMode: .random(probabilityThreshold: 0.9)),
			capabilities: .init(samplingParams: true)
		)
		#expect(request.topP == 0.9)
	}

	@Test func samplingDisabledSkipsAll() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			options: GenerationOptions(temperature: 0.5),
			capabilities: .init(samplingParams: false)
		)
		#expect(request.temperature == nil)
		#expect(request.topP == nil)
	}

	@Test func temperaturePassedThrough() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			options: GenerationOptions(temperature: 0.7),
			capabilities: .init(samplingParams: true)
		)
		#expect(request.temperature == 0.7)
	}

	// MARK: - Reasoning (capability-gated)

	@Test func reasoningLightMapsToLow() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			contextOptions: ContextOptions(reasoningLevel: .light),
			capabilities: .init(reasoning: true)
		)
		#expect(request.reasoning?.effort == .low)
	}

	@Test func reasoningModerateMapsToMedium() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			contextOptions: ContextOptions(reasoningLevel: .moderate),
			capabilities: .init(reasoning: true)
		)
		#expect(request.reasoning?.effort == .medium)
	}

	@Test func reasoningDeepMapsToHigh() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			contextOptions: ContextOptions(reasoningLevel: .deep),
			capabilities: .init(reasoning: true)
		)
		#expect(request.reasoning?.effort == .high)
	}

	@Test func reasoningDisabledSkips() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))],
			contextOptions: ContextOptions(reasoningLevel: .moderate),
			capabilities: .init(reasoning: false)
		)
		#expect(request.reasoning == nil)
	}

	// MARK: - Model ID

	@Test func modelIdPassedThrough() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))]
		)
		#expect(request.model == "test-model")
	}

	// MARK: - Stream flag

	@Test func streamAlwaysTrue() throws {
		let request = try buildRequest(
			entries: [.prompt(Transcript.Prompt(segments: [textSegment("Hi")]))]
		)
		#expect(request.stream == true)
	}
}
