import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesDSL
@testable import SwiftOpenResponsesLanguageModel

@Suite("EventTranslator")
struct EventTranslatorTests {

	// MARK: - Helpers

	private func makeStream(
		events: [StreamEvent]
	) -> AsyncThrowingStream<StreamEvent, Error> {
		AsyncThrowingStream { continuation in
			for event in events {
				continuation.yield(event)
			}
			continuation.finish()
		}
	}

	private func makeStreamThrowing(
		events: [StreamEvent],
		error: Error
	) -> AsyncThrowingStream<StreamEvent, Error> {
		AsyncThrowingStream { continuation in
			for event in events {
				continuation.yield(event)
			}
			continuation.finish(throwing: error)
		}
	}

	private func translate(
		events: [StreamEvent]
	) async throws {
		let translator = EventTranslator(
			responseEntryID: "resp-1",
			toolCallsEntryID: "tc-1"
		)
		let channel = LanguageModelExecutorGenerationChannel()
		try await translator.translate(makeStream(events: events), into: channel)
	}

	private func completedResponse(
		usage: ResponseObject.Usage? = nil,
		error: ResponseObject.ErrorInfo? = nil
	) -> ResponseObject {
		ResponseObject(
			id: "resp-1",
			model: "test",
			output: [],
			status: .completed,
			usage: usage,
			error: error
		)
	}

	private func failedResponse(
		code: String = "error",
		message: String = "something failed"
	) -> ResponseObject {
		ResponseObject(
			id: "resp-1",
			model: "test",
			output: [],
			status: .failed,
			error: .init(code: code, message: message)
		)
	}

	// MARK: - Content Deltas

	@Test func contentDeltaProcessedSuccessfully() async throws {
		try await translate(events: [
			.contentPartDelta(delta: "Hello", index: 0, contentIndex: 0),
			.contentPartDelta(delta: " world", index: 0, contentIndex: 0),
			.responseCompleted(completedResponse())
		])
	}

	// MARK: - Function Calls

	@Test func functionCallAddedAndDeltaProcessed() async throws {
		let call = FunctionCallItem(
			id: "fc-1", callId: "call-1", name: "get_date", arguments: ""
		)
		try await translate(events: [
			.outputItemAdded(.functionCall(call), index: 0),
			.functionCallArgumentsDelta(delta: "{}", callId: "call-1", index: 0),
			.responseCompleted(completedResponse())
		])
	}

	@Test func multipleFunctionCallsTrackedByIndex() async throws {
		let call1 = FunctionCallItem(
			id: "fc-1", callId: "call-1", name: "get_date", arguments: ""
		)
		let call2 = FunctionCallItem(
			id: "fc-2", callId: "call-2", name: "get_time", arguments: ""
		)
		try await translate(events: [
			.outputItemAdded(.functionCall(call1), index: 0),
			.outputItemAdded(.functionCall(call2), index: 1),
			.functionCallArgumentsDelta(delta: "{}", callId: "call-1", index: 0),
			.functionCallArgumentsDelta(delta: "{}", callId: "call-2", index: 1),
			.responseCompleted(completedResponse())
		])
	}

	// MARK: - Reasoning

	@Test func reasoningItemWithSummaryProcessed() async throws {
		let reasoning = ReasoningItem(
			id: "r-1",
			summary: [ReasoningSummary(type: "summary_text", text: "thinking...")]
		)
		try await translate(events: [
			.outputItemAdded(.reasoning(reasoning), index: 0),
			.responseCompleted(completedResponse())
		])
	}

	@Test func reasoningItemWithoutSummaryProcessed() async throws {
		let reasoning = ReasoningItem(id: "r-1")
		try await translate(events: [
			.outputItemAdded(.reasoning(reasoning), index: 0),
			.responseCompleted(completedResponse())
		])
	}

	@Test func reasoningSummaryPartProcessed() async throws {
		let part = ReasoningSummary(type: "summary_text", text: "step 1")
		try await translate(events: [
			.reasoningSummaryPartAdded(part: part, index: 0, summaryIndex: 0),
			.responseCompleted(completedResponse())
		])
	}

	// MARK: - Completion & Usage

	@Test func responseCompletedWithUsage() async throws {
		let usage = ResponseObject.Usage(
			inputTokens: 100,
			outputTokens: 50,
			totalTokens: 150,
			outputTokensDetails: .init(reasoningTokens: 10),
			inputTokensDetails: .init(cachedTokens: 20)
		)
		try await translate(events: [
			.contentPartDelta(delta: "Hi", index: 0, contentIndex: 0),
			.responseCompleted(completedResponse(usage: usage))
		])
	}

	@Test func responseCompletedWithNilUsage() async throws {
		try await translate(events: [
			.contentPartDelta(delta: "Hi", index: 0, contentIndex: 0),
			.responseCompleted(completedResponse())
		])
	}

	@Test func noCompletionSendsFallbackUsage() async throws {
		try await translate(events: [
			.contentPartDelta(delta: "Hello", index: 0, contentIndex: 0),
		])
	}

	// MARK: - Error Events

	@Test func responseFailedThrowsApiError() async {
		await #expect(throws: OpenResponsesError.self) {
			try await translate(events: [
				.responseFailed(failedResponse(code: "invalid_api_key", message: "bad key"))
			])
		}
	}

	@Test func errorEventThrowsStreamError() async {
		await #expect(throws: OpenResponsesError.self) {
			try await translate(events: [
				.error("connection dropped")
			])
		}
	}

	// MARK: - Ignored Events

	@Test func ignoredEventsProcessWithoutError() async throws {
		try await translate(events: [
			.responseCreated(completedResponse()),
			.responseInProgress(completedResponse()),
			.contentPartAdded(index: 0, contentIndex: 0),
			.contentPartDone(index: 0, contentIndex: 0),
			.responseCompleted(completedResponse())
		])
	}

	// MARK: - Mixed Event Sequences

	@Test func fullConversationSequence() async throws {
		let call = FunctionCallItem(
			id: "fc-1", callId: "call-1", name: "get_date", arguments: ""
		)
		let usage = ResponseObject.Usage(
			inputTokens: 50, outputTokens: 30, totalTokens: 80
		)
		try await translate(events: [
			.responseCreated(completedResponse()),
			.contentPartDelta(delta: "Let me check", index: 0, contentIndex: 0),
			.outputItemAdded(.functionCall(call), index: 1),
			.functionCallArgumentsDelta(delta: "{}", callId: "call-1", index: 1),
			.functionCallArgumentsDone(arguments: "{}", callId: "call-1", index: 1),
			.contentPartDelta(delta: " the date.", index: 0, contentIndex: 0),
			.responseCompleted(completedResponse(usage: usage))
		])
	}
}
