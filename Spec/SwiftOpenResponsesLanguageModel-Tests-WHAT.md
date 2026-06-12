# SwiftOpenResponsesLanguageModel — Tests WHAT Spec

## Scope

Unit tests for the three internal translation components that bridge FoundationModels types to Open Responses types. No live API calls. No integration tests through `LanguageModelSession` (those require a running inference server).

## Components Under Test

### ErrorMapper

`ErrorMapper.map(_:)` — normalizes `LLMError` into `LanguageModelError` or `OpenResponsesError`, passing unrecognized errors through unchanged.

### OpenResponsesModel + OpenResponsesLanguageModel

Capability flag defaults, capability mapping to `LanguageModelCapabilities`, and auth mode → executor configuration wiring (including custom headers from `.proxied`).

### RequestBuilder

`RequestBuilder.build(from:model:)` — translates `LanguageModelExecutorGenerationRequest` into `ResponseRequest`. Covers all transcript entry types, generation options, capability-gated features (sampling, reasoning, structured output, tool definitions), and image encoding.

### EventTranslator

`EventTranslator.translate(_:into:)` — translates `AsyncThrowingStream<StreamEvent>` into `LanguageModelExecutorGenerationChannel` sends. Covers all handled stream event types, error propagation, and the zero-usage fallback for providers that omit `response.completed`.

## Test Framework

Swift Testing (`@Test`, `#expect`, `@Suite`). Not XCTest.

## Platform

macOS 27.0+ (deployment target). No `@available` annotations on test suites — the package's platform minimum handles availability.

## Acceptance Criteria

- [ ] All tests build with `swift build --build-tests`
- [ ] All tests pass with `swift test` on macOS Tahoe
- [ ] ErrorMapper: every documented LLMError → LanguageModelError mapping is covered, plus passthrough for unknown errors
- [ ] RequestBuilder: every Transcript.Entry type produces the correct InputItem (or is correctly skipped)
- [ ] RequestBuilder: capability flags gate sampling, reasoning, structured output, and tool strict mode
- [ ] RequestBuilder: GenerationOptions fields (temperature, sampling mode, max tokens, tool calling mode) are forwarded correctly
- [ ] EventTranslator: every handled StreamEvent produces the correct channel action
- [ ] EventTranslator: zero-usage fallback fires when stream ends without `responseCompleted`
- [ ] EventTranslator: error events throw the correct error types
- [ ] No live API calls or network dependencies
