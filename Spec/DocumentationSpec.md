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

Five badges on the first line after the H1 title, in this order: Swift 6.2+, Platform (macOS 27 | iOS 27 | visionOS 27 | watchOS 27), License (Apache 2.0), Version, Built with Claude Code.

### One-Sentence Description

Must convey: Swift package providing a `LanguageModel` implementation that connects Apple's FoundationModels to any Open Responses specification endpoint. Must use "drop-in" or "swap" language to convey substitutability.

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

### Constraints

- Each section must include at least one complete, compilable code block
- Each section builds on the previous — later sections can reference concepts from earlier ones without re-explaining
- No more than 2-3 sentences of explanation per code block — let the code speak
- Link to specific example app files for complete app implementations rather than reproducing full app code
- The guide covers only FoundationModels API usage (sessions, prompts, streaming) — it does not explain SwiftUI or app architecture

---

## 3. CLAUDE.md

**Purpose:** AI contributor's entry point to the codebase. Orients the reader to navigate the project and generate correct code.

**Target length:** ~60-70 lines.

**Structure:**

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

### Spec Files

| File | Covers |
|------|--------|
| `SwiftOpenResponsesLanguageModel-WHAT.md` | Public API surface + acceptance criteria |
| `SwiftOpenResponsesLanguageModel-HOW.md` | Implementation details |
| `SwiftOpenResponsesLanguageModel-WHY.md` | Design rationale |
| `SwiftOpenResponsesLanguageModel-Tests-WHAT/HOW/WHY.md` | Test strategy + implementation |

Directive: "Consult Spec/ files for detailed design decisions."

### Testing Strategy

- Unit tests only, no live API calls
- Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- Four test suites: ErrorMapper, OpenResponsesModel, RequestBuilder, EventTranslator

### Constraints

- Must not duplicate WHAT/HOW/WHY spec content — its job is to orient, not to be a reference
- Must point to Spec/ for implementation details

---

## 4. AGENTS.md

**Purpose:** Machine-readable patterns and pitfalls for AI coding tools consuming this library (not contributing to it).

**Target length:** ~100-120 lines.

**Format:** Each topic section follows Pattern/Pitfalls structure.

**Structure:**

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

### Constraints

- For consumers, not contributors (architecture details belong in CLAUDE.md)
- Every Pattern must be a compilable code block
- Every Pitfall must describe a concrete mistake and its consequence

---

## 5. CONTRIBUTING.md

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
2. **Issues drive changes** — All changes start as a GitHub Issue (bug report or feature request). Issues are resolved interactively with an AI coding agent.
3. **The workflow** — Issue raised → AI agent analyzes the issue against existing specs → specs are updated to reflect the change → code is generated from the updated specs → tests verify the implementation.
4. **Why no code PRs** — Unsolicited code PRs skip the spec step and cannot be accepted. The specs must be updated first so that design decisions are captured and code can be regenerated consistently. Feature ideas raised via issues may be implemented in a future release when they align with the project's direction.

Must link to the `Spec/` directory so contributors can see how specs are structured.

### Constraints

- Tone: welcoming but clear about the process — not apologetic about rejecting PRs
- Frame it as "this is how the project works," not "sorry we can't accept your code"
- Must be concise — the CONTRIBUTING.md itself should be under 40 lines
- No conventional commits section, no PR template — those don't apply when code PRs aren't accepted

---

## File Changes Summary

**Create:**
- `README.md`
- `docs/getting-started.md`
- `CLAUDE.md`
- `AGENTS.md`
- `CONTRIBUTING.md`

**Untouched:**
- `Spec/` — all 6 spec files remain as the detailed reference
- `Examples/` — existing example apps with their own specs
- `docs/superpowers/` — internal planning docs
- `Sources/` and `Tests/`
- `Package.swift`

**Not created (intentional):**
- No multiple topic guides — one getting-started guide covers the full progression
- No DocC catalog — WHAT spec covers API reference
- No agent skills — API surface fits in AGENTS.md
- No CODE_OF_CONDUCT/SECURITY — single-maintainer, early-stage
- No GitHub issue/PR templates

---

## Verification

- [ ] README code examples compile when extracted and built against a project importing the package
- [ ] README substitutability story shows identical usage code with only the session init differing
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
