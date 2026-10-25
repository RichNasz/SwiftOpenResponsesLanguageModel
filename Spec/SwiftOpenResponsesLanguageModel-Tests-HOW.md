# SwiftOpenResponsesLanguageModel — Tests HOW Spec

## File Structure

```
Tests/SwiftOpenResponsesLanguageModelTests/     # Unit tests (no network)
├── ErrorMapperTests.swift                      # ~8 tests
├── OpenResponsesModelTests.swift               # ~6 tests
├── RequestBuilderTests.swift                   # ~20 tests
└── EventTranslatorTests.swift                  # ~12 tests

Tests/IntegrationTests/                         # Integration tests (live endpoint)
├── IntegrationTestConfiguration.swift          # Env var reading, model factory, skip predicates
├── BasicGenerationTests.swift                  # 5 tests: text gen, streaming, collect, multi-turn, instructions
├── SamplingTests.swift                         # 1 test: greedy sampling and maximumResponseTokens
├── ToolCallingTests.swift                      # 4 tests: zero-arg, structured-arg, required, disallowed
├── StructuredOutputTests.swift                 # 1 test: @Generable struct decoding
├── ReasoningTests.swift                        # 2 tests: reasoning respond + stream
├── ImageInputTests.swift                       # 1 test: image attachment, opt-in
└── ErrorHandlingTests.swift                    # 2 tests: invalid URL, invalid path
```

The `IntegrationTests` target is defined separately in `Package.swift` and can be run independently via `swift test --filter IntegrationTests` or `xcodebuild -only-testing IntegrationTests`.

## Imports

All test files use:

```swift
import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesDSL
@testable import SwiftOpenResponsesLanguageModel
```

SourceKit may show false-positive "cannot find type" diagnostics for `ContextOptions`, `LanguageModelExecutorGenerationRequest`, and `LanguageModelExecutorGenerationChannel`. These are SourceKit indexing issues — the compiler resolves them correctly.

## FoundationModels Type Construction

All key types have public initializers. Patterns for constructing test fixtures:

**Transcript entries:**
- `Transcript.Segment.text(.init(content: "text"))` — text segment
- `Transcript.Prompt(segments: [...])` — user prompt
- `Transcript.Instructions(segments: [...], toolDefinitions: [])` — system instructions
- `Transcript.Response(assetIDs: [], segments: [...])` — model response
- `Transcript.ToolOutput(id: "call-id", toolName: "name", segments: [...])` — tool result
- `Transcript(entries: [.prompt(...), .response(...)])` — full transcript

**Generation options:**
- `GenerationOptions()` — defaults
- `GenerationOptions(samplingMode: .greedy)` — greedy sampling
- `GenerationOptions(samplingMode: .random(probabilityThreshold: 0.9))` — nucleus
- `GenerationOptions(samplingMode: .random(top: 5))` — top-k
- `GenerationOptions(temperature: 0.7, maximumResponseTokens: 100)` — explicit values

Note: use `samplingMode:` (not `sampling:` which is deprecated).

**Context options:**
- `ContextOptions(reasoningLevel: .moderate)` — reasoning level

**Full generation request:**
```
LanguageModelExecutorGenerationRequest(
    id: UUID(),
    transcript: transcript,
    enabledTools: [],
    generationOptions: GenerationOptions(),
    contextOptions: ContextOptions(),
    metadata: [:]
)
```

**Tool definitions:**
```
Transcript.ToolDefinition(
    name: "tool_name",
    description: "description",
    parameters: GenerationSchema(...)
)
```

**Generation schema** — constructed via `DynamicGenerationSchema`:
```
try GenerationSchema(
    root: DynamicGenerationSchema(name: "Args", properties: [...]),
    dependencies: []
)
```

---

## ErrorMapperTests

Test `ErrorMapper.map(_:)` by passing each `LLMError` case and asserting the output error type. No async, no fixtures.

| Test | Input | Expected output type |
|---|---|---|
| rateLimitMapsToRateLimited | `LLMError.rateLimit` | `LanguageModelError` (`.rateLimited`) |
| serverError413MapsToContextSizeExceeded | `LLMError.serverError(statusCode: 413, message: "too big")` | `LanguageModelError` (`.contextSizeExceeded`) |
| serverError413NilMessageUsesDefault | `LLMError.serverError(statusCode: 413, message: nil)` | `LanguageModelError` (`.contextSizeExceeded`) |
| networkErrorMapsToTimeout | `LLMError.networkError("timeout")` | `LanguageModelError` (`.timeout`) |
| missingBaseURLMapsToBadCredential | `LLMError.missingBaseURL` | `OpenResponsesError.missingCredential` |
| missingModelMapsToBadCredential | `LLMError.missingModel` | `OpenResponsesError.missingCredential` |
| otherLLMErrorPassesThrough | `LLMError.invalidURL` | `LLMError` (unchanged) |
| nonLLMErrorPassesThrough | `NSError(domain: "test", code: 1)` | `NSError` (unchanged) |

---

## OpenResponsesModelTests

Test capability defaults, capability mapping, and auth-to-configuration wiring. No FoundationModels executor types needed.

| Test | What it checks |
|---|---|
| defaultCapabilities | `.init()` defaults: samplingParams=true, toolCalling=true, reasoning=false, structuredOutput=false, imageInput=false |
| capabilityMappingAllEnabled | All flags true → capabilities include `.toolCalling`, `.vision`, `.reasoning`, `.guidedGeneration` |
| capabilityMappingAllDisabled | All flags false → capabilities is empty |
| apiKeyAuthProducesEmptyHeaders | `.apiKey("key")` → executorConfiguration.customHeaders is empty |
| proxiedAuthForwardsHeaders | `.proxied(headers: ["X-Token": "abc"])` → executorConfiguration.customHeaders contains that header |
| modelEquality | Two models with same id and capabilities are equal |

---

## RequestBuilderTests

Test `RequestBuilder.build(from:model:)` by constructing a `LanguageModelExecutorGenerationRequest` with specific transcript entries and options, then inspecting the resulting `ResponseRequest`.

Helper: a factory function that builds a request with a given transcript, options, context options, tools, and model capabilities, returning the `Built.request`.

### Transcript entry tests

| Test | Transcript entry | Assertion on ResponseRequest |
|---|---|---|
| instructionsSetsInstructions | `.instructions("Be helpful")` | `request.instructions == "Be helpful"` |
| multipleInstructionsJoined | Two `.instructions` entries | Instructions joined with `"\n\n"` |
| promptSingleTextProducesUserMessage | `.prompt("Hello")` | Input contains `.message` with `.user` role and `.text("Hello")` |
| promptMultipleSegmentsProducesParts | `.prompt` with text + structure segments | Input contains `.message` with `.parts(...)` |
| responseProducesAssistantMessage | `.response("Answer")` | Input contains `.message` with `.assistant` role |
| emptyResponseSkipped | `.response("")` | Input has no assistant message |
| toolOutputProducesFunctionCallOutput | `.toolOutput(id: "c1", text: "result")` | Input contains `.functionCallOutput` with callId "c1" |
| emptyToolOutputFallsBackToEmptyJSON | `.toolOutput(id: "c1", text: "")` | Output text is `"{}"` |
| reasoningEntrySkipped | `.reasoning(...)` | Input has no corresponding item |
| metadataSendsDecodedStringsAndRequestID | metadata `["suite": "live"]` and a fixed request id | `metadata["suite"] == "live"` and `metadata["request_id"]` equals that UUID string |
| callerRequestIDIsKept | metadata `["request_id": "caller"]` | `metadata["request_id"] == "caller"` |
| objectMetadataStaysJSON | metadata value whose `jsonString` is a JSON object | The wire value equals that `jsonString` and is not unquoted |
| labeledImagePrependsTextPart | one image segment labeled `"diagram"` | User parts are `.inputText("diagram")` then `.inputImage` with `detail == nil` |

### Generation options tests

| Test | Options | Assertion |
|---|---|---|
| maxTokensForwarded | `maximumResponseTokens: 500` | `request.maxOutputTokens == 500` |
| maxTokensNilNotSet | `maximumResponseTokens: nil` | `request.maxOutputTokens == nil` |
| toolCallingModeRequired | `.required` | `request.toolChoice == .required` |
| toolCallingModeDisallowed | `.disallowed` | `request.toolChoice == .none` |
| toolCallingModeAllowed | `.allowed` | `request.toolChoice == .auto` |
| toolCallingModeNilNotSet | `nil` | `request.toolChoice == nil` |

### Capability-gated tests

| Test | Capability | Options | Assertion |
|---|---|---|---|
| samplingGreedySetsTemperatureZero | samplingParams=true | `.greedy` | `request.temperature == 0` |
| samplingNucleusSetsTopP | samplingParams=true | `.random(probabilityThreshold: 0.9)` | `request.topP == 0.9` |
| samplingDisabledSkipsAll | samplingParams=false | temperature=0.5 | `request.temperature == nil` |
| reasoningLightMapsToLow | reasoning=true | `.light` | `request.reasoning?.effort == .low` |
| reasoningModerateMapsToMedium | reasoning=true | `.moderate` | `request.reasoning?.effort == .medium` |
| reasoningDeepMapsToHigh | reasoning=true | `.deep` | `request.reasoning?.effort == .high` |
| reasoningDisabledSkips | reasoning=false | `.moderate` | `request.reasoning == nil` |

### Schema conversion tests

Test `RequestBuilder.jsonSchemaFromGenerationSchema()` (internal-visible via `@testable import`) with constructed `GenerationSchema` values. Verify the resulting `JSONSchema` matches expected structure.

---

## EventTranslatorTests

Test `EventTranslator.translate(_:into:)` by constructing a `StreamEvent` stream, running the translator, and verifying the channel received correct events.

### Test pattern

1. Create `EventTranslator(responseEntryID: "resp-1", toolCallsEntryID: "tc-1")` with deterministic IDs
2. Create `AsyncThrowingStream<StreamEvent, Error>` that yields specific events then finishes
3. Create `LanguageModelExecutorGenerationChannel()`
4. Start a drain task — `Task { for try await _ in channel {} }` — to consume channel actions (without this, `channel.send()` blocks when the internal buffer fills, hanging the test)
5. Call `translator.translate(stream, into: channel)` and await completion
6. Cancel the drain task in `defer`

### Test cases

| Test | Stream events | Expected behavior |
|---|---|---|
| contentDeltaSendsResponseText | `.contentPartDelta("Hello", 0, 0)` | Channel receives response appendText |
| functionCallAddedStoresAndSends | `.outputItemAdded(.functionCall(name: "fn", callId: "c1"), 0)` | Channel receives toolCalls with empty arguments |
| functionCallDeltaSendsArguments | `.outputItemAdded(.functionCall(...))` then `.functionCallArgumentsDelta("{", "c1", 0)` | Channel receives arguments delta with correct name |
| functionCallDeltaBeforeOutputItemBuffers | `.functionCallArgumentsDelta("{", "c1", 0)` then `.outputItemAdded(.functionCall(name: "fn", callId: "c1"), 0)` | Buffered delta is flushed with correct tool name after outputItemAdded |
| reasoningItemSendsText | `.outputItemAdded(.reasoning(summaryText: "thinking..."), 0)` | Channel receives reasoning appendText |
| reasoningSummaryPartCreatesLazyID | `.reasoningSummaryPartAdded(text: "step 1")` (no prior reasoning item) | Channel receives reasoning with auto-generated entry ID |
| responseCompletedSendsUsage | `.responseCompleted(usage: {input: 10, output: 20, cached: 5, reasoning: 3})` | Channel receives updateUsage with correct counts |
| responseCompletedNilUsageSendsZeros | `.responseCompleted(usage: nil)` | Channel receives updateUsage with all zeros |
| responseFailedThrowsApiError | `.responseFailed(error: {code: "err", message: "msg"})` | Throws `OpenResponsesError.apiError` |
| errorEventThrowsStreamError | `.error("something broke")` | Throws `OpenResponsesError.streamError` |
| noCompletionSendsFallbackUsage | Stream ends without `.responseCompleted` | Channel receives zero-usage update |
| responseCreatedSendsIdentityOnce | `.responseCreated` then `.responseCompleted` | Two sends: identity metadata, then usage. Not three |
| responseCompletedSendsIdentityWhenCreatedMissing | `.responseCompleted` alone | Two sends: identity metadata, then usage |
| annotationMetadataIsForwarded | one non-nil `.outputTextAnnotationAdded`, then `.responseCompleted` | Three sends. A nil annotation plus completion is two sends |
| encryptedReasoningSendsSignatureOnce | reasoning item with only `encryptedContent`, including when the same item is also `.outputItemDone`, then `.responseCompleted` | Three sends: signature, identity metadata, usage. A later done item that adds `contentText` makes four: signature, text, identity metadata, usage |
| ignoredEventsProduceNoSends | `.contentPartAdded`, `.outputItemDone` for an empty message | No channel events beyond the completion usage when completion is present. `.responseCreated` is not an ignored no-send event |
| outputTextDeltaDoesNotAppendAgain | `.contentPartDelta("Hello")`, `.outputTextDelta` with the same delta, `.outputTextDone("Hello")`, `.responseCompleted` | Three sends: the content delta, identity metadata, and the usage update |
| reasoningDeltaAppendsOnce | `.reasoningDelta("think")`, `.reasoningDone("think")`, `.responseCompleted` | Three sends: one reasoning append, identity metadata, and the usage update |
| refusalDoneThrowsRefusal | `.refusalDone("no")` | Throws `LanguageModelError.refusal` |
| functionCallDoneSuppliesArguments | `.outputItemAdded` function call with empty arguments, then `.outputItemDone` with `{"message":"hi"}`, no deltas, then `.responseCompleted` | Four channel sends: open, arguments, identity metadata, usage |
| reasoningDoneSuppliesContent | `.outputItemAdded` reasoning with no summary, then `.outputItemDone` with content text, then `.responseCompleted` | Three channel sends: reasoning append, identity metadata, usage |

---

## Implementation Order (Unit Tests)

1. **ErrorMapperTests** — simplest, validates test infrastructure
2. **OpenResponsesModelTests** — validates capability mapping used by RequestBuilder
3. **RequestBuilderTests** — bulk of coverage, depends on fixture construction patterns
4. **EventTranslatorTests** — most complex async patterns, built last
5. **OpenResponsesExecutorTests** — `warmRequest` header and timeout rules, and `prewarm` returning in under one second against `http://192.0.2.1/v1/responses`

---

## Integration Tests

### Running Integration Tests

**Minimal (LM Studio or local server, no auth):**

```bash
export OPEN_RESPONSES_BASE_URL=http://localhost:1234/v1/responses
export OPEN_RESPONSES_API_KEY=nokey
export OPEN_RESPONSES_MODEL_ID=my-local-model
export OPEN_RESPONSES_STRUCTURED_OUTPUT=false  # most local models don't support this
```

**Full (OpenAI-compatible API with reasoning model):**

```bash
export OPEN_RESPONSES_BASE_URL=https://api.openai.com/v1/responses
export OPEN_RESPONSES_API_KEY=sk-...
export OPEN_RESPONSES_MODEL_ID=gpt-4o-mini
export OPEN_RESPONSES_REASONING_MODEL_ID=o4-mini
```

**Invocation:**

The package requires Xcode 27+ (beta). Use `xcodebuild` with the beta toolchain, then run the test bundle directly with `xcrun xctest` (which inherits shell environment variables — `xcodebuild test` does not pass env vars to the test process):

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild build-for-testing \
  -scheme SwiftOpenResponsesLanguageModel \
  -destination 'platform=macOS' \
  -skipPackagePluginValidation -skipMacroValidation -quiet

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcrun xctest path/to/DerivedData/.../IntegrationTests.xctest
```

Without env vars set, all 12 integration tests skip immediately with descriptive messages.

### Environment Variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `OPEN_RESPONSES_BASE_URL` | Yes | — | Full endpoint URL (e.g., `http://localhost:1234/v1/responses`) |
| `OPEN_RESPONSES_API_KEY` | Yes | — | API key for the provider |
| `OPEN_RESPONSES_MODEL_ID` | No | `gpt-4o-mini` | Model ID for basic tests |
| `OPEN_RESPONSES_REASONING_MODEL_ID` | No | — | Model ID for reasoning tests; reasoning tests skip if absent |
| `OPEN_RESPONSES_STRUCTURED_OUTPUT` | No | `true` | Set to `false` to skip structured output and structured-arg tool tests |
| `OPEN_RESPONSES_TOOL_CALLING` | No | `true` | Set to `false` to skip tool calling tests |
| `OPEN_RESPONSES_IMAGE_INPUT` | No | unset | Set to `true` to run the image attachment test. Otherwise the suite skips |

### Skip Logic

Suite-level: `@Suite(.enabled(if: IntegrationTestConfiguration.isConfigured))` — skips entire suite if `BASE_URL` or `API_KEY` is missing. Optional capabilities use per-test `.enabled(if:)` traits.

### IntegrationTestConfiguration

Shared enum providing:
- `isConfigured`, `supportsStructuredOutput`, `supportsToolCalling`, `supportsReasoning` — static predicates for skip logic
- `makeModel(capabilities:)` — factory producing `OpenResponsesLanguageModel` with 120s timeout
- `makeReasoningModel()` — factory using `OPEN_RESPONSES_REASONING_MODEL_ID` with `reasoning: true`
- `makeSession(capabilities:instructions:tools:)` — convenience that creates model + `LanguageModelSession`

### Imports

Integration test files use public API only:

```swift
import Testing
import Foundation
import FoundationModels
import SwiftOpenResponsesLanguageModel
```

No `@testable import` — integration tests exercise the public surface.

### BasicGenerationTests (5 tests)

| Test | What it exercises | Assertion |
|---|---|---|
| `textGeneration` | `session.respond(to:)` end-to-end | `!response.content.isEmpty`, `usage.input.totalTokenCount > 0`, `usage.output.totalTokenCount > 0` |
| `streamingTextGeneration` | `session.streamResponse(to:)` iteration | Multiple snapshots, last content non-empty |
| `streamCollect` | `stream.collect()` convenience | `!response.content.isEmpty` |
| `multiTurnConversation` | Two `respond` calls on same session | Second response contains info from first turn |
| `systemInstructions` | `LanguageModelSession(model:instructions:)` | Response follows instruction constraint |

### ToolCallingTests (2 tests)

Two `Tool`-conforming types defined in the test file:
- `GetCurrentDateTool` — zero-argument tool, returns formatted date string
- `EchoTool` — single `message: String` argument, returns `"ECHO: \(message)"`

| Test | Gating | What it exercises | Assertion |
|---|---|---|---|
| `toolCallRoundTrip` | `supportsToolCalling` | Zero-arg tool call round-trip via `LanguageModelSession` | `!response.content.isEmpty` |
| `toolCallWithArguments` | `supportsToolCalling && supportsStructuredOutput` | Structured-arg tool call + argument decoding | A `.toolOutput` transcript entry contains `ECHO: integration test` |
| `toolCallRequired` | `supportsToolCalling` | `GenerationOptions(toolCallingMode: .required)` with the date tool | `transcriptEntries` contains `.toolCalls` |
| `toolCallDisallowed` | `supportsToolCalling` | `GenerationOptions(toolCallingMode: .disallowed)` with the date tool available | Content is non-empty and `transcriptEntries` has no `.toolCalls` |

### SamplingTests (1 test)

| Test | Gating | What it exercises | Assertion |
|---|---|---|---|
| `greedyRespectsMaxTokens` | configured | `samplingParams: true`, `samplingMode: .greedy`, `maximumResponseTokens: 64` | Content is non-empty, `usage.output.totalTokenCount > 0` and `<= 64` |

### StructuredOutputTests (1 test)

`@Generable` struct `SimpleAnswer` with a single `answer: String` property.

| Test | Gating | What it exercises | Assertion |
|---|---|---|---|
| `generableStructDecoding` | `supportsStructuredOutput` | `session.respond(to:generating: SimpleAnswer.self)` | `!response.content.answer.isEmpty` |

### ReasoningTests (2 tests)

Uses `IntegrationTestConfiguration.makeReasoningModel()`.

| Test | Gating | What it exercises | Assertion |
|---|---|---|---|
| `reasoningRespond` | `supportsReasoning` | `session.respond(to:contextOptions:)` with `.moderate` | Contains `255`, and a `.reasoning` transcript entry has non-empty text |
| `reasoningStream` | `supportsReasoning` | `session.streamResponse(to:contextOptions:)` | Snapshots received, last content non-empty |

### ImageInputTests (1 test)

Builds a solid red `CGImage` and sends it with `Attachment` in the prompt builder. The suite is enabled only when `OPEN_RESPONSES_IMAGE_INPUT=true`. The model is created with `imageInput: true`.

| Test | Gating | What it exercises | Assertion |
|---|---|---|---|
| `describesAttachedImage` | `OPEN_RESPONSES_IMAGE_INPUT=true` | Prompt plus one image attachment | Response is non-empty |

### ErrorHandlingTests (2 tests)

| Test | What it exercises | Assertion |
|---|---|---|
| `invalidBaseURLThrows` | Unreachable endpoint (`localhost:1`) | `session.respond` throws |
| `invalidEndpointPathThrows` | Valid host, invalid path suffix | `session.respond` throws |

### Assertion Strategy

- **Loose content matching** — `contains` / `localizedStandardContains` since model outputs vary
- **Deterministic prompts** — prompts designed for deterministic-ish answers (math, tool output, explicit instructions)
- **No timing assumptions** — streaming tests assert snapshots > 0, not exact counts
- **Time limits** — `.timeLimit(.minutes(3))` on generation tests, `.timeLimit(.minutes(1))` on error tests
