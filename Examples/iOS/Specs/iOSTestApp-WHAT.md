# iOS Test App — WHAT Spec

## Overview

An iOS demo app showing `OpenResponsesLanguageModel` used with FoundationModels' `LanguageModelSession`. Demonstrates endpoint configuration, real-time streaming, token counting, and cancellation — a single-turn text generation request. There is no preset catalog. `OpenResponsesModel` is built from the model ID the user types.

## Features

- **Base URL**: Full endpoint URL. Persisted across launches via `UserDefaults`. Required.
- **Model ID**: Free-text field. Persisted via `UserDefaults`. A custom `OpenResponsesModel` uses `toolCalling: false`. `samplingParams` stays at its default, `true`. The app does not set `GenerationOptions`.
- **API Key**: Secure text field. Required. Persisted via `UserDefaults`.
- **Prompt Input**: Multi-line `TextEditor`.
- **Send / Stop**: Toggles between sending a request and cancelling the in-flight `Task`. Send is disabled while a request is in progress or when the base URL, model ID, API key, or prompt is empty.
- **Streaming Response**: Displays response text as it arrives, updating in real time.
- **Token Counts**: Shows input and output totals from the latest `ResponseStream` snapshot once either count is non-zero. Earlier snapshots report zero because streamed deltas do not carry a token count. Hidden when both are zero.
- **Error Display**: Shows `error.localizedDescription` for non-cancellation failures.

## Conversation Model

Single-turn only. Each Send creates a fresh `LanguageModelSession` — no conversation history is preserved between sends.

## Acceptance Criteria

- [ ] Compiles for iOS 27+
- [ ] Base URL, model ID, and API key persist between app launches
- [ ] Model IDs are used as-is with `toolCalling: false`
- [ ] Streaming response text appears incrementally in the UI
- [ ] Input and output token totals appear after completion when the provider reports usage, and stay hidden while both are zero
- [ ] Send button is disabled when base URL, model ID, API key, or prompt is empty
- [ ] Tapping Stop cancels generation cleanly without showing an error
- [ ] Network or API errors display `localizedDescription`
