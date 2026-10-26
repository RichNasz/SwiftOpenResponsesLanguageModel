import Foundation

@Observable
final class EndpointSettings {
    var baseURL: String = UserDefaults.standard.string(forKey: "macos_examples_baseURL") ?? "" {
        didSet { UserDefaults.standard.set(baseURL, forKey: "macos_examples_baseURL") }
    }
    var modelID: String = UserDefaults.standard.string(forKey: "macos_examples_modelID") ?? "" {
        didSet { UserDefaults.standard.set(modelID, forKey: "macos_examples_modelID") }
    }
    var apiKey: String = UserDefaults.standard.string(forKey: "macos_examples_apiKey") ?? "" {
        didSet { UserDefaults.standard.set(apiKey, forKey: "macos_examples_apiKey") }
    }
}
