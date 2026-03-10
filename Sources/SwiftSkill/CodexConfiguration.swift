import Foundation
import Yams

/// OpenAI Codex-specific configuration parsed from `agents/openai.yaml`.
public struct CodexConfiguration: ConfigurationRepresentable {

    public init(configurationData data: Data) throws {
        guard let yaml = String(data: data, encoding: .utf8) else {
            throw SkillParserError.invalidEncoding
        }
        self = try YAMLDecoder().decode(CodexConfiguration.self, from: yaml)
    }

    public func configurationData() throws -> Data {
        let yaml = try YAMLEncoder().encode(self)
        return Data(yaml.utf8)
    }

    /// UI display settings for the skill.
    public struct Interface: Sendable, Hashable, Codable {
        public var displayName: String?
        public var shortDescription: String?
        public var iconSmall: String?
        public var iconLarge: String?
        public var brandColor: String?
        public var defaultPrompt: String?

        public init(
            displayName: String? = nil,
            shortDescription: String? = nil,
            iconSmall: String? = nil,
            iconLarge: String? = nil,
            brandColor: String? = nil,
            defaultPrompt: String? = nil
        ) {
            self.displayName = displayName
            self.shortDescription = shortDescription
            self.iconSmall = iconSmall
            self.iconLarge = iconLarge
            self.brandColor = brandColor
            self.defaultPrompt = defaultPrompt
        }

        private enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case shortDescription = "short_description"
            case iconSmall = "icon_small"
            case iconLarge = "icon_large"
            case brandColor = "brand_color"
            case defaultPrompt = "default_prompt"
        }
    }

    /// Invocation policy settings.
    public struct Policy: Sendable, Hashable, Codable {
        public var allowImplicitInvocation: Bool?

        public init(allowImplicitInvocation: Bool? = nil) {
            self.allowImplicitInvocation = allowImplicitInvocation
        }

        private enum CodingKeys: String, CodingKey {
            case allowImplicitInvocation = "allow_implicit_invocation"
        }
    }

    /// External tool dependency.
    public struct ToolDependency: Sendable, Hashable, Codable {
        public var type: String
        public var value: String
        public var description: String?
        public var transport: String?
        public var url: String?

        public init(
            type: String,
            value: String,
            description: String? = nil,
            transport: String? = nil,
            url: String? = nil
        ) {
            self.type = type
            self.value = value
            self.description = description
            self.transport = transport
            self.url = url
        }
    }

    /// Dependencies for the skill.
    public struct Dependencies: Sendable, Hashable, Codable {
        public var tools: [ToolDependency]?

        public init(tools: [ToolDependency]? = nil) {
            self.tools = tools
        }
    }

    public var interface: Interface?
    public var policy: Policy?
    public var dependencies: Dependencies?

    public init(
        interface: Interface? = nil,
        policy: Policy? = nil,
        dependencies: Dependencies? = nil
    ) {
        self.interface = interface
        self.policy = policy
        self.dependencies = dependencies
    }
}
