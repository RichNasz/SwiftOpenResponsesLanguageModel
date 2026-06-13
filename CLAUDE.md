## Project Overview

SwiftOpenResponsesLanguageModel is a Swift package that bridges Apple's FoundationModels framework to Open Responses specification-compliant inference endpoints. It provides a `LanguageModel` implementation so any app written against FoundationModels can use any Open Responses-compatible provider by swapping in `OpenResponsesLanguageModel` — no changes to app-level session or generation code required.

**Package:** SwiftOpenResponsesLanguageModel
**Platforms:** macOS 27.0+, iOS 27.0+, visionOS 27.0+, watchOS 27.0+
**Swift:** 6.0+

## Commands

```bash
swift build
swift test
```

Tests require macOS 27+ (Tahoe) with Xcode 27+.

## Architecture

Thin adapter — no business logic, no caching, no conversation management. Three translation layers:

- **RequestBuilder** — converts FoundationModels `LanguageModelExecutorGenerationRequest` to Open Responses `ResponseRequest`
- **EventTranslator** — converts Open Responses `AsyncThrowingStream<StreamEvent>` to FoundationModels `LanguageModelExecutorGenerationChannel` actions
- **ErrorMapper** — maps `LLMError` to `LanguageModelError` with an intermediate `OpenResponsesError` layer

Key decision: capability flags are declared per-model at init time, not auto-detected. See `Spec/SwiftOpenResponsesLanguageModel-WHY.md` for rationale.

## File Map

| File | Purpose |
|------|---------|
| `OpenResponsesLanguageModel.swift` | `LanguageModel` conformance, capability mapping |
| `OpenResponsesModel.swift` | Model identity + `Capabilities` flags |
| `OpenResponsesExecutor.swift` | `LanguageModelExecutor` conformance, `LLMClient` init |
| `RequestBuilder.swift` | Transcript-to-`ResponseRequest` translation |
| `EventTranslator.swift` | Stream event-to-channel action translation |
| `ErrorMapper.swift` | Error mapping + `OpenResponsesError` definition |
| `AuthMode.swift` | `.apiKey` / `.proxied` enum |

## Dependencies

- **SwiftOpenResponsesDSL** — provides `LLMClient`, `ResponseRequest`, `StreamEvent`, streaming protocol
- **SwiftLLMToolMacros** (transitive) — provides `JSONSchema` types for tool definitions

## Spec Files

Consult `Spec/` files for detailed design decisions:

| File | Covers |
|------|--------|
| `SwiftOpenResponsesLanguageModel-WHAT.md` | Public API surface + acceptance criteria |
| `SwiftOpenResponsesLanguageModel-HOW.md` | Implementation details |
| `SwiftOpenResponsesLanguageModel-WHY.md` | Design rationale |
| `SwiftOpenResponsesLanguageModel-Tests-WHAT/HOW/WHY.md` | Test strategy + implementation (unit + integration) |

## Testing Strategy

Two test targets:

- **SwiftOpenResponsesLanguageModelTests** — Unit tests for the three translation components. No network calls. Four suites: ErrorMapperTests, OpenResponsesModelTests, RequestBuilderTests, EventTranslatorTests.
- **IntegrationTests** — End-to-end tests through `LanguageModelSession` against a live Open Responses endpoint. Gated on environment variables; skip if not configured. Five suites: BasicGeneration, ToolCalling, StructuredOutput, Reasoning, ErrorHandling.

Both use Swift Testing framework (`@Test`, `#expect`, `@Suite`).

```bash
# Unit tests (integration tests skip automatically)
swift test

# Integration tests — requires Xcode 27 beta toolchain and env vars set:
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild build-for-testing \
  -scheme SwiftOpenResponsesLanguageModel \
  -destination 'platform=macOS' \
  -skipPackagePluginValidation -skipMacroValidation -quiet

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcrun xctest .build/path/to/IntegrationTests.xctest
```

Note: `xcodebuild test` does not pass shell environment variables to the test process. Use `xcrun xctest <bundle>` directly, which inherits the shell environment.

Integration test environment variables:
- `OPEN_RESPONSES_BASE_URL` — full endpoint URL (required)
- `OPEN_RESPONSES_API_KEY` — API key (required)
- `OPEN_RESPONSES_MODEL_ID` — model ID (default: `gpt-4o-mini`)
- `OPEN_RESPONSES_REASONING_MODEL_ID` — reasoning model ID (optional, enables reasoning tests)
- `OPEN_RESPONSES_STRUCTURED_OUTPUT` — `true`/`false` (default: `true`)
- `OPEN_RESPONSES_TOOL_CALLING` — `true`/`false` (default: `true`)
