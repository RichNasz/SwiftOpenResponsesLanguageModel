# visionOSExamplesApp — HOW Spec

## File Structure

```
visionOSExamplesApp/
├── App.swift                    # @main; creates EndpointSettings, injects into environment
├── EndpointSettings.swift       # @Observable class; baseURL, modelID, apiKey + UserDefaults sync
├── SettingsSheet.swift          # Form sheet for editing EndpointSettings; opened from toolbar
├── RootView.swift               # NavigationSplitView + Example enum
├── Examples/
│   ├── StreamingView.swift      # session.streamResponse(to:); usage totals after completion
│   ├── MultiTurnView.swift      # session.respond(to:) on a reused session; prewarm()
│   ├── ToolCallingView.swift    # GetCurrentDateTool; capabilities: .init(toolCalling: true)
│   ├── StructuredOutputView.swift # @Generable MovieRecommendation; capabilities: .init(structuredOutput: true)
│   ├── ImageInputView.swift     # Attachment<ImageAttachmentContent> plus optional label
│   └── ReasoningView.swift      # ContextOptions.ReasoningLevel; reasoning text and token count
└── Specs/
    ├── visionOSExamplesApp-WHAT.md
    └── visionOSExamplesApp-HOW.md
```

## EndpointSettings

`@Observable final class`. Three stored properties — `baseURL`, `modelID`, `apiKey` — initialized from `UserDefaults` and synced back via `didSet`. Stored (not computed) so the `@Observable` macro can track mutations. Injected via `.environment(settings)` in `App.swift`, consumed via `@Environment(EndpointSettings.self)` in each scene.

Key: uses `examples_` prefix on all `UserDefaults` keys to avoid collision with the `visionOSTestApp` which uses unprefixed keys (`api_key`, `base_url`, `model_id`).

## SettingsSheet

Uses `@Bindable var settings = settings` to derive bindings from the `@Observable` environment object. `@Bindable` is required for `@Observable` types; `@ObservedObject` bindings are not used.

## RootView

`Example` is a `CaseIterable` enum with `rawValue: String` labels and `systemImage` computed property. The `NavigationSplitView` sidebar uses `List(Example.allCases, selection: $selectedExample)` with `.tag(example)` on each row. The detail column switches on `selectedExample` with a `ContentUnavailableView` default.

## OpenResponsesLanguageModel Construction

Each example constructs `OpenResponsesLanguageModel` at generation time (inside the async task), not at view init. This ensures settings are captured at the moment Send is tapped, not at the time the view appears. `MultiTurnView` is the exception: it builds the model when settings change so one session can keep the transcript.

After every `LanguageModelSession` is created, the scene calls `session.prewarm()`. The method returns immediately. The executor schedules `LLMClient.prewarm()`, a `GET` on the client's session with the same auth headers as generation, and does not wait for it. The call does not generate.

## ToolCallingView: Tool Protocol (Verified API)

The FoundationModels `Tool` protocol (visionOS 27) requires:
- Instance properties `let name: String` and `let description: String` (not `static let`)
- `@Generable struct Arguments` for argument schema generation
- `@concurrent func call(arguments: Arguments) async throws -> String` where `Output = String`

`GetCurrentDateTool` must be `Sendable` (required by the `Tool` protocol). Rather than a shared `actor`-based log, the tool receives a `@Sendable @MainActor (String, String) -> Void` closure. The closure is declared `@MainActor` so it can safely mutate the `@State` array `events` without `await MainActor.run { }` wrapping.

The model is `capabilities: .init(toolCalling: true)`. `structuredOutput` stays at its default, `false`, so `RequestBuilder` leaves `FunctionTool.strict` unset.

## StructuredOutputView: Structured Output (Verified API)

`@Generable` and `@Guide(description:)` are available on visionOS 27 FoundationModels. `session.respond(to:generating:)` returns `Response<T>` — the generated struct is accessed via `response.content`, not as a direct return value.

## Build Configuration

`GENERATE_INFOPLIST_FILE = YES` — the project uses a generated Info.plist rather than a manual one. Required keys (`CFBundleIdentifier`, bundle version, etc.) are derived from build settings (`PRODUCT_BUNDLE_IDENTIFIER`, `MARKETING_VERSION`, etc.). `INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES` enables automatic scene manifest generation for SwiftUI lifecycle.

`NSAppTransportSecurity` is configured with `NSAllowsArbitraryLoads = YES`. The app connects to user-configured LLM endpoints that may be local (HTTP) or remote (HTTPS) at arbitrary URLs — restricting transport security would break the core use case. Acceptable for a developer-facing example app; a production app should use domain-specific exceptions instead.

## StreamingView: Sampling and Usage

`makeModel()` uses `capabilities: .init()`. `samplingParams` therefore stays at its default, `true`. The view does not pass `GenerationOptions`, so this scene does not set temperature or top-p itself.

The stream loop keeps the latest `partial.usage`. After the loop, if `input.totalTokenCount` or `output.totalTokenCount` is non-zero, the view shows both. Earlier snapshots stay at zero because Open Responses deltas have no token count.

## ImageInputView: Session Attachment

Image input goes through `LanguageModelSession`, with `capabilities: .init(imageInput: true)`.

The `.onChange(of: pickerItem)` closure uses `Task { @MainActor in ... }` so that `@State` properties (`imageData`, `displayImage`) are accessed on the main actor. Without `@MainActor`, Swift 6 strict concurrency flags a warning because `@State` properties are main-actor-isolated and cannot be referenced from a plain `Sendable` closure.

1. Load image bytes via `PhotosPickerItem.loadTransferable(type: Data.self)`.
2. Decode a `CGImage`.
3. Build `Attachment<ImageAttachmentContent>(cgImage)`. Do not pass an orientation. This package sends the pixel buffer as a JPEG data URI and leaves `detail` unset.
4. If the label field is non-empty after trimming, call `.label(_)` on the attachment. `RequestBuilder` emits that string as `input_text` immediately before the image. An empty label adds no text part.
5. Stream with `session.streamResponse { imageAttachment; prompt }`.

`RequestBuilder` performs the JPEG encoding. The view does not build a data URI or call `LLMClient`.

## ReasoningView: Reasoning API (Verified API)

Reasoning level is passed via `ContextOptions(reasoningLevel:)` to `session.respond(to:contextOptions:)` — not through `GenerationOptions`. `ContextOptions.ReasoningLevel` has `.light`, `.moderate`, `.deep`, `.custom(String)` cases.

Reasoning text is not a dedicated property on `Response<String>`. It is recovered by filtering `result.transcriptEntries` for `.reasoning(Transcript.Reasoning)` entries and reading their `.description` computed property:

```swift
let ctxOptions = ContextOptions(reasoningLevel: reasoningLevel.foundationModelsLevel)
let result = try await session.respond(to: prompt, contextOptions: ctxOptions)
answerText = result.content
let reasoningSegments = result.transcriptEntries.compactMap { entry -> String? in
    guard case .reasoning(let r) = entry else { return nil }
    return r.description
}
reasoningText = reasoningSegments.joined(separator: "\n\n")
```

The signature on that reasoning entry is not displayed and is not sent on a later turn. `InputItem` in SwiftOpenResponsesDSL has no reasoning case. When `result.usage.output.reasoningTokenCount` or `totalTokenCount` is non-zero, the view shows both under the answer.

## MultiTurnView: Session Rebuild

`buildSession()` runs from `onAppear` and whenever `baseURL`, `modelID`, or `apiKey` changes. The API key is part of `LLMClient` initialization, so a settings change has to replace the session. An empty or invalid URL or model ID sets `session` to `nil` and disables Send. `prewarm()` runs on each successful build.

Uses `session.respond(to:)` rather than `session.streamResponse(to:)`. Streaming in a chat list requires tracking which bubble is accumulating — an extra `@State` array index plus special-casing the last message — which would obscure the multi-turn concept. `respond()` appends the complete assistant message in one step, keeping the implementation focused.

All other examples create a fresh `LanguageModelSession` per generation call, call `prewarm()`, and drop the session when that call finishes.
