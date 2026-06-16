import Foundation

/// Authentication strategy for connecting to an Open Responses endpoint.
///
/// - Important: With ``apiKey(_:)``, no custom headers are sent.
///   With ``proxied(headers:)``, no `Authorization` header is sent — the proxy must handle auth.
public enum AuthMode: Sendable, Hashable {
	/// Authenticate with a Bearer token sent in the `Authorization` header.
	///
	/// - Parameter apiKey: The API key string. Pass an empty string (`""`) for LM Studio,
	///   which substitutes `"lm-studio"` automatically.
	case apiKey(String)

	/// Delegate authentication to an upstream proxy by forwarding custom headers.
	///
	/// Use this for enterprise API gateways, mutual-TLS proxies, or any setup where
	/// the proxy handles authentication and the client only needs to pass identity headers.
	///
	/// - Parameter headers: Headers forwarded with every request (e.g., `["X-Forwarded-User": "alice"]`).
	case proxied(headers: [String: String])
}
