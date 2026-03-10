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
    /// Claude Code fields: disable-model-invocation, user-invocable, model, context, agent, argument-hint, hooks.
    /// Codex fields are stored in `codexConfiguration`.
    public var extensions: [String: SkillValue]

    // MARK: - Supporting files

    /// Files bundled with the skill (scripts/, references/, assets/).
    public var supportingFiles: [SupportingFile]

    // MARK: - OpenAI Codex configuration

    /// Configuration parsed from agents/openai.yaml when present.
    public var codexConfiguration: CodexConfiguration?

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
        codexConfiguration: CodexConfiguration? = nil
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
        self.codexConfiguration = codexConfiguration
    }
}
