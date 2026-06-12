# Documentation Generation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate all 5 documentation files defined in `Spec/DocumentationSpec.md`: README.md, docs/getting-started.md, CLAUDE.md, AGENTS.md, and CONTRIBUTING.md.

**Architecture:** Each file is generated directly from the spec requirements and verified against source code for accuracy. No tests — these are markdown files. Verification is by line count, link resolution, and content accuracy.

**Tech Stack:** Markdown

---

### Task 1: Create README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

```markdown
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
```

- [ ] **Step 2: Verify line count and structure**

Run: `wc -l README.md`
Expected: ~80 lines. Verify the substitutability story shows identical code except the session init.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add README with substitutability story and API overview"
```

---

### Task 2: Create docs/getting-started.md

**Files:**
- Create: `docs/getting-started.md`

- [ ] **Step 1: Write docs/getting-started.md**

```markdown
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

See [Examples/visionOS/visionOSExamplesApp/Examples/ToolCallingView.swift](Examples/visionOS/visionOSExamplesApp/Examples/ToolCallingView.swift) for a complete app implementation.

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

See [Examples/visionOS/visionOSExamplesApp/Examples/StructuredOutputView.swift](Examples/visionOS/visionOSExamplesApp/Examples/StructuredOutputView.swift) for a complete app.

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

Images are JPEG-encoded at 0.8 quality and sent as base64 data URIs. See [Examples/visionOS/visionOSExamplesApp/Examples/ImageInputView.swift](Examples/visionOS/visionOSExamplesApp/Examples/ImageInputView.swift) for a complete app with PhotosPicker integration.

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

Reasoning levels: `.light`, `.moderate`, `.deep`. See [Examples/visionOS/visionOSExamplesApp/Examples/ReasoningView.swift](Examples/visionOS/visionOSExamplesApp/Examples/ReasoningView.swift) for a complete app.
```

- [ ] **Step 2: Verify line count and progression**

Run: `wc -l docs/getting-started.md`
Expected: ~120-150 lines. Verify sections progress from simple (streaming) to complex (reasoning).

- [ ] **Step 3: Commit**

```bash
git add docs/getting-started.md
git commit -m "docs: add getting-started guide with progressive feature examples"
```

---

### Task 3: Create CLAUDE.md

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Write CLAUDE.md**

```markdown
## Project Overview

SwiftOpenResponsesLanguageModel is a Swift package that bridges Apple's FoundationModels framework to Open Responses specification-compliant inference endpoints. It provides a `LanguageModel` implementation so any app written against FoundationModels can use any Open Responses-compatible provider by swapping in `OpenResponsesLanguageModel` — no changes to app-level session or generation code required.

**Package:** SwiftOpenResponsesLanguageModel
**Platforms:** macOS 27.0+, iOS 27.0+, visionOS 27.0+, watchOS 27.0+
**Swift:** 6.0+

## Commands

```bash
swift build
swift test
```

Tests require macOS 27+ (Tahoe) with Xcode 27+.

## Architecture

Thin adapter — no business logic, no caching, no conversation management. Three translation layers:

- **RequestBuilder** — converts FoundationModels `LanguageModelExecutorGenerationRequest` to Open Responses `ResponseRequest`
- **EventTranslator** — converts Open Responses `AsyncThrowingStream<StreamEvent>` to FoundationModels `LanguageModelExecutorGenerationChannel` actions
- **ErrorMapper** — maps `LLMError` to `LanguageModelError` with an intermediate `OpenResponsesError` layer

Key decision: capability flags are declared per-model at init time, not auto-detected. See `Spec/SwiftOpenResponsesLanguageModel-WHY.md` for rationale.

## File Map

| File | Purpose |
|------|---------|
| `OpenResponsesLanguageModel.swift` | `LanguageModel` conformance, capability mapping |
| `OpenResponsesModel.swift` | Model identity + `Capabilities` flags |
| `OpenResponsesExecutor.swift` | `LanguageModelExecutor` conformance, `LLMClient` init |
| `RequestBuilder.swift` | Transcript-to-`ResponseRequest` translation |
| `EventTranslator.swift` | Stream event-to-channel action translation |
| `ErrorMapper.swift` | Error mapping + `OpenResponsesError` definition |
| `AuthMode.swift` | `.apiKey` / `.proxied` enum |

## Dependencies

- **SwiftOpenResponsesDSL** — provides `LLMClient`, `ResponseRequest`, `StreamEvent`, streaming protocol
- **SwiftLLMToolMacros** (transitive) — provides `JSONSchema` types for tool definitions

## Spec Files

Consult `Spec/` files for detailed design decisions:

| File | Covers |
|------|--------|
| `SwiftOpenResponsesLanguageModel-WHAT.md` | Public API surface + acceptance criteria |
| `SwiftOpenResponsesLanguageModel-HOW.md` | Implementation details |
| `SwiftOpenResponsesLanguageModel-WHY.md` | Design rationale |
| `SwiftOpenResponsesLanguageModel-Tests-WHAT/HOW/WHY.md` | Test strategy + implementation |

## Testing Strategy

- Unit tests only, no live API calls
- Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- Four test suites: ErrorMapperTests, OpenResponsesModelTests, RequestBuilderTests, EventTranslatorTests
```

- [ ] **Step 2: Verify line count**

Run: `wc -l CLAUDE.md`
Expected: ~60-70 lines.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md with architecture and file map"
```

---

### Task 4: Create AGENTS.md

**Files:**
- Create: `AGENTS.md`

- [ ] **Step 1: Write AGENTS.md**

```markdown
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
```

- [ ] **Step 2: Verify line count**

Run: `wc -l AGENTS.md`
Expected: ~100-120 lines.

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs: add AGENTS.md with patterns and pitfalls for AI tools"
```

---

### Task 5: Create CONTRIBUTING.md

**Files:**
- Create: `CONTRIBUTING.md`

- [ ] **Step 1: Write CONTRIBUTING.md**

```markdown
# Contributing to SwiftOpenResponsesLanguageModel

Thanks for your interest in SwiftOpenResponsesLanguageModel. Contributions via GitHub Issues are welcome.

## Reporting Bugs

Open a [GitHub Issue](https://github.com/RichNasz/SwiftOpenResponsesLanguageModel/issues). Please include:

- What you expected to happen
- What actually happened
- Your Swift version and platform (macOS/iOS/visionOS)
- A minimal code snippet that reproduces the problem

## Requesting Features

Open a [GitHub Issue](https://github.com/RichNasz/SwiftOpenResponsesLanguageModel/issues). Describe what you want and why — not how to implement it. The best feature requests focus on the problem to solve, not a specific solution.

## How Changes Are Made

This project uses spec-driven development. The [`Spec/`](Spec/) directory contains WHAT specs (desired behavior), HOW specs (implementation approach), and WHY specs (design rationale). Code is generated from these specs.

All changes start as a GitHub Issue. Issues are resolved interactively with an AI coding agent through this workflow:

1. Issue is raised (bug report or feature request)
2. AI agent analyzes the issue against existing specs
3. Specs are updated to reflect the change
4. Code is generated from the updated specs
5. Tests verify the implementation

**Code PRs are not accepted.** Unsolicited code PRs skip the spec step and can't be merged — the specs must be updated first so that design decisions are captured and code can be regenerated consistently. Feature ideas raised via issues may be implemented in a future release when they align with the project's direction.
```

- [ ] **Step 2: Verify line count**

Run: `wc -l CONTRIBUTING.md`
Expected: ~30-40 lines.

- [ ] **Step 3: Commit**

```bash
git add CONTRIBUTING.md
git commit -m "docs: add CONTRIBUTING.md with spec-driven development workflow"
```

---

### Task 6: Final Verification

**Files:**
- Verify: `README.md`, `docs/getting-started.md`, `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`

- [ ] **Step 1: Verify total line count**

Run: `wc -l README.md docs/getting-started.md CLAUDE.md AGENTS.md CONTRIBUTING.md`
Expected: under 450 lines total.

- [ ] **Step 2: Verify all cross-references resolve**

Run: `grep -rn '\[.*\](.*\.md)' README.md CLAUDE.md AGENTS.md CONTRIBUTING.md docs/getting-started.md | grep -v '^#'`
Check each linked file exists.

- [ ] **Step 3: Verify no content duplication**

Spot-check: README's API table should not be repeated in AGENTS.md. CLAUDE.md file map should not repeat the same level of detail as the WHAT spec. AGENTS.md should not explain architecture (that's CLAUDE.md territory).

- [ ] **Step 4: Verify substitutability story**

Read README.md. The two code blocks should differ only in the session init line. The prompt, stream iteration, and print statement should be identical.

- [ ] **Step 5: Commit all docs together if not already committed individually**

```bash
git add README.md docs/getting-started.md CLAUDE.md AGENTS.md CONTRIBUTING.md
git commit -m "docs: generate documentation suite from DocumentationSpec"
```
