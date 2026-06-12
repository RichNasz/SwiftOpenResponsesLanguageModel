# SwiftOpenResponsesLanguageModel — HOW Spec

## File Structure

```
Sources/SwiftOpenResponsesLanguageModel/
├── AuthMode.swift                  # AuthMode enum (apiKey / proxied)
├── OpenResponsesModel.swift        # OpenResponsesModel struct + Capabilities
├── OpenResponsesLanguageModel.swift # LanguageModel conformance, capability mapping, executorConfiguration
├── OpenResponsesExecutor.swift     # LanguageModelExecutor conformance, LLMClient initialization, respond()
├── RequestBuilder.swift            # Translates LanguageModelExecutorGenerationRequest → ResponseRequest (imports CoreGraphics, ImageIO for image encoding)
├── EventTranslator.swift           # Translates AsyncThrowingStream<StreamEvent> → LanguageModelExecutorGenerationChannel
└── ErrorMapper.swift               # Maps LLMError / OpenResponsesError → LanguageModelError; defines OpenResponsesError
```

---

## LanguageModel Conformance (`OpenResponsesLanguageModel`)

`OpenResponsesLanguageModel` conforms to `LanguageModel` with `Executor = OpenResponsesExecutor`.

**Capability mapping** — reads `model.capabilities` flags and builds `LanguageModelCapabilities`. Only flags that are `true` contribute a capability; `false` flags are omitted entirely (no capability is added for them).

| `OpenResponsesModel.Capabilities` flag | `LanguageModelCapabilities.Capability` appended |
|---|---|
| `toolCalling` | `.toolCalling` |
| `imageInput` | `.vision` |
| `reasoning` | `.reasoning` |
| `structuredOutput` | `.guidedGeneration` |

**Executor configuration** — packages model, baseURL, authMode, timeout, and `customHeaders` into `OpenResponsesExecutor.Configuration` and returns it as `executorConfiguration`. Headers are extracted from the auth mode: `.proxied(headers:)` forwards the headers dictionary; `.apiKey` passes an empty dictionary.

---

## LanguageModelExecutor Conformance (`OpenResponsesExecutor`)

**Initialization** — derives an API key string from `AuthMode` and constructs `LLMClient`:

- `.apiKey("")` (empty string) → substitutes `"lm-studio"` as the key value (LM Studio requires a non-empty string but ignores the value)
- `.apiKey(nonEmpty)` → passes the key as-is
- `.proxied` → passes an empty string (proxy handles auth; no Authorization header is sent)

`LLMClient` is constructed with the configuration's `baseURL.absoluteString`, the derived key, and `configuration.customHeaders`.

**Execution** — the `respond(to:model:streamingInto:)` method:

1. Calls `RequestBuilder.build(from:model:)` to produce a `ResponseRequest`
2. Creates `EventTranslator()` with fresh UUID entry IDs
3. Streams via `client.stream(built.request)` and feeds events to the channel
4. Any error is passed through `ErrorMapper.map(_:)` before re-throwing

---

## RequestBuilder

`RequestBuilder.build(from:model:)` iterates `request.transcript` entries and builds `inputItems: [InputItem]`:

### Transcript Entry → InputItem Translation

| Transcript.Entry | OpenResponses InputItem | Notes |
|---|---|---|
| `.instructions(i)` | Sets `responseRequest.instructions` | Multiple instruction entries are joined with `"\n\n"` |
| `.prompt(p)` | `.message(InputMessage(role: .user, content: ...))` | Single text → `.text(String)`; multiple/mixed parts → `.parts([InputContentPart])` |
| `.response(r)` | `.message(InputMessage(role: .assistant, content: .text(...)))` | Skipped if text is empty |
| `.toolCalls(calls)` | `.functionCall(FunctionCallItem(...))` one per call | Uses `call.id` for both `id` and `callId`; `call.toolName` for `name`; `call.arguments.jsonString` for arguments |
| `.toolOutput(out)` | `.functionCallOutput(FunctionCallOutputItem(callId: out.id, output: ...))` | Falls back to `"{}"` if text is empty |
| `.reasoning` | (skipped) | Reasoning history is not re-sent to the model |

### Segment → Content Part Translation

`segmentsToText()` — joins non-nil segment content with `"\n"`:
- `.text(t)` → `t.content`
- `.structure(s)` → `s.content.jsonString`
- `.attachment`, `.custom` → skipped (images cannot be represented as plain text)

`segmentsToContentParts()` — produces `[InputContentPart]`:
- `.text(t)` (non-empty) → `.inputText(t.content)`
- `.structure(s)` → `.inputText(s.content.jsonString)`
- `.attachment(a)` → dispatches on `a.content`:
  - `.image(img)` with a non-file URL → `.inputImage(url: img.url.absoluteString, detail: nil)` (remote URLs are passed directly)
  - `.image(img)` otherwise → JPEG-encodes `img.cgImage` via `CGImageDestination` at 0.8 quality, then base64-encodes into a `data:image/jpeg;base64,...` data URI → `.inputImage(url: dataURI, detail: nil)`
  - Returns `nil` if JPEG encoding fails
- `.custom` → skipped

`cgImageToDataURI(_:)` — helper that writes a `CGImage` to an in-memory JPEG via ImageIO's `CGImageDestinationCreateWithData`, base64-encodes the result, and returns a `data:image/jpeg;base64,...` string. Returns `nil` on encoding failure.

### Tool Definitions

```swift
let tools: [FunctionToolParam] = request.enabledToolDefinitions.map { def in
    FunctionToolParam(
        name: def.name,
        description: def.description,
        parameters: jsonSchemaFromGenerationSchema(def.parameters),
        strict: model.capabilities.structuredOutput ? true : nil
    )
}
```

Set on the request only if `tools` is non-empty.

### Tool Choice Mapping

| GenerationOptions.ToolCallingMode | ToolChoice |
|---|---|
| `.required` | `.required` |
| `.disallowed` | `.none` |
| `.allowed` | `.auto` |
| `nil` | (not set — model default) |

### Response Token Limit

```swift
if let maxTokens = request.generationOptions.maximumResponseTokens {
    responseRequest.maxOutputTokens = maxTokens
}
```

Passed directly when set; omitted if nil (server default applies).

### Sampling Parameters (guarded by `model.capabilities.samplingParams`)

`temperature` is set directly from `options.temperature` when present. `samplingMode` overrides it:

| `SamplingMode` | Effect |
|---|---|
| `.greedy` | Forces `temperature = 0` |
| `.nucleus(t, _)` | Sets `topP = t` |
| `.top` / `nil` | No override |

### Reasoning (guarded by `model.capabilities.reasoning`)

| ContextOptions.ReasoningLevel | ReasoningEffort |
|---|---|
| `.light` | `.low` |
| `.moderate` | `.medium` |
| `.deep` | `.high` |
| `.custom(let level)` | `ReasoningEffort(rawValue: level)` |

Applied as `ReasoningConfig(effort: effort, summary: .auto)`.

### Structured Output (guarded by `model.capabilities.structuredOutput`)

Converts `GenerationSchema` → `JSONSchema` via `jsonSchemaFromGenerationSchema()` and sets:

```swift
request.text = TextParam(format: .jsonSchema(name: "response", schema: jsonSchema, strict: true))
```

`jsonSchemaFromGenerationSchema()` — encodes the `GenerationSchema` to JSON, then recursively converts the dictionary to `JSONSchema` enum values. Type dispatch:
- `"object"` → `.object(properties: [(String, JSONSchema)], required: [String])` — properties sorted alphabetically
- `"array"` → `.array(items: JSONSchema)` — falls back to `.array(items: .string())` if no `items` key
- `"string"` → `.string(description: String?, enumValues: [String]?)`
- `"integer"` → `.integer(description: String?, minimum: Int?, maximum: Int?)`
- `"number"` → `.number(description: String?, minimum: Double?, maximum: Double?)`
- `"boolean"` → `.boolean(description: String?)`
- Unknown types → `.string()` fallback

---

## EventTranslator

Translates `AsyncThrowingStream<StreamEvent, Error>` into `LanguageModelExecutorGenerationChannel` sends. `Task.checkCancellation()` is called at the top of each event iteration so that task cancellation propagates promptly during streaming.

State tracked across events:
- `activeFunctionCalls: [Int: (id: String, name: String)]` — keyed by output item index
- `reasoningEntryID: String?` — lazily created on first reasoning event
- `sentCompletion: Bool` — tracks whether `responseCompleted` was received

### StreamEvent → Channel Action Mapping

| StreamEvent | Channel action |
|---|---|
| `.contentPartDelta(delta, _, _)` | `.response(entryID: responseEntryID, action: .appendText(delta, tokenCount: 0))` |
| `.functionCallArgumentsDelta(delta, callId, index)` | `.toolCalls(entryID: toolCallsEntryID, action: .toolCall(id: callId, name: activeFunctionCalls[index]?.name ?? "", action: .appendArguments(delta, tokenCount: 0)))` |
| `.outputItemAdded(.functionCall(call), index)` | Stores `(id: call.callId, name: call.name)` in `activeFunctionCalls[index]`; sends `.toolCalls` with `.appendArguments("", tokenCount: 0)` to open the entry |
| `.outputItemAdded(.reasoning(reasoning), _)` | Creates `reasoningEntryID` (new UUID); sends `.reasoning` with `reasoning.summaryText` if non-nil |
| `.reasoningSummaryPartAdded(part, _, _)` | Uses existing `reasoningEntryID` or creates one lazily (handles providers that emit this event without a prior `.outputItemAdded(.reasoning)`); sends `.reasoning(entryID:, action: .appendText(part.text, tokenCount: 0))` |
| `.responseCompleted(response)` | Extracts `inputTokens`, `outputTokens`, `inputTokensDetails.cachedTokens`, and `outputTokensDetails.reasoningTokens` from `response.usage`; sends `.response(entryID: responseEntryID, action: .updateUsage(...))` with these counts (defaulting to 0 for absent fields); sets `sentCompletion = true` |
| `.responseFailed(response)` | Throws `OpenResponsesError.apiError(code: error.code, message: error.message)` |
| `.error(message)` | Throws `OpenResponsesError.streamError(message)` |
| All others | Ignored |

**Resilience fallback** — after the stream ends, if `sentCompletion == false`, sends a zero-usage update to close the generation cleanly (required when providers never emit `response.completed`).

---

## ErrorMapper

`ErrorMapper.map(_:)` — if the error is an `LLMError`, maps it; otherwise passes through unchanged.

| LLMError | LanguageModelError / OpenResponsesError |
|---|---|
| `.rateLimit` | `LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: "Rate limit exceeded"))` |
| `.serverError(413, message)` | `LanguageModelError.contextSizeExceeded(.init(contextSize: 0, tokenCount: 0, debugDescription: message ?? "..."))` |
| `.networkError` | `LanguageModelError.timeout(.init(debugDescription: "Network error"))` |
| `.missingBaseURL`, `.missingModel` | `OpenResponsesError.missingCredential` |
| All others | Passed through unchanged |

---

## Entry ID Generation

`EventTranslator` holds two string entry IDs (`responseEntryID`, `toolCallsEntryID`), defaulting to freshly generated UUIDs. The executor creates a new `EventTranslator` for each `respond()` call, ensuring IDs are unique across consecutive calls in a long session. The parameters accept explicit strings so tests can inject deterministic IDs and make stable assertions on entry identity.
