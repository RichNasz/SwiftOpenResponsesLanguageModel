# visionOS Examples App — Design

**Date:** 2026-06-11
**Status:** Approved

## Overview

A new visionOS Xcode app (`visionOSExamplesApp`) that demonstrates all six major usage patterns of `SwiftOpenResponsesLanguageModel` in isolated, self-contained scenes. The app is designed to serve two audiences equally: human developers learning the package API and AI agents reviewing code to understand how to apply it. Each capability maps to one source file and one navigation destination — no cross-example shared state beyond endpoint configuration.

The existing `visionOSTestApp` is unchanged in behavior but its specs are updated to clearly document its purpose as a bare-metal endpoint tester, distinct from this examples app.

---

## Scope

### Six Examples

| Example | Capability Flags | Core API Demonstrated |
|---|---|---|
| Streaming | defaults (`capabilities: .init()`) | `session.streamResponse(to:)` |
| Multi-turn Conversation | defaults | `LanguageModelSession` reused across exchanges |
| Tool Calling | `toolCalling: true` | Tool registration, tool call → output → response cycle |
| Structured Output | `structuredOutput: true` | `session.respond(to:, generating: T.self)` |
| Image Input | `imageInput: true` | Image attachment on a session prompt |
| Reasoning | `reasoning: true` | Reasoning level options, reasoning summary vs. final answer |

### Out of Scope

- Sampling parameters (`samplingParams`) — not a separate example; the streaming example's model uses defaults. A note in the streaming example's spec will mention where `samplingParams` fits.
- Auth mode switching — each example uses `.apiKey(apiKey)` via shared settings; `AuthMode.proxied` is documented in the existing WHAT spec, not demonstrated in a live example.
- Error handling showcase — all examples use the same error display pattern (`String(reflecting: error)`); no dedicated error-handling example.

---

## Architecture

### Navigation

`RootView` is a `NavigationSplitView`. The sidebar lists the six examples as `NavigationLink` entries. The detail column shows the selected example view. On first launch the sidebar is visible and no example is selected.

### Shared Endpoint Settings

`EndpointSettings` is a `final class` conforming to `Observable` (using the `@Observable` macro). It holds three `@AppStorage`-backed properties: `baseURL: String`, `modelID: String`, `apiKey: String`. It is instantiated once in `App.swift` and injected into the SwiftUI environment via `.environment(settings)`. Each example reads it with `@Environment(EndpointSettings.self)`.

Each example constructs its own `OpenResponsesLanguageModel` at generation time — not at view init. Settings are not observed reactively during generation; values are captured at the moment Send is tapped.

### Settings Sheet

A toolbar button (gear icon) in `RootView`'s toolbar opens `SettingsSheet` as a `.sheet`. `SettingsSheet` contains a `Form` with fields for Base URL, Model ID, and API Key (optional). Changes write immediately to `@AppStorage` via `EndpointSettings`. No explicit Save button — dismiss closes the sheet.

### Error Display

All examples display errors as `String(reflecting: error)` in a red `Text` block (matching the existing visionOSTestApp convention). This surfaces richer diagnostic detail than `localizedDescription`, appropriate for developer-facing demo apps.

### Send Guard

All examples enable the Send button only when `baseURL` and `modelID` are non-empty after whitespace trimming. API key is optional.

---

## File Structure

```
Examples/visionOS/visionOSExamplesApp/
├── visionOSExamplesApp.xcodeproj/
├── App.swift                          # @main, WindowGroup, environment injection
├── RootView.swift                     # NavigationSplitView, sidebar, toolbar
├── EndpointSettings.swift             # @Observable settings — baseURL, modelID, apiKey
├── SettingsSheet.swift                # Form UI for editing endpoint settings
├── Examples/
│   ├── StreamingView.swift            # Example 1: basic streaming
│   ├── MultiTurnView.swift            # Example 2: conversation history
│   ├── ToolCallingView.swift          # Example 3: function calling
│   ├── StructuredOutputView.swift     # Example 4: guided generation
│   ├── ImageInputView.swift           # Example 5: vision / image attachment
│   └── ReasoningView.swift            # Example 6: extended thinking
└── Specs/
    ├── visionOSExamplesApp-WHAT.md
    └── visionOSExamplesApp-HOW.md
```

---

## Per-Example Detail

### 1. StreamingView

**File:** `Examples/StreamingView.swift`

**Demonstrates:** The minimal package usage pattern. Constructs `OpenResponsesLanguageModel` with all-default capabilities and streams a response via `session.streamResponse(to:)`. The response text fills in progressively as partial results arrive.

**UI:**
- Prompt `TextEditor`
- Send / Stop `Button` (toggles on `isGenerating`)
- `Text` block showing accumulated response (selectable)
- Conditional error display

**Key state:**
- `prompt: String` — `@State`
- `response: String` — `@State`, updated on each partial
- `isGenerating: Bool` — `@State`
- `currentTask: Task<Void, Never>?` — `@State`, held for cancellation
- `errorMessage: String?` — `@State`

**Note in source:** A comment explains that `samplingParams: false` (the default) means temperature and top-P are omitted from the request. To enable them, set `samplingParams: true` and the executor will include sampling values from `GenerationOptions`.

---

### 2. MultiTurnView

**File:** `Examples/MultiTurnView.swift`

**Demonstrates:** A single `LanguageModelSession` reused across multiple user–assistant exchanges. The session accumulates transcript context automatically; the caller only needs to call `respond(to:)` again with the next user message.

**UI:**
- Scrollable message list — alternating user (trailing) and assistant (leading) bubbles
- `TextField` + Send button pinned to bottom
- "New Conversation" button in toolbar — discards the current session and creates a fresh one
- Typing indicator during generation

**Key state:**
- `session: LanguageModelSession` — `@State`, created fresh on view init and on "New Conversation"
- `messages: [(role: String, text: String)]` — `@State`, drives the message list
- `input: String` — `@State`, bound to the bottom `TextField`
- `isGenerating: Bool` — `@State`
- `errorMessage: String?` — `@State`

**Behavior:** On Send, the user message is appended to `messages`, then `session.respond(to: input)` is called. The assistant reply uses `session.respond(to:)` (non-streaming) rather than `streamResponse` — streaming in a chat list requires tracking which bubble is accumulating, which adds state-management complexity that would obscure the multi-turn concept being demonstrated. The reply is appended to `messages` when complete. If the session errors, the error is shown but the session is not reset — the conversation history is preserved for retry.

---

### 3. ToolCallingView

**File:** `Examples/ToolCallingView.swift`

**Demonstrates:** Registering a tool with a `LanguageModelSession` and observing the full tool call → tool output → final response cycle.

**Tool:** `GetCurrentDateTool` — returns the current date as an ISO 8601 string. No network calls, no side effects, deterministic. Chosen to be maximally readable without domain noise.

**UI:**
- Prompt `TextEditor` with a suggested starter prompt pre-filled ("What day is it today, and how many days until the end of the year?")
- Send / Stop button
- Event log — a `List` that grows as events arrive: "Calling tool: GetCurrentDate", "Tool returned: 2026-06-11", "Response: …"
- Error display

**Key state:**
- `events: [EventEntry]` — `@State`; `EventEntry` is a local enum: `.toolCall(name:)`, `.toolResult(String)`, `.response(String)`
- `isGenerating: Bool` — `@State`

**Capability flags:** `OpenResponsesModel(id:, capabilities: .init(toolCalling: true))`

---

### 4. StructuredOutputView

**File:** `Examples/StructuredOutputView.swift`

**Demonstrates:** `session.respond(to:, generating: T.self)` where `T` is a `@Generable` struct, returning typed data instead of a raw string.

**Output type:** `MovieRecommendation` — a local `@Generable` struct with three fields: `title: String`, `year: Int`, `reason: String`. Small enough to read at a glance, realistic enough to be relatable.

**UI:**
- Prompt `TextEditor` pre-filled with "Recommend a classic science fiction film."
- Send button
- Result panel: three labeled rows (`Title`, `Year`, `Reason`) populated from the decoded struct, empty until generation completes
- Error display

**Key state:**
- `result: MovieRecommendation?` — `@State`
- `isGenerating: Bool` — `@State`
- `errorMessage: String?` — `@State`

**Capability flags:** `OpenResponsesModel(id:, capabilities: .init(structuredOutput: true))`

**Note in source:** Comment explains that `structuredOutput: true` causes `RequestBuilder` to attach a JSON schema constraint to the request; the model response is schema-validated before being decoded into `MovieRecommendation`.

---

### 5. ImageInputView

**File:** `Examples/ImageInputView.swift`

**Demonstrates:** Attaching an image to a session prompt via FoundationModels' `Attachment<ImageAttachmentContent>` and querying a vision-capable model about it. Uses `LanguageModelSession` with a `@PromptBuilder` closure — the same session API as all other examples. The `RequestBuilder` handles converting the `ImageAttachment` to an Open Responses `input_image` content part (JPEG-encoded base64 data URI).

**UI:**
- `PhotosPicker` button — opens the system photo picker; selected image shown as a thumbnail
- Prompt `TextEditor` pre-filled with "Describe what you see in this image."
- Send / Stop button (disabled until an image is selected and model/URL are set)
- Response `Text` (selectable, streaming)
- Error display

**Key state:**
- `imageData: Data?` — `@State`, loaded from `PhotosPickerItem`
- `displayImage: Image?` — `@State`, rendered as the thumbnail
- `prompt: String` — `@State`
- `response: String` — `@State`
- `isGenerating: Bool` — `@State`

**Capability flags:** `OpenResponsesModel(id:, capabilities: .init(imageInput: true))`

**Send flow:** Converts `imageData` → `UIImage` → `CGImage`, creates `Attachment<ImageAttachmentContent>(cgImage)`, then streams via `@PromptBuilder`:
```swift
let stream = session.streamResponse {
    imageAttachment
    prompt
}
```

**Send guard:** requires image selected + model ID + base URL.

---

### 6. ReasoningView

**File:** `Examples/ReasoningView.swift`

**Demonstrates:** Enabling reasoning on a model that supports it, choosing a reasoning level, and surfacing the reasoning summary alongside the final answer as separate UI sections.

**UI:**
- Segmented control: Light / Moderate / Deep (maps to `ContextOptions.ReasoningLevel`)
- Prompt `TextEditor`
- Send / Stop button
- Two collapsible `DisclosureGroup` sections below: "Reasoning" (the summary trace) and "Answer" (the final response text). Reasoning group is collapsed by default, answer is expanded.
- Error display

**Key state:**
- `reasoningLevel: ReasoningLevel` — `@State`, drives the segmented control; default `.moderate`
- `reasoningText: String` — `@State`
- `answerText: String` — `@State`
- `isGenerating: Bool` — `@State`

**Capability flags:** `OpenResponsesModel(id:, capabilities: .init(reasoning: true))`

**Note in source:** Comment explains that reasoning content arrives via `EventTranslator`'s `.reasoning` channel action and surfaces separately from `.response` — the session caller does not need to parse it out of the answer text.

---

## Existing visionOSTestApp Update

The two existing spec files receive the following additions:

**`visionOSTestApp-WHAT.md`** — a "Purpose" section inserted at the top:

> This app is a bare-metal endpoint tester. Configure any Open Responses-compatible URL, model ID, and optional API key, then fire a streaming request and observe the raw response. Its value is verifying connectivity to an endpoint and comparing raw model output — not demonstrating specific package capabilities. For capability-focused examples, see `visionOSExamplesApp`.

**`visionOSTestApp-HOW.md`** — no changes needed; the implementation detail is accurate.

---

## Acceptance Criteria

- [ ] `visionOSExamplesApp` compiles for visionOS 27+
- [ ] Endpoint settings persist across app launches via `@AppStorage`
- [ ] Each of the six example scenes is reachable from the sidebar
- [ ] StreamingView: streaming text updates incrementally; Stop cancels mid-stream
- [ ] MultiTurnView: session maintains context across at least two exchanges; "New Conversation" resets
- [ ] ToolCallingView: tool call and result appear in the event log before the final response
- [ ] StructuredOutputView: result fields populate from a decoded struct, not raw text parsing
- [ ] ImageInputView: selected image previews before sending; response refers to image content
- [ ] ReasoningView: reasoning and answer appear in separate sections; level control changes behavior
- [ ] All examples display errors via `String(reflecting: error)`
- [ ] `visionOSTestApp-WHAT.md` contains the "Purpose" section describing it as an endpoint tester
