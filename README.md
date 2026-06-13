# SwiftOpenResponsesLanguageModel

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2027%20%7C%20iOS%2027%20%7C%20visionOS%2027%20%7C%20watchOS%2027-lightgrey.svg)](Package.swift)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-0.1.0-brightgreen.svg)](Package.swift)
[![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-blueviolet?logo=claude)](https://claude.ai/code)

A drop-in `LanguageModel` implementation that connects Apple's FoundationModels to any [Open Responses](https://www.openresponses.org/) specification endpoint — swap in `OpenResponsesLanguageModel` and your existing FoundationModels code works with any compatible provider.

## Why

Apple's FoundationModels gives Swift apps a unified API for language models — sessions, streaming, tools, structured output — all through `LanguageModelSession`. But the on-device model is one provider among many. When you want to use Claude, GPT, Llama, or a local server, you shouldn't have to rewrite your app.

The problem is provider lock-in. Each LLM provider has its own SDK, its own request format, its own streaming protocol, its own error types. Switching providers means rewriting networking, auth, and response handling — even though the app-level intent ("stream a response to this prompt") hasn't changed.

This package solves it by targeting a *specification*, not a provider. The [Open Responses API](https://www.openresponses.org/) defines a standard inference endpoint that any provider can implement. SwiftOpenResponsesLanguageModel bridges FoundationModels (the app-facing API) to Open Responses (the provider-facing protocol). The result: write your app once against `LanguageModelSession`, swap providers by changing one line.

The bridge is intentionally thin — no business logic, no caching, no opinions. Three translation layers convert requests in, events out, and errors between. Both FoundationModels and Open Responses can evolve independently; only the affected translator needs updating.

See [docs/philosophy.md](docs/philosophy.md) for the full design philosophy.

## The Swap

**With on-device model:**

```swift
import FoundationModels

let session = LanguageModelSession()
let stream = session.streamResponse(to: "Explain Swift concurrency.")
for try await partial in stream {
    print(partial.content)
}
```

**With any Open Responses provider:**

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

The prompt, stream, and print are identical. Only the session init changes.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftOpenResponsesLanguageModel.git", from: "0.1.0"),
]
```

Then add the dependency to your target:

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "SwiftOpenResponsesLanguageModel", package: "SwiftOpenResponsesLanguageModel"),
]),
```

Requires macOS 27+, iOS 27+, visionOS 27+, or watchOS 27+ (Xcode 27+).

## API Overview

| Type | Purpose |
|------|---------|
| `OpenResponsesLanguageModel` | `LanguageModel` conformance — pass to `LanguageModelSession` |
| `OpenResponsesModel` | Model identity + capability flags |
| `AuthMode` | `.apiKey(String)` or `.proxied(headers:)` |
| `OpenResponsesError` | Provider-specific error cases |

See [Spec/SwiftOpenResponsesLanguageModel-WHAT.md](Spec/SwiftOpenResponsesLanguageModel-WHAT.md) for full API details.

## Capability Flags

| Flag | Default | Enables |
|------|---------|---------|
| `samplingParams` | `true` | Temperature, topP, sampling mode sent in requests |
| `reasoning` | `false` | Extended thinking / reasoning effort |
| `structuredOutput` | `false` | JSON schema-constrained output |
| `imageInput` | `false` | Image attachments in prompts |
| `toolCalling` | `true` | Function calling / tool use |

## Next Steps

See [docs/getting-started.md](docs/getting-started.md) for the full progression from basic streaming through tool calling, structured output, image input, and reasoning. Complete app implementations are in [Examples/](Examples/) — the visionOS examples app demonstrates all six usage patterns.

## Testing

```bash
swift test
```

This runs the unit tests, which cover the three translation layers (RequestBuilder, EventTranslator, ErrorMapper) with no network calls. Requires macOS 27+ with Xcode 27+.

### Integration Tests

A separate test target exercises the full `LanguageModelSession` stack against a live Open Responses endpoint. Set two environment variables to enable them:

```bash
export OPEN_RESPONSES_BASE_URL=http://localhost:1234/v1/responses
export OPEN_RESPONSES_API_KEY=your-key
```

Optional variables control the model ID, enable reasoning tests, or disable capabilities your provider doesn't support. Integration tests skip cleanly when unconfigured — `swift test` always works without an endpoint.

See [Spec/SwiftOpenResponsesLanguageModel-Tests-HOW.md](Spec/SwiftOpenResponsesLanguageModel-Tests-HOW.md#running-integration-tests) for the full environment variable reference and run instructions.

## For AI Coding Tools

See [AGENTS.md](AGENTS.md) for machine-readable patterns and pitfalls.

## License

[Apache License 2.0](LICENSE)
