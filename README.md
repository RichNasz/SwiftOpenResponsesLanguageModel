# SwiftOpenResponsesLanguageModel

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2027%20%7C%20iOS%2027%20%7C%20visionOS%2027%20%7C%20watchOS%2027-lightgrey.svg)](Package.swift)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-0.1.0-brightgreen.svg)](Package.swift)
[![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-blueviolet?logo=claude)](https://claude.ai/code)

A drop-in `LanguageModel` implementation that connects Apple's FoundationModels to any [Open Responses](https://www.openresponses.org/) specification endpoint — swap in `OpenResponsesLanguageModel` and your existing FoundationModels code works with any compatible provider.

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

## For AI Coding Tools

See [AGENTS.md](AGENTS.md) for machine-readable patterns and pitfalls.

## License

[Apache License 2.0](LICENSE)
