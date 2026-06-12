# Rename: SwiftOpenLanguageModel → SwiftOpenResponsesLanguageModel

**Date:** 2026-06-11
**Status:** Approved

## Overview

Rename all package-level identifiers from `SwiftOpenLanguageModel` to `SwiftOpenResponsesLanguageModel` to accurately reflect the package's purpose: providing a `LanguageModel` implementation for Open Responses-compatible endpoints. The internal Swift type names (`OpenResponsesLanguageModel`, `OpenResponsesExecutor`, etc.) are already correct and unchanged.

The root directory on disk (`/Users/rnaszcyn/Development/SwiftLLMapis/SwiftOpenLanguageModel`) is intentionally left as-is.

## Scope

### 1. Package.swift

| Before | After |
|---|---|
| `name: "SwiftOpenLanguageModel"` | `name: "SwiftOpenResponsesLanguageModel"` |
| library `name: "SwiftOpenLanguageModel"` | `name: "SwiftOpenResponsesLanguageModel"` |
| target `name: "SwiftOpenLanguageModel"` | `name: "SwiftOpenResponsesLanguageModel"` |
| test target `name: "SwiftOpenLanguageModelTests"` | `name: "SwiftOpenResponsesLanguageModelTests"` |

### 2. Source Directories (filesystem rename)

| Before | After |
|---|---|
| `Sources/SwiftOpenLanguageModel/` | `Sources/SwiftOpenResponsesLanguageModel/` |
| `Tests/SwiftOpenLanguageModelTests/` | `Tests/SwiftOpenResponsesLanguageModelTests/` |

All Swift files inside remain named as-is — only the containing directories change.

### 3. Spec Files (rename + update content)

| Before | After |
|---|---|
| `Spec/SwiftOpenLanguageModel-HOW.md` | `Spec/SwiftOpenResponsesLanguageModel-HOW.md` |
| `Spec/SwiftOpenLanguageModel-WHAT.md` | `Spec/SwiftOpenResponsesLanguageModel-WHAT.md` |
| `Spec/SwiftOpenLanguageModel-WHY.md` | `Spec/SwiftOpenResponsesLanguageModel-WHY.md` |

Within each file: title headings and inline module/path references updated to match.

### 4. Xcode Scheme Files (rename + update identifiers)

All scheme files under `.swiftpm/xcode/xcshareddata/xcschemes/`:
- `SwiftOpenLanguageModel.xcscheme` → `SwiftOpenResponsesLanguageModel.xcscheme`
- `SwiftOpenLanguageModel-Package.xcscheme` → `SwiftOpenResponsesLanguageModel-Package.xcscheme`
- `iOSTestApp.xcscheme` — update internal `BlueprintIdentifier`/`BuildableName` references only (filename unchanged)
- Internal `BlueprintIdentifier` and `BuildableName` values updated inside all scheme files.

### 5. Test File + Example App

| File | Change |
|---|---|
| `Tests/.../SwiftOpenLanguageModelTests.swift` | `@testable import SwiftOpenResponsesLanguageModel` |
| `Examples/visionOS/visionOSTestApp/ContentView.swift` | `import SwiftOpenResponsesLanguageModel` |
| `Examples/visionOS/.../project.pbxproj` | All `SwiftOpenLanguageModel` product/framework/productName references updated |
| `Examples/iOS/Specs/iOSTestApp-HOW.md` | Package name + import statement updated |
| `Examples/macOS/Specs/macOSTestApp-HOW.md` | Package name + import statement updated |
| `Examples/visionOS/Specs/visionOSTestApp-HOW.md` | Package name + import statement updated |

## What Does NOT Change

- Swift source filenames within `Sources/` (e.g., `OpenResponsesLanguageModel.swift`)
- All internal type names (`OpenResponsesLanguageModel`, `OpenResponsesExecutor`, `OpenResponsesModel`, `AuthMode`, etc.)
- `Examples/visionOS/visionOSTestApp/App.swift` (no module import)
- Root working directory on disk

## Acceptance Criteria

- [ ] `swift build` succeeds after all changes
- [ ] No remaining occurrences of `SwiftOpenLanguageModel` in non-build, non-binary files (excluding the root directory name itself)
- [ ] Spec files have correct titles and accurate module/path references
- [ ] Xcode schemes resolve correctly (target identifiers match new names)
- [ ] visionOS example app project still links the renamed package product
