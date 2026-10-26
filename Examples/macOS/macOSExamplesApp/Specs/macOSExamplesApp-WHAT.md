# macOSExamplesApp — WHAT Spec

## Overview

A macOS 27+ app demonstrating the same six usage patterns as `visionOSExamplesApp`. Each pattern maps to one scene in a `NavigationSplitView` sidebar and one source file in `Examples/`. Behavior matches `Examples/visionOS/visionOSExamplesApp/Specs/visionOSExamplesApp-WHAT.md` except for the platform differences below.

## Platform Differences

- Image bytes are decoded with `NSImage`, then `cgImage(forProposedRect:context:hints:)`. The attachment is still `Attachment<ImageAttachmentContent>`. Orientation is not passed.
- Settings are stored under `macos_examples_baseURL`, `macos_examples_modelID`, and `macos_examples_apiKey`.
- The settings sheet does not call `textInputAutocapitalization`. That modifier is absent on macOS.
- Toolbar items use `.primaryAction`. `.topBarTrailing` is unavailable on macOS.
- The window opens at 980×720.
- `NSPhotoLibraryUsageDescription` is set so PhotosPicker can read a selected image.

## Acceptance Criteria

- [ ] Compiles for macOS 27+
- [ ] Endpoint settings persist across app launches
- [ ] All six scenes reachable from the sidebar
- [ ] Streaming, multi-turn, tool calling, structured output, image input, and reasoning match the visionOS examples acceptance criteria
- [ ] Image Input decodes the picked image with AppKit and sends it through `LanguageModelSession`
