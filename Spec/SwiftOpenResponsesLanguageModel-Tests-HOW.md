# SwiftOpenResponsesLanguageModel — Tests HOW Spec

## File Structure

```
Tests/SwiftOpenResponsesLanguageModelTests/
├── ErrorMapperTests.swift           # ~8 tests
├── OpenResponsesModelTests.swift    # ~6 tests
├── RequestBuilderTests.swift        # ~20 tests
└── EventTranslatorTests.swift       # ~12 tests
```

The existing `SwiftOpenLanguageModelTests.swift` placeholder is replaced by these files.

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
4. Call `translator.translate(stream, into: channel)` in a task
5. Verify results — the exact verification approach depends on what the channel exposes for reading. If the channel doesn't support async iteration from the test side, verify behavior through the translator's state or by testing at a higher level through the executor.

### Test cases

| Test | Stream events | Expected behavior |
|---|---|---|
| contentDeltaSendsResponseText | `.contentPartDelta("Hello", 0, 0)` | Channel receives response appendText |
| functionCallAddedStoresAndSends | `.outputItemAdded(.functionCall(name: "fn", callId: "c1"), 0)` | Channel receives toolCalls with empty arguments |
| functionCallDeltaSendsArguments | `.outputItemAdded(.functionCall(...))` then `.functionCallArgumentsDelta("{", "c1", 0)` | Channel receives arguments delta with correct name |
| reasoningItemSendsText | `.outputItemAdded(.reasoning(summaryText: "thinking..."), 0)` | Channel receives reasoning appendText |
| reasoningSummaryPartCreatesLazyID | `.reasoningSummaryPartAdded(text: "step 1")` (no prior reasoning item) | Channel receives reasoning with auto-generated entry ID |
| responseCompletedSendsUsage | `.responseCompleted(usage: {input: 10, output: 20, cached: 5, reasoning: 3})` | Channel receives updateUsage with correct counts |
| responseCompletedNilUsageSendsZeros | `.responseCompleted(usage: nil)` | Channel receives updateUsage with all zeros |
| responseFailedThrowsApiError | `.responseFailed(error: {code: "err", message: "msg"})` | Throws `OpenResponsesError.apiError` |
| errorEventThrowsStreamError | `.error("something broke")` | Throws `OpenResponsesError.streamError` |
| noCompletionSendsFallbackUsage | Stream ends without `.responseCompleted` | Channel receives zero-usage update |
| ignoredEventsProduceNoSends | `.responseCreated`, `.contentPartAdded`, `.outputItemDone` | No channel events |

---

## Implementation Order

1. **ErrorMapperTests** — simplest, validates test infrastructure
2. **OpenResponsesModelTests** — validates capability mapping used by RequestBuilder
3. **RequestBuilderTests** — bulk of coverage, depends on fixture construction patterns
4. **EventTranslatorTests** — most complex async patterns, built last
