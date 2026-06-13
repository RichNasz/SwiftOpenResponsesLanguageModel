# SwiftOpenResponsesLanguageModel — Tests WHY Spec

This document captures why the test suite is designed the way it is. If a future change to the test approach seems tempting, check here first.

---

## Why Test the Internal Components Directly

The three translation components — RequestBuilder, EventTranslator, ErrorMapper — are the package's entire value proposition. They sit at the boundary between two independently-defined protocol surfaces (FoundationModels and Open Responses). Testing them through `LanguageModelSession` would require a running inference server and would conflate session logic with translation logic. Direct testing isolates the translation contracts that this package is responsible for.

---

## Why Real FoundationModels Types Instead of Mocks

All key FoundationModels types (`Transcript`, `GenerationOptions`, `ContextOptions`, `LanguageModelExecutorGenerationRequest`, `LanguageModelExecutorGenerationChannel`) have public initializers that are constructible in tests. Testing against real types catches signature drift — if Apple changes an initializer or adds a required parameter, the test will fail at compile time. Mock types would silently diverge and miss these breaking changes.

The spike (Phase 1) empirically verified constructibility of every type needed for the test suite.

---

## Why Injectable Entry IDs in EventTranslator

`EventTranslator` accepts `responseEntryID` and `toolCallsEntryID` as constructor parameters with UUID defaults. Tests inject deterministic strings (`"resp-1"`, `"tc-1"`) so assertions on entry identity are stable across runs. This was a design decision made during implementation specifically to support testing — it's not incidental.

---

## Why No Image Encoding Tests

`cgImageToDataURI` requires constructing a `CGImage`, which depends on platform-specific graphics frameworks (CoreGraphics, ImageIO). A minimal test (1x1 pixel → verify `data:image/jpeg;base64,` prefix) is feasible but low-value: the encoding logic delegates entirely to ImageIO, and the only custom code is the quality parameter and base64 wrapping. The risk of regression is low compared to the translation logic.

If image encoding becomes a source of bugs, add a targeted test then — not preemptively.

---

## Why Capability-Gated Tests Are Paired

Each capability-gated feature (sampling, reasoning, structured output) has both an "enabled" test (verify the parameter is sent) and a "disabled" test (verify it's omitted). This paired structure guards against two distinct regressions:

1. A change that accidentally sends parameters for disabled capabilities (could cause API errors on providers that don't support them).
2. A change that accidentally stops sending parameters for enabled capabilities (would silently degrade functionality).

---

## Why ErrorMapper Tests Don't Assert on Error Descriptions

ErrorMapper tests verify the **type** of the mapped error (e.g., `is LanguageModelError`), not the specific description strings. The descriptions are informational and may change; the error type is the contract that callers pattern-match on. Testing descriptions would couple tests to wording that isn't part of the API surface.

---

## Why Integration Tests Exist Alongside Unit Tests

Unit tests on the three translation components verify that each boundary conversion is correct in isolation. But they can't catch issues that emerge from the full stack: HTTP serialization, SSE parsing, FoundationModels session orchestration, and the interaction between all three translators in sequence. Integration tests exercise the path that users actually take — `LanguageModelSession` → `OpenResponsesExecutor` → `LLMClient` → HTTP → response parsing — and catch problems that unit tests structurally cannot.

The integration tests are environment-gated (skip if no endpoint is configured) so they don't break CI or require infrastructure. They complement, not replace, the unit tests.

---

## Why Swift Testing Over XCTest

The existing project and its dependency (SwiftOpenResponsesDSL) both use Swift Testing. `@Test` and `#expect` are more concise than XCTest's `XCTAssert` family, and `@Suite` provides natural grouping. The test target already imports `Testing`.

---

## Why SourceKit Diagnostics Are Ignored

SourceKit (the IDE language service) shows false-positive "cannot find type" errors for `ContextOptions`, `LanguageModelExecutorGenerationRequest`, and `LanguageModelExecutorGenerationChannel` in test files. The actual compiler resolves these types correctly — builds succeed and tests run. This is a known SourceKit indexing issue with new framework types in beta SDKs. Tests should not be restructured to work around SourceKit limitations.

---

## Why a Separate Test Target for Integration Tests

Integration tests live in their own SPM test target (`IntegrationTests`) rather than alongside unit tests in `SwiftOpenResponsesLanguageModelTests`. This separation provides two benefits: (1) `swift test` runs unit tests without requiring endpoint configuration, and (2) integration tests can be run selectively with `--filter IntegrationTests`. Mixing them in one target would require every CI run and every developer to either configure endpoints or tolerate skip noise in the test output.

---

## Why Environment Variable Gating Instead of Conditional Compilation

Integration tests use runtime skip logic (`@Suite(.enabled(if:))`) rather than `#if` compile-time flags. Runtime skipping means the tests always compile — catching API drift even when no endpoint is available — and produce clear skip messages in the test runner output. Compile-time flags would silently exclude the code from the build, allowing it to rot undetected.

---

## Why Loose Content Assertions

Integration tests assert `response.content.contains("X")` rather than exact string equality. Different models produce different phrasing for the same prompt, and even the same model may vary across runs. Exact assertions would make tests brittle and provider-specific. The prompts are designed to elicit deterministic-ish answers (math problems, tool output echoing, explicit "reply with exactly" instructions) to minimize false failures while still validating that the adapter produced a meaningful response.

---

## Why Error Tests Use Unreachable URLs Instead of Invalid Credentials

Local LLM servers (LM Studio, Ollama) typically accept any API key and any model name without validation. Testing with invalid credentials or model IDs passes silently on these servers, producing a false-positive test result. Testing with an unreachable URL (`localhost:1`) or an invalid endpoint path reliably produces errors regardless of the provider, making the tests provider-agnostic.

---

## Why Tool-With-Arguments Is Gated on Structured Output

The `toolCallWithArguments` test requires the model to produce JSON arguments that match the `@Generable` schema exactly — including correct property names. Models without structured output support frequently emit malformed or missing properties, causing `GeneratedContent does not contain a property` errors. Gating on `supportsStructuredOutput` prevents false failures on models that handle tool calling (function name + basic args) but not schema-strict argument generation.

---

## Why Public API Only (No @testable import)

Integration tests use `import SwiftOpenResponsesLanguageModel` without `@testable`. They exercise the same API surface that library consumers use — `OpenResponsesLanguageModel`, `OpenResponsesModel`, `AuthMode`, and `LanguageModelSession`. This ensures the public API is sufficient for all intended use cases. If an integration test needs `@testable` access, that's a signal that the public API is missing something.
