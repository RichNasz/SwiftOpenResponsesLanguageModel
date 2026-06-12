# SwiftOpenResponsesLanguageModel — WHY Spec

This document captures **why** design decisions were made. It preserves intent and guards against regressions — if a future change seems tempting, check here first.

---

## Why the Adapter Architecture

The package's sole job is bridging two independently-defined protocol surfaces: Apple's `LanguageModel`/`LanguageModelExecutor` (from FoundationModels) and `LLMClient`/`ResponseRequest`/`StreamEvent` (from SwiftOpenResponsesDSL). Keeping the bridge thin — no business logic, no caching, no conversation management — means both upstream packages can evolve independently. When FoundationModels adds a new transcript entry type or SwiftOpenResponsesDSL changes its streaming API, only the relevant translation file needs updating.

The adapter is complete at the boundary: `RequestBuilder` converts everything going in, `EventTranslator` converts everything coming out, and `ErrorMapper` normalizes errors. None of the upstream types leak through the public API.

---

## Why Sendable Everywhere

All public types (`OpenResponsesLanguageModel`, `OpenResponsesModel`, `AuthMode`, `OpenResponsesExecutor.Configuration`) conform to `Sendable`. This ensures callers can compose them across actors in Swift 6 strict concurrency without annotation noise at the call site. FoundationModels itself requires `Sendable` conformance on executor types; extending it to all public types proactively prevents propagation problems when types are stored in `@Observable` classes or passed across actor boundaries.

---

## Why Model-Level Capability Flags

Capability flags live on `OpenResponsesModel`, not on individual requests. This design serves two purposes:

1. **RequestBuilder simplicity** — the builder reads flags once and makes conditional decisions without per-request introspection or runtime API probing.
2. **Framework-level gating** — FoundationModels reads `LanguageModelCapabilities` from the `LanguageModel` instance and can disable session features (e.g., tool registration) before a request is ever made. This means the app UI can reflect the model's limits without firing a request.

The tradeoff is that capability flags must be declared manually per model. This is intentional: the alternative (auto-detection via a probe request) would add latency, require error handling at init time, and be unreliable for models that report capabilities inaccurately. Manual flags are a one-time cost that prevents silent feature misapplication at runtime. For example, a reasoning model that rejects sampling parameters must have `samplingParams: false` — the `RequestBuilder` will then omit temperature and top-p unconditionally, avoiding an API error the caller would otherwise have to handle.

---

## Why Two-Layer Error Mapping

The error chain is: `LLMError` (SwiftOpenResponsesDSL) → `OpenResponsesError` (intermediate) → `LanguageModelError` (FoundationModels).

The intermediate `OpenResponsesError` type preserves detail that `LanguageModelError` can't carry — specifically, the error `code` and `message` strings from the API response. An app that needs to display provider-specific error context (e.g., "invalid_api_key" vs "model_not_found") can catch `OpenResponsesError.apiError` before it reaches the framework's generic error type. Meanwhile, the framework-standard `LanguageModelError` cases allow FoundationModels to handle errors uniformly across providers.

Not all `LLMError` cases are mapped — unrecognized errors are passed through unchanged. This is intentional: silent swallowing of unknown errors would make debugging harder.

---

## Why UUID Entry IDs

FoundationModels tracks transcript entries by ID across a session. Generating fresh UUIDs per `respond()` call ensures:
1. No ID collisions between consecutive calls in a long session.
2. Test code can inject deterministic IDs by constructing `EventTranslator(responseEntryID: "fixed", toolCallsEntryID: "fixed")`, making assertions on entry IDs stable.

Using the same IDs across calls would risk the framework treating a new response as an update to a prior one.

---

## Why Stream Resilience (Zero-Usage Fallback)

Some local LLM server implementations (e.g., servers built on Ollama) never emit `response.completed` — the SSE stream simply ends. FoundationModels requires a usage update event to finalize a generation; without it, the channel would stall waiting for data that never arrives.

The `sentCompletion` flag in `EventTranslator` detects this condition and sends a zero-usage update after the stream ends. Zero token counts are a minor inaccuracy that is far preferable to a hung session.

The comment in the source code names the affected category of server explicitly, so future maintainers understand this is not dead code.

---

## Why Proxied Auth Mode

Enterprise deployments and development environments often sit behind authenticating reverse proxies — API gateways, internal auth layers, mutual TLS termination — that inject authorization before traffic reaches the inference server. In these environments, the client itself should not add an `Authorization` header (it may conflict with the proxy's auth scheme, or the proxy may sign the entire request).

`AuthMode.proxied` signals this intent: the LLMClient is initialized with an empty API key, leaving the Authorization header absent. The `headers` dictionary in `.proxied(headers:)` is forwarded as `customHeaders` to `LLMClient`, which sets them on every outgoing request. This allows proxy environments to inject required headers (e.g., `X-Forwarded-User`, internal routing tokens) without conflicting with the standard Authorization flow. For `.apiKey` mode, no custom headers are sent.

---

## Why Image Attachments Are JPEG-Encoded to Data URIs

FoundationModels provides image attachments as `CGImage` instances (or file URLs). The Open Responses `input_image` content part accepts `image_url` as a flat string — either a remote URL or a base64 data URI.

Remote URLs are passed through directly (no encoding needed). For in-memory images (`CGImage` from PhotosPicker, camera, or programmatic sources), the builder JPEG-encodes via ImageIO's `CGImageDestination` and base64-encodes the result into a `data:image/jpeg;base64,...` URI.

**Why JPEG at 0.8 quality** — balances image fidelity against payload size. Vision models are robust to JPEG compression artifacts, and base64 encoding inflates size by ~33%, so keeping the source compact matters for request latency and provider input limits (the Open Responses spec caps `image_url` at 20 MiB).

**Why ImageIO instead of UIImage** — `CGImageDestination` is available on all target platforms (macOS, iOS, visionOS, watchOS). `UIImage.jpegData` is UIKit-only and unavailable on macOS or watchOS.

**Why `nil` on encoding failure** — a failed image encode silently drops the attachment rather than aborting the entire request. The remaining text content is still valid and the model can respond to it. This matches the existing pattern where `.custom` segments are silently skipped.

---

## Why the "lm-studio" API Key Default

When an `.apiKey("")` is passed with an empty string, the executor substitutes `"lm-studio"` as the API key value. LM Studio (a popular local LLM server) requires a non-empty string in the Authorization header but ignores the value. Using `"lm-studio"` as the sentinel allows users to connect to LM Studio by passing an empty string — a natural choice for a server with no real authentication — without requiring them to know LM Studio's convention.

This is a convenience trade-off: it makes the common LM Studio case work transparently at the cost of a minor magic constant in the init.
