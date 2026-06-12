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

## Why No LanguageModelSession Integration Tests

`LanguageModelSession` orchestrates tool calling, conversation management, and response streaming. Testing through it would require either a live inference server or a mock HTTP layer, and would test FoundationModels' session logic alongside our translation logic. Unit tests on the three components give higher confidence with lower complexity. Integration testing is deferred to the example app and manual validation against real endpoints.

---

## Why Swift Testing Over XCTest

The existing project and its dependency (SwiftOpenResponsesDSL) both use Swift Testing. `@Test` and `#expect` are more concise than XCTest's `XCTAssert` family, and `@Suite` provides natural grouping. The test target already imports `Testing`.

---

## Why SourceKit Diagnostics Are Ignored

SourceKit (the IDE language service) shows false-positive "cannot find type" errors for `ContextOptions`, `LanguageModelExecutorGenerationRequest`, and `LanguageModelExecutorGenerationChannel` in test files. The actual compiler resolves these types correctly — builds succeed and tests run. This is a known SourceKit indexing issue with new framework types in beta SDKs. Tests should not be restructured to work around SourceKit limitations.
