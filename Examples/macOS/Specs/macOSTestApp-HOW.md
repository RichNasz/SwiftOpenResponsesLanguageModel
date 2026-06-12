# macOS Test App — HOW Spec

## Implementation Target

- Package: `SwiftOpenResponsesLanguageModel`
- Imports: `import SwiftUI`, `import FoundationModels`, `import SwiftOpenResponsesLanguageModel`
- Entry point: `@main App` + single `ContentView`
- SDK: `macosx`, deployment target: macOS 27.0

## Relationship to visionOS App

The macOS app is functionally identical to the visionOS test app. The SwiftUI structure — state fields, model resolution, generation flow, cancellation, and layout — is the same on both platforms. The only differences are Xcode project settings (SDK, deployment target, bundle ID) and the window title.

## State

Uses `@AppStorage` for persisted fields (automatically reads/writes `UserDefaults`). `@State` for transient fields.

| Field | Persistence | Tracks |
|---|---|---|
| `apiKey` | `@AppStorage` | API key; optional for send |
| `baseURL` | `@AppStorage` | Inference endpoint URL |
| `modelID` | `@AppStorage` | Model identifier string |
| `prompt` | `@State` | Current prompt text |
| `response` | `@State` | Accumulated response text |
| `isGenerating` | `@State` | Whether a generation task is in flight |
| `errorMessage` | `@State String?` | Last error to display |
| `currentTask` | `@State Task<Void, Never>?` | Handle to in-flight task for cancellation |
| `effectiveURL` | `@State String` | Resolved URL shown while generating; cleared after |

## Model Resolution

Build an `OpenResponsesModel` from the `modelID` string with `toolCalling: false` as a safe default.

## Send Guard

Send is enabled when both `modelID` and `prompt` are non-empty after whitespace trimming. The API key is optional — the empty string is valid and passes through the `lm-studio` sentinel in the executor.

## Generation Flow

Same sequence as the visionOS app:

1. Set `isGenerating = true`; clear `response`, `errorMessage`.
2. Strip whitespace from `baseURL`, validate as a `URL`, set `effectiveURL` on success.
3. Construct `OpenResponsesLanguageModel` and a fresh `LanguageModelSession`.
4. Stream partial responses on `@MainActor`; break on `Task.isCancelled`.
5. Catch `CancellationError` silently; display other errors via `errorMessage`.
6. On exit (defer): clear `isGenerating`, `currentTask`, and `effectiveURL`.

## Xcode Project Settings

| Setting | Value |
|---|---|
| `SDKROOT` | `macosx` |
| `MACOSX_DEPLOYMENT_TARGET` | `27.0` |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.example.macOSTestApp` |
| `SWIFT_VERSION` | `6.0` |
| `INFOPLIST_FILE` | `Info.plist` |

## Info.plist Notes

Remove all `UIApplication*` and `UIScene*` keys — those are iOS/visionOS-only. Include:
- `NSHighResolutionCapable = YES` for Retina display support
- `NSAppTransportSecurity.NSAllowsArbitraryLoads = YES` for local HTTP servers

## Layout

`NavigationStack` wrapping a `Form` with four sections:
1. **Endpoint** — base URL `TextField`, model ID `TextField`, API key `SecureField` (labeled "optional")
2. **Prompt** — `TextEditor` + `HStack` with Send/Stop button and effective URL label
3. **Error** (conditional) — red `Text`
4. **Response** (conditional) — selectable `Text`

`.navigationTitle("OpenResponses")` sets the window title.
