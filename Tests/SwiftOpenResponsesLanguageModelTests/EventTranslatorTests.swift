import Testing
import Foundation
import os
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

	private func sendCount(
		events: [StreamEvent]
	) async throws -> Int {
		let translator = EventTranslator(
			responseEntryID: "resp-1",
			toolCallsEntryID: "tc-1"
		)
		let channel = LanguageModelExecutorGenerationChannel()
		let count = OSAllocatedUnfairLock(initialState: 0)
		let drainTask = Task {
			for try await _ in channel {
				count.withLock { $0 += 1 }
			}
		}
		defer { drainTask.cancel() }
		try await translator.translate(makeStream(events: events), into: channel)
		try await Task.sleep(for: .milliseconds(50))
		return count.withLock { $0 }
	}

	private func translate(
		events: [StreamEvent]
	) async throws {
		let translator = EventTranslator(
			responseEntryID: "resp-1",
			toolCallsEntryID: "tc-1"
		)
		let channel = LanguageModelExecutorGenerationChannel()
		let drainTask = Task { for try await _ in channel {} }
		defer { drainTask.cancel() }
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

	@Test func outputTextDeltaDoesNotAppendAgain() async throws {
		let count = try await sendCount(events: [
			.contentPartDelta(delta: "Hello", index: 0, contentIndex: 0),
			.outputTextDelta(
				delta: "Hello",
				index: 0,
				contentIndex: 0,
				itemId: "item-1",
				sequenceNumber: 1,
				logprobs: nil
			),
			.outputTextDone(
				text: "Hello",
				index: 0,
				contentIndex: 0,
				itemId: "item-1",
				sequenceNumber: 2,
				logprobs: nil
			),
			.responseCompleted(completedResponse())
		])
		#expect(count == 3)
	}

	@Test func reasoningDeltaAppendsOnce() async throws {
		let count = try await sendCount(events: [
			.reasoningDelta(
				delta: "think",
				index: 0,
				contentIndex: 0,
				itemId: "item-1",
				sequenceNumber: 1
			),
			.reasoningDone(
				text: "think",
				index: 0,
				contentIndex: 0,
				itemId: "item-1",
				sequenceNumber: 2
			),
			.responseCompleted(completedResponse())
		])
		#expect(count == 3)
	}

	@Test func functionCallDoneSuppliesArguments() async throws {
		let added = FunctionCallItem(
			id: "fc-1", callId: "call-1", name: "echo", arguments: ""
		)
		let done = FunctionCallItem(
			id: "fc-1", callId: "call-1", name: "echo", arguments: #"{"message":"hi"}"#
		)
		let count = try await sendCount(events: [
			.outputItemAdded(.functionCall(added), index: 0),
			.outputItemDone(.functionCall(done), index: 0),
			.responseCompleted(completedResponse())
		])
		#expect(count == 4)
	}

	@Test func reasoningDoneSuppliesContent() async throws {
		let added = ReasoningItem(id: "r-1", summary: [], content: [])
		let done = ReasoningItem(
			id: "r-1",
			summary: [],
			content: [ReasoningContent(type: "reasoning_text", text: "working")]
		)
		let count = try await sendCount(events: [
			.outputItemAdded(.reasoning(added), index: 0),
			.outputItemDone(.reasoning(done), index: 0),
			.responseCompleted(completedResponse())
		])
		#expect(count == 3)
	}

	@Test func refusalDoneThrowsRefusal() async {
		await #expect(throws: LanguageModelError.self) {
			try await translate(events: [
				.refusalDone(
					refusal: "no",
					index: 0,
					contentIndex: 0,
					itemId: "item-1",
					sequenceNumber: 1
				)
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

	@Test func responseIdentityUsesResponseModel() {
		let values = EventTranslator.responseIdentityMetadata(
			model: "server",
			fallbackModelID: "fallback",
			responseID: "resp-9"
		)
		#expect(values["model"] == "server")
		#expect(values["response_id"] == "resp-9")
	}

	@Test func responseIdentityUsesFallbackWhenModelEmpty() {
		let values = EventTranslator.responseIdentityMetadata(
			model: "",
			fallbackModelID: "fallback",
			responseID: "resp-9"
		)
		#expect(values["model"] == "fallback")
		#expect(values["response_id"] == "resp-9")
	}

	@Test func responseIdentityOmitsEmptyModel() {
		let values = EventTranslator.responseIdentityMetadata(
			model: "",
			fallbackModelID: "",
			responseID: "resp-9"
		)
		#expect(values["model"] == nil)
		#expect(values["response_id"] == "resp-9")
	}

	@Test func annotationMetadataUsesIndexes() {
		let annotation = Annotation(
			type: "url_citation",
			startIndex: 1,
			endIndex: 4,
			url: "https://example.com",
			title: "Example"
		)
		let values = EventTranslator.annotationMetadata(
			annotation: annotation,
			outputIndex: 1,
			contentIndex: 0,
			annotationIndex: 2
		)
		#expect(values["annotation.1.0.2.type"] == "url_citation")
		#expect(values["annotation.1.0.2.url"] == "https://example.com")
		#expect(values["annotation.1.0.2.title"] == "Example")
		#expect(values["annotation.1.0.2.start_index"] == "1")
		#expect(values["annotation.1.0.2.end_index"] == "4")
	}

	@Test func annotationMetadataOmitsNilFields() {
		let values = EventTranslator.annotationMetadata(
			annotation: Annotation(type: "file_citation"),
			outputIndex: 1,
			contentIndex: 0,
			annotationIndex: 2
		)
		#expect(values["annotation.1.0.2.type"] == "file_citation")
		#expect(values["annotation.1.0.2.url"] == nil)
		#expect(values["annotation.1.0.2.title"] == nil)
	}

	@Test func signatureDataDecodesBase64() {
		#expect(EventTranslator.signatureData(encryptedContent: "YQ==") == Data("a".utf8))
	}

	@Test func signatureDataFallsBackToUTF8() {
		let raw = "not base64!"
		#expect(EventTranslator.signatureData(encryptedContent: raw) == Data(raw.utf8))
	}

	@Test func signatureDataEmptyIsNil() {
		#expect(EventTranslator.signatureData(encryptedContent: "") == nil)
	}

	@Test func responseCreatedSendsIdentityOnce() async throws {
		let count = try await sendCount(events: [
			.responseCreated(completedResponse()),
			.responseCompleted(completedResponse())
		])
		#expect(count == 2)
	}

	@Test func responseCompletedSendsIdentityWhenCreatedMissing() async throws {
		let count = try await sendCount(events: [
			.responseCompleted(completedResponse())
		])
		#expect(count == 2)
	}

	@Test func annotationMetadataIsForwarded() async throws {
		let annotation = Annotation(type: "url_citation", url: "https://example.com", title: "Example")
		let count = try await sendCount(events: [
			.outputTextAnnotationAdded(
				annotation: annotation,
				index: 1,
				contentIndex: 0,
				annotationIndex: 2,
				itemId: "item-1",
				sequenceNumber: 1
			),
			.responseCompleted(completedResponse())
		])
		#expect(count == 3)
	}

	@Test func nilAnnotationIsIgnored() async throws {
		let count = try await sendCount(events: [
			.outputTextAnnotationAdded(
				annotation: nil,
				index: 0,
				contentIndex: 0,
				annotationIndex: 0,
				itemId: "item-1",
				sequenceNumber: 1
			),
			.responseCompleted(completedResponse())
		])
		#expect(count == 2)
	}

	@Test func encryptedReasoningSendsSignatureOnce() async throws {
		let item = ReasoningItem(id: "r-1", encryptedContent: "YQ==")
		let count = try await sendCount(events: [
			.outputItemAdded(.reasoning(item), index: 0),
			.outputItemDone(.reasoning(item), index: 0),
			.responseCompleted(completedResponse())
		])
		#expect(count == 3)
	}

	@Test func encryptedReasoningStillAppendsLaterContent() async throws {
		let added = ReasoningItem(id: "r-1", summary: [], encryptedContent: "YQ==")
		let done = ReasoningItem(
			id: "r-1",
			content: [ReasoningContent(type: "reasoning_text", text: "working")]
		)
		let count = try await sendCount(events: [
			.outputItemAdded(.reasoning(added), index: 0),
			.outputItemDone(.reasoning(done), index: 0),
			.responseCompleted(completedResponse())
		])
		#expect(count == 4)
	}

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
