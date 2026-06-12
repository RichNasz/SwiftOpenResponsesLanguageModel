import Testing
import Foundation
import FoundationModels
@testable import SwiftOpenResponsesLanguageModel

@Suite("OpenResponsesModel")
struct OpenResponsesModelTests {

	@Test func defaultCapabilities() {
		let caps = OpenResponsesModel.Capabilities()
		#expect(caps.samplingParams == true)
		#expect(caps.toolCalling == true)
		#expect(caps.reasoning == false)
		#expect(caps.structuredOutput == false)
		#expect(caps.imageInput == false)
	}

	@Test func capabilityMappingAllEnabled() {
		let model = OpenResponsesModel(
			id: "test",
			capabilities: .init(
				samplingParams: true,
				reasoning: true,
				structuredOutput: true,
				imageInput: true,
				toolCalling: true
			)
		)
		let lm = OpenResponsesLanguageModel(
			name: model,
			auth: .apiKey("key"),
			baseURL: URL(string: "https://example.com")!
		)
		let caps = lm.capabilities
		#expect(caps.contains(.toolCalling))
		#expect(caps.contains(.vision))
		#expect(caps.contains(.reasoning))
		#expect(caps.contains(.guidedGeneration))
	}

	@Test func capabilityMappingAllDisabled() {
		let model = OpenResponsesModel(
			id: "test",
			capabilities: .init(
				samplingParams: false,
				reasoning: false,
				structuredOutput: false,
				imageInput: false,
				toolCalling: false
			)
		)
		let lm = OpenResponsesLanguageModel(
			name: model,
			auth: .apiKey("key"),
			baseURL: URL(string: "https://example.com")!
		)
		let caps = lm.capabilities
		#expect(!caps.contains(.toolCalling))
		#expect(!caps.contains(.vision))
		#expect(!caps.contains(.reasoning))
		#expect(!caps.contains(.guidedGeneration))
	}

	@Test func apiKeyAuthProducesEmptyHeaders() {
		let lm = OpenResponsesLanguageModel(
			name: .init(id: "test", capabilities: .init()),
			auth: .apiKey("key"),
			baseURL: URL(string: "https://example.com")!
		)
		let config = lm.executorConfiguration
		#expect(config.customHeaders.isEmpty)
	}

	@Test func proxiedAuthForwardsHeaders() {
		let headers = ["X-Token": "abc", "X-Org": "myorg"]
		let lm = OpenResponsesLanguageModel(
			name: .init(id: "test", capabilities: .init()),
			auth: .proxied(headers: headers),
			baseURL: URL(string: "https://example.com")!
		)
		let config = lm.executorConfiguration
		#expect(config.customHeaders == headers)
	}

	@Test func modelEquality() {
		let a = OpenResponsesModel(id: "gpt-4o", capabilities: .init(reasoning: true))
		let b = OpenResponsesModel(id: "gpt-4o", capabilities: .init(reasoning: true))
		#expect(a == b)
		#expect(a.hashValue == b.hashValue)
	}
}
