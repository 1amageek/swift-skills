import Foundation

/// Maps a configuration type to its relative file path within a skill directory.
///
/// Used by ``SkillParser`` and ``SkillWriter`` to determine where configuration
/// files are read from and written to. The ``key`` identifies the configuration
/// in ``Skill/configurations`` and the ``relativePath`` specifies the file location.
///
/// ```swift
/// let mapping = ConfigurationFileMapping(
///     CodexConfiguration.self,
///     relativePath: "agents/openai.yaml"
/// )
/// ```
public struct ConfigurationFileMapping: Sendable, Hashable {

    /// Configuration key used in ``Skill/configurations``.
    /// Derived from the type name by default.
    public let key: String

    /// Relative file path within the skill directory.
    public let relativePath: String

    public init(key: String, relativePath: String) {
        self.key = key
        self.relativePath = relativePath
    }

    /// Create a mapping from a ``ConfigurationRepresentable`` type.
    ///
    /// The key is automatically derived from the type name.
    public init<T: ConfigurationRepresentable>(_ type: T.Type, relativePath: String) {
        self.key = String(describing: T.self)
        self.relativePath = relativePath
    }
}

extension ConfigurationFileMapping {

    /// Default mapping for ``CodexConfiguration``.
    public static let codex = ConfigurationFileMapping(
        CodexConfiguration.self,
        relativePath: "agents/openai.yaml"
    )

    /// Default set of configuration file mappings.
    public static let defaults: [ConfigurationFileMapping] = [.codex]
}
