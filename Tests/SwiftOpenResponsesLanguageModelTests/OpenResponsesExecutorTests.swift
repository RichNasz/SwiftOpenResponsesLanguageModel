import Testing
import Foundation
import FoundationModels
@testable import SwiftOpenResponsesLanguageModel

@Suite("OpenResponsesExecutor")
struct OpenResponsesExecutorTests {
	private func configuration(
		auth: AuthMode,
		timeout: TimeInterval = 60,
		headers: [String: String] = [:]
	) -> OpenResponsesExecutor.Configuration {
		OpenResponsesExecutor.Configuration(
			model: OpenResponsesModel(id: "test-model", capabilities: .init()),
			baseURL: URL(string: "http://192.0.2.1/v1/responses")!,
			authMode: auth,
			timeout: timeout,
			customHeaders: headers
		)
	}

	@Test func warmRequestUsesBearerAndCapsTimeout() {
		let request = OpenResponsesExecutor.warmRequest(
			configuration: configuration(auth: .apiKey("sk-test"), timeout: 60)
		)
		#expect(request.httpMethod == "GET")
		#expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
		#expect(request.timeoutInterval == 5)
	}

	@Test func emptyAPIKeyUsesLMStudio() {
		let request = OpenResponsesExecutor.warmRequest(
			configuration: configuration(auth: .apiKey(""))
		)
		#expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer lm-studio")
	}

	@Test func shortTimeoutIsKept() {
		let request = OpenResponsesExecutor.warmRequest(
			configuration: configuration(auth: .apiKey("sk-test"), timeout: 2)
		)
		#expect(request.timeoutInterval == 2)
	}

	@Test func proxiedForwardsHeadersWithoutAuthorization() {
		let request = OpenResponsesExecutor.warmRequest(
			configuration: configuration(
				auth: .proxied(headers: ["X-Token": "abc"]),
				headers: ["X-Token": "abc"]
			)
		)
		#expect(request.value(forHTTPHeaderField: "X-Token") == "abc")
		#expect(request.value(forHTTPHeaderField: "Authorization") == nil)
	}

	@Test func prewarmReturnsWithoutWaiting() throws {
		let config = configuration(auth: .apiKey("sk-test"), timeout: 30)
		let executor = try OpenResponsesExecutor(configuration: config)
		let model = OpenResponsesLanguageModel(
			name: config.model,
			auth: .apiKey("sk-test"),
			baseURL: config.baseURL,
			timeout: config.timeout
		)
		let start = ContinuousClock.now
		executor.prewarm(model: model, transcript: Transcript(entries: []))
		let elapsed = start.duration(to: .now)
		#expect(elapsed < .seconds(1))
	}
}
