# visionOSExamplesApp — WHAT Spec

## Overview

A visionOS 27+ app demonstrating six usage patterns of `SwiftOpenResponsesLanguageModel`. Each pattern maps to one scene in a `NavigationSplitView` sidebar and one source file in `Examples/`. Designed as a reference for human developers learning the package API and for AI agents reading code to understand how to apply it.

## Scenes

| Scene | File | Capability Flags | Core API |
|---|---|---|---|
| Streaming | `StreamingView.swift` | defaults (`capabilities: .init()`) | `session.streamResponse(to:)`, then usage totals |
| Multi-turn Conversation | `MultiTurnView.swift` | defaults | `LanguageModelSession` reused across exchanges; `prewarm()` |
| Tool Calling | `ToolCallingView.swift` | `toolCalling: true` | Tool registration, tool call → output → response |
| Structured Output | `StructuredOutputView.swift` | `structuredOutput: true` | `session.respond(to:generating:)` returning `Response<T>` |
| Image Input | `ImageInputView.swift` | `imageInput: true` | `Attachment<ImageAttachmentContent>` on `session.streamResponse` |
| Reasoning | `ReasoningView.swift` | `reasoning: true` | `session.respond(to:contextOptions:)`, reasoning from `transcriptEntries` |

**Image input:** The scene uses the same `LanguageModelSession` API as the others. `imageInput: true` maps to `.vision`. `RequestBuilder` turns `Attachment<ImageAttachmentContent>` into an `input_image` JPEG data URI. A non-empty `Attachment.label(_:)` is sent as text immediately before that image. The attachment initializer accepts an orientation; this package does not apply it, and image `detail` stays unset.

**Sampling:** `samplingParams` defaults to `true`. `StreamingView` does not set `GenerationOptions`, so temperature and top-p are included only when the session supplies them.

**Usage:** Text, reasoning, and tool deltas do not carry a token count. Totals arrive on the completed snapshot and on `Response.usage`. `StreamingView` shows input and output totals once either count is non-zero. `ReasoningView` also shows reasoning tokens.

**Prewarm:** Each scene calls `session.prewarm()` after creating the session. The call returns without waiting and does not generate. It schedules `GET` on the client's own session.

**Reasoning replay:** A reasoning transcript entry and its signature are not sent on a later turn. `ReasoningView` only reads the current response.

**Tool strict:** `FunctionTool.strict` is set only when `structuredOutput` is also on. `ToolCallingView` leaves structured output off, so `strict` is omitted.

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
- [ ] Image Input: image previews before sending; optional label is sent as text before the image; request uses `Attachment<ImageAttachmentContent>`
- [ ] Streaming: input and output token totals appear after completion when the provider reports usage
- [ ] Reasoning: reasoning and answer in separate sections; level control changes behavior; reasoning token count appears when reported
- [ ] Settings sheet opens, edits persist, closes cleanly
