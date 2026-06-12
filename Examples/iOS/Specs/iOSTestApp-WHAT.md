# iOS Test App — WHAT Spec

## Overview

An iOS demo app showing `OpenResponsesLanguageModel` used with FoundationModels' `LanguageModelSession`. Demonstrates API key configuration, model selection, real-time streaming, token counting, and cancellation — covering the core use case of a single-turn text generation request.

## Features

- **API Key**: Secure text field. Persisted across launches via `UserDefaults`.
- **Model Picker**: Menu picker over all predefined `OpenResponsesModel` presets. Defaults to `gpt-4.1`.
- **Prompt Input**: Multi-line `TextEditor`.
- **Send / Stop**: Toggles between sending a request and cancelling the in-flight `Task`. Send is disabled while a request is in progress or if either the API key or prompt is empty.
- **Streaming Response**: Displays response text as it arrives, updating in real time.
- **Token Counts**: Shows input and output token totals below the Send button once available. Hidden when both are zero.
- **Error Display**: Shows a localized error message for non-cancellation failures.

## Conversation Model

Single-turn only. Each Send creates a fresh `LanguageModelSession` — no conversation history is preserved between sends.

## Acceptance Criteria

- [ ] Compiles for iOS 27+
- [ ] API key persists between app launches
- [ ] All predefined model presets appear in the picker
- [ ] Streaming response text appears incrementally in the UI
- [ ] Send button is disabled when API key or prompt is empty
- [ ] Tapping Stop cancels generation cleanly without showing an error
- [ ] Network or API errors display a readable message
