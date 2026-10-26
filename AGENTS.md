# SwiftOpenResponsesLanguageModel — AI Coding Reference

Machine-readable documentation for AI coding tools consuming this library.

## Maintenance

Claude Code created this project initially. All project-related work uses Grok Build. When a model is required, use the latest Grok model available. Do not treat Claude Code as the current toolchain.

## Installation

### Package.swift

Add the dependency and target:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftOpenResponsesLanguageModel.git", from: "0.2.0"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "SwiftOpenResponsesLanguageModel", package: "SwiftOpenResponsesLanguageModel"),
        ]
    ),
]
```

### Xcode (GUI)

File → Add Package Dependencies → paste `https://github.com/RichNasz/SwiftOpenResponsesLanguageModel.git` → Add Package → select your target.

### Pitfalls

- **Platform requirement** — Requires macOS 27.0+ / iOS 27.0+ / visionOS 27.0+ / watchOS 27.0+ and Xcode 27+. The package uses FoundationModels which is only available on these platforms.
- **Swift tools version** — The package requires swift-tools-version 6.2+. Older toolchains will fail to resolve the package.
- **Transitive dependency** — SwiftOpenResponsesDSL (and its transitive SwiftLLMToolMacros) are pulled in automatically. You do not need to add them separately.

## Project Overview

SwiftOpenResponsesLanguageModel is a Swift package providing a `LanguageModel` implementation that bridges Apple's FoundationModels to any Open Responses specification endpoint. Drop in `OpenResponsesLanguageModel` and your existing FoundationModels code works with any compatible provider.

**Package:** SwiftOpenResponsesLanguageModel
**Platforms:** macOS 27.0+, iOS 27.0+, visionOS 27.0+, watchOS 27.0+
**Swift:** 6.0+
**Public types:** `OpenResponsesLanguageModel`, `OpenResponsesModel`, `AuthMode`, `OpenResponsesError`

## Basic Usage

### Pattern

```swift
import FoundationModels
import SwiftOpenResponsesLanguageModel

let model = OpenResponsesModel(id: "my-model", capabilities: .init())
let lm = OpenResponsesLanguageModel(
    name: model,
    auth: .apiKey("my-api-key"),
    baseURL: URL(string: "https://my-provider.example.com/v1/responses")!
)

let session = LanguageModelSession(model: lm)
let stream = session.streamResponse(to: "Explain Swift concurrency.")
for try await partial in stream {
    print(partial.content)
}
```

### Pitfalls

- **Capability flag mismatch** — Setting `reasoning: true` for a model that doesn't support reasoning causes API errors. Flags must match the model's actual abilities.
- **Incomplete baseURL** — `baseURL` must include the full path (e.g., `https://api.openai.com/v1/responses`), not just the host.
- **name: takes OpenResponsesModel** — The `name:` parameter label in the init takes an `OpenResponsesModel` struct, not a string model ID.

## Auth Modes

### Pattern

**API key (Bearer token):**

```swift
auth: .apiKey("sk-your-api-key")
```

**Proxied (enterprise/local proxy):**

```swift
auth: .proxied(headers: ["X-Forwarded-User": "alice", "X-Internal-Token": "abc123"])
```

### Pitfalls

- **Empty string = LM Studio** — `.apiKey("")` substitutes `"lm-studio"` as the key. This is intentional for LM Studio connections.
- **No Authorization with proxied** — `.proxied` sends no `Authorization` header; the proxy must handle auth.
- **No custom headers with apiKey** — `.apiKey` sends no custom headers; `.proxied` forwards the provided headers dictionary.

## Capability Flags

### Pattern

```swift
let model = OpenResponsesModel(
    id: "claude-sonnet-4-20250514",
    capabilities: .init(
        samplingParams: true,   // default: true
        reasoning: true,        // default: false
        structuredOutput: true, // default: false
        imageInput: true,       // default: false
        toolCalling: true       // default: true
    )
)
```

### Pitfalls

- **Flags gate request construction** — If `samplingParams: false`, temperature and topP are never sent even if set on generation options. The feature is silently omitted, not errored.
- **reasoning: false suppresses reasoning** — Reasoning effort is never included in the request, even if `ContextOptions(reasoningLevel:)` is set.
- **structuredOutput: false suppresses schemas** — JSON schema output format is never applied, even if `@Generable` types are used.

## Error Handling

### Pattern

```swift
do {
    let result = try await session.respond(to: "Hello")
    print(result.content)
} catch let error as OpenResponsesError {
    switch error {
    case .missingCredential:
        print("No API key configured")
    case .apiError(let code, let message):
        print("Provider error \(code): \(message)")
    case .streamError(let detail):
        print("Stream failed: \(detail)")
    }
} catch {
    print("Framework error: \(error)")
}
```

### Pitfalls

- **Dual error types** — Some errors are mapped to `LanguageModelError` (rate limit, context size, timeout) for framework compatibility. `OpenResponsesError.apiError` preserves provider-specific detail. Catch both types for full coverage.
- **Unmapped passthrough** — Unrecognized `LLMError` cases from SwiftOpenResponsesDSL pass through unmapped. Don't assume all errors are `OpenResponsesError` or `LanguageModelError`.

## Common Mistakes

1. **Missing capability flags** — Forgetting to set `reasoning: true` or `structuredOutput: true` for models that support these features. The features silently won't activate.
2. **Wrong platform** — Using this package without macOS 27+ / iOS 27+. FoundationModels is only available on these platforms.
3. **Unused model** — Constructing `OpenResponsesLanguageModel` but not passing it to `LanguageModelSession`. The model does nothing on its own.
4. **On-device assumptions** — Remote providers have different latency, token limits, and error patterns compared to on-device models.
5. **Stream event ordering** — Local LLM servers may emit events in a different order than hosted APIs. The `EventTranslator` buffers `functionCallArgumentsDelta` events that arrive before `outputItemAdded` and handles streams that end without `response.completed`. Don't assume canonical event ordering when modifying stream handling.

## Not available

FoundationModels behavior this package does not provide. Do not invent stand-in values. The Open Responses spec is [openresponses.org/specification](https://www.openresponses.org/specification) (OpenAPI `2026-04-24`). When the spec does not define a behavior, that is a characteristic of the API, not a bug in SwiftOpenResponsesDSL. When the spec defines it and the DSL does not implement it, the API is not the gap.

1. **Reasoning is not sent back on the next turn.** A reasoning transcript entry and its signature are skipped. Treating them as unsupported content would break multi-turn reasoning that already works. Open Responses allows this: `ReasoningItemParam` is an input item. SwiftOpenResponsesDSL does not encode it. `ReasoningItem` is decode-only, and `InputItem` has no reasoning case.

2. **Top-k sampling and sampling seeds are dropped.** `.randomProbabilityThreshold` sends `top_p` and drops the seed. `.randomTopK` is ignored. This is a characteristic of Open Responses. `CreateResponseBody` has `temperature` and `top_p` and has no `top_k` or `seed`. The DSL is not missing those fields.

3. **`previous_response_id` and `prompt_cache_key` are not sent.** The package sends the full transcript every turn. Setting either field as well can duplicate the prompt. Open Responses defines both, and the DSL already has them on `ResponseRequest`. Leaving them unset is this package's turn policy.

4. **Streamed fragments do not carry a token count.** Appends use `0`. Totals arrive with the completed response. This is a characteristic of Open Responses. Text, reasoning, and tool-argument deltas do not include a token count. `Usage` is on the completed response. The DSL cannot report a count the events do not have.

5. **HTTP 413 has no real context size or token count, and rate limits have no reset date.** The mapped errors use zeros and `resetDate: nil`. This is a characteristic of Open Responses. `Error` is `code` and `message`. The spec defines no context size, no error token count, and no reset time. Do not treat that as a DSL omission.

6. **Guardrail and locale errors are not produced.** Guessing them from a generic provider error would be wrong. This is a characteristic of Open Responses. The spec has no guardrail event and no language or locale error.

7. **Object schema `title`, `description`, and `x-order` are not copied.** `additionalProperties: false` is still sent. Open Responses accepts an open JSON Schema object, so `title` and `description` are allowed on the wire. Dropping them is SwiftLLMToolMacros: `JSONSchemaValue.object` is only properties and required fields. `x-order` is not Open Responses and not JSON Schema. With `strict: true`, the spec says only an unnamed subset of JSON Schema is supported, so a server may reject keywords the object can carry.

8. **Unknown schema keywords, including `anyOf`, become a string schema.** Open Responses does not forbid `anyOf`. The schema object is open. The collapse is SwiftLLMToolMacros, whose `JSONSchemaValue` has no `anyOf`. The spec only warns that `strict: true` supports a subset of JSON Schema.

9. **Tool `strict: true` is not always sent.** It is set only when `structuredOutput` is on. Some servers rewrite or reject strict schemas. Open Responses defines `FunctionTool.strict`, and the DSL already has it. The gate is a compatibility choice in this package.

10. **On-device-only `SystemLanguageModel` API is absent.** That includes `isAvailable`, `contextSize`, `tokenCount(for:)`, guardrails, adapters, and Private Cloud Compute. `LanguageModel` does not require them. They are not an Open Responses surface, and the DSL is not expected to grow them.

11. **Data attachments are not sent.** Segments are text, structure, and images. Open Responses allows file input through `InputFileContentParam` (`filename`, `file_data`, `file_url`). SwiftOpenResponsesDSL encodes that as `InputContentPart.inputFile`. The FoundationModels interface in Xcode 27.1 does not include the OS 27.2 data-attachment APIs. `Transcript.Attachment` is only an image, so this package has nothing to translate yet. Image input already uses `input_image`.

12. **Image orientation is not applied.** The JPEG is the pixel buffer as handed over, and `detail` stays unset. This is a characteristic of Open Responses. `InputImageContent` has `image_url` and `detail` (`low`, `high`, `auto`) and no orientation. The DSL matches that. Apple's image attachment has orientation and no detail level. A non-empty attachment label is sent as text immediately before the image.

## Quick Reference

Complete happy-path example — copy, paste, fill in your provider details:

```swift
import FoundationModels
import SwiftOpenResponsesLanguageModel

// 1. Declare model identity and capabilities.
//    Flags must match what the provider's model actually supports.
let model = OpenResponsesModel(
    id: "gpt-4o",                    // model ID sent to the provider
    capabilities: .init(
        samplingParams: true,        // temperature, topP (default: true)
        reasoning: false,            // extended thinking (default: false)
        structuredOutput: true,      // JSON schema output (default: false)
        imageInput: true,            // image attachments (default: false)
        toolCalling: true            // function calling (default: true)
    )
)

// 2. Create the LanguageModel with auth and endpoint URL.
//    baseURL must include the full path, not just the host.
let lm = OpenResponsesLanguageModel(
    name: model,                     // NOTE: parameter label is `name:`, takes OpenResponsesModel
    auth: .apiKey("sk-your-key"),    // or .proxied(headers: ["X-Token": "..."])
    baseURL: URL(string: "https://api.openai.com/v1/responses")!,
    timeout: 60                      // seconds (default: 60)
)

// 3. Use standard FoundationModels session API — no library-specific calls needed.
let session = LanguageModelSession(model: lm)
let stream = session.streamResponse(to: "Explain Swift concurrency.")
for try await partial in stream {
    print(partial.content)
}
```
