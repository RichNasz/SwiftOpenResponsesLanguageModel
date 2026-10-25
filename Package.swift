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
		.package(url: "https://github.com/RichNasz/SwiftOpenResponsesDSL.git", revision: "728851b604fb7be9d2cdd033682f714cb3bd62be"),
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
		.testTarget(
			name: "IntegrationTests",
			dependencies: ["SwiftOpenResponsesLanguageModel"]
		),
	]
)
