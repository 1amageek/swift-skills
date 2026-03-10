import Foundation
import Yams

/// Serializes `Skill` instances to SKILL.md format and writes skill directories.
public struct SkillWriter: Sendable {

    public init() {}

    // MARK: - Public API

    /// Generate SKILL.md content string from a skill.
    public func write(_ skill: Skill) throws -> String {
        let frontmatter = try buildFrontmatterYAML(skill)
        var result = "---\n"
        result += frontmatter
        result += "---\n"
        if !skill.body.isEmpty {
            result += "\n"
            result += skill.body
            if !skill.body.hasSuffix("\n") {
                result += "\n"
            }
        }
        return result
    }

    /// Write SKILL.md to a file.
    public func write(_ skill: Skill, to url: URL) throws {
        let content = try write(skill)
        do {
            try Data(content.utf8).write(to: url)
        } catch {
            throw SkillWriterError.fileWriteFailed(url, underlying: error)
        }
    }

    /// Write a full skill directory (SKILL.md + supporting files + optional codex config).
    public func writeDirectory(_ skill: Skill, to url: URL) throws {
        let fm = FileManager.default

        // Create the skill directory
        do {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw SkillWriterError.directoryCreationFailed(url)
        }

        // Write SKILL.md
        let skillMDURL = url.appending(path: "SKILL.md")
        try write(skill, to: skillMDURL)

        // Write supporting files
        for file in skill.supportingFiles {
            let fileURL = url.appending(path: file.relativePath)
            let parentDir = fileURL.deletingLastPathComponent()
            try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
            do {
                try file.content.write(to: fileURL)
            } catch {
                throw SkillWriterError.fileWriteFailed(fileURL, underlying: error)
            }
        }

        // Write Codex configuration if present
        if let codexConfig = skill.codexConfiguration {
            try writeCodexConfiguration(codexConfig, in: url)
        }
    }

    // MARK: - Frontmatter serialization

    private func buildFrontmatterYAML(_ skill: Skill) throws -> String {
        // Build ordered key-value pairs for deterministic output
        var pairs: [(String, Any)] = []

        pairs.append(("name", skill.name))
        pairs.append(("description", skill.description))

        if let license = skill.license {
            pairs.append(("license", license))
        }
        if let compatibility = skill.compatibility {
            pairs.append(("compatibility", compatibility))
        }
        if let metadata = skill.metadata, !metadata.isEmpty {
            pairs.append(("metadata", metadata))
        }
        if let allowedTools = skill.allowedTools, !allowedTools.isEmpty {
            pairs.append(("allowed-tools", allowedTools.joined(separator: ", ")))
        }

        // Extensions sorted by key for deterministic output
        for (key, value) in skill.extensions.sorted(by: { $0.key < $1.key }) {
            pairs.append((key, value.toAny))
        }

        // Build a Yams Node.Mapping to preserve key order
        let mappingPairs: [(Yams.Node, Yams.Node)] = try pairs.map { key, value in
            let keyNode = Yams.Node.scalar(.init(key))
            let valueNode = try yamlNode(from: value)
            return (keyNode, valueNode)
        }

        let node = Yams.Node.mapping(.init(mappingPairs))
        do {
            return try Yams.serialize(node: node)
        } catch {
            throw SkillWriterError.serializationFailed(error.localizedDescription)
        }
    }

    // MARK: - Yams Node conversion

    private func yamlNode(from value: Any) throws -> Yams.Node {
        switch value {
        case let s as String:
            return .scalar(.init(s))
        case let b as Bool:
            return .scalar(.init(b ? "true" : "false", Tag(.bool)))
        case let i as Int:
            return .scalar(.init(String(i), Tag(.int)))
        case let d as Double:
            return .scalar(.init(String(d), Tag(.float)))
        case let arr as [Any]:
            let nodes = try arr.map { try yamlNode(from: $0) }
            return .sequence(.init(nodes))
        case let dict as [String: Any]:
            let sortedPairs: [(Yams.Node, Yams.Node)] = try dict
                .sorted(by: { $0.key < $1.key })
                .map { key, val in
                    (.scalar(.init(key)), try yamlNode(from: val))
                }
            return .mapping(.init(sortedPairs))
        case is NSNull:
            return .scalar(.init("null", Tag(.null)))
        default:
            return .scalar(.init(String(describing: value)))
        }
    }

    // MARK: - Codex configuration

    private func writeCodexConfiguration(_ config: CodexConfiguration, in skillDirectory: URL) throws {
        let agentsDir = skillDirectory.appending(path: "agents")
        let fm = FileManager.default
        try fm.createDirectory(at: agentsDir, withIntermediateDirectories: true)

        let encoder = YAMLEncoder()
        let yamlString: String
        do {
            yamlString = try encoder.encode(config)
        } catch {
            throw SkillWriterError.serializationFailed("Codex configuration: \(error.localizedDescription)")
        }

        let url = agentsDir.appending(path: "openai.yaml")
        do {
            try Data(yamlString.utf8).write(to: url)
        } catch {
            throw SkillWriterError.fileWriteFailed(url, underlying: error)
        }
    }
}
