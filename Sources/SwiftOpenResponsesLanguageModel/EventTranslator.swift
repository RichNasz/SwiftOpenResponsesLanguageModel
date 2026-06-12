import Foundation
import FoundationModels
import SwiftOpenResponsesDSL

@available(macOS 27.0, iOS 27.0, visionOS 27.0, watchOS 27.0, *)
struct EventTranslator: Sendable {
	let responseEntryID: String
	let toolCallsEntryID: String

	init(
		responseEntryID: String = UUID().uuidString,
		toolCallsEntryID: String = UUID().uuidString
	) {
		self.responseEntryID = responseEntryID
		self.toolCallsEntryID = toolCallsEntryID
	}

	func translate(
		_ events: AsyncThrowingStream<StreamEvent, Error>,
		into channel: LanguageModelExecutorGenerationChannel
	) async throws {
		var activeFunctionCalls: [Int: (id: String, name: String)] = [:]
		var reasoningEntryID: String?
		var sentCompletion = false

		for try await event in events {
			try Task.checkCancellation()

			switch event {
			case .contentPartDelta(let delta, _, _):
				await channel.send(
					.response(
						entryID: responseEntryID,
						action: .appendText(delta, tokenCount: 0)
					)
				)

			case .functionCallArgumentsDelta(let delta, let callId, let index):
				let name = activeFunctionCalls[index]?.name ?? ""
				await channel.send(
					.toolCalls(
						entryID: toolCallsEntryID,
						action: .toolCall(
							id: callId,
							name: name,
							action: .appendArguments(delta, tokenCount: 0)
						)
					)
				)

			case .outputItemAdded(let item, let index):
				switch item {
				case .functionCall(let call):
					activeFunctionCalls[index] = (id: call.callId, name: call.name)
					await channel.send(
						.toolCalls(
							entryID: toolCallsEntryID,
							action: .toolCall(
								id: call.callId,
								name: call.name,
								action: .appendArguments("", tokenCount: 0)
							)
						)
					)

				case .reasoning(let reasoning):
					let entryID = UUID().uuidString
					reasoningEntryID = entryID
					if let summaryText = reasoning.summaryText {
						await channel.send(
							.reasoning(
								entryID: entryID,
								action: .appendText(summaryText, tokenCount: 0)
							)
						)
					}

				default:
					break
				}

			case .reasoningSummaryPartAdded(let part, _, _):
				let entryID: String
				if let existing = reasoningEntryID {
					entryID = existing
				} else {
					let id = UUID().uuidString
					reasoningEntryID = id
					entryID = id
				}
				await channel.send(
					.reasoning(
						entryID: entryID,
						action: .appendText(part.text, tokenCount: 0)
					)
				)

			case .reasoningSummaryPartDone:
				break

			case .responseCompleted(let response):
				let inputTokens = response.usage?.inputTokens ?? 0
				let outputTokens = response.usage?.outputTokens ?? 0
				let cachedTokens = response.usage?.inputTokensDetails?.cachedTokens ?? 0
				let reasoningTokens = response.usage?.outputTokensDetails?.reasoningTokens ?? 0

				await channel.send(
					.response(
						entryID: responseEntryID,
						action: .updateUsage(
							input: .init(
								totalTokenCount: inputTokens,
								cachedTokenCount: cachedTokens
							),
							output: .init(
								totalTokenCount: outputTokens,
								reasoningTokenCount: reasoningTokens
							)
						)
					)
				)
				sentCompletion = true

			case .responseFailed(let response):
				if let error = response.error {
					throw OpenResponsesError.apiError(
						code: error.code,
						message: error.message
					)
				}

			case .error(let message):
				throw OpenResponsesError.streamError(message)

			case .responseCreated, .responseInProgress, .contentPartAdded,
				 .contentPartDone, .outputItemDone, .functionCallArgumentsDone,
				 .responseQueued, .responseIncomplete:
				break
			}
		}

		// Some providers (e.g. local LLM servers) never emit response.completed,
		// so the usage update is never sent. FoundationModels requires it to
		// finalize the generation — send zeros if we never got a real one.
		if !sentCompletion {
			await channel.send(
				.response(
					entryID: responseEntryID,
					action: .updateUsage(
						input: .init(totalTokenCount: 0, cachedTokenCount: 0),
						output: .init(totalTokenCount: 0, reasoningTokenCount: 0)
					)
				)
			)
		}
	}
}
