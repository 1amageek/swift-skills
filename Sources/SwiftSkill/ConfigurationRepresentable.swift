import Foundation

/// A type that can be represented as a configuration within a skill.
///
/// Conform to this protocol to define a provider-specific configuration format.
/// ``Skill`` stores configurations as opaque data keyed by the conforming type name.
/// File paths for I/O are managed externally via ``ConfigurationFileMapping``.
///
/// ```swift
/// struct CodexConfiguration: ConfigurationRepresentable {
///     init(configurationData: Data) throws { ... }
///     func configurationData() throws -> Data { ... }
/// }
/// ```
public protocol ConfigurationRepresentable: Sendable, Hashable, Codable {

    /// Create an instance from raw file data.
    init(configurationData: Data) throws

    /// Serialize to raw file data.
    func configurationData() throws -> Data
}
