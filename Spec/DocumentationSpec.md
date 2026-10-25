---
status: draft
---

# SwiftOpenResponsesLanguageModel Documentation Design

**Date:** 2026-06-12
**Status:** Draft
**Audience:** Developers using FoundationModels who want to connect to non-Apple providers; AI coding tools (AGENTS.md)

## Goal

Create a lean documentation suite for a project that currently has no README, CLAUDE.md, or AGENTS.md. The library is a thin adapter (4 public types, ~450 lines of implementation), and the documentation should be proportional — five files totaling under 450 lines. A single getting-started guide provides progressive depth from basic streaming through advanced features.

## Principles

1. **Proportionality** — 4 public types. One getting-started guide covers the full progression — no multiple topic guides, no DocC catalog, no agent skills.
2. **Substitutability as the story** — The README's code example shows the FoundationModels baseline (on-device) alongside the OpenResponsesLanguageModel alternative (remote provider). The user sees that only the model passed to `LanguageModelSession` changes.
3. **Progressive disclosure** — README shows install + one example. The getting-started guide builds from basic streaming through auth, capabilities, tool calling, structured output, image input, and reasoning. Each section builds on the previous one.
4. **Two audiences** — Humans read README and the guide; AI tools read AGENTS.md; contributors read CLAUDE.md. No content is duplicated across files.
5. **Examples already exist** — The project has three example apps (iOS, macOS, visionOS). The guide references them but doesn't reproduce full app code.

---

## 1. README.md

**Purpose:** Landing page. Gets the reader from zero to first streaming response in under 60 seconds of reading.

**Target length:** ~80 lines.

**Structure:**

### Badge Row

Five badges on the first line after the H1 title, in this order: Swift 6.2+, Platform (macOS 27 | iOS 27 | visionOS 27 | watchOS 27), License (Apache 2.0), Version, Built with Grok Build.

The Grok Build badge links to `https://github.com/xai-org/grok-build`. Shields.io has no Grok logo, so the badge is text-only: `https://img.shields.io/badge/Built%20with-Grok%20Build-111111`.

No "Built with Claude Code" badge. That badge reads as the current toolchain.

### One-Sentence Description

Must convey: Swift package providing a `LanguageModel` implementation that connects Apple's FoundationModels to any Open Responses specification endpoint. Must use "drop-in" or "swap" language to convey substitutability.

Immediately under that description, one sentence: this project was started with Claude Code. All project-related work now uses Grok Build and the latest Grok model available. Link Grok Build to `https://github.com/xai-org/grok-build`. Claude Code history stays in that sentence. It does not appear in the badge row.

### Why Section

~15-20 lines introducing the project's philosophy focused on **provider freedom**:
- FoundationModels gives Swift a unified session API, but the on-device model is one provider among many
- The problem: provider lock-in forces app rewrites when switching providers
- The solution: target a specification (Open Responses), not a provider — any compatible endpoint works automatically
- The bridge is intentionally thin — three translation layers, no business logic
- Link to `docs/philosophy.md` for the full design philosophy

### The Substitutability Story

This is the README's core section. Two paired code blocks:

1. **"With on-device model"** — `LanguageModelSession()` with Apple's default on-device model, streaming a response and printing output.
2. **"With any Open Responses provider"** — Identical code except the session is constructed with `LanguageModelSession(model: lm)` where `lm` is an `OpenResponsesLanguageModel`.

The prompt, stream iteration, and print statements must be identical in both blocks. This visually demonstrates that only the session init changes.

### Installation

- SPM `Package.swift` dependency snippet (`.package(url:from:)`)
- Target dependency snippet
- Note: requires macOS 27+ / iOS 27+ / visionOS 27+ / watchOS 27+ (Xcode 27+)

### API Overview

Table of the 4 public types with one-line descriptions:

| Type | Purpose |
|------|---------|
| `OpenResponsesLanguageModel` | `LanguageModel` conformance — pass to `LanguageModelSession` |
| `OpenResponsesModel` | Model identity + capability flags |
| `AuthMode` | `.apiKey(String)` or `.proxied(headers:)` |
| `OpenResponsesError` | Provider-specific error cases |

Link to `Spec/SwiftOpenResponsesLanguageModel-WHAT.md` for full API details.

### Capability Flags

Table mapping `OpenResponsesModel.Capabilities` flags to what they enable:

| Flag | Default | Enables |
|------|---------|---------|
| `samplingParams` | `true` | Temperature, topP, sampling mode sent in requests |
| `reasoning` | `false` | Extended thinking / reasoning effort |
| `structuredOutput` | `false` | JSON schema-constrained output |
| `imageInput` | `false` | Image attachments in prompts |
| `toolCalling` | `true` | Function calling / tool use |

### Next Steps

Link to `docs/getting-started.md` for the full progression from basic streaming through advanced features. Link to example apps in `Examples/` for complete app implementations.

### For AI Coding Tools

One line linking to `AGENTS.md`.

### License

One line with link to LICENSE file.

### Constraints

- README is a landing page — feature details live in the getting-started guide
- No inline API documentation — the WHAT spec serves as the detailed reference
- Tone: direct and practical, no marketing language

---

## 2. docs/getting-started.md

**Purpose:** Single guide that takes the reader from first streaming response through every feature the library supports. Progresses from easy to difficult — each section builds on the previous one.

**Target length:** ~120-150 lines.

**Structure:**

### 1. Basic Streaming

The simplest possible usage. Construct an `OpenResponsesModel` with default capabilities, create an `OpenResponsesLanguageModel` with `.apiKey` auth, pass to `LanguageModelSession`, and stream a response.

Must include: complete code block, brief explanation of what each line does.

### 2. Auth Modes

Two patterns for authentication:

- **API Key** — `.apiKey("sk-...")` for providers like OpenAI, Anthropic, or any endpoint requiring a Bearer token. Note the LM Studio convenience: `.apiKey("")` substitutes `"lm-studio"` automatically.
- **Proxied** — `.proxied(headers: [...])` for enterprise/proxy setups where auth is handled upstream. Explain when to use this (corporate proxies, mutual TLS termination, API gateways).

### 3. Configuring Capability Flags

Explain what capability flags do and why they matter. Show how to construct `OpenResponsesModel.Capabilities` with specific flags enabled. Include the capability flags table (same as README) and explain the consequence of misconfiguration: flags gate request construction, so a missing flag means the feature is silently omitted from requests.

### 4. Tool Calling

Show how to define a tool using `@LLMTool` and use it with `LanguageModelSession`. Must demonstrate:
- Tool definition with the macro
- Passing tools to the session
- The model calling the tool and the session executing it

Reference the visionOS examples app `ToolCallingView.swift` for a complete app implementation.

### 5. Structured Output

Show how to use `@Generable` to get typed, schema-constrained output from a model with `structuredOutput: true`. Must demonstrate:
- Defining a `@Generable` struct
- Using `session.respond(to:generating:)` to get typed output
- The role of the `structuredOutput` capability flag

Reference `StructuredOutputView.swift` for a complete example.

### 6. Image Input

Show how to send image attachments in prompts for models with `imageInput: true`. Must demonstrate:
- Creating an image attachment
- Passing it to the session prompt
- The image being encoded as a base64 JPEG data URI under the hood

Reference `ImageInputView.swift` for a complete example.

### 7. Reasoning

Show how to enable extended thinking for models with `reasoning: true`. Must demonstrate:
- Setting the `reasoning` capability flag
- Using reasoning effort in generation options
- Accessing the model's reasoning output

Reference `ReasoningView.swift` for a complete example.

### 8. Limits

After reasoning. Two or three sentences: the adapter does not invent values for FoundationModels features the wire protocol or its dependencies cannot carry. Link to the Not available section of `AGENTS.md` for the list. Do not repeat the table.

### Constraints

- Each section must include at least one complete, compilable code block, except Limits, which is a pointer and has no code
- Each section builds on the previous — later sections can reference concepts from earlier ones without re-explaining
- No more than 2-3 sentences of explanation per code block — let the code speak
- Link to specific example app files for complete app implementations rather than reproducing full app code
- The guide covers only FoundationModels API usage (sessions, prompts, streaming) — it does not explain SwiftUI or app architecture

---

## 3. docs/philosophy.md

**Purpose:** Deep-dive article exploring the project's design philosophy for an external audience. Draws from the WHY spec but reframed from contributor-facing rationale to user-facing narrative.

**Target length:** ~80-120 lines.

**Structure:**

### 1. The Provider Problem
LLM apps couple to provider-specific APIs. Switching providers means rewriting networking, auth, streaming, error handling. FoundationModels solves the app side; this package fills the provider side.

### 2. Standards Over SDKs
Target a specification (Open Responses) rather than building per-provider adapters. New providers work automatically. Tradeoff: providers must implement the spec or sit behind a proxy.

### 3. The Thin Adapter Principle
No business logic, no caching, no opinions. Three translation layers (RequestBuilder, EventTranslator, ErrorMapper). Why thin matters: fewer opinions means fewer conflicts with either upstream.

### 4. Capability Flags: Explicit Over Implicit
Manual declaration over auto-detection. Why: avoids latency, unreliable model reporting, and silent feature misapplication. One-time cost per model prevents runtime surprises.

### 5. Error Transparency
Two-layer mapping preserves provider-specific detail while conforming to framework-standard errors. Unrecognized errors pass through unmapped.

### 6. Local-First Flexibility
LM Studio convention, proxied auth for enterprise, stream resilience for servers that don't emit `response.completed`. The library meets providers where they are.

### Constraints

- Written for external audiences — not contributor-facing like the WHY spec
- Must be accurate against the WHY spec but use accessible language
- No code blocks — this is a philosophy article, not a usage guide

---

## 4. CLAUDE.md

**Purpose:** AI contributor's entry point to the codebase. Orients the reader to navigate the project and generate correct code.

**Target length:** ~60-70 lines.

**Structure:**

### Maintenance

One sentence at the top, before Project Overview: this project was started with Claude Code. All project-related work uses Grok Build and the latest Grok model available. Do not describe Claude Code as the current toolchain. The same sentence is in `AGENTS.md` so a session that loads either file follows it.

### Project Overview

One paragraph: what the package does, its relationship to FoundationModels and SwiftOpenResponsesDSL. Package name, platforms, Swift version.

### Commands

- `swift build` / `swift test`
- Tests require macOS 27+ (Tahoe) with Xcode 27+

### Architecture

The adapter pattern in one sentence per component:
- `RequestBuilder` — converts FoundationModels `LanguageModelExecutorGenerationRequest` to Open Responses `ResponseRequest`
- `EventTranslator` — converts Open Responses `AsyncThrowingStream<StreamEvent>` to FoundationModels `LanguageModelExecutorGenerationChannel` actions
- `ErrorMapper` — maps `LLMError` to `LanguageModelError` with an intermediate `OpenResponsesError` layer

Key decision: capability flags are declared per-model at init time, not auto-detected.

### File Map

| File | Purpose |
|------|---------|
| `OpenResponsesLanguageModel.swift` | `LanguageModel` conformance, capability mapping |
| `OpenResponsesModel.swift` | Model identity + `Capabilities` flags |
| `OpenResponsesExecutor.swift` | `LanguageModelExecutor` conformance, `LLMClient` init |
| `RequestBuilder.swift` | Transcript-to-`ResponseRequest` translation |
| `EventTranslator.swift` | Stream event-to-channel action translation |
| `ErrorMapper.swift` | Error mapping + `OpenResponsesError` definition |
| `AuthMode.swift` | `.apiKey` / `.proxied` enum |

### Dependencies

- **SwiftOpenResponsesDSL** — provides `LLMClient`, `ResponseRequest`, `StreamEvent`, streaming protocol
- **SwiftLLMToolMacros** (transitive) — provides `JSONSchema` types for tool definitions

Point at the Limits section below before adding a FoundationModels behavior this package does not already translate. That section names which dependency has to change. Do not repeat the table here.

### Spec Files

| File | Covers |
|------|--------|
| `SwiftOpenResponsesLanguageModel-WHAT.md` | Public API surface + acceptance criteria |
| `SwiftOpenResponsesLanguageModel-HOW.md` | Implementation details |
| `SwiftOpenResponsesLanguageModel-WHY.md` | Design rationale |
| `SwiftOpenResponsesLanguageModel-Tests-WHAT/HOW/WHY.md` | Test strategy + implementation |

Directive: "Consult Spec/ files for detailed design decisions."

### Testing Strategy

Two test targets:
- Unit tests (4 suites) — no live API calls, test translation components in isolation
- Integration tests (5 suites) — end-to-end through `LanguageModelSession` against a live endpoint, gated on environment variables
- Swift Testing framework (`@Test`, `#expect`, `@Suite`) for both targets
- Environment variables: `OPEN_RESPONSES_BASE_URL`, `OPEN_RESPONSES_API_KEY`, plus optional capability flags

### Constraints

- Must not duplicate WHAT/HOW/WHY spec content — its job is to orient, not to be a reference
- Must point to Spec/ for implementation details

---

## 5. AGENTS.md

**Purpose:** Machine-readable patterns and pitfalls for AI coding tools consuming this library (not contributing to it).

**Target length:** ~140-170 lines.

**Format:** Each topic section follows Pattern/Pitfalls structure.

**Structure:**

### Maintenance

First section, before Installation. State that Claude Code created this project initially, and that all project-related work — maintenance and expansion — uses Grok Build. When a model is required, use the latest Grok model available. Do not treat Claude Code as the current toolchain. This is the session rule. The README badge row shows Grok Build only; the Claude Code history stays in prose.

### Installation

SPM dependency snippets for both `Package.swift` and Xcode GUI workflows. Pitfalls covering platform requirements (macOS 27+ / iOS 27+ / visionOS 27+ / watchOS 27+, Xcode 27+), Swift tools version (6.2+), and transitive dependencies (SwiftOpenResponsesDSL pulled in automatically).

The `Package.swift` snippet must use the canonical URL `https://github.com/RichNasz/SwiftOpenResponsesLanguageModel.git` and show both the `.package(url:from:)` dependency and the `.product(name:package:)` target dependency.

### Project Overview

One paragraph: what the library does, package name, platforms, Swift version. List of the 4 public types.

### Basic Usage

**Pattern:** Complete code block showing `OpenResponsesModel` construction, `OpenResponsesLanguageModel` init, `LanguageModelSession(model:)`, and `session.streamResponse(to:)`.

**Pitfalls:**
- Capability flags must match the actual model's abilities — setting `reasoning: true` for a model that doesn't support it causes API errors
- `baseURL` must include the full path (e.g., `https://api.openai.com/v1/responses`), not just the host
- The `name:` parameter label in the init takes an `OpenResponsesModel`, not a string

### Auth Modes

**Pattern:** Two code blocks — `.apiKey("sk-...")` for direct API access, `.proxied(headers: ["X-Custom": "value"])` for proxy/enterprise setups.

**Pitfalls:**
- `.apiKey("")` (empty string) substitutes `"lm-studio"` as the key — use this for LM Studio connections
- `.proxied` sends no `Authorization` header; the proxy must handle auth
- `.apiKey` sends no custom headers; `.proxied` forwards the provided headers dictionary

### Capability Flags

**Pattern:** Code block showing `OpenResponsesModel(id:capabilities:)` with explicit capability flags.

**Pitfalls:**
- Flags gate request construction, not just feature availability — if `samplingParams: false`, temperature and topP are never sent even if set on generation options
- If `reasoning: false`, reasoning effort is never included in the request
- If `structuredOutput: false`, JSON schema output format is never applied
- Defaults: `samplingParams: true`, `reasoning: false`, `structuredOutput: false`, `imageInput: false`, `toolCalling: true`

### Error Handling

**Pattern:** Code block showing `do/catch` with `OpenResponsesError` cases.

**Pitfalls:**
- `OpenResponsesError.apiError(code:message:)` preserves the provider's error code and message — use for provider-specific diagnostics
- Some errors are mapped to `LanguageModelError` (rate limit, context size, timeout) for framework compatibility — catch both types for full coverage
- Unrecognized `LLMError` cases pass through unmapped

### Common Mistakes

Numbered list:
1. Forgetting to set capability flags for models that support reasoning/structured output — the features silently won't activate
2. Using this package without macOS 27+ / iOS 27+ — FoundationModels is only available on these platforms
3. Constructing `OpenResponsesLanguageModel` but not passing it to `LanguageModelSession` — the model does nothing on its own
4. Expecting on-device model behavior — remote providers have different latency, token limits, and error patterns

### Quick Reference

A single complete copy-pasteable code block showing the full happy path: model construction with all capability flags, `OpenResponsesLanguageModel` init, `LanguageModelSession(model:)`, and streaming. Every parameter has an inline comment explaining its purpose and default value.

Must use correct current API signatures:
- `OpenResponsesModel(id:capabilities:)` with `Capabilities(samplingParams:reasoning:structuredOutput:imageInput:toolCalling:)`
- `OpenResponsesLanguageModel(name:auth:baseURL:timeout:)` — note the `name:` label takes `OpenResponsesModel`
- `AuthMode.apiKey(_:)` or `AuthMode.proxied(headers:)`

### Not available

Required section, after Common Mistakes. It is the user-facing copy of the Limits table in this spec. For each row: the behavior a caller might expect, why this package does not provide it, and the Open Responses fact from the Where the limit is column. When that column names the API, say the limit is a characteristic of Open Responses and not a bug in SwiftOpenResponsesDSL. When it names the DSL, say the Open Responses spec already allows the behavior and the client has not implemented it. Do not add workarounds that invent server data. Do not duplicate the table in the getting-started guide.

### Constraints

- For consumers, not contributors (architecture details belong in CLAUDE.md)
- Every Pattern must be a compilable code block
- Every Pitfall must describe a concrete mistake and its consequence

---

## 6. CONTRIBUTING.md

**Purpose:** Tell potential contributors how this project works — specs are the source of truth, code is generated from specs, and the contribution path is GitHub Issues, not code PRs.

**Target length:** ~30-40 lines.

**Structure:**

### Opening

One-line thanks. State that contributions via GitHub Issues are welcome.

### Reporting Bugs

What to include in a bug report:
- What you expected to happen
- What actually happened
- Swift version and platform
- Minimal code snippet that reproduces the problem

### Requesting Features

Describe what you want and why — not how to implement it. The best feature requests focus on the problem to solve, not a specific solution.

### How Changes Are Made

This is the core section that distinguishes this project's contribution model. Must explain:

1. **Specs are the source of truth** — This project uses spec-driven development. The `Spec/` directory contains WHAT specs (desired behavior), HOW specs (implementation approach), and WHY specs (design rationale). Code is generated from these specs.
2. **Issues drive changes** — All changes start as a GitHub Issue (bug report or feature request). Issues are resolved in Grok Build with the latest Grok model. The project was started with Claude Code. Claude Code is not the current toolchain.
3. **The workflow** — Issue raised → AI agent analyzes the issue against existing specs → specs are updated to reflect the change → code is generated from the updated specs → tests verify the implementation.
4. **Why no code PRs** — Unsolicited code PRs skip the spec step and cannot be accepted. The specs must be updated first so that design decisions are captured and code can be regenerated consistently. Feature ideas raised via issues may be implemented in a future release when they align with the project's direction.

Must link to the `Spec/` directory so contributors can see how specs are structured.

### Constraints

- Tone: welcoming but clear about the process — not apologetic about rejecting PRs
- Frame it as "this is how the project works," not "sorry we can't accept your code"
- Must be concise — the CONTRIBUTING.md itself should be under 40 lines
- No conventional commits section, no PR template — those don't apply when code PRs aren't accepted

---

## 7. Source Doc Comment Convention

**Purpose:** Ensure all public symbols carry `///` documentation comments so DocC, Xcode Quick Help, and AI coding tools can surface API docs inline.

**Scope:** Every `public` type, initializer, property, enum case, and method in `Sources/`. Internal types are not documented.

**Rules:**

1. **Summary line** — First line is a single sentence describing the symbol.
2. **Markup tags** — Use `- Parameters:`, `- Returns:`, `- Throws:` for initializers and methods with multiple inputs or notable error behavior.
3. **Important callouts** — Use `- Important:` for pitfalls (surprising parameter labels, silent behavior when flags are off, empty-string conventions).
4. **Default values** — State default values explicitly in parameter docs (e.g., "Default: `true`").
5. **Code examples** — Add one inline code example on the main entry-point type only (`OpenResponsesLanguageModel`). Other types get summary + parameter docs only.
6. **Length proportionality** — 1–2 lines for properties and enum cases, 3–5 lines for type summaries, 5–10 lines for multi-parameter initializers.
7. **No internal docs** — Only document `public` API that package consumers see. `RequestBuilder`, `EventTranslator`, and `ErrorMapper` (the `enum`, not `OpenResponsesError`) are internal and undocumented.

**Example:**

```swift
/// Authentication strategy for connecting to an Open Responses endpoint.
///
/// - Important: With ``apiKey(_:)``, no custom headers are sent.
///   With ``proxied(headers:)``, no `Authorization` header is sent.
public enum AuthMode: Sendable, Hashable {
    /// Authenticate with a Bearer token sent in the `Authorization` header.
    ///
    /// - Parameter apiKey: The API key string. Pass an empty string (`""`) for LM Studio,
    ///   which substitutes `"lm-studio"` automatically.
    case apiKey(String)
}
```

---

## 8. Limits

**Purpose:** One inventory of FoundationModels behavior this package does not provide. Generated docs take their wording from this section. `Spec/SwiftOpenResponsesLanguageModel-HOW.md` follows it and must not grow a second list.

**Where it is published:**

- `AGENTS.md` section "Not available" carries every row, in the order below, for people and for AI tools using the package.
- `docs/getting-started.md` section "Limits" is a short pointer to that section. It does not repeat the rows.
- `CLAUDE.md` tells contributors to read this section before translating a new Apple API, and does not repeat the rows.

**Rules for every row:**

- Say what the caller does not get.
- Say why this package leaves it unimplemented. "Not implemented" without a reason is not enough.
- Name where the limit lives. A dependency on SwiftOpenResponsesDSL is also a dependency on the Open Responses API. The site is <https://www.openresponses.org/>. The normative spec for this inventory is <https://www.openresponses.org/specification>, OpenAPI `info.version` `2026-04-24` at <https://www.openresponses.org/openapi/openapi.json>.
- If that spec does not define the behavior, the row says so and calls it a characteristic of the Open Responses API. Do not describe that absence as a SwiftOpenResponsesDSL bug, and do not ask the DSL to add a field the spec does not have.
- If that spec defines the behavior and the DSL does not implement it, the row says the API allows it and names the DSL type that is missing. The DSL is the code gap. The API is not.
- "This package" means the spec and the DSL already allow the behavior and this adapter chooses not to send it, or can change its own code.
- Do not promise a fix inside this package for a row whose next change is another package, the Open Responses spec, or a future Apple SDK.

Checked against that OpenAPI file, SwiftOpenResponsesDSL `Spec/Unimplemented.md`, `ResponseRequest` / `LLMError`, and `LLMClient.prewarm()` at revision `6e19d76`, `JSONSchemaValue` in SwiftLLMToolMacros, and the FoundationModels swiftinterface shipped with Xcode 27.1.

| Gap | Why it stays unimplemented | Where the limit is |
|---|---|---|
| Replaying `Transcript.Entry.reasoning` and its signature on a later turn | The entry is skipped. Rejecting it as unsupported transcript content would fail multi-turn reasoning sessions that already work. The signature stored on the way out is not sent back. | **Open Responses allows this.** `ItemParam` includes `ReasoningItemParam` (`id`, `type`, `summary`, `content`, `encrypted_content`). Items are defined as bidirectional. **SwiftOpenResponsesDSL does not.** `ReasoningItem` is decode-only, and `InputItem` has no reasoning case. That package's `Spec/Unimplemented.md` names it under "Reasoning item as input". After the DSL can encode the item, this package sends the signature it already stored. |
| `SamplingMode.randomTopK` and sampling seeds | `.randomProbabilityThreshold` sets `top_p` and drops the seed. `.randomTopK` is ignored. | **Characteristic of the Open Responses API.** `CreateResponseBody` has `temperature` and `top_p`. The 2026-04-24 OpenAPI file has no `top_k` and no `seed`. The DSL is not missing a field. Do not add those keys to SwiftOpenResponsesDSL unless the spec adds them. |
| `previous_response_id` and `prompt_cache_key` | This package still sends the full transcript. Setting either field as well can duplicate the prompt or make the provider reject the turn. The executor does not keep a response id between calls. | **Open Responses defines both** on `CreateResponseBody`. The DSL already has them on `ResponseRequest`. **This package** leaves them unset. That is a turn policy, not a missing API or a missing DSL field. |
| Per-token `tokenCount` on streamed text, tools, and reasoning | Appends use `0`. The completion usage update carries the real totals. | **Characteristic of the Open Responses API.** Delta events (`response.output_text.delta`, `response.reasoning.delta`, `response.function_call_arguments.delta`) carry the text delta, indexes, and in some cases `logprobs` or `obfuscation`. They do not carry a token count. `Usage` (`input_tokens`, `output_tokens`, `total_tokens`, plus cached and reasoning details) is on the response. The DSL cannot surface a count the events do not have. |
| `contextSize` and `tokenCount` on HTTP 413, and a rate-limit `resetDate` | The mapper fills zeros and `resetDate: nil`. | **Characteristic of the Open Responses API.** `POST /responses` documents a `200` response. `Error` is `code` and `message`. Streaming `ErrorPayload` adds `type`, `param`, and an untyped `headers` map. The spec defines no context size, no token count on an error, and no reset time. `LLMError.serverError` and `LLMError.rateLimit` match that shape. Do not treat the missing numbers as a DSL omission. Map them only if a later spec version defines them. |
| `LanguageModelError.guardrailViolation` and `unsupportedLanguageOrLocale` | Mapping a generic provider error onto them would be a guess. | **Characteristic of the Open Responses API.** The 2026-04-24 spec has no guardrail event and no language or locale error. This is not a DSL gap. |
| Object-level JSON Schema `title`, `description`, and `x-order` | Those keywords are dropped while converting `GenerationSchema`. `additionalProperties: false` is still written. | **Split.** `JsonSchemaResponseFormatParam.schema` is a JSON Schema object with open properties, so `title` and `description` are allowed on the wire. Losing them is **SwiftLLMToolMacros**: `JSONSchemaValue.object` is only `properties` and `required`. **`x-order` is not Open Responses and not JSON Schema.** The spec does not define Apple's property-order extension. `strict: true` also says only a subset of JSON Schema is supported, without listing the subset, so a server may still reject keywords the wire object can carry. |
| Unknown `GenerationSchema` keywords, including `anyOf`, become a string schema | A hard `unsupportedGenerationGuide` error would reject guided generation for keywords `JSONSchemaValue` cannot carry. | **Not an Open Responses ban.** The schema object is open, so `anyOf` can appear in it. The collapse to `.string()` is **SwiftLLMToolMacros**, whose `JSONSchemaValue` has object, array, string, integer, number, boolean, and null. The spec's only related limit is `strict: true`: "Only a subset of JSON Schema is supported," with the subset unnamed. |
| Tool `strict: true` whenever tool calling is on | `strict` is set only when `structuredOutput` is on. Servers such as LM Studio rewrite or reject strict schemas, and unconditional strict would break tool calls that work today. | **Open Responses defines `FunctionTool.strict`.** The DSL already has it. **This package** gates it. That is a compatibility choice, not a missing API or DSL field. |
| `SystemLanguageModel` API: `isAvailable`, `contextSize`, `tokenCount(for:)`, guardrails, adapters, Private Cloud Compute | `LanguageModel` does not require them. | **Not an Open Responses surface.** They belong to Apple's on-device model. The DSL is not expected to grow them. |
| Data attachments, `supportsDataAttachmentType`, and `supportsDataEntryType` | Segments here are text, structure, and image attachments. | **Open Responses allows file input.** `InputFileContentParam` has `filename`, `file_data` (base64), and `file_url`. **SwiftOpenResponsesDSL encodes it** as `InputContentPart.inputFile` and `UserFile`. **FoundationModels in Xcode 27.1** does not include the OS 27.2 data-attachment APIs. `Transcript.Attachment` is only `.image`, so this package has nothing to translate yet. Image input already uses `input_image`. |
| Image orientation | The JPEG is the pixel buffer as handed over. `detail` stays unset. | **Characteristic of the Open Responses API.** `InputImageContent` has `image_url` and `detail` (`low`, `high`, `auto`). It has no orientation. The DSL's `detail` field matches the spec. Apple's `ImageAttachment` has orientation and no detail level, so `detail` is left nil. Baking orientation into the JPEG would be a change in this package's `cgImageToDataURI`. It would not add a field the API does not have. |

### Constraints

- The published "Not available" section stays in this order.
- A row moves out only when the behavior ships and the spec that describes the shipped behavior is updated in the same change.
- Length budgets elsewhere in this file do not justify deleting a row. The AGENTS.md budget grows by this section. The five-file total may exceed 450 lines by the length of "Not available" and the getting-started pointer.

---

## File Changes Summary

**Create:**
- `README.md`
- `docs/getting-started.md`
- `docs/philosophy.md`
- `CLAUDE.md`
- `AGENTS.md`
- `CONTRIBUTING.md`

**Modified:**
- `Sources/` — `///` doc comments added to all public symbols (types, initializers, properties, enum cases, methods)

**Untouched:**
- `Spec/` — all 6 spec files remain as the detailed reference
- `Examples/` — existing example apps with their own specs
- `docs/superpowers/` — internal planning docs
- `Tests/`
- `Package.swift`

**Not created (intentional):**
- No multiple topic guides — one getting-started guide covers the full progression
- No DocC catalog — WHAT spec covers API reference
- No agent skills — API surface fits in AGENTS.md
- No CODE_OF_CONDUCT/SECURITY — single-maintainer, early-stage
- No GitHub issue/PR templates

---

## Verification

- [ ] README badge row ends with Built with Grok Build, text-only, linking to `https://github.com/xai-org/grok-build`
- [ ] README has no Built with Claude Code badge
- [ ] README states the project was started with Claude Code and that all project-related work uses Grok Build and the latest Grok model
- [ ] AGENTS.md and CLAUDE.md state the same maintenance rule, and neither treats Claude Code as the current toolchain
- [ ] CONTRIBUTING.md names Grok Build and the latest Grok model as the agent that resolves issues
- [ ] README code examples compile when extracted and built against a project importing the package
- [ ] README substitutability story shows identical usage code with only the session init differing
- [ ] README "Why" section is ~15-20 lines, between the description and "The Swap"
- [ ] README links to `docs/philosophy.md`
- [ ] `docs/philosophy.md` is ~80-120 lines with 6 sections covering provider problem, standards, thin adapter, capability flags, errors, and local flexibility
- [ ] Philosophy article content is accurate against the WHY spec
- [ ] Philosophy article is written for external audiences, not contributor-facing
- [ ] Getting-started guide progresses from basic streaming through reasoning with increasing complexity
- [ ] Getting-started guide code examples compile and each section builds on the previous
- [ ] Getting-started guide references correct example app files (ToolCallingView.swift, StructuredOutputView.swift, etc.)
- [ ] CLAUDE.md file map matches actual source file listing in `Sources/SwiftOpenResponsesLanguageModel/`
- [ ] CLAUDE.md spec files table matches actual files in `Spec/`
- [ ] AGENTS.md patterns match current public API signatures (verified against source)
- [ ] AGENTS.md pitfalls describe real failure modes (verified against WHY spec and source)
- [ ] All cross-references between files resolve (README links to guide and AGENTS.md, CLAUDE.md points to Spec/)
- [ ] CONTRIBUTING.md explains spec-driven workflow: issue → AI agent → spec update → code generation
- [ ] CONTRIBUTING.md states that code PRs are not accepted and explains why (specs must be updated first)
- [ ] CONTRIBUTING.md links to `Spec/` directory
- [ ] No content duplication between README, getting-started guide, CLAUDE.md, AGENTS.md, and CONTRIBUTING.md
- [ ] Total documentation added is under 450 lines across all five files
- [ ] Every `public` symbol in `Sources/SwiftOpenResponsesLanguageModel/` has a `///` doc comment (types, inits, properties, enum cases, methods)
- [ ] AGENTS.md Installation section uses the correct SPM URL (`https://github.com/RichNasz/SwiftOpenResponsesLanguageModel.git`)
- [ ] AGENTS.md Quick Reference code block uses correct API signatures: `OpenResponsesModel(id:capabilities:)`, `OpenResponsesLanguageModel(name:auth:baseURL:timeout:)`, `AuthMode.apiKey(_:)` / `.proxied(headers:)`
- [ ] AGENTS.md "Not available" matches the Limits table in this spec: every row, same order, with the reason and the Open Responses fact. A row the API does not define is described as a characteristic of Open Responses, not as a SwiftOpenResponsesDSL bug. A row the API defines and the DSL omits says the spec allows it and names the missing DSL type.
- [ ] Getting-started "Limits" points at AGENTS.md and does not repeat the table
- [ ] CLAUDE.md points contributors at the Limits section and does not repeat the table
- [ ] No Limits row tells this package to invent `top_k`, seed, per-token counts, 413 sizes, rate-limit dates, guardrail errors, or locale errors
