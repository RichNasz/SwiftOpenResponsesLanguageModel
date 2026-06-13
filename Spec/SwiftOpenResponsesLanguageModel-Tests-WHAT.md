# SwiftOpenResponsesLanguageModel — Tests WHAT Spec

## Scope

Two test suites covering the adapter at different levels:

1. **Unit tests** — test the three internal translation components (RequestBuilder, EventTranslator, ErrorMapper) in isolation with no network calls.
2. **Integration tests** — exercise the full stack through `LanguageModelSession` against a real Open Responses endpoint. Require a running inference server configured via environment variables.

## Unit Test Components

### ErrorMapper

`ErrorMapper.map(_:)` — normalizes `LLMError` into `LanguageModelError` or `OpenResponsesError`, passing unrecognized errors through unchanged.

### OpenResponsesModel + OpenResponsesLanguageModel

Capability flag defaults, capability mapping to `LanguageModelCapabilities`, and auth mode → executor configuration wiring (including custom headers from `.proxied`).

### RequestBuilder

`RequestBuilder.build(from:model:)` — translates `LanguageModelExecutorGenerationRequest` into `ResponseRequest`. Covers all transcript entry types, generation options, capability-gated features (sampling, reasoning, structured output, tool definitions), and image encoding.

### EventTranslator

`EventTranslator.translate(_:into:)` — translates `AsyncThrowingStream<StreamEvent>` into `LanguageModelExecutorGenerationChannel` sends. Covers all handled stream event types, error propagation, and the zero-usage fallback for providers that omit `response.completed`.

## Integration Test Components

### Basic Generation

End-to-end text generation through `LanguageModelSession`: single prompt, streaming, stream collect, multi-turn conversation, and system instructions.

### Tool Calling

Tool definition via FoundationModels `Tool` protocol with `@Generable` arguments, tool call round-trip through the adapter, and tool argument decoding.

### Structured Output

`@Generable` struct decoding via `session.respond(to:generating:)` with the `structuredOutput` capability flag enabled.

### Reasoning

Reasoning mode via `ContextOptions(reasoningLevel:)` with a reasoning-capable model, both non-streaming and streaming.

### Error Handling

Error propagation for unreachable endpoints and invalid endpoint paths.

## Test Framework

Swift Testing (`@Test`, `#expect`, `@Suite`). Not XCTest.

## Platform

macOS 27.0+ (deployment target). No `@available` annotations on test suites — the package's platform minimum handles availability.

## Acceptance Criteria

### Unit Tests

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

### Integration Tests

- [ ] All integration tests build alongside unit tests
- [ ] Without environment variables set, all integration tests skip with descriptive messages
- [ ] With a valid endpoint, basic generation tests pass (text gen, streaming, multi-turn, instructions)
- [ ] Tool calling round-trip works with zero-argument tools
- [ ] Tool calling with structured arguments works on models that support structured output
- [ ] Structured output decodes `@Generable` types correctly on capable models
- [ ] Reasoning mode produces responses with reasoning-capable models
- [ ] Error handling tests detect unreachable endpoints and invalid paths
- [ ] Tests use loose content assertions (contains-checks) to accommodate model variation
