# visionOS Test App — HOW Spec

## Implementation Target

- Package: `SwiftOpenResponsesLanguageModel`
- Imports: `import SwiftUI`, `import FoundationModels`, `import SwiftOpenResponsesLanguageModel`

## State

Uses `@AppStorage` for persisted fields. `@State` for transient fields.

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

Build an `OpenResponsesModel` from `modelID` with `toolCalling: false` as a safe default. API key is passed as-is — the executor substitutes the `lm-studio` sentinel for empty strings.

## Send Guard

Send is enabled when both `modelID` and `prompt` are non-empty after whitespace trimming. The API key is optional (unlike iOS where all three fields are required).

## Generation Flow

1. Set `isGenerating = true`; clear `response`, `errorMessage`.
2. Strip whitespace from `baseURL`, validate as a `URL`. If invalid, set `errorMessage` and exit. On success, set `effectiveURL`.
3. Construct `OpenResponsesLanguageModel` with `.apiKey(apiKey)` auth and the validated URL.
4. Create a fresh `LanguageModelSession` and stream partial responses on `@MainActor`; break on `Task.isCancelled`.
5. Catch `CancellationError` silently (user tapped Stop).
6. Catch other errors and display via `String(reflecting: error)` — this surfaces richer diagnostic detail than `localizedDescription`, which is appropriate for a developer-facing demo app.
7. On exit (defer): clear `isGenerating`, `currentTask`, and `effectiveURL`.

## Differences from iOS App

| Concern | iOS | visionOS/macOS |
|---|---|---|
| Persistence | `UserDefaults` + `onChange` (required for `SecureField`) | `@AppStorage` |
| Send guard | Requires API key, baseURL, and prompt | Requires only modelID and prompt |
| Error display | `error.localizedDescription` | `String(reflecting: error)` for richer output |
| Token display | Shows input/output token counts | Not shown |

## Layout

`NavigationStack` wrapping a `Form` with four sections:
1. **Endpoint** — base URL `TextField`, model ID `TextField`, API key `SecureField` (labeled "optional")
2. **Prompt** — `TextEditor` + `HStack` with Send/Stop button and effective URL label (shown only while generating)
3. **Error** (conditional) — red `Text`
4. **Response** (conditional) — selectable `Text`
