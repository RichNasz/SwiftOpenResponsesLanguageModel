import Testing
import Foundation
import CoreGraphics
import FoundationModels
import SwiftOpenResponsesLanguageModel

@Suite(
	"Image Input",
	.enabled(
		if: IntegrationTestConfiguration.isConfigured && IntegrationTestConfiguration.supportsImageInput,
		"Requires endpoint configuration and OPEN_RESPONSES_IMAGE_INPUT=true"
	)
)
struct ImageInputTests {

	@Test(.timeLimit(.minutes(3)))
	func describesAttachedImage() async throws {
		let session = IntegrationTestConfiguration.makeSession(
			capabilities: .init(imageInput: true)
		)
		let image = try solidImage(red: 1, green: 0, blue: 0)
		let response = try await session.respond {
			"Describe the attached image in a few words."
			Attachment(image)
		}
		#expect(!response.content.isEmpty)
	}

	private func solidImage(red: CGFloat, green: CGFloat, blue: CGFloat) throws -> CGImage {
		let width = 32
		let height = 32
		guard let context = CGContext(
			data: nil,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: 0,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		) else {
			throw ImageInputError.contextUnavailable
		}
		context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1))
		context.fill(CGRect(x: 0, y: 0, width: width, height: height))
		guard let image = context.makeImage() else {
			throw ImageInputError.contextUnavailable
		}
		return image
	}
}

private enum ImageInputError: Error {
	case contextUnavailable
}
