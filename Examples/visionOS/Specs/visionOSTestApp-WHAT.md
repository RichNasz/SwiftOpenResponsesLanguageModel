# visionOS Test App — WHAT Spec

## Purpose

This app is a bare-metal endpoint tester. Configure any Open Responses-compatible URL, model ID, and optional API key, then fire a streaming request and observe the raw response. Its value is verifying connectivity to an endpoint and comparing raw model output — not demonstrating specific package capabilities.

For capability-focused examples (streaming, multi-turn, tool calling, structured output, image input, reasoning), see `Examples/visionOS/visionOSExamplesApp/`.

---

## Overview

A visionOS demo app for custom endpoints and model IDs. Designed to demonstrate connecting to local LLM servers (LM Studio, Ollama, etc.) in addition to Open Responses-compatible hosted APIs. The macOS test app follows this same flow. The iOS test app uses the same endpoint fields and also shows token totals.

## Features

- **Base URL Input**: Plain text field for the full endpoint URL. Persisted via `@AppStorage`. Required — no default.
- **Model ID Input**: Free-text field for any model ID string. Persisted via `@AppStorage`. No default.
  - A custom `OpenResponsesModel` is created with `toolCalling: false`. `samplingParams` stays at its default, `true`.
- **API Key**: Optional — labeled "API Key (optional)". An empty value is sent as `Authorization: Bearer lm-studio`.
- **Effective URL Display**: Shows the active endpoint URL inline while a request is in progress, and clears it when generation ends.
- **Prewarm**: `session.prewarm()` runs after the session is created. It returns immediately and does not generate.

## Differences from iOS App

| iOS App | visionOS App |
|---|---|
| API key required to send | API key optional (`Bearer lm-studio` when empty) |
| `UserDefaults` persistence | `@AppStorage` persistence |
| Token count display | Active URL display during generation |

## Acceptance Criteria

- [ ] Compiles for visionOS 27+
- [ ] Persists base URL, model ID, and API key across launches
- [ ] Custom base URL routes requests to the specified endpoint
- [ ] Model IDs are used as-is with `toolCalling: false` as a safe default capability
- [ ] Invalid or empty base URL shows an error rather than falling back to a default
- [ ] Empty API key works for local servers. The client sends `Authorization: Bearer lm-studio`
- [ ] Effective URL appears during generation and clears on completion
- [ ] Streaming, cancellation, and `String(reflecting:)` error display work as specified
