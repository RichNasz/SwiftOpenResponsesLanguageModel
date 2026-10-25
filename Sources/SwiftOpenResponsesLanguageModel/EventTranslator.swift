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
		into channel: LanguageModelExecutorGenerationChannel,
		fallbackModelID: String = ""
	) async throws {
		var activeFunctionCalls: [Int: (id: String, name: String)] = [:]
		var pendingArgumentDeltas: [Int: [(delta: String, callId: String)]] = [:]
		var argumentDeltasApplied: Set<Int> = []
		var reasoningEntryID: String?
		var sentReasoningText = false
		var sentReasoningSignature = false
		var sentResponseMetadata = false
		var sentCompletion = false

		func ensureReasoningEntryID() -> String {
			if let existing = reasoningEntryID {
				return existing
			}
			let id = UUID().uuidString
			reasoningEntryID = id
			return id
		}

		func appendReasoning(_ text: String) async {
			guard !text.isEmpty else { return }
			sentReasoningText = true
			await channel.send(
				.reasoning(
					entryID: ensureReasoningEntryID(),
					action: .appendText(text, tokenCount: 0)
				)
			)
		}

		func sendSignatureIfNeeded(_ encryptedContent: String?) async {
			guard !sentReasoningSignature,
				  let encryptedContent,
				  let data = Self.signatureData(encryptedContent: encryptedContent) else {
				return
			}
			sentReasoningSignature = true
			await channel.send(
				.reasoning(
					entryID: ensureReasoningEntryID(),
					action: .updateSignature(data, tokenCount: 0)
				)
			)
		}

		func sendResponseIdentity(_ response: ResponseObject) async {
			guard !sentResponseMetadata else { return }
			sentResponseMetadata = true
			await channel.send(
				.response(
					entryID: responseEntryID,
					action: .updateMetadata(Self.metadataPayload(Self.responseIdentityMetadata(
						model: response.model,
						fallbackModelID: fallbackModelID,
						responseID: response.id
					)))
				)
			)
		}

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
				if let call = activeFunctionCalls[index] {
					argumentDeltasApplied.insert(index)
					await channel.send(
						.toolCalls(
							entryID: toolCallsEntryID,
							action: .toolCall(
								id: callId,
								name: call.name,
								action: .appendArguments(delta, tokenCount: 0)
							)
						)
					)
				} else {
					pendingArgumentDeltas[index, default: []].append((delta: delta, callId: callId))
				}

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
					if let buffered = pendingArgumentDeltas.removeValue(forKey: index) {
						argumentDeltasApplied.insert(index)
						for pending in buffered {
							await channel.send(
								.toolCalls(
									entryID: toolCallsEntryID,
									action: .toolCall(
										id: pending.callId,
										name: call.name,
										action: .appendArguments(pending.delta, tokenCount: 0)
									)
								)
							)
						}
					}

				case .reasoning(let reasoning):
					if let summaryText = reasoning.summaryText {
						await appendReasoning(summaryText)
					}
					await sendSignatureIfNeeded(reasoning.encryptedContent)

				default:
					break
				}

			case .outputItemDone(let item, let index):
				switch item {
				case .functionCall(let call):
					if !argumentDeltasApplied.contains(index), !call.arguments.isEmpty {
						await channel.send(
							.toolCalls(
								entryID: toolCallsEntryID,
								action: .toolCall(
									id: call.callId,
									name: call.name,
									action: .appendArguments(call.arguments, tokenCount: 0)
								)
							)
						)
					}
				case .reasoning(let reasoning):
					if !sentReasoningText {
						if let summaryText = reasoning.summaryText, !summaryText.isEmpty {
							await appendReasoning(summaryText)
						} else if let contentText = reasoning.contentText {
							await appendReasoning(contentText)
						}
					}
					await sendSignatureIfNeeded(reasoning.encryptedContent)
				default:
					break
				}

			case .reasoningSummaryPartAdded(let part, _, _):
				await appendReasoning(part.text)

			case .reasoningSummaryPartDone:
				break

			case .reasoningDelta(let delta, _, _, _, _):
				await appendReasoning(delta)

			case .reasoningSummaryTextDelta(let delta, _, _, _, _):
				await appendReasoning(delta)

			case .refusalDone(let refusal, _, _, _, _):
				throw LanguageModelError.refusal(
					.init(explanation: refusal, debugDescription: refusal)
				)

			case .responseCreated(let response):
				await sendResponseIdentity(response)

			case .outputTextAnnotationAdded(let annotation, let index, let contentIndex, let annotationIndex, _, _):
				guard let annotation else { break }
				await channel.send(
					.response(
						entryID: responseEntryID,
						action: .updateMetadata(Self.metadataPayload(Self.annotationMetadata(
							annotation: annotation,
							outputIndex: index,
							contentIndex: contentIndex,
							annotationIndex: annotationIndex
						)))
					)
				)

			case .responseCompleted(let response):
				await sendResponseIdentity(response)
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

			case .responseInProgress, .contentPartAdded,
				 .contentPartDone, .functionCallArgumentsDone,
				 .responseQueued, .responseIncomplete,
				 .outputTextDelta, .outputTextDone,
				 .refusalDelta, .reasoningDone, .reasoningSummaryTextDone:
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

	static func responseIdentityMetadata(
		model: String,
		fallbackModelID: String,
		responseID: String
	) -> [String: String] {
		var values = ["response_id": responseID]
		let chosen = model.isEmpty ? fallbackModelID : model
		if !chosen.isEmpty {
			values["model"] = chosen
		}
		return values
	}

	static func annotationMetadata(
		annotation: Annotation,
		outputIndex: Int,
		contentIndex: Int,
		annotationIndex: Int
	) -> [String: String] {
		let prefix = "annotation.\(outputIndex).\(contentIndex).\(annotationIndex)"
		var values = ["\(prefix).type": annotation.type]
		if let url = annotation.url {
			values["\(prefix).url"] = url
		}
		if let title = annotation.title {
			values["\(prefix).title"] = title
		}
		if let startIndex = annotation.startIndex {
			values["\(prefix).start_index"] = String(startIndex)
		}
		if let endIndex = annotation.endIndex {
			values["\(prefix).end_index"] = String(endIndex)
		}
		return values
	}

	static func signatureData(encryptedContent: String) -> Data? {
		guard !encryptedContent.isEmpty else { return nil }
		if let decoded = Data(base64Encoded: encryptedContent) {
			return decoded
		}
		return Data(encryptedContent.utf8)
	}

	private static func metadataPayload(
		_ values: [String: String]
	) -> [String: any ConvertibleToGeneratedContent] {
		var payload: [String: any ConvertibleToGeneratedContent] = [:]
		for (key, value) in values {
			payload[key] = value
		}
		return payload
	}
}
