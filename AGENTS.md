# SwiftOpenResponsesLanguageModel — AI Coding Reference

Machine-readable documentation for AI coding tools (Claude Code, Copilot, Cursor, etc.).

## Installation

### Package.swift

Add the dependency and target:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftOpenResponsesLanguageModel.git", from: "0.1.0"),
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
