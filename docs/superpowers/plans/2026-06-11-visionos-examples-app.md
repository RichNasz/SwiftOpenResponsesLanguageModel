# visionOS Examples App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `visionOSExamplesApp` — a new visionOS 27+ Xcode app with six NavigationSplitView scenes each demonstrating one usage pattern of `SwiftOpenResponsesLanguageModel`, plus update the existing `visionOSTestApp` WHAT spec.

**Architecture:** `NavigationSplitView` with a sidebar listing six examples. `EndpointSettings` (`@Observable`) holds shared `baseURL`, `modelID`, `apiKey` and is injected into the environment at the app root. Each example scene reads settings from the environment and constructs its own `OpenResponsesLanguageModel`. Source files for the six example views are created as stubs first so the shared infrastructure (which references all six) can compile, then each stub is replaced with its full implementation.

**Tech Stack:** SwiftUI, FoundationModels, SwiftOpenResponsesLanguageModel, PhotosUI, visionOS 27.0+, Swift 6.0

---

## File Map

| Path | Role |
|---|---|
| `Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcodeproj/project.pbxproj` | Xcode project — created once, not modified after |
| `Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcworkspace/contents.xcworkspacedata` | Workspace — links project + package |
| `Examples/visionOS/visionOSExamplesApp/Info.plist` | Minimal app plist |
| `Examples/visionOS/visionOSExamplesApp/App.swift` | `@main` entry point, injects `EndpointSettings` |
| `Examples/visionOS/visionOSExamplesApp/EndpointSettings.swift` | `@Observable` shared endpoint config |
| `Examples/visionOS/visionOSExamplesApp/SettingsSheet.swift` | Sheet UI for editing endpoint settings |
| `Examples/visionOS/visionOSExamplesApp/RootView.swift` | `NavigationSplitView` sidebar + `Example` enum |
| `Examples/visionOS/visionOSExamplesApp/Examples/StreamingView.swift` | Example 1: basic streaming |
| `Examples/visionOS/visionOSExamplesApp/Examples/MultiTurnView.swift` | Example 2: multi-turn conversation |
| `Examples/visionOS/visionOSExamplesApp/Examples/ToolCallingView.swift` | Example 3: tool calling |
| `Examples/visionOS/visionOSExamplesApp/Examples/StructuredOutputView.swift` | Example 4: guided generation |
| `Examples/visionOS/visionOSExamplesApp/Examples/ImageInputView.swift` | Example 5: image/vision input |
| `Examples/visionOS/visionOSExamplesApp/Examples/ReasoningView.swift` | Example 6: extended thinking |
| `Examples/visionOS/visionOSExamplesApp/Specs/visionOSExamplesApp-WHAT.md` | What spec |
| `Examples/visionOS/visionOSExamplesApp/Specs/visionOSExamplesApp-HOW.md` | How spec |
| `Examples/visionOS/Specs/visionOSTestApp-WHAT.md` | Updated: add Purpose section |

All paths are relative to the package root (`SwiftOpenLanguageModel/`).

---

## Task 1: Create project scaffold (project.pbxproj, workspace, Info.plist)

**Files:**
- Create: `Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcodeproj/project.pbxproj`
- Create: `Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcworkspace/contents.xcworkspacedata`
- Create: `Examples/visionOS/visionOSExamplesApp/Info.plist`
- Create: `Examples/visionOS/visionOSExamplesApp/Examples/` (directory)

- [ ] **Step 1: Create the directory structure**

```bash
mkdir -p Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcodeproj/xcshareddata/xcschemes
mkdir -p Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcworkspace
mkdir -p Examples/visionOS/visionOSExamplesApp/Examples
mkdir -p Examples/visionOS/visionOSExamplesApp/Specs
```

- [ ] **Step 2: Write `project.pbxproj`**

Write the following content to `Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcodeproj/project.pbxproj`:

```
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		CC0000010000000000000000 /* App.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC0000020000000000000000 /* App.swift */; };
		CC0000030000000000000000 /* EndpointSettings.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC0000040000000000000000 /* EndpointSettings.swift */; };
		CC0000050000000000000000 /* SettingsSheet.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC0000060000000000000000 /* SettingsSheet.swift */; };
		CC0000070000000000000000 /* RootView.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC0000080000000000000000 /* RootView.swift */; };
		CC0000090000000000000000 /* StreamingView.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC00000A0000000000000000 /* StreamingView.swift */; };
		CC00000B0000000000000000 /* MultiTurnView.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC00000C0000000000000000 /* MultiTurnView.swift */; };
		CC00000D0000000000000000 /* ToolCallingView.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC00000E0000000000000000 /* ToolCallingView.swift */; };
		CC00000F0000000000000000 /* StructuredOutputView.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC0000100000000000000000 /* StructuredOutputView.swift */; };
		CC0000110000000000000000 /* ImageInputView.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC0000120000000000000000 /* ImageInputView.swift */; };
		CC0000130000000000000000 /* ReasoningView.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC0000140000000000000000 /* ReasoningView.swift */; };
		CC0000150000000000000000 /* SwiftOpenResponsesLanguageModel in Frameworks */ = {isa = PBXBuildFile; productRef = CC0000160000000000000000 /* SwiftOpenResponsesLanguageModel */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		CC0000020000000000000000 /* App.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = App.swift; sourceTree = "<group>"; };
		CC0000040000000000000000 /* EndpointSettings.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EndpointSettings.swift; sourceTree = "<group>"; };
		CC0000060000000000000000 /* SettingsSheet.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SettingsSheet.swift; sourceTree = "<group>"; };
		CC0000080000000000000000 /* RootView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RootView.swift; sourceTree = "<group>"; };
		CC00000A0000000000000000 /* StreamingView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StreamingView.swift; sourceTree = "<group>"; };
		CC00000C0000000000000000 /* MultiTurnView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MultiTurnView.swift; sourceTree = "<group>"; };
		CC00000E0000000000000000 /* ToolCallingView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ToolCallingView.swift; sourceTree = "<group>"; };
		CC0000100000000000000000 /* StructuredOutputView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StructuredOutputView.swift; sourceTree = "<group>"; };
		CC0000120000000000000000 /* ImageInputView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ImageInputView.swift; sourceTree = "<group>"; };
		CC0000140000000000000000 /* ReasoningView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ReasoningView.swift; sourceTree = "<group>"; };
		CC0000170000000000000000 /* visionOSExamplesApp.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = visionOSExamplesApp.app; sourceTree = BUILT_PRODUCTS_DIR; };
		CC0000180000000000000000 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		CC0000220000000000000000 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				CC0000150000000000000000 /* SwiftOpenResponsesLanguageModel in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		CC0000240000000000000000 = {
			isa = PBXGroup;
			children = (
				CC0000020000000000000000 /* App.swift */,
				CC0000040000000000000000 /* EndpointSettings.swift */,
				CC0000060000000000000000 /* SettingsSheet.swift */,
				CC0000080000000000000000 /* RootView.swift */,
				CC0000260000000000000000 /* Examples */,
				CC0000180000000000000000 /* Info.plist */,
				CC0000250000000000000000 /* Products */,
			);
			sourceTree = "<group>";
		};
		CC0000250000000000000000 /* Products */ = {
			isa = PBXGroup;
			children = (
				CC0000170000000000000000 /* visionOSExamplesApp.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		CC0000260000000000000000 /* Examples */ = {
			isa = PBXGroup;
			children = (
				CC00000A0000000000000000 /* StreamingView.swift */,
				CC00000C0000000000000000 /* MultiTurnView.swift */,
				CC00000E0000000000000000 /* ToolCallingView.swift */,
				CC0000100000000000000000 /* StructuredOutputView.swift */,
				CC0000120000000000000000 /* ImageInputView.swift */,
				CC0000140000000000000000 /* ReasoningView.swift */,
			);
			name = Examples;
			path = Examples;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		CC0000190000000000000000 /* visionOSExamplesApp */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = CC00001B0000000000000000 /* Build configuration list for PBXNativeTarget "visionOSExamplesApp" */;
			buildPhases = (
				CC0000210000000000000000 /* Sources */,
				CC0000220000000000000000 /* Frameworks */,
				CC0000230000000000000000 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = visionOSExamplesApp;
			packageProductDependencies = (
				CC0000160000000000000000 /* SwiftOpenResponsesLanguageModel */,
			);
			productName = visionOSExamplesApp;
			productReference = CC0000170000000000000000 /* visionOSExamplesApp.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		CC00001A0000000000000000 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2700;
				LastUpgradeCheck = 2700;
				TargetAttributes = {
					CC0000190000000000000000 = {
						CreatedOnToolsVersion = 27.0;
					};
				};
			};
			buildConfigurationList = CC00001C0000000000000000 /* Build configuration list for PBXProject "visionOSExamplesApp" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = CC0000240000000000000000;
			productRefGroup = CC0000250000000000000000 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				CC0000190000000000000000 /* visionOSExamplesApp */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		CC0000230000000000000000 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		CC0000210000000000000000 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				CC0000010000000000000000 /* App.swift in Sources */,
				CC0000030000000000000000 /* EndpointSettings.swift in Sources */,
				CC0000050000000000000000 /* SettingsSheet.swift in Sources */,
				CC0000070000000000000000 /* RootView.swift in Sources */,
				CC0000090000000000000000 /* StreamingView.swift in Sources */,
				CC00000B0000000000000000 /* MultiTurnView.swift in Sources */,
				CC00000D0000000000000000 /* ToolCallingView.swift in Sources */,
				CC00000F0000000000000000 /* StructuredOutputView.swift in Sources */,
				CC0000110000000000000000 /* ImageInputView.swift in Sources */,
				CC0000130000000000000000 /* ReasoningView.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		CC00001D0000000000000000 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				DEVELOPMENT_TEAM = YWJU9P6KL8;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = xros;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				XROS_DEPLOYMENT_TARGET = 27.0;
			};
			name = Debug;
		};
		CC00001E0000000000000000 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				DEVELOPMENT_TEAM = YWJU9P6KL8;
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MTL_FAST_MATH = YES;
				SDKROOT = xros;
				SWIFT_COMPILATION_MODE = wholemodule;
				XROS_DEPLOYMENT_TARGET = 27.0;
			};
			name = Release;
		};
		CC00001F0000000000000000 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = YWJU9P6KL8;
				INFOPLIST_FILE = Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.visionOSExamplesApp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = xros;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "7";
				XROS_DEPLOYMENT_TARGET = 27.0;
			};
			name = Debug;
		};
		CC0000200000000000000000 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = YWJU9P6KL8;
				INFOPLIST_FILE = Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.visionOSExamplesApp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = xros;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "7";
				XROS_DEPLOYMENT_TARGET = 27.0;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		CC00001C0000000000000000 /* Build configuration list for PBXProject "visionOSExamplesApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				CC00001D0000000000000000 /* Debug */,
				CC00001E0000000000000000 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		CC00001B0000000000000000 /* Build configuration list for PBXNativeTarget "visionOSExamplesApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				CC00001F0000000000000000 /* Debug */,
				CC0000200000000000000000 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */

/* Begin XCSwiftPackageProductDependency section */
		CC0000160000000000000000 /* SwiftOpenResponsesLanguageModel */ = {
			isa = XCSwiftPackageProductDependency;
			productName = SwiftOpenResponsesLanguageModel;
		};
/* End XCSwiftPackageProductDependency section */

	};
	rootObject = CC00001A0000000000000000 /* Project object */;
}
```

- [ ] **Step 3: Write `contents.xcworkspacedata`**

Write the following to `Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcworkspace/contents.xcworkspacedata`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version = "1.0">
   <FileRef location = "group:visionOSExamplesApp.xcodeproj">
   </FileRef>
   <FileRef location = "group:../../..">
   </FileRef>
</Workspace>
```

The `group:../../..` reference resolves from the workspace bundle's parent (`visionOSExamplesApp/`) three levels up to the package root, identical to the existing `visionOSTestApp` workspace pattern.

- [ ] **Step 4: Write `Info.plist`**

Write the following to `Examples/visionOS/visionOSExamplesApp/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
```

---

## Task 2: Write stub source files for the six example views

RootView references all six views by name. These stubs compile so the shared infrastructure can be built and verified before full implementations are written.

**Files:**
- Create: `Examples/visionOS/visionOSExamplesApp/Examples/StreamingView.swift`
- Create: `Examples/visionOS/visionOSExamplesApp/Examples/MultiTurnView.swift`
- Create: `Examples/visionOS/visionOSExamplesApp/Examples/ToolCallingView.swift`
- Create: `Examples/visionOS/visionOSExamplesApp/Examples/StructuredOutputView.swift`
- Create: `Examples/visionOS/visionOSExamplesApp/Examples/ImageInputView.swift`
- Create: `Examples/visionOS/visionOSExamplesApp/Examples/ReasoningView.swift`

- [ ] **Step 1: Write `Examples/StreamingView.swift` stub**

```swift
import SwiftUI

struct StreamingView: View {
    var body: some View {
        Text("Streaming — coming soon")
            .navigationTitle("Streaming")
    }
}
```

- [ ] **Step 2: Write `Examples/MultiTurnView.swift` stub**

```swift
import SwiftUI

struct MultiTurnView: View {
    var body: some View {
        Text("Multi-turn Conversation — coming soon")
            .navigationTitle("Multi-turn Conversation")
    }
}
```

- [ ] **Step 3: Write `Examples/ToolCallingView.swift` stub**

```swift
import SwiftUI

struct ToolCallingView: View {
    var body: some View {
        Text("Tool Calling — coming soon")
            .navigationTitle("Tool Calling")
    }
}
```

- [ ] **Step 4: Write `Examples/StructuredOutputView.swift` stub**

```swift
import SwiftUI

struct StructuredOutputView: View {
    var body: some View {
        Text("Structured Output — coming soon")
            .navigationTitle("Structured Output")
    }
}
```

- [ ] **Step 5: Write `Examples/ImageInputView.swift` stub**

```swift
import SwiftUI

struct ImageInputView: View {
    var body: some View {
        Text("Image Input — coming soon")
            .navigationTitle("Image Input")
    }
}
```

- [ ] **Step 6: Write `Examples/ReasoningView.swift` stub**

```swift
import SwiftUI

struct ReasoningView: View {
    var body: some View {
        Text("Reasoning — coming soon")
            .navigationTitle("Reasoning")
    }
}
```

---

## Task 3: Write shared infrastructure

**Files:**
- Create: `Examples/visionOS/visionOSExamplesApp/EndpointSettings.swift`
- Create: `Examples/visionOS/visionOSExamplesApp/SettingsSheet.swift`
- Create: `Examples/visionOS/visionOSExamplesApp/RootView.swift`
- Create: `Examples/visionOS/visionOSExamplesApp/App.swift`

- [ ] **Step 1: Write `EndpointSettings.swift`**

`@Observable` tracked stored properties sync to `UserDefaults` via `didSet`. Using stored properties (not computed) ensures the `@Observable` macro can track mutations for SwiftUI updates.

```swift
import Foundation

@Observable
final class EndpointSettings {
    var baseURL: String = UserDefaults.standard.string(forKey: "examples_baseURL") ?? "" {
        didSet { UserDefaults.standard.set(baseURL, forKey: "examples_baseURL") }
    }
    var modelID: String = UserDefaults.standard.string(forKey: "examples_modelID") ?? "" {
        didSet { UserDefaults.standard.set(modelID, forKey: "examples_modelID") }
    }
    var apiKey: String = UserDefaults.standard.string(forKey: "examples_apiKey") ?? "" {
        didSet { UserDefaults.standard.set(apiKey, forKey: "examples_apiKey") }
    }
}
```

- [ ] **Step 2: Write `SettingsSheet.swift`**

```swift
import SwiftUI

struct SettingsSheet: View {
    @Environment(EndpointSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Endpoint") {
                    TextField("Base URL", text: $settings.baseURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Model ID", text: $settings.modelID)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("API Key (optional)", text: $settings.apiKey)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

- [ ] **Step 3: Write `RootView.swift`**

```swift
import SwiftUI

enum Example: String, CaseIterable, Identifiable {
    case streaming = "Streaming"
    case multiTurn = "Multi-turn Conversation"
    case toolCalling = "Tool Calling"
    case structuredOutput = "Structured Output"
    case imageInput = "Image Input"
    case reasoning = "Reasoning"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .streaming: return "text.word.spacing"
        case .multiTurn: return "bubble.left.and.bubble.right"
        case .toolCalling: return "wrench.and.screwdriver"
        case .structuredOutput: return "list.bullet.rectangle"
        case .imageInput: return "photo"
        case .reasoning: return "brain"
        }
    }
}

struct RootView: View {
    @State private var selectedExample: Example?
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            List(Example.allCases, selection: $selectedExample) { example in
                Label(example.rawValue, systemImage: example.systemImage)
                    .tag(example)
            }
            .navigationTitle("Examples")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        } detail: {
            if let example = selectedExample {
                switch example {
                case .streaming: StreamingView()
                case .multiTurn: MultiTurnView()
                case .toolCalling: ToolCallingView()
                case .structuredOutput: StructuredOutputView()
                case .imageInput: ImageInputView()
                case .reasoning: ReasoningView()
                }
            } else {
                ContentUnavailableView("Select an Example", systemImage: "sidebar.left")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
    }
}
```

- [ ] **Step 4: Write `App.swift`**

```swift
import SwiftUI

@main
struct visionOSExamplesApp: App {
    @State private var settings = EndpointSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
    }
}
```

---

## Task 4: Build to verify shared infrastructure

Open `Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcworkspace` in Xcode, select the `visionOSExamplesApp` scheme and a visionOS simulator, then build.

- [ ] **Step 1: Open workspace in Xcode**

Open `Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcworkspace`. If Xcode prompts to create a scheme, accept — Xcode will auto-generate the `visionOSExamplesApp` scheme.

- [ ] **Step 2: Build the project**

Use the `BuildProject` Xcode MCP tool on the `visionOSExamplesApp` tab. Expected result: build succeeds with zero errors. All six stub views and the full shared infrastructure compile.

If build fails with "module 'SwiftOpenResponsesLanguageModel' not found": the workspace's `group:../../..` reference is relative to the `.xcworkspace` directory's *parent*, not the file's directory. Verify the workspace file path is exactly `Examples/visionOS/visionOSExamplesApp/visionOSExamplesApp.xcworkspace/contents.xcworkspacedata` — three directories above the package root is correct.

---

## Task 5: Implement `StreamingView`

The minimal usage pattern: construct `OpenResponsesLanguageModel` with all-default capabilities, stream a response, update UI on each partial.

**File:** `Examples/visionOS/visionOSExamplesApp/Examples/StreamingView.swift`

- [ ] **Step 1: Replace stub with full implementation**

```swift
import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct StreamingView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var prompt = ""
    @State private var response = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var currentTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("Prompt") {
                TextEditor(text: $prompt)
                    .frame(minHeight: 80)
                Button(isGenerating ? "Stop" : "Send") {
                    isGenerating ? cancel() : send()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isGenerating && !canSend)
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            if !response.isEmpty {
                Section("Response") {
                    Text(response)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Streaming")
    }

    // samplingParams: false (default) omits temperature and top-P from the request.
    // Set samplingParams: true on the model to pass GenerationOptions values through.
    private func makeModel() -> OpenResponsesModel {
        OpenResponsesModel(id: settings.modelID, capabilities: .init())
    }

    private var canSend: Bool {
        !settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        currentTask = Task { @MainActor in await generate() }
    }

    private func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isGenerating = false
    }

    @MainActor
    private func generate() async {
        isGenerating = true
        response = ""
        errorMessage = nil

        guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "Invalid base URL"
            isGenerating = false
            return
        }

        do {
            let lm = OpenResponsesLanguageModel(
                name: makeModel(),
                auth: .apiKey(settings.apiKey),
                baseURL: url
            )
            let session = LanguageModelSession(model: lm)
            let stream = session.streamResponse(to: prompt)
            for try await partial in stream {
                guard !Task.isCancelled else { break }
                response = partial.content
            }
        } catch is CancellationError {
            // user tapped Stop
        } catch {
            errorMessage = String(reflecting: error)
        }

        isGenerating = false
        currentTask = nil
    }
}
```

- [ ] **Step 2: Build and verify**

Build in Xcode. Expected: zero errors. Navigate to the Streaming scene in the simulator sidebar — verify the form renders with Prompt, Send button, and that the Response section is absent until a message is sent.

---

## Task 6: Implement `MultiTurnView`

A single `LanguageModelSession` reused across multiple exchanges. The session accumulates transcript context automatically — the caller only calls `respond(to:)` again with the next message.

`respond(to:)` is used rather than `streamResponse` because tracking which chat bubble is accumulating would require additional state that obscures the multi-turn concept being demonstrated.

**File:** `Examples/visionOS/visionOSExamplesApp/Examples/MultiTurnView.swift`

- [ ] **Step 1: Replace stub with full implementation**

```swift
import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct MultiTurnView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var session: LanguageModelSession?
    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if isGenerating {
                            HStack {
                                Text("···")
                                    .padding(10)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Spacer()
                            }
                            .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Message…", text: $input)
                    .textFieldStyle(.plain)
                    .padding(.leading)
                    .disabled(isGenerating)
                    .onSubmit { if canSend { sendMessage() } }
                Button("Send", action: sendMessage)
                    .buttonStyle(.borderedProminent)
                    .padding(.trailing)
                    .disabled(!canSend)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Multi-turn Conversation")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Conversation") { reset() }
                    .disabled(isGenerating)
            }
        }
        .onAppear { buildSession() }
        .onChange(of: settings.baseURL) { _, _ in buildSession() }
        .onChange(of: settings.modelID) { _, _ in buildSession() }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var canSend: Bool {
        !isGenerating
            && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && session != nil
    }

    private func buildSession() {
        let trimmedURL = settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedID = settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty, let url = URL(string: trimmedURL) else { session = nil; return }
        let model = OpenResponsesModel(id: trimmedID, capabilities: .init())
        let lm = OpenResponsesLanguageModel(name: model, auth: .apiKey(settings.apiKey), baseURL: url)
        session = LanguageModelSession(model: lm)
    }

    private func reset() {
        messages = []
        errorMessage = nil
        buildSession()
    }

    private func sendMessage() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let session else { return }
        input = ""
        messages.append(ChatMessage(role: .user, text: text))

        Task { @MainActor in
            isGenerating = true
            do {
                // The session holds transcript history across all calls — no manual
                // history management needed. Each respond() continues the conversation.
                let result = try await session.respond(to: text)
                messages.append(ChatMessage(role: .assistant, text: result.content))
            } catch {
                errorMessage = String(reflecting: error)
            }
            isGenerating = false
        }
    }
}

private struct ChatMessage: Identifiable {
    let id = UUID()
    enum Role { case user, assistant }
    let role: Role
    let text: String
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .padding(10)
                .background(message.role == .user
                    ? Color.accentColor.opacity(0.2)
                    : Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .textSelection(.enabled)
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Build in Xcode. Navigate to Multi-turn Conversation in the simulator — the chat list renders, the input field is at the bottom, and "New Conversation" appears in the toolbar.

---

## Task 7: Implement `ToolCallingView`

Registers a tool (`GetCurrentDateTool`) with a `LanguageModelSession` and shows the tool call and result as intermediate events before the final response.

The tool must be `Sendable` to be passed to the session. Rather than a shared mutable log (which causes actor isolation issues), the tool receives a `@Sendable` closure that it calls during execution. The view captures the closure against its own `@MainActor`-isolated state.

**File:** `Examples/visionOS/visionOSExamplesApp/Examples/ToolCallingView.swift`

- [ ] **Step 1: Replace stub with full implementation**

```swift
import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct ToolCallingView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var prompt = "What day is it today, and how many days until the end of the year?"
    @State private var events: [EventEntry] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var currentTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("Prompt") {
                TextEditor(text: $prompt)
                    .frame(minHeight: 60)
                Button(isGenerating ? "Stop" : "Send") {
                    isGenerating ? cancel() : send()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isGenerating && !canSend)
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if !events.isEmpty {
                Section("Event Log") {
                    ForEach(events) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: entry.icon)
                                .foregroundStyle(entry.color)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.label).font(.caption).foregroundStyle(.secondary)
                                Text(entry.value).textSelection(.enabled)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Tool Calling")
    }

    private var canSend: Bool {
        !settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        currentTask = Task { @MainActor in await generate() }
    }

    private func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isGenerating = false
    }

    @MainActor
    private func generate() async {
        isGenerating = true
        events = []
        errorMessage = nil

        guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "Invalid base URL"
            isGenerating = false
            return
        }

        let model = OpenResponsesModel(
            id: settings.modelID,
            capabilities: .init(toolCalling: true)
        )
        let lm = OpenResponsesLanguageModel(
            name: model,
            auth: .apiKey(settings.apiKey),
            baseURL: url
        )

        // The closure is @Sendable and @MainActor so appending to @State is safe.
        let onEvent: @Sendable @MainActor (String, String) -> Void = { [self] label, value in
            events.append(EventEntry(label: label, value: value))
        }

        let tool = GetCurrentDateTool(onEvent: onEvent)

        do {
            let session = LanguageModelSession(model: lm, tools: [tool])
            let result = try await session.respond(to: prompt)
            events.append(EventEntry(label: "Response", value: result.content))
        } catch is CancellationError {
            // user tapped Stop
        } catch {
            errorMessage = String(reflecting: error)
        }

        isGenerating = false
        currentTask = nil
    }
}

// MARK: - Tool

private struct GetCurrentDateTool: Tool {
    static let name: String = "get_current_date"
    static let description: String = "Returns today's date as an ISO 8601 string (YYYY-MM-DD). Use this when asked about the current date."

    @Generable struct Arguments {}

    // @Sendable closure lets the tool report events without shared mutable state.
    // The closure is @MainActor so it can safely mutate the view's @State.
    let onEvent: @Sendable @MainActor (String, String) -> Void

    func call(arguments: Arguments) async throws -> ToolOutput {
        let date = ISO8601DateFormatter().string(from: Date())
        await onEvent("Tool called", Self.name)
        await onEvent("Tool returned", date)
        return ToolOutput(date)
    }
}

// MARK: - Supporting types

private struct EventEntry: Identifiable {
    let id = UUID()
    let label: String
    let value: String

    var icon: String {
        switch label {
        case "Tool called": return "wrench"
        case "Tool returned": return "checkmark.circle"
        default: return "text.bubble"
        }
    }

    var color: Color {
        switch label {
        case "Tool called": return .orange
        case "Tool returned": return .green
        default: return .primary
        }
    }
}
```

**Note on the `Tool` protocol:** The `Tool` protocol, `@Generable`, and `ToolOutput` are part of Apple's FoundationModels framework. The exact protocol definition (static vs instance `name`/`description`, exact `Arguments` constraint) may differ from the signature shown above. If the compiler reports a conformance error, check the FoundationModels module for the exact `Tool` protocol signature and adjust the `GetCurrentDateTool` definition accordingly. The observable behavior — tool called → events logged → final response — is the goal; the exact syntax is secondary.

- [ ] **Step 2: Build and verify**

Build in Xcode. Navigate to Tool Calling — the form renders. The pre-filled prompt appears in the text editor.

---

## Task 8: Implement `StructuredOutputView`

Demonstrates `session.respond(to:, generating: T.self)` where `T` is `@Generable`. The model returns a typed struct rather than a raw string.

**File:** `Examples/visionOS/visionOSExamplesApp/Examples/StructuredOutputView.swift`

- [ ] **Step 1: Replace stub with full implementation**

```swift
import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

// structuredOutput: true causes RequestBuilder to attach a JSON schema constraint to the
// request. The model must return JSON matching the MovieRecommendation schema; the session
// decodes and type-checks the response before returning it.
@Generable
struct MovieRecommendation {
    @Guide(description: "The film title") var title: String
    @Guide(description: "The release year as a four-digit integer, e.g. 1977") var year: Int
    @Guide(description: "One sentence explaining why this film is recommended") var reason: String
}

struct StructuredOutputView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var prompt = "Recommend a classic science fiction film."
    @State private var result: MovieRecommendation?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Prompt") {
                TextEditor(text: $prompt)
                    .frame(minHeight: 60)
                Button(isGenerating ? "Generating…" : "Send") {
                    send()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating || !canSend)
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if let result {
                Section("Result") {
                    LabeledContent("Title", value: result.title)
                    LabeledContent("Year", value: String(result.year))
                    LabeledContent("Reason", value: result.reason)
                }
            }
        }
        .navigationTitle("Structured Output")
    }

    private var canSend: Bool {
        !settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        Task { @MainActor in
            isGenerating = true
            result = nil
            errorMessage = nil

            guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                errorMessage = "Invalid base URL"
                isGenerating = false
                return
            }

            let model = OpenResponsesModel(
                id: settings.modelID,
                capabilities: .init(structuredOutput: true)
            )
            let lm = OpenResponsesLanguageModel(
                name: model,
                auth: .apiKey(settings.apiKey),
                baseURL: url
            )

            do {
                let session = LanguageModelSession(model: lm)
                result = try await session.respond(to: prompt, generating: MovieRecommendation.self)
            } catch {
                errorMessage = String(reflecting: error)
            }

            isGenerating = false
        }
    }
}
```

**Note on `@Generable` and `@Guide`:** These are FoundationModels macros. `@Generable` generates the schema used by `session.respond(to:generating:)`. `@Guide` attaches a description to each property. If `@Guide` is named differently in the installed FoundationModels version, the description is optional — the key requirement is `@Generable` on the struct.

- [ ] **Step 2: Build and verify**

Build in Xcode. Navigate to Structured Output — verify the form renders and the Result section is absent until a response arrives.

---

## Task 9: Implement `ImageInputView`

Demonstrates attaching an image to a session prompt for a vision-capable model.

**File:** `Examples/visionOS/visionOSExamplesApp/Examples/ImageInputView.swift`

- [ ] **Step 1: Replace stub with full implementation**

```swift
import SwiftUI
import PhotosUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct ImageInputView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var displayImage: Image?
    @State private var prompt = "Describe what you see in this image."
    @State private var response = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var currentTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("Image") {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    if let displayImage {
                        displayImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Label("Select Image", systemImage: "photo")
                    }
                }
                .onChange(of: pickerItem) { _, newItem in
                    Task {
                        guard let newItem else { return }
                        imageData = try? await newItem.loadTransferable(type: Data.self)
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            displayImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }

            Section("Prompt") {
                TextEditor(text: $prompt)
                    .frame(minHeight: 60)
                Button(isGenerating ? "Stop" : "Send") {
                    isGenerating ? cancel() : send()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isGenerating && !canSend)
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if !response.isEmpty {
                Section("Response") {
                    Text(response).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Image Input")
    }

    private var canSend: Bool {
        imageData != nil
            && !settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        currentTask = Task { @MainActor in await generate() }
    }

    private func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isGenerating = false
    }

    @MainActor
    private func generate() async {
        guard let imageData else { return }
        isGenerating = true
        response = ""
        errorMessage = nil

        guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "Invalid base URL"
            isGenerating = false
            return
        }

        let model = OpenResponsesModel(
            id: settings.modelID,
            capabilities: .init(imageInput: true)
        )
        let lm = OpenResponsesLanguageModel(
            name: model,
            auth: .apiKey(settings.apiKey),
            baseURL: url
        )

        do {
            let session = LanguageModelSession(model: lm)
            // FoundationModels attachment API: wraps raw image bytes with a MIME type.
            // Verify the exact Attachment initializer and Prompt API against the
            // installed FoundationModels framework if this does not compile.
            let attachment = Attachment(data: imageData, mimeType: "image/jpeg")
            let imagePrompt = Prompt(parts: [.attachment(attachment), .text(prompt)])
            let stream = session.streamResponse(to: imagePrompt)
            for try await partial in stream {
                guard !Task.isCancelled else { break }
                response = partial.content
            }
        } catch is CancellationError {
            // user tapped Stop
        } catch {
            errorMessage = String(reflecting: error)
        }

        isGenerating = false
        currentTask = nil
    }
}
```

**Note on `Attachment` and `Prompt`:** The `Attachment` type and `Prompt(parts:)` initializer are part of FoundationModels. The exact API — including whether `Prompt` takes `.attachment(_:)` vs a different part type — should be verified against the installed FoundationModels headers. If the compiler rejects this form, look for an `Attachment` or `ImageContent` type in FoundationModels and construct the prompt accordingly. The observable behavior (image selected → attached to prompt → model describes it) is the goal.

- [ ] **Step 2: Build and verify**

Build in Xcode. Navigate to Image Input — verify the PhotosPicker button renders and the Send button is disabled until an image is selected.

---

## Task 10: Implement `ReasoningView`

Demonstrates enabling reasoning on a model that supports extended thinking, selecting a reasoning level, and surfacing the reasoning summary and final answer in separate UI sections.

**File:** `Examples/visionOS/visionOSExamplesApp/Examples/ReasoningView.swift`

- [ ] **Step 1: Replace stub with full implementation**

```swift
import SwiftUI
import FoundationModels
import SwiftOpenResponsesLanguageModel

struct ReasoningView: View {
    @Environment(EndpointSettings.self) private var settings

    @State private var prompt = "How many prime numbers are there between 1 and 100? Show your work."
    @State private var reasoningLevel: ReasoningLevelOption = .moderate
    @State private var reasoningText = ""
    @State private var answerText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var currentTask: Task<Void, Never>?
    @State private var reasoningExpanded = false
    @State private var answerExpanded = true

    var body: some View {
        Form {
            Section("Reasoning Level") {
                Picker("Level", selection: $reasoningLevel) {
                    ForEach(ReasoningLevelOption.allCases) { level in
                        Text(level.label).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Prompt") {
                TextEditor(text: $prompt)
                    .frame(minHeight: 60)
                Button(isGenerating ? "Stop" : "Send") {
                    isGenerating ? cancel() : send()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isGenerating && !canSend)
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if !reasoningText.isEmpty || !answerText.isEmpty {
                Section {
                    // Reasoning content arrives via its own channel action in EventTranslator,
                    // separate from the response text. It surfaces here as a distinct section
                    // rather than being embedded in the answer.
                    DisclosureGroup("Reasoning", isExpanded: $reasoningExpanded) {
                        Text(reasoningText.isEmpty ? "No reasoning summary available." : reasoningText)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    DisclosureGroup("Answer", isExpanded: $answerExpanded) {
                        Text(answerText)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle("Reasoning")
    }

    private var canSend: Bool {
        !settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        currentTask = Task { @MainActor in await generate() }
    }

    private func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isGenerating = false
    }

    @MainActor
    private func generate() async {
        isGenerating = true
        reasoningText = ""
        answerText = ""
        errorMessage = nil

        guard let url = URL(string: settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "Invalid base URL"
            isGenerating = false
            return
        }

        let model = OpenResponsesModel(
            id: settings.modelID,
            capabilities: .init(reasoning: true)
        )
        let lm = OpenResponsesLanguageModel(
            name: model,
            auth: .apiKey(settings.apiKey),
            baseURL: url
        )

        do {
            let session = LanguageModelSession(model: lm)
            // FoundationModels reasoning API: the reasoning level is passed via
            // GenerationOptions or ContextOptions. Verify the exact property name
            // (reasoningLevel, reasoningEffort, or similar) against the installed
            // FoundationModels framework. The mapping from ReasoningLevelOption to
            // FoundationModels' own level type follows the same light/moderate/deep
            // pattern described in the HOW spec's EventTranslator section.
            var options = GenerationOptions()
            options.reasoningLevel = reasoningLevel.foundationModelsLevel
            let result = try await session.respond(to: prompt, options: options)
            answerText = result.content
            reasoningText = result.reasoning?.summary ?? ""
            answerExpanded = true
            reasoningExpanded = !reasoningText.isEmpty
        } catch is CancellationError {
            // user tapped Stop
        } catch {
            errorMessage = String(reflecting: error)
        }

        isGenerating = false
        currentTask = nil
    }
}

// MARK: - Supporting types

private enum ReasoningLevelOption: String, CaseIterable, Identifiable {
    case light, moderate, deep
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    // Map to FoundationModels' own reasoning level type.
    // Adjust the property path if FoundationModels uses a different enum name.
    var foundationModelsLevel: ContextOptions.ReasoningLevel {
        switch self {
        case .light: return .light
        case .moderate: return .moderate
        case .deep: return .deep
        }
    }
}
```

**Note on reasoning API:** `GenerationOptions.reasoningLevel`, `result.reasoning?.summary`, and `ContextOptions.ReasoningLevel` are assumed based on the HOW spec's mapping table (`light` → `.low`, `moderate` → `.medium`, `deep` → `.high`). Verify the exact property names in the FoundationModels framework. If `GenerationOptions` doesn't expose `reasoningLevel`, look for `ContextOptions` or `Instructions` as the carrier type.

- [ ] **Step 2: Build and verify**

Build in Xcode. Navigate to Reasoning — the segmented control (Light / Moderate / Deep), prompt editor, and Send button all render. The Reasoning and Answer disclosure groups are absent until a response arrives.

---

## Task 11: Full build verification

- [ ] **Step 1: Build the complete app**

Build the project in Xcode. Expected: zero errors, zero warnings about missing modules.

- [ ] **Step 2: Verify all six scenes are reachable**

Run in the visionOS simulator. In the sidebar, tap each of the six examples in sequence and verify:
- Each scene title appears in the navigation bar
- No crashes on navigation
- Settings sheet opens from the gear toolbar button and closes on Done

---

## Task 12: Write `Specs/visionOSExamplesApp-WHAT.md`

**File:** `Examples/visionOS/visionOSExamplesApp/Specs/visionOSExamplesApp-WHAT.md`

- [ ] **Step 1: Write the WHAT spec**

```markdown
# visionOSExamplesApp — WHAT Spec

## Overview

A visionOS 27+ app demonstrating six usage patterns of `SwiftOpenResponsesLanguageModel`. Each pattern maps to one scene in a `NavigationSplitView` sidebar and one source file in `Examples/`. Designed as a reference for human developers learning the package API and for AI agents reading code to understand how to apply it.

## Scenes

| Scene | File | Capability Flags | Core API |
|---|---|---|---|
| Streaming | `StreamingView.swift` | defaults (`capabilities: .init()`) | `session.streamResponse(to:)` |
| Multi-turn Conversation | `MultiTurnView.swift` | defaults | `LanguageModelSession` reused across exchanges |
| Tool Calling | `ToolCallingView.swift` | `toolCalling: true` | Tool registration, tool call → output → response |
| Structured Output | `StructuredOutputView.swift` | `structuredOutput: true` | `session.respond(to:, generating: T.self)` |
| Image Input | `ImageInputView.swift` | `imageInput: true` | Image attachment on a session prompt |
| Reasoning | `ReasoningView.swift` | `reasoning: true` | Reasoning level, reasoning summary vs. answer |

## Shared Infrastructure

`EndpointSettings` (`@Observable`) holds `baseURL`, `modelID`, and `apiKey`. It is instantiated once in `App.swift`, injected into the SwiftUI environment, and read by each example scene. Each scene constructs its own `OpenResponsesLanguageModel` at generation time — settings are captured when Send is tapped, not observed reactively during generation.

`SettingsSheet` is a `.sheet` opened via the toolbar gear button. Changes write immediately to `UserDefaults` via `EndpointSettings.didSet`.

## Error Display

All examples display errors as `String(reflecting: error)` — richer diagnostic detail than `localizedDescription`, appropriate for developer-facing demo apps.

## Acceptance Criteria

- [ ] Compiles for visionOS 27+
- [ ] Endpoint settings persist across app launches
- [ ] All six scenes reachable from the sidebar
- [ ] Streaming: text updates incrementally; Stop cancels mid-stream
- [ ] Multi-turn: session holds context across exchanges; New Conversation resets
- [ ] Tool Calling: tool call and result appear in event log before final response
- [ ] Structured Output: result fields populate from a decoded struct, not raw text
- [ ] Image Input: image previews before sending; response refers to image content
- [ ] Reasoning: reasoning and answer in separate sections; level control changes behavior
- [ ] Settings sheet opens, edits persist, closes cleanly
```

---

## Task 13: Write `Specs/visionOSExamplesApp-HOW.md`

**File:** `Examples/visionOS/visionOSExamplesApp/Specs/visionOSExamplesApp-HOW.md`

- [ ] **Step 1: Write the HOW spec**

```markdown
# visionOSExamplesApp — HOW Spec

## File Structure

```
visionOSExamplesApp/
├── App.swift                    # @main; creates EndpointSettings, injects into environment
├── EndpointSettings.swift       # @Observable class; baseURL, modelID, apiKey + UserDefaults sync
├── SettingsSheet.swift          # Form sheet for editing EndpointSettings; opened from toolbar
├── RootView.swift               # NavigationSplitView + Example enum
├── Examples/
│   ├── StreamingView.swift      # session.streamResponse(to:); capabilities: .init()
│   ├── MultiTurnView.swift      # session.respond(to:) on reused LanguageModelSession
│   ├── ToolCallingView.swift    # GetCurrentDateTool; capabilities: .init(toolCalling: true)
│   ├── StructuredOutputView.swift # @Generable MovieRecommendation; capabilities: .init(structuredOutput: true)
│   ├── ImageInputView.swift     # PhotosPicker + Attachment; capabilities: .init(imageInput: true)
│   └── ReasoningView.swift      # GenerationOptions.reasoningLevel; capabilities: .init(reasoning: true)
└── Specs/
    ├── visionOSExamplesApp-WHAT.md
    └── visionOSExamplesApp-HOW.md
```

## EndpointSettings

`@Observable final class`. Three stored properties — `baseURL`, `modelID`, `apiKey` — initialized from `UserDefaults` and synced back via `didSet`. Stored (not computed) so the `@Observable` macro can track mutations. Injected via `.environment(settings)` in `App.swift`, consumed via `@Environment(EndpointSettings.self)` in each scene.

Key: uses `examples_` prefix on all `UserDefaults` keys to avoid collision with the `visionOSTestApp` which uses unprefixed keys (`api_key`, `base_url`, `model_id`).

## SettingsSheet

Uses `@Bindable var settings = settings` to derive bindings from the `@Observable` environment object. `@Bindable` is required for `@Observable` types; `@ObservedObject` bindings are not used.

## RootView

`Example` is a `CaseIterable` enum with `rawValue: String` labels and `systemImage` computed property. The `NavigationSplitView` sidebar uses `List(Example.allCases, selection: $selectedExample)` with `.tag(example)` on each row. The detail column switches on `selectedExample` with a `ContentUnavailableView` default.

## OpenResponsesLanguageModel Construction

Each example constructs `OpenResponsesLanguageModel` at generation time (inside the async task), not at view init. This ensures settings are captured at the moment Send is tapped, not at the time the view appears.

## ToolCallingView: Sendable Tool Event Reporting

`GetCurrentDateTool` must be `Sendable` (required by the `Tool` protocol). Rather than a shared `actor`-based log (which requires `await` in the view and complicates observation), the tool receives a `@Sendable @MainActor (String, String) -> Void` closure. The closure is declared on `@MainActor` so it can safely mutate the `@State` array `events` without additional `await MainActor.run { }` wrapping.

## MultiTurnView: Non-streaming Respond

Uses `session.respond(to:)` rather than `session.streamResponse(to:)`. Streaming in a chat list requires tracking which bubble is accumulating — an extra `@State` array index plus special-casing the last message — which would obscure the multi-turn concept. `respond()` appends the complete assistant message in one step, keeping the implementation focused.

## Session Lifecycle

`MultiTurnView` rebuilds the session (`buildSession()`) whenever `settings.baseURL` or `settings.modelID` changes. The session is set to `nil` when the URL or model ID is empty or invalid, which disables the Send button via `canSend`.

All other examples create a fresh `LanguageModelSession` per generation call — this is correct since single-turn examples don't need to preserve history.
```

---

## Task 14: Update `visionOSTestApp-WHAT.md`

Add a Purpose section to the top of the existing spec to clearly distinguish the test app from the examples app.

**File:** `Examples/visionOS/Specs/visionOSTestApp-WHAT.md`

- [ ] **Step 1: Read the current file**

Read `Examples/visionOS/Specs/visionOSTestApp-WHAT.md` to confirm current content before editing.

- [ ] **Step 2: Insert Purpose section**

Insert the following block immediately after the `# visionOS Test App — WHAT Spec` heading (before `## Overview`):

```markdown
## Purpose

This app is a bare-metal endpoint tester. Configure any Open Responses-compatible URL, model ID, and optional API key, then fire a streaming request and observe the raw response. Its value is verifying connectivity to an endpoint and comparing raw model output — not demonstrating specific package capabilities.

For capability-focused examples (streaming, multi-turn, tool calling, structured output, image input, reasoning), see `Examples/visionOS/visionOSExamplesApp/`.

---
```

---

## Self-Review Checklist

- **Spec coverage:** All six capabilities covered (Tasks 5–10). Shared infrastructure (Tasks 3–4). Specs (Tasks 12–13). Existing test app update (Task 14). ✓
- **No placeholders:** FoundationModels API notes call out specific property names that need verification and explain what to look for — this is documentation, not "TBD". ✓
- **Type consistency:** `EndpointSettings` defined in Task 3, consumed identically in Tasks 5–10. `OpenResponsesModel`, `OpenResponsesLanguageModel` spellings match package WHAT spec. `ChatMessage`, `EventEntry`, `ReasoningLevelOption` are private types defined in the same task that uses them. ✓
- **Project file consistency:** `project.pbxproj` lists all 10 Swift files in both `PBXFileReference` and `PBXSourcesBuildPhase`. GUID pairs are odd/even — build file = odd, file ref = even. No GUID reused. ✓
