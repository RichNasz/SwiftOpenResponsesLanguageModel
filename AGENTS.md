# SwiftOpenResponsesLanguageModel — AI Coding Reference

Machine-readable documentation for AI coding tools (Claude Code, Copilot, Cursor, etc.).

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
