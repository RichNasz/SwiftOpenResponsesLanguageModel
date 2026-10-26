# macOSExamplesApp — HOW Spec

## Source

`Examples/macOS/macOSExamplesApp/`. Open `macOSExamplesApp.xcworkspace`, which also references the package at the repository root.

## File Structure

```
macOSExamplesApp/
├── App.swift
├── EndpointSettings.swift
├── SettingsSheet.swift
├── RootView.swift
├── Examples/
│   ├── StreamingView.swift
│   ├── MultiTurnView.swift
│   ├── ToolCallingView.swift
│   ├── StructuredOutputView.swift
│   ├── ImageInputView.swift
│   └── ReasoningView.swift
└── Specs/
```

`StreamingView`, `ToolCallingView`, `StructuredOutputView`, and `ReasoningView` match the visionOS examples sources. `RootView` and `MultiTurnView` use `ToolbarItemPlacement.primaryAction` instead of `.topBarTrailing`. Session construction, `prewarm()`, usage totals, tool strictness, and reasoning replay follow `visionOSExamplesApp-HOW.md`.

## EndpointSettings

Same `@Observable` shape as the visionOS app. Keys use the `macos_examples_` prefix.

## ImageInputView

1. Load image bytes via `PhotosPickerItem.loadTransferable(type: Data.self)`.
2. Decode with `NSImage(data:)`.
3. Take a `CGImage` from `cgImage(forProposedRect:context:hints:)`.
4. Build `Attachment<ImageAttachmentContent>(cgImage)` and apply `.label(_:)` when the label is non-empty.
5. Stream with `session.streamResponse { imageAttachment; prompt }`.

## Build Configuration

| Setting | Value |
|---|---|
| `SDKROOT` | `macosx` |
| `MACOSX_DEPLOYMENT_TARGET` | `27.0` |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.example.macOSExamplesApp` |
| `SWIFT_VERSION` | `6.0` |
| `GENERATE_INFOPLIST_FILE` | `YES` |
| `INFOPLIST_FILE` | `Info.plist` |

`Info.plist` sets `NSHighResolutionCapable`, `NSAllowsArbitraryLoads`, and `NSPhotoLibraryUsageDescription`. It has no `UIApplication` or `UIScene` keys.

The app is not sandboxed, so a user-entered local HTTP endpoint does not need a network entitlement.
