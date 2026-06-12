# macOS Test App — WHAT Spec

## Overview

A macOS demo app showing `OpenResponsesLanguageModel` used with FoundationModels' `LanguageModelSession`. Targets the macOS developer workflow — custom base URLs for local LLM servers (LM Studio, Ollama, etc.), free-text model ID, and optional API key.

## Features

- **Base URL Input**: Full endpoint URL, persisted via `@AppStorage`. Required — no default.
- **Model ID Input**: Free-text field for any model ID. Persisted via `@AppStorage`. No default.
  - A custom `OpenResponsesModel` is created with `toolCalling: false` as a safe default.
- **API Key**: Optional — empty string is valid for unauthenticated local servers.
- **Send / Stop**: Toggles between sending a request and cancelling the in-flight `Task`. Requires non-empty model ID and prompt.
- **Streaming Response**: Displays response text in real time as it arrives.
- **Effective URL Display**: Shows the active endpoint URL during generation.
- **Error Display**: Shows error details using `String(reflecting:)` for developer-readable output.

## Acceptance Criteria

- [ ] Compiles for macOS 27+
- [ ] All persisted fields survive app relaunch
- [ ] Custom base URL routes requests to the specified endpoint
- [ ] Model IDs are used as-is with `toolCalling: false` as a safe default capability
- [ ] Invalid or empty base URL shows an error rather than falling back to a default
- [ ] Empty API key works for local unauthenticated servers
- [ ] Effective URL appears during generation and clears on completion
- [ ] Streaming response text appears incrementally
- [ ] Tapping Stop cancels generation cleanly without showing an error
- [ ] Errors display full detail via `String(reflecting:)`
