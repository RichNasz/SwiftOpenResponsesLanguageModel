# Rename SwiftOpenLanguageModel → SwiftOpenResponsesLanguageModel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename every package-level identifier from `SwiftOpenLanguageModel` to `SwiftOpenResponsesLanguageModel` so the package name accurately reflects its purpose.

**Architecture:** Pure rename — no behavioral changes. Internal Swift type names (`OpenResponsesLanguageModel`, `OpenResponsesExecutor`, etc.) are already correct and untouched. Changes fall into: filesystem directory renames, Package.swift, test imports, Xcode scheme files, spec docs, and the visionOS example app.

**Tech Stack:** Swift Package Manager, Xcode scheme XML, Swift 6

---

## File Map

| Action | Path |
|---|---|
| Rename dir | `Sources/SwiftOpenLanguageModel/` → `Sources/SwiftOpenResponsesLanguageModel/` |
| Rename dir | `Tests/SwiftOpenLanguageModelTests/` → `Tests/SwiftOpenResponsesLanguageModelTests/` |
| Modify | `Package.swift` |
| Modify | `Tests/SwiftOpenResponsesLanguageModelTests/SwiftOpenLanguageModelTests.swift` |
| Rename + modify | `.swiftpm/xcode/xcshareddata/xcschemes/SwiftOpenLanguageModel.xcscheme` → `SwiftOpenResponsesLanguageModel.xcscheme` |
| Rename + modify | `.swiftpm/xcode/xcshareddata/xcschemes/SwiftOpenLanguageModel-Package.xcscheme` → `SwiftOpenResponsesLanguageModel-Package.xcscheme` |
| Modify | `.swiftpm/xcode/xcshareddata/xcschemes/iOSTestApp.xcscheme` |
| Rename + modify | `Spec/SwiftOpenLanguageModel-HOW.md` → `Spec/SwiftOpenResponsesLanguageModel-HOW.md` |
| Rename + modify | `Spec/SwiftOpenLanguageModel-WHAT.md` → `Spec/SwiftOpenResponsesLanguageModel-WHAT.md` |
| Rename + modify | `Spec/SwiftOpenLanguageModel-WHY.md` → `Spec/SwiftOpenResponsesLanguageModel-WHY.md` |
| Modify | `Examples/visionOS/visionOSTestApp/ContentView.swift` |
| Modify | `Examples/visionOS/visionOSTestApp/visionOSTestApp.xcodeproj/project.pbxproj` |
| Modify | `Examples/iOS/Specs/iOSTestApp-HOW.md` |
| Modify | `Examples/macOS/Specs/macOSTestApp-HOW.md` |
| Modify | `Examples/visionOS/Specs/visionOSTestApp-HOW.md` |

---

### Task 1: Rename source directories + update Package.swift

These three changes must land in the same commit — SPM resolves `Sources/<TargetName>/` from the target name in Package.swift, so they must be consistent.

**Files:**
- Rename: `Sources/SwiftOpenLanguageModel/` → `Sources/SwiftOpenResponsesLanguageModel/`
- Rename: `Tests/SwiftOpenLanguageModelTests/` → `Tests/SwiftOpenResponsesLanguageModelTests/`
- Modify: `Package.swift`

- [ ] **Step 1: Rename the source directory**

Run from the repo root (`/Users/rnaszcyn/Development/SwiftLLMapis/SwiftOpenLanguageModel`):

```bash
mv Sources/SwiftOpenLanguageModel Sources/SwiftOpenResponsesLanguageModel
```

- [ ] **Step 2: Rename the test directory**

```bash
mv Tests/SwiftOpenLanguageModelTests Tests/SwiftOpenResponsesLanguageModelTests
```

- [ ] **Step 3: Rewrite Package.swift**

Replace the entire file with:

```swift
// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "SwiftOpenResponsesLanguageModel",
	platforms: [
		.iOS("27.0"), .macOS("27.0"), .visionOS("27.0"), .watchOS("27.0"),
	],
	products: [
		.library(
			name: "SwiftOpenResponsesLanguageModel",
			targets: ["SwiftOpenResponsesLanguageModel"]
		),
	],
	dependencies: [
		.package(path: "../SwiftOpenResponsesDSL"),
	],
	targets: [
		.target(
			name: "SwiftOpenResponsesLanguageModel",
			dependencies: [
				.product(name: "SwiftOpenResponsesDSL", package: "SwiftOpenResponsesDSL"),
			]
		),
		.testTarget(
			name: "SwiftOpenResponsesLanguageModelTests",
			dependencies: ["SwiftOpenResponsesLanguageModel"]
		),
	]
)
```

- [ ] **Step 4: Commit**

```bash
git add Package.swift Sources/ Tests/
git commit -m "rename: SwiftOpenLanguageModel → SwiftOpenResponsesLanguageModel (dirs + Package.swift)"
```

---

### Task 2: Update test file import + verify build

**Files:**
- Modify: `Tests/SwiftOpenResponsesLanguageModelTests/SwiftOpenLanguageModelTests.swift`

- [ ] **Step 1: Update the import**

In `Tests/SwiftOpenResponsesLanguageModelTests/SwiftOpenLanguageModelTests.swift`, change:

```swift
@testable import SwiftOpenLanguageModel
```

to:

```swift
@testable import SwiftOpenResponsesLanguageModel
```

- [ ] **Step 2: Run swift build to verify**

```bash
swift build
```

Expected: build succeeds with no errors. If you see `no targets named 'SwiftOpenLanguageModel'`, the Package.swift or directory rename from Task 1 is incomplete.

- [ ] **Step 3: Commit**

```bash
git add Tests/SwiftOpenResponsesLanguageModelTests/SwiftOpenLanguageModelTests.swift
git commit -m "rename: update test import to SwiftOpenResponsesLanguageModel"
```

---

### Task 3: Rename and update Xcode scheme files

**Files:**
- Rename + modify: `.swiftpm/xcode/xcshareddata/xcschemes/SwiftOpenLanguageModel.xcscheme`
- Rename + modify: `.swiftpm/xcode/xcshareddata/xcschemes/SwiftOpenLanguageModel-Package.xcscheme`
- Modify: `.swiftpm/xcode/xcshareddata/xcschemes/iOSTestApp.xcscheme`

- [ ] **Step 1: Rename SwiftOpenLanguageModel.xcscheme**

```bash
mv .swiftpm/xcode/xcshareddata/xcschemes/SwiftOpenLanguageModel.xcscheme \
   .swiftpm/xcode/xcshareddata/xcschemes/SwiftOpenResponsesLanguageModel.xcscheme
```

- [ ] **Step 2: Replace content of SwiftOpenResponsesLanguageModel.xcscheme**

Write the file with these exact contents (all `SwiftOpenLanguageModel` and `SwiftOpenLanguageModelTests` identifiers replaced):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2700"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "SwiftOpenResponsesLanguageModel"
               BuildableName = "SwiftOpenResponsesLanguageModel"
               ReferencedContainer = "container:">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "SwiftOpenResponsesLanguageModelTests"
               BuildableName = "SwiftOpenResponsesLanguageModelTests"
               ReferencedContainer = "container:">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES"
      queueDebuggingEnabled = "No">
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "SwiftOpenResponsesLanguageModel"
            BuildableName = "SwiftOpenResponsesLanguageModel"
            ReferencedContainer = "container:">
         </BuildableReference>
      </MacroExpansion>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
```

- [ ] **Step 3: Rename SwiftOpenLanguageModel-Package.xcscheme**

```bash
mv .swiftpm/xcode/xcshareddata/xcschemes/SwiftOpenLanguageModel-Package.xcscheme \
   .swiftpm/xcode/xcshareddata/xcschemes/SwiftOpenResponsesLanguageModel-Package.xcscheme
```

- [ ] **Step 4: Replace content of SwiftOpenResponsesLanguageModel-Package.xcscheme**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2700"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "SwiftOpenResponsesLanguageModel"
               BuildableName = "SwiftOpenResponsesLanguageModel"
               ReferencedContainer = "container:">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "iOSTestApp"
               BuildableName = "iOSTestApp"
               ReferencedContainer = "container:">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "SwiftOpenResponsesLanguageModelTests"
               BuildableName = "SwiftOpenResponsesLanguageModelTests"
               ReferencedContainer = "container:">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES"
      queueDebuggingEnabled = "No">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "iOSTestApp"
            BuildableName = "iOSTestApp"
            ReferencedContainer = "container:">
         </BuildableReference>
      </MacroExpansion>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "iOSTestApp"
            BuildableName = "iOSTestApp"
            ReferencedContainer = "container:">
         </BuildableReference>
      </MacroExpansion>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
```

- [ ] **Step 5: Update iOSTestApp.xcscheme (in place — two occurrences)**

In `.swiftpm/xcode/xcshareddata/xcschemes/iOSTestApp.xcscheme`, replace:

```xml
               BlueprintIdentifier = "SwiftOpenLanguageModelTests"
               BuildableName = "SwiftOpenLanguageModelTests"
```

with:

```xml
               BlueprintIdentifier = "SwiftOpenResponsesLanguageModelTests"
               BuildableName = "SwiftOpenResponsesLanguageModelTests"
```

- [ ] **Step 6: Commit**

```bash
git add .swiftpm/xcode/xcshareddata/xcschemes/
git commit -m "rename: update Xcode scheme files to SwiftOpenResponsesLanguageModel"
```

---

### Task 4: Rename and update main spec files

**Files:**
- Rename + modify: `Spec/SwiftOpenLanguageModel-HOW.md`
- Rename + modify: `Spec/SwiftOpenLanguageModel-WHAT.md`
- Rename + modify: `Spec/SwiftOpenLanguageModel-WHY.md`

- [ ] **Step 1: Rename all three spec files**

```bash
mv Spec/SwiftOpenLanguageModel-HOW.md Spec/SwiftOpenResponsesLanguageModel-HOW.md
mv Spec/SwiftOpenLanguageModel-WHAT.md Spec/SwiftOpenResponsesLanguageModel-WHAT.md
mv Spec/SwiftOpenLanguageModel-WHY.md Spec/SwiftOpenResponsesLanguageModel-WHY.md
```

- [ ] **Step 2: Update title in SwiftOpenResponsesLanguageModel-HOW.md**

Change the first line from:
```
# SwiftOpenLanguageModel — HOW Spec
```
to:
```
# SwiftOpenResponsesLanguageModel — HOW Spec
```

Also update the file structure block — change:
```
Sources/SwiftOpenLanguageModel/
```
to:
```
Sources/SwiftOpenResponsesLanguageModel/
```

- [ ] **Step 3: Update title in SwiftOpenResponsesLanguageModel-WHAT.md**

Change the first line from:
```
# SwiftOpenLanguageModel — WHAT Spec
```
to:
```
# SwiftOpenResponsesLanguageModel — WHAT Spec
```

- [ ] **Step 4: Update title in SwiftOpenResponsesLanguageModel-WHY.md**

Change the first line from:
```
# SwiftOpenLanguageModel — WHY Spec
```
to:
```
# SwiftOpenResponsesLanguageModel — WHY Spec
```

- [ ] **Step 5: Commit**

```bash
git add Spec/
git commit -m "rename: update spec files to SwiftOpenResponsesLanguageModel"
```

---

### Task 5: Update visionOS example app

**Files:**
- Modify: `Examples/visionOS/visionOSTestApp/ContentView.swift`
- Modify: `Examples/visionOS/visionOSTestApp/visionOSTestApp.xcodeproj/project.pbxproj`

- [ ] **Step 1: Update ContentView.swift import**

In `Examples/visionOS/visionOSTestApp/ContentView.swift`, change line 3 from:
```swift
import SwiftOpenLanguageModel
```
to:
```swift
import SwiftOpenResponsesLanguageModel
```

- [ ] **Step 2: Update project.pbxproj — PBXBuildFile comment (line 12)**

Change:
```
		BB0000050000000000000000 /* SwiftOpenLanguageModel in Frameworks */ = {isa = PBXBuildFile; productRef = BB0000060000000000000000 /* SwiftOpenLanguageModel */; };
```
to:
```
		BB0000050000000000000000 /* SwiftOpenResponsesLanguageModel in Frameworks */ = {isa = PBXBuildFile; productRef = BB0000060000000000000000 /* SwiftOpenResponsesLanguageModel */; };
```

- [ ] **Step 3: Update project.pbxproj — PBXFrameworksBuildPhase files list (line 27)**

Change:
```
				BB0000050000000000000000 /* SwiftOpenLanguageModel in Frameworks */,
```
to:
```
				BB0000050000000000000000 /* SwiftOpenResponsesLanguageModel in Frameworks */,
```

- [ ] **Step 4: Update project.pbxproj — packageProductDependencies list (line 69)**

Change:
```
				BB0000060000000000000000 /* SwiftOpenLanguageModel */,
```
to:
```
				BB0000060000000000000000 /* SwiftOpenResponsesLanguageModel */,
```

- [ ] **Step 5: Update project.pbxproj — XCSwiftPackageProductDependency section (lines 292–294)**

Change:
```
		BB0000060000000000000000 /* SwiftOpenLanguageModel */ = {
			isa = XCSwiftPackageProductDependency;
			productName = SwiftOpenLanguageModel;
		};
```
to:
```
		BB0000060000000000000000 /* SwiftOpenResponsesLanguageModel */ = {
			isa = XCSwiftPackageProductDependency;
			productName = SwiftOpenResponsesLanguageModel;
		};
```

- [ ] **Step 6: Commit**

```bash
git add Examples/visionOS/visionOSTestApp/ContentView.swift \
        Examples/visionOS/visionOSTestApp/visionOSTestApp.xcodeproj/project.pbxproj
git commit -m "rename: update visionOS example app to SwiftOpenResponsesLanguageModel"
```

---

### Task 6: Update example spec files

**Files:**
- Modify: `Examples/iOS/Specs/iOSTestApp-HOW.md`
- Modify: `Examples/macOS/Specs/macOSTestApp-HOW.md`
- Modify: `Examples/visionOS/Specs/visionOSTestApp-HOW.md`

Each HOW spec has two lines to update in the "Implementation Target" section.

- [ ] **Step 1: Update Examples/iOS/Specs/iOSTestApp-HOW.md**

Change:
```markdown
- Package: `SwiftOpenLanguageModel`
- Imports: `import SwiftUI`, `import FoundationModels`, `import SwiftOpenLanguageModel`
```
to:
```markdown
- Package: `SwiftOpenResponsesLanguageModel`
- Imports: `import SwiftUI`, `import FoundationModels`, `import SwiftOpenResponsesLanguageModel`
```

- [ ] **Step 2: Update Examples/macOS/Specs/macOSTestApp-HOW.md**

Change:
```markdown
- Package: `SwiftOpenLanguageModel`
- Imports: `import SwiftUI`, `import FoundationModels`, `import SwiftOpenLanguageModel`
```
to:
```markdown
- Package: `SwiftOpenResponsesLanguageModel`
- Imports: `import SwiftUI`, `import FoundationModels`, `import SwiftOpenResponsesLanguageModel`
```

- [ ] **Step 3: Update Examples/visionOS/Specs/visionOSTestApp-HOW.md**

Change:
```markdown
- Package: `SwiftOpenLanguageModel`
- Imports: `import SwiftUI`, `import FoundationModels`, `import SwiftOpenLanguageModel`
```
to:
```markdown
- Package: `SwiftOpenResponsesLanguageModel`
- Imports: `import SwiftUI`, `import FoundationModels`, `import SwiftOpenResponsesLanguageModel`
```

- [ ] **Step 4: Commit**

```bash
git add Examples/iOS/Specs/iOSTestApp-HOW.md \
        Examples/macOS/Specs/macOSTestApp-HOW.md \
        Examples/visionOS/Specs/visionOSTestApp-HOW.md
git commit -m "rename: update example app specs to SwiftOpenResponsesLanguageModel"
```

---

### Task 7: Final verification

- [ ] **Step 1: Confirm swift build passes**

```bash
swift build
```

Expected output ends with `Build complete!` and no errors or warnings about missing targets.

- [ ] **Step 2: Verify no stray occurrences remain**

```bash
grep -rn "SwiftOpenLanguageModel" . \
  --include="*.swift" --include="*.md" --include="*.xcscheme" \
  --include="*.pbxproj" --include="*.plist" \
  | grep -v ".build/" | grep -v "xcuserdata" \
  | grep -v "docs/superpowers/"
```

Expected: no output. Any remaining lines indicate missed changes — fix them and commit before marking done.

- [ ] **Step 3: Commit the plan and design docs**

```bash
git add docs/
git commit -m "docs: add rename design spec and implementation plan"
```
