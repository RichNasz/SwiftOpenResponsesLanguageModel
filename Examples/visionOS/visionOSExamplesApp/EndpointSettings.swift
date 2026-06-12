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
