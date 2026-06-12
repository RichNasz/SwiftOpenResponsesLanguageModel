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
| `SwiftOpenResponsesLanguageModel-Tests-WHAT/HOW/WHY.md` | Test strategy + implementation |

## Testing Strategy

- Unit tests only, no live API calls
- Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- Four test suites: ErrorMapperTests, OpenResponsesModelTests, RequestBuilderTests, EventTranslatorTests
