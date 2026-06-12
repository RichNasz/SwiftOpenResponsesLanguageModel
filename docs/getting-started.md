# Getting Started

This guide progresses from basic streaming through every feature the library supports. Each section builds on the previous one.

## 1. Basic Streaming

The simplest usage — stream a text response from any Open Responses-compatible provider:

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

`OpenResponsesModel` declares the model's identity and capabilities. `OpenResponsesLanguageModel` wraps it into a `LanguageModel` that `LanguageModelSession` can use. From there, the session API is identical to on-device usage.

## 2. Auth Modes

**API Key** — for any provider requiring a Bearer token:

```swift
let lm = OpenResponsesLanguageModel(
    name: model,
    auth: .apiKey("sk-your-api-key"),
    baseURL: URL(string: "https://api.openai.com/v1/responses")!
)
```

For LM Studio and other local servers that don't require real auth, pass an empty string — the library substitutes `"lm-studio"` automatically:

```swift
auth: .apiKey("")
```

**Proxied** — for enterprise setups where a reverse proxy handles auth upstream:

```swift
let lm = OpenResponsesLanguageModel(
    name: model,
    auth: .proxied(headers: ["X-Forwarded-User": "alice", "X-Internal-Token": "abc123"]),
    baseURL: URL(string: "https://internal-gateway.corp.example.com/v1/responses")!
)
```

`.proxied` sends no `Authorization` header — the proxy handles it. The headers dictionary is forwarded on every request.

## 3. Configuring Capability Flags

Capability flags tell the library what features the model supports. They gate request construction — if a flag is `false`, the corresponding parameter is never sent, even if set in generation options.

```swift
let model = OpenResponsesModel(
    id: "claude-sonnet-4-20250514",
    capabilities: .init(
        samplingParams: true,
        reasoning: true,
        structuredOutput: true,
        imageInput: true,
        toolCalling: true
    )
)
```

| Flag | Default | What it gates |
|------|---------|---------------|
| `samplingParams` | `true` | Temperature, topP, sampling mode |
| `reasoning` | `false` | Extended thinking / reasoning effort |
| `structuredOutput` | `false` | JSON schema-constrained output |
| `imageInput` | `false` | Image attachments in prompts |
| `toolCalling` | `true` | Function calling / tool use |

If you set `reasoning: false` but the model supports reasoning, reasoning effort will silently never be sent. Always match flags to the model's actual abilities.

## 4. Tool Calling

Define a tool conforming to `Tool`, then pass it to the session. The model calls it automatically when relevant:

```swift
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct GetCurrentDate: Tool {
    let name = "get_current_date"
    let description = "Returns today's date as an ISO 8601 string."
    @Generable struct Arguments {}

    @concurrent func call(arguments: Arguments) async throws -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}

let model = OpenResponsesModel(id: "my-model", capabilities: .init(toolCalling: true))
let lm = OpenResponsesLanguageModel(name: model, auth: .apiKey("key"), baseURL: url)

let session = LanguageModelSession(model: lm, tools: [GetCurrentDate()])
let result = try await session.respond(to: "What day is it today?")
print(result.content)
```

See [Examples/visionOS/visionOSExamplesApp/Examples/ToolCallingView.swift](../Examples/visionOS/visionOSExamplesApp/Examples/ToolCallingView.swift) for a complete app implementation.

## 5. Structured Output

Use `@Generable` to get typed, schema-constrained responses. The model must have `structuredOutput: true`:

```swift
import FoundationModels
import SwiftOpenResponsesLanguageModel

@Generable
struct MovieRecommendation {
    @Guide(description: "The film title") var title: String
    @Guide(description: "Release year") var year: Int
    @Guide(description: "Why this film is recommended") var reason: String
}

let model = OpenResponsesModel(id: "my-model", capabilities: .init(structuredOutput: true))
let lm = OpenResponsesLanguageModel(name: model, auth: .apiKey("key"), baseURL: url)

let session = LanguageModelSession(model: lm)
let response = try await session.respond(to: "Recommend a classic sci-fi film.", generating: MovieRecommendation.self)
print(response.content.title)   // e.g. "Blade Runner"
print(response.content.year)    // e.g. 1982
print(response.content.reason)  // e.g. "A landmark in visual science fiction..."
```

See [Examples/visionOS/visionOSExamplesApp/Examples/StructuredOutputView.swift](../Examples/visionOS/visionOSExamplesApp/Examples/StructuredOutputView.swift) for a complete app.

## 6. Image Input

Send image attachments to vision-capable models with `imageInput: true`:

```swift
import FoundationModels
import SwiftOpenResponsesLanguageModel

let model = OpenResponsesModel(id: "my-model", capabilities: .init(imageInput: true))
let lm = OpenResponsesLanguageModel(name: model, auth: .apiKey("key"), baseURL: url)

let session = LanguageModelSession(model: lm)
let imageAttachment = Attachment<ImageAttachmentContent>(cgImage)
let stream = session.streamResponse {
    imageAttachment
    "Describe what you see in this image."
}
for try await partial in stream {
    print(partial.content)
}
```

Images are JPEG-encoded at 0.8 quality and sent as base64 data URIs. See [Examples/visionOS/visionOSExamplesApp/Examples/ImageInputView.swift](../Examples/visionOS/visionOSExamplesApp/Examples/ImageInputView.swift) for a complete app with PhotosPicker integration.

## 7. Reasoning

Enable extended thinking for models with `reasoning: true`. Control the reasoning level via `ContextOptions`:

```swift
import FoundationModels
import SwiftOpenResponsesLanguageModel

let model = OpenResponsesModel(id: "my-model", capabilities: .init(reasoning: true))
let lm = OpenResponsesLanguageModel(name: model, auth: .apiKey("key"), baseURL: url)

let session = LanguageModelSession(model: lm)
let options = ContextOptions(reasoningLevel: .deep)
let result = try await session.respond(to: "How many primes between 1 and 100?", contextOptions: options)
print(result.content)

// Access reasoning trace from transcript entries
let reasoning = result.transcriptEntries.compactMap { entry -> String? in
    guard case .reasoning(let r) = entry else { return nil }
    return r.description
}
print(reasoning.joined(separator: "\n\n"))
```

Reasoning levels: `.light`, `.moderate`, `.deep`. See [Examples/visionOS/visionOSExamplesApp/Examples/ReasoningView.swift](../Examples/visionOS/visionOSExamplesApp/Examples/ReasoningView.swift) for a complete app.
