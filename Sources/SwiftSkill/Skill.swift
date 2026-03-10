import Foundation

/// Represents an Agent Skill following the agentskills.io open standard.
///
/// Supports the common Agent Skills specification and provider-specific extensions
/// from Claude Code and OpenAI Codex via the `extensions` dictionary.
public struct Skill: Sendable, Hashable, Identifiable, Codable {
    public var id: String { name }

    // MARK: - Required (Agent Skills standard)

    /// Skill identifier. Max 64 characters, lowercase letters, numbers, and hyphens only.
    public var name: String

    /// What this skill does and when to use it. Max 1024 characters.
    public var description: String

    // MARK: - Optional (Agent Skills standard)

    /// License name or reference to a bundled license file.
    public var license: String?

    /// Environment requirements (intended product, system packages, network access, etc.).
    public var compatibility: String?

    /// Arbitrary key-value mapping for additional metadata.
    public var metadata: [String: String]?

    /// Pre-approved tools the skill may use.
    public var allowedTools: [String]?

    // MARK: - Body

    /// Markdown content with skill instructions.
    public var body: String

    // MARK: - Extensions

    /// Provider-specific frontmatter fields not covered by the standard.
    public var extensions: [String: SkillValue]

    // MARK: - Supporting files

    /// Files bundled with the skill (scripts/, references/, assets/).
    public var supportingFiles: [SupportingFile]

    // MARK: - Provider configurations

    /// Provider-specific configurations keyed by an opaque identifier.
    public var configurations: [String: Data]

    public init(
        name: String,
        description: String,
        license: String? = nil,
        compatibility: String? = nil,
        metadata: [String: String]? = nil,
        allowedTools: [String]? = nil,
        body: String = "",
        extensions: [String: SkillValue] = [:],
        supportingFiles: [SupportingFile] = [],
        configurations: [String: Data] = [:]
    ) {
        self.name = name
        self.description = description
        self.license = license
        self.compatibility = compatibility
        self.metadata = metadata
        self.allowedTools = allowedTools
        self.body = body
        self.extensions = extensions
        self.supportingFiles = supportingFiles
        self.configurations = configurations
    }

    // MARK: - Typed configuration access

    /// Retrieve a typed configuration.
    public func configuration<T: ConfigurationRepresentable>(_ type: T.Type) throws -> T? {
        let key = String(describing: T.self)
        guard let data = configurations[key] else { return nil }
        return try T(configurationData: data)
    }

    /// Store a typed configuration, replacing any existing one.
    public mutating func setConfiguration<T: ConfigurationRepresentable>(_ config: T?) throws {
        let key = String(describing: T.self)
        if let config {
            configurations[key] = try config.configurationData()
        } else {
            configurations.removeValue(forKey: key)
        }
    }

    /// Check whether a configuration of the given type is present.
    public func hasConfiguration<T: ConfigurationRepresentable>(_ type: T.Type) -> Bool {
        configurations[String(describing: T.self)] != nil
    }
}
