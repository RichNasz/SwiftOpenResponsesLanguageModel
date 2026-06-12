# Design Philosophy

This document explains the thinking behind SwiftOpenResponsesLanguageModel — the problems it solves, the tradeoffs it makes, and the principles that guide its design.

## The Provider Problem

LLM apps today couple tightly to specific providers. An app built on the OpenAI SDK speaks OpenAI's request format, handles OpenAI's streaming events, and catches OpenAI's error types. Switching to Anthropic, Google, or a local model means rewriting networking, authentication, streaming, error handling, and tool calling — even though the app's intent hasn't changed.

Apple's FoundationModels framework addresses the app side of this problem. `LanguageModelSession` provides a unified Swift API for prompts, streaming, tools, structured output, and reasoning. But the framework needs providers behind it. Without third-party `LanguageModel` implementations, apps are limited to Apple's on-device model.

SwiftOpenResponsesLanguageModel fills that gap: it implements `LanguageModel` by speaking Open Responses on the wire, so any compatible endpoint becomes a provider that FoundationModels can use.

## Standards Over SDKs

A natural approach would be to build provider-specific adapters — one for OpenAI, one for Anthropic, one for Ollama. Each adapter would translate between FoundationModels and that provider's API. This works, but it scales linearly: every new provider needs a new adapter, and every adapter is a maintenance surface.

This project takes a different approach: target a *specification* rather than a provider. The [Open Responses API](https://www.openresponses.org/) defines a standard inference endpoint — request format, streaming protocol, tool calling convention, error shape. Any provider that implements the spec works automatically. New providers don't require new code.

The tradeoff is indirection. A provider must either implement the Open Responses spec natively or sit behind a proxy that translates. In practice, many providers already support Open Responses-compatible endpoints, and local servers like LM Studio and Ollama expose them directly.

## The Thin Adapter Principle

The package has no business logic. No caching. No conversation management. No retry logic. No rate limiting. No token counting. Its sole job is translating between two independently-defined protocol surfaces:

- **Inbound:** `RequestBuilder` converts FoundationModels' `LanguageModelExecutorGenerationRequest` (transcript entries, generation options, tool definitions) into an Open Responses `ResponseRequest`.
- **Outbound:** `EventTranslator` converts Open Responses' `AsyncThrowingStream<StreamEvent>` into FoundationModels' `LanguageModelExecutorGenerationChannel` actions.
- **Errors:** `ErrorMapper` normalizes `LLMError` from the HTTP layer into `LanguageModelError` for the framework, with an intermediate `OpenResponsesError` layer preserving provider-specific detail.

Why thin? Because the adapter sits between two systems that evolve independently. When FoundationModels adds a new transcript entry type, only `RequestBuilder` needs updating. When the Open Responses spec adds a new streaming event, only `EventTranslator` changes. No business logic means no opinions that conflict with either upstream. The adapter is a pure translation layer — it converts faithfully and gets out of the way.

None of the upstream types leak through the public API. The boundary is complete.

## Capability Flags: Explicit Over Implicit

Every `OpenResponsesModel` declares its capabilities at init time — whether it supports sampling parameters, reasoning, structured output, image input, and tool calling. These flags gate request construction: if `reasoning: false`, reasoning effort is never sent, even if generation options request it.

The alternative would be auto-detection — probe the provider's model endpoint at init time and discover capabilities dynamically. This was rejected for three reasons:

1. **Latency.** A probe request at init adds network round-trip time before the first real request.
2. **Reliability.** Models report capabilities inconsistently. Some claim support for features they handle poorly. Others expose capabilities through non-standard endpoints.
3. **Silent misapplication.** Auto-detected flags that are wrong lead to requests with parameters the model can't handle — and the errors surface at response time, far from the init where the misconfiguration happened.

Manual declaration is a one-time cost per model. In exchange, capability mismatches surface immediately and deterministically. A model that rejects sampling parameters has `samplingParams: false`, and `RequestBuilder` omits temperature and topP unconditionally — no API error the caller has to handle.

## Error Transparency

The error chain has three layers: `LLMError` (SwiftOpenResponsesDSL) → `OpenResponsesError` (this package) → `LanguageModelError` (FoundationModels).

The intermediate `OpenResponsesError` layer exists because `LanguageModelError` can't carry provider-specific detail. An error code like `"invalid_api_key"` or `"model_not_found"` matters for debugging but has no representation in the framework's generic error type. `OpenResponsesError.apiError(code:message:)` preserves this context.

Apps that don't need provider-specific diagnostics get framework-standard error handling for free — rate limiting maps to `LanguageModelError.rateLimited`, context overflow maps to `LanguageModelError.contextSizeExceeded`. Apps that do need the detail can catch `OpenResponsesError` before it reaches the framework layer.

Unrecognized errors pass through unmapped. Silent swallowing would make debugging harder; explicit passthrough means no error is ever hidden.

## Local-First Flexibility

The library meets providers where they are, not where a specification says they should be.

**LM Studio convention.** `.apiKey("")` substitutes `"lm-studio"` as the API key. LM Studio requires a non-empty Authorization header but ignores the value. An empty string is the natural choice for a server with no real authentication, and the sentinel makes it work transparently.

**Enterprise proxies.** `.proxied(headers:)` supports environments behind authenticating reverse proxies — API gateways, internal auth layers, mutual TLS termination. The client sends no `Authorization` header (avoiding conflicts with the proxy's auth scheme) and forwards custom headers on every request.

**Stream resilience.** Some local LLM servers (particularly Ollama-based implementations) never emit `response.completed` — the SSE stream simply ends. FoundationModels requires a usage update to finalize a generation; without it, the session stalls. The `EventTranslator` detects this condition and sends a zero-usage fallback after the stream ends. Zero token counts are a minor inaccuracy that is far preferable to a hung session.

These accommodations are pragmatic, not principled. The Open Responses spec defines the ideal; reality includes servers that don't fully implement it. The library bridges both.
