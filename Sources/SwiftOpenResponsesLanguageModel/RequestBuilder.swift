import Foundation
import FoundationModels
import SwiftOpenResponsesDSL
import CoreGraphics
import ImageIO

@available(macOS 27.0, iOS 27.0, visionOS 27.0, watchOS 27.0, *)
enum RequestBuilder {

	struct Built {
		var request: ResponseRequest
	}

	static func build(
		from request: LanguageModelExecutorGenerationRequest,
		model: OpenResponsesModel
	) throws -> Built {
		var instructions: String?
		var inputItems: [InputItem] = []

		for entry in request.transcript {
			switch entry {
			case .instructions(let i):
				let text = segmentsToText(i.segments)
				if let existing = instructions {
					instructions = existing + "\n\n" + text
				} else {
					instructions = text
				}

			case .prompt(let p):
				let parts = segmentsToContentParts(p.segments)
				if parts.count == 1, case .inputText(let text) = parts[0] {
					inputItems.append(
						.message(InputMessage(role: .user, content: .text(text)))
					)
				} else if !parts.isEmpty {
					inputItems.append(
						.message(InputMessage(role: .user, content: .parts(parts)))
					)
				}

			case .response(let r):
				let text = segmentsToText(r.segments)
				if !text.isEmpty {
					inputItems.append(
						.message(InputMessage(role: .assistant, content: .text(text)))
					)
				}

			case .toolCalls(let calls):
				for call in calls {
					inputItems.append(
						.functionCall(FunctionCallItem(
							id: call.id,
							callId: call.id,
							name: call.toolName,
							arguments: call.arguments.jsonString
						))
					)
				}

			case .toolOutput(let out):
				let text = segmentsToText(out.segments)
				inputItems.append(
					.functionCallOutput(FunctionCallOutputItem(
						callId: out.id,
						output: text.isEmpty ? "{}" : text
					))
				)

			case .reasoning:
				break

			@unknown default:
				break
			}
		}

		let tools: [FunctionToolParam] = request.enabledToolDefinitions.map { def in
			FunctionToolParam(
				name: def.name,
				description: def.description,
				parameters: jsonSchemaFromGenerationSchema(def.parameters),
				strict: model.capabilities.structuredOutput ? true : nil
			)
		}

		var responseRequest = try ResponseRequest(
			model: model.id,
			stream: true,
			input: inputItems
		)

		if let instructions {
			responseRequest.instructions = instructions
		}

		if !tools.isEmpty {
			responseRequest.tools = tools
		}

		if let maxTokens = request.generationOptions.maximumResponseTokens {
			responseRequest.maxOutputTokens = maxTokens
		}

		applyToolChoice(request.generationOptions.toolCallingMode, to: &responseRequest)
		applySampling(request.generationOptions, to: &responseRequest, model: model)
		applyReasoning(request.contextOptions, to: &responseRequest, model: model)
		applyStructuredOutput(request.schema, to: &responseRequest, model: model)

		return Built(request: responseRequest)
	}

	// MARK: - Private

	private static func segmentsToText(_ segments: [Transcript.Segment]) -> String {
		segments.compactMap {
			switch $0 {
			case .text(let t): t.content
			case .structure(let s): s.content.jsonString
			case .attachment, .custom: nil
			@unknown default: nil
			}
		}
		.joined(separator: "\n")
	}

	private static func segmentsToContentParts(_ segments: [Transcript.Segment]) -> [InputContentPart] {
		segments.compactMap { segment -> InputContentPart? in
			switch segment {
			case .text(let t) where !t.content.isEmpty:
				return .inputText(t.content)
			case .text:
				return nil
			case .structure(let s):
				return .inputText(s.content.jsonString)
			case .attachment(let a):
				switch a.content {
				case .image(let img):
					if let url = img.url, !url.isFileURL {
						return .inputImage(url: url.absoluteString, detail: nil)
					}
					guard let dataURI = Self.cgImageToDataURI(img.cgImage) else { return nil }
					return .inputImage(url: dataURI, detail: nil)
				@unknown default:
					return nil
				}
			case .custom:
				return nil
			@unknown default:
				return nil
			}
		}
	}

	private static func applyToolChoice(
		_ mode: GenerationOptions.ToolCallingMode?,
		to request: inout ResponseRequest
	) {
		guard let mode else { return }
		switch mode.kind {
		case .required:
			request.toolChoice = .required
		case .disallowed:
			request.toolChoice = ToolChoice.none
		case .allowed:
			request.toolChoice = .auto
		@unknown default:
			break
		}
	}

	private static func applySampling(
		_ options: GenerationOptions,
		to request: inout ResponseRequest,
		model: OpenResponsesModel
	) {
		guard model.capabilities.samplingParams else { return }

		request.temperature = options.temperature

		switch options.samplingMode?.kind {
		case .greedy:
			request.temperature = 0
		case .nucleus(let threshold, _):
			request.topP = threshold
		case .top, nil:
			break
		@unknown default:
			break
		}
	}

	private static func applyReasoning(
		_ options: ContextOptions,
		to request: inout ResponseRequest,
		model: OpenResponsesModel
	) {
		guard model.capabilities.reasoning else { return }

		let effort: ReasoningEffort? = switch options.reasoningLevel {
		case .light: .low
		case .moderate: .medium
		case .deep: .high
		case .custom(let level): ReasoningEffort(rawValue: level)
		default: nil
		}

		if let effort {
			request.reasoning = ReasoningConfig(effort: effort, summary: .auto)
		}
	}

	private static func applyStructuredOutput(
		_ schema: GenerationSchema?,
		to request: inout ResponseRequest,
		model: OpenResponsesModel
	) {
		guard let schema, model.capabilities.structuredOutput else { return }
		let jsonSchema = jsonSchemaFromGenerationSchema(schema)
		request.text = TextParam(
			format: .jsonSchema(name: "response", schema: jsonSchema, strict: true)
		)
	}

	static func jsonSchemaFromGenerationSchema(_ schema: GenerationSchema) -> JSONSchema {
		guard let data = try? JSONEncoder().encode(schema),
			  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
			return .object(properties: [], required: [])
		}
		return convertToJSONSchema(dict)
	}

	private static func convertToJSONSchema(_ value: Any) -> JSONSchema {
		guard let dict = value as? [String: Any],
			  let type = dict["type"] as? String else {
			if let dict = value as? [String: Any] {
				return convertObjectToJSONSchema(dict)
			}
			return .string()
		}

		switch type {
		case "object":
			return convertObjectToJSONSchema(dict)
		case "array":
			if let items = dict["items"] {
				return .array(items: convertToJSONSchema(items))
			}
			return .array(items: .string())
		case "string":
			let desc = dict["description"] as? String
			let enumVals = dict["enum"] as? [String]
			return .string(description: desc, enumValues: enumVals)
		case "integer":
			let desc = dict["description"] as? String
			let min = dict["minimum"] as? Int
			let max = dict["maximum"] as? Int
			return .integer(description: desc, minimum: min, maximum: max)
		case "number":
			let desc = dict["description"] as? String
			let min = dict["minimum"] as? Double
			let max = dict["maximum"] as? Double
			return .number(description: desc, minimum: min, maximum: max)
		case "boolean":
			let desc = dict["description"] as? String
			return .boolean(description: desc)
		default:
			return .string()
		}
	}

	private static func cgImageToDataURI(_ cgImage: CGImage) -> String? {
		let data = NSMutableData()
		guard let destination = CGImageDestinationCreateWithData(
			data, "public.jpeg" as CFString, 1, nil
		) else { return nil }
		CGImageDestinationAddImage(
			destination, cgImage,
			[kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary
		)
		guard CGImageDestinationFinalize(destination) else { return nil }
		return "data:image/jpeg;base64,\((data as Data).base64EncodedString())"
	}

	private static func convertObjectToJSONSchema(_ dict: [String: Any]) -> JSONSchema {
		let properties = dict["properties"] as? [String: Any] ?? [:]
		let required = dict["required"] as? [String] ?? []
		let props: [(String, JSONSchema)] = properties
			.sorted { $0.key < $1.key }
			.map { ($0.key, convertToJSONSchema($0.value)) }
		return .object(properties: props, required: required)
	}
}
