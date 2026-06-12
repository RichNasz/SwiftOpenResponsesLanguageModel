# SwiftOpenResponsesLanguageModel — WHAT Spec

## Overview

A Swift package that provides a `LanguageModel` implementation bridging Apple's FoundationModels framework to [Open Responses](https://www.openresponses.org/) specification-compliant inference endpoints. Any app written against FoundationModels can use any Open Responses-compatible provider (hosted APIs, local LLM servers, etc.) by swapping in `OpenResponsesLanguageModel` — no changes to app-level session or generation code required.

## Public API

### `OpenResponsesLanguageModel`

The `LanguageModel` conformance. Constructed once and passed to `LanguageModelSession`.

```swift
public struct OpenResponsesLanguageModel: LanguageModel, Sendable {
    public init(
        name: OpenResponsesModel,
        auth: AuthMode,
        baseURL: URL,
        timeout: TimeInterval = 60
    )
}
```

### `OpenResponsesModel`

Model identity and capability declaration.

```swift
public struct OpenResponsesModel: Sendable, Hashable {
    public let id: String
    public let capabilities: Capabilities

    public struct Capabilities: Sendable, Hashable {
        public var samplingParams: Bool      // temperature, topP, samplingMode
        public var reasoning: Bool           // extended thinking / reasoning effort
        public var structuredOutput: Bool    // JSON schema-constrained output
        public var imageInput: Bool          // vision / image attachments
        public var toolCalling: Bool         // function calling
    }
}
```

Models are instantiated directly with the provider's model ID and the capabilities that model supports:

```swift
OpenResponsesModel(id: "my-model", capabilities: .init(
    samplingParams: true,
    reasoning: false,
    structuredOutput: true,
    imageInput: true,
    toolCalling: true
))
```

All capability flags default to conservative values if omitted (see `Capabilities.init` defaults).

### `AuthMode`

```swift
public enum AuthMode: Sendable, Hashable {
    case apiKey(String)                        // Bearer token in Authorization header
    case proxied(headers: [String: String])    // Custom headers for enterprise/local proxies
}
```

### `OpenResponsesError`

```swift
public enum OpenResponsesError: Error, Sendable {
    case missingCredential
    case apiError(code: String, message: String)
    case streamError(String)
}
```

## FoundationModels Capability Mapping

Capability flags on `OpenResponsesModel` map to FoundationModels' `LanguageModelCapabilities`, enabling framework-level feature gating (e.g., the session can disable tool use UI for models without `toolCalling`):

| OpenResponsesModel.Capabilities flag | LanguageModelCapabilities |
|---|---|
| `toolCalling` | `.toolCalling` |
| `imageInput` | `.vision` |
| `reasoning` | `.reasoning` |
| `structuredOutput` | `.guidedGeneration` |

## Minimal Usage

```swift
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

## Platform Requirements

- macOS 27.0+, iOS 27.0+, visionOS 27.0+, watchOS 27.0+
- Swift 6+

## Dependencies

- **SwiftOpenResponsesDSL** (local path) — HTTP client, request/response types, streaming event handling
- **SwiftLLMToolMacros** (transitive via SwiftOpenResponsesDSL) — JSON schema types

## Acceptance Criteria

- [ ] Package compiles with `swift build`
- [ ] Streaming text responses work via `LanguageModelSession.streamResponse(to:)`
- [ ] Tool calling works for models where `toolCalling` capability is enabled
- [ ] Temperature and sampling are only sent to models where `samplingParams` is `true`
- [ ] Reasoning effort is only sent to models where `reasoning` is `true`
- [ ] Structured output is only applied where `structuredOutput` is `true`
- [ ] Image attachments (`Attachment<ImageAttachmentContent>`) in prompts are converted to `input_image` content parts with base64 data URIs
- [ ] `.apiKey` auth routes requests with correct `Authorization: Bearer` header
- [ ] `.proxied` auth passes an empty API key and forwards the provided custom headers to `LLMClient`
- [ ] `.apiKey` auth passes no custom headers
- [ ] Custom `baseURL` routes requests to the specified endpoint
- [ ] Custom `timeout` is applied to the underlying HTTP session
