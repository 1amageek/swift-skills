import Foundation
import YAML

/// OpenAI Codex-specific configuration parsed from `agents/openai.yaml`.
public struct CodexConfiguration: ConfigurationRepresentable {

    public init(configurationData data: Data) throws {
        // Try JSON first, fall back to YAML for backward compatibility
        if let decoded = try? JSONDecoder().decode(CodexConfiguration.self, from: data) {
            self = decoded
            return
        }
        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw SkillParserError.invalidEncoding
        }
        self = try Self.decodeFromYAML(yamlString)
    }

    public func configurationData() throws -> Data {
        try JSONEncoder().encode(self)
    }

    private static func decodeFromYAML(_ yaml: String) throws -> CodexConfiguration {
        guard let node = try compose(yaml: yaml),
              case .mapping(let root) = node else {
            throw SkillParserError.invalidFrontmatter("Expected YAML mapping for CodexConfiguration")
        }

        var config = CodexConfiguration()

        if case .mapping(let ifMap)? = root["interface"] {
            config.interface = Interface(
                displayName: ifMap["display_name"]?.scalar?.string,
                shortDescription: ifMap["short_description"]?.scalar?.string,
                iconSmall: ifMap["icon_small"]?.scalar?.string,
                iconLarge: ifMap["icon_large"]?.scalar?.string,
                brandColor: ifMap["brand_color"]?.scalar?.string,
                defaultPrompt: ifMap["default_prompt"]?.scalar?.string
            )
        }

        if case .mapping(let polMap)? = root["policy"] {
            if let val = polMap["allow_implicit_invocation"]?.scalar?.string {
                config.policy = Policy(
                    allowImplicitInvocation: val == "true" || val == "True" || val == "yes"
                )
            }
        }

        if case .mapping(let depMap)? = root["dependencies"] {
            if case .sequence(let toolSeq)? = depMap["tools"] {
                let tools: [ToolDependency] = toolSeq.compactMap { toolNode in
                    guard case .mapping(let tMap) = toolNode,
                          let type = tMap["type"]?.scalar?.string,
                          let value = tMap["value"]?.scalar?.string else { return nil }
                    return ToolDependency(
                        type: type,
                        value: value,
                        description: tMap["description"]?.scalar?.string,
                        transport: tMap["transport"]?.scalar?.string,
                        url: tMap["url"]?.scalar?.string
                    )
                }
                config.dependencies = Dependencies(tools: tools)
            }
        }

        return config
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
