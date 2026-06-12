# visionOSExamplesApp — WHAT Spec

## Overview

A visionOS 27+ app demonstrating six usage patterns of `SwiftOpenResponsesLanguageModel`. Each pattern maps to one scene in a `NavigationSplitView` sidebar and one source file in `Examples/`. Designed as a reference for human developers learning the package API and for AI agents reading code to understand how to apply it.

## Scenes

| Scene | File | Capability Flags | Core API |
|---|---|---|---|
| Streaming | `StreamingView.swift` | defaults (`capabilities: .init()`) | `session.streamResponse(to:)` |
| Multi-turn Conversation | `MultiTurnView.swift` | defaults | `LanguageModelSession` reused across exchanges |
| Tool Calling | `ToolCallingView.swift` | `toolCalling: true` | Tool registration, tool call → output → response |
| Structured Output | `StructuredOutputView.swift` | `structuredOutput: true` | `session.respond(to:generating:)` returning `Response<T>` |
| Image Input | `ImageInputView.swift` | N/A (see note) | `LLMClient` + `InputContentPart.inputImage` |
| Reasoning | `ReasoningView.swift` | `reasoning: true` | `session.respond(to:contextOptions:)`, reasoning from `transcriptEntries` |

**Image Input note:** FoundationModels does not expose an image attachment API in the public `Transcript.Segment` interface in this SDK release. `ImageInputView` uses `LLMClient` from `SwiftOpenResponsesDSL` directly, encoding the image as a base64 data URI passed as `InputContentPart.inputImage`. This is documented in a comment in the source file.

## Shared Infrastructure

`EndpointSettings` (`@Observable`) holds `baseURL`, `modelID`, and `apiKey`. It is instantiated once in `App.swift`, injected into the SwiftUI environment, and read by each example scene. Each scene constructs its own `OpenResponsesLanguageModel` at generation time — settings are captured when Send is tapped, not observed reactively during generation.

`SettingsSheet` is a `.sheet` opened via the toolbar gear button. Changes write immediately to `UserDefaults` via `EndpointSettings.didSet`.

## FoundationModels API Notes (Verified Against Installed SDK)

These notes reflect the actual FoundationModels API for visionOS 27, discovered during implementation:

- **Tool protocol:** Uses instance properties `let name: String` and `let description: String` (not `static let`), and `@concurrent func call(arguments:) async throws -> Output`. `Output` is `String` (not a `ToolOutput` type).
- **Structured output:** `session.respond(to:generating:)` returns `Response<T>` — access the generated value via `response.content`.
- **Reasoning level:** Passed via `ContextOptions(reasoningLevel:)` to `session.respond(to:contextOptions:)`. `ContextOptions.ReasoningLevel` has `.light`, `.moderate`, `.deep`, `.custom(String)` cases.
- **Reasoning text:** Extracted from `result.transcriptEntries` by filtering for `.reasoning(Transcript.Reasoning)` entries and reading their `.description` computed property. There is no `.reasoning` property on `Response<String>`.

## Network Access

The app requires unrestricted network access (`NSAllowsArbitraryLoads`) because users configure arbitrary LLM endpoint URLs — including local HTTP servers. This is a developer-facing example app, not a production consumer app.

## Error Display

All examples display errors as `String(reflecting: error)` — richer diagnostic detail than `localizedDescription`, appropriate for developer-facing demo apps.

## Acceptance Criteria

- [ ] Compiles for visionOS 27+
- [ ] Endpoint settings persist across app launches
- [ ] All six scenes reachable from the sidebar
- [ ] Streaming: text updates incrementally; Stop cancels mid-stream
- [ ] Multi-turn: session holds context across exchanges; New Conversation resets
- [ ] Tool Calling: tool call and result appear in event log before final response
- [ ] Structured Output: result fields populate from a decoded struct, not raw text
- [ ] Image Input: image previews before sending; request sent with base64-encoded image
- [ ] Reasoning: reasoning and answer in separate sections; level control changes behavior
- [ ] Settings sheet opens, edits persist, closes cleanly
