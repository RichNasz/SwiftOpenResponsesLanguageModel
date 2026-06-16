import Foundation

/// Identity and capability declaration for a remote language model.
///
/// Capability flags are declared at init time and gate which features are included in
/// requests. A missing flag means the feature is silently omitted — not errored.
///
/// - Important: Flags must match the model's actual abilities. Setting `reasoning: true`
///   for a model that doesn't support reasoning causes provider-side API errors.
public struct OpenResponsesModel: Sendable, Hashable {
	/// The model identifier sent to the provider (e.g., `"gpt-4o"`, `"claude-sonnet-4-20250514"`).
	public let id: String

	/// The set of features this model supports.
	public let capabilities: Capabilities

	/// Creates a model identity with explicit capability flags.
	///
	/// - Parameters:
	///   - id: The model identifier string sent to the provider in every request.
	///   - capabilities: Feature flags declaring what this model supports.
	public init(id: String, capabilities: Capabilities) {
		self.id = id
		self.capabilities = capabilities
	}

	/// Feature flags that gate which parts of the Open Responses request are populated.
	///
	/// Each flag controls whether the corresponding feature is included in outgoing requests.
	/// Disabled flags cause the feature to be silently omitted — the request is still valid,
	/// but the feature won't activate.
	public struct Capabilities: Sendable, Hashable {
		/// Whether temperature, `topP`, and sampling mode are sent. Default: `true`.
		public var samplingParams: Bool

		/// Whether reasoning effort is included in requests. Default: `false`.
		public var reasoning: Bool

		/// Whether JSON schema output format is applied for `@Generable` types. Default: `false`.
		public var structuredOutput: Bool

		/// Whether image attachments are encoded and sent in prompts. Default: `false`.
		public var imageInput: Bool

		/// Whether function/tool definitions are included in requests. Default: `true`.
		public var toolCalling: Bool

		/// Creates a capability set with explicit feature flags.
		///
		/// - Parameters:
		///   - samplingParams: Enable temperature and sampling parameters. Default: `true`.
		///   - reasoning: Enable extended thinking / reasoning effort. Default: `false`.
		///   - structuredOutput: Enable JSON schema-constrained output. Default: `false`.
		///   - imageInput: Enable image attachments in prompts. Default: `false`.
		///   - toolCalling: Enable function calling / tool use. Default: `true`.
		public init(
			samplingParams: Bool = true,
			reasoning: Bool = false,
			structuredOutput: Bool = false,
			imageInput: Bool = false,
			toolCalling: Bool = true
		) {
			self.samplingParams = samplingParams
			self.reasoning = reasoning
			self.structuredOutput = structuredOutput
			self.imageInput = imageInput
			self.toolCalling = toolCalling
		}
	}

}
