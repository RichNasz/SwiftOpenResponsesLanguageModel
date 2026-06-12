# iOS Test App — HOW Spec

## Implementation Target

- Package: `SwiftOpenResponsesLanguageModel`
- Imports: `import SwiftUI`, `import FoundationModels`, `import SwiftOpenResponsesLanguageModel`
- Entry point: `@main App` + single `ContentView`

## State

`@State` is used for all fields. Persistent fields are mirrored to `UserDefaults` via `onChange` (not `@AppStorage`, since `SecureField` requires `@State`).

| Field | Type | Tracks |
|---|---|---|
| `apiKey` | `String` | API key; persisted to `UserDefaults` on every keystroke |
| `baseURL` | `String` | Inference endpoint URL; persisted to `UserDefaults` |
| `modelID` | `String` | Model identifier string; persisted to `UserDefaults` |
| `prompt` | `String` | Current prompt text |
| `response` | `String` | Accumulated response text from the last generation |
| `isGenerating` | `Bool` | Whether a generation task is in flight |
| `errorMessage` | `String?` | Last error to display; `nil` when no error |
| `inputTokens` | `Int` | Input token count from last completed generation |
| `outputTokens` | `Int` | Output token count from last completed generation |
| `currentTask` | `Task<Void, Never>?` | Handle to the in-flight generation task for cancellation |

## Model Resolution

Build an `OpenResponsesModel` from the `modelID` string with `toolCalling: false` as a safe default (capability varies by provider and is not surfaced in the demo UI).

## Send Guard

Send is enabled only when all three fields are non-empty after whitespace trimming: `baseURL`, `modelID`, and `prompt`. The API key field is required on iOS (unlike visionOS/macOS where it is optional).

## Send / Stop Toggle

The button label and action toggle based on `isGenerating`. When generating: tapping cancels the in-flight task and clears `isGenerating`. When idle: tapping starts a new generation task. The button is disabled when idle and `canSend` is false.

## Generation Flow

Runs on `@MainActor` via a `Task<Void, Never>` stored in `currentTask`:

1. Set `isGenerating = true`; clear `response`, `errorMessage`, `inputTokens`, `outputTokens`.
2. Validate `baseURL` by trimming whitespace and constructing a `URL`. If invalid, set `errorMessage` and return early.
3. Construct `OpenResponsesLanguageModel` with the validated URL, the resolved model, and `.apiKey(apiKey)` auth.
4. Create a fresh `LanguageModelSession` and call `streamResponse(to: prompt)`.
5. Iterate partial responses on the main actor; check `Task.isCancelled` before each update and break early if cancelled.
6. Catch `CancellationError` silently (user tapped Stop — no error message shown).
7. Catch all other errors and display `error.localizedDescription` in `errorMessage`.
8. On exit (defer): set `isGenerating = false`, clear `currentTask`.

## Layout

`NavigationStack` wrapping a `Form` with four sections:
1. **Endpoint** — base URL `TextField`, model ID `TextField`, API key `SecureField` (labeled "optional")
2. **Prompt** — `TextEditor` + `HStack` with Send/Stop button and token count label
3. **Error** (conditional) — red `Text`
4. **Response** (conditional) — selectable `Text`
