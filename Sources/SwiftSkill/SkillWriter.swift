import Foundation

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

    /// Default configuration file mappings for writing directories.
    public static let defaultConfigurationMappings: [ConfigurationFileMapping] = ConfigurationFileMapping.defaults

    /// Write a full skill directory (SKILL.md + supporting files + configurations).
    ///
    /// Configuration data from ``Skill/configurations`` is written to file paths
    /// determined by the provided mappings. Configurations without a matching
    /// mapping are skipped.
    public func writeDirectory(
        _ skill: Skill,
        to url: URL,
        configurationMappings: [ConfigurationFileMapping] = SkillWriter.defaultConfigurationMappings
    ) throws {
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

        // Write configurations using mappings
        let keyToPath = Dictionary(uniqueKeysWithValues: configurationMappings.map { ($0.key, $0.relativePath) })
        for (key, data) in skill.configurations {
            guard let relativePath = keyToPath[key] else { continue }
            let configURL = url.appending(path: relativePath)
            let parentDir = configURL.deletingLastPathComponent()
            try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
            do {
                try data.write(to: configURL)
            } catch {
                throw SkillWriterError.fileWriteFailed(configURL, underlying: error)
            }
        }
    }

    // MARK: - Frontmatter serialization

    private func buildFrontmatterYAML(_ skill: Skill) throws -> String {
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

        var lines: [String] = []
        for (key, value) in pairs {
            lines.append(contentsOf: serializeKeyValue(key: key, value: value, indent: 0))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - YAML serialization

    private func serializeKeyValue(key: String, value: Any, indent: Int) -> [String] {
        let prefix = String(repeating: "  ", count: indent)
        switch value {
        case let dict as [String: Any]:
            var lines = ["\(prefix)\(key):"]
            for (k, v) in dict.sorted(by: { $0.key < $1.key }) {
                lines.append(contentsOf: serializeKeyValue(key: k, value: v, indent: indent + 1))
            }
            return lines
        case let arr as [Any]:
            var lines = ["\(prefix)\(key):"]
            for item in arr {
                lines.append("\(prefix)- \(serializeScalar(item))")
            }
            return lines
        default:
            return ["\(prefix)\(key): \(serializeScalar(value))"]
        }
    }

    private func serializeScalar(_ value: Any) -> String {
        switch value {
        case let b as Bool:
            return b ? "true" : "false"
        case let i as Int:
            return String(i)
        case let d as Double:
            return String(d)
        case let s as String:
            return quoteIfNeeded(s)
        case is NSNull:
            return "null"
        default:
            return quoteIfNeeded(String(describing: value))
        }
    }

    private func quoteIfNeeded(_ string: String) -> String {
        if string.isEmpty { return "''" }
        let needsQuoting = string.contains(":") || string.contains("#") ||
            string.contains("\"") || string.contains("'") ||
            string.contains("\n") || string.contains("{") ||
            string.contains("}") || string.contains("[") ||
            string.contains("]") || string.contains(",") ||
            string.contains("&") || string.contains("*") ||
            string.contains("!") || string.contains("|") ||
            string.contains(">") || string.contains("%") ||
            string.contains("@") || string.contains("`") ||
            string.hasPrefix("- ") || string.hasPrefix("? ") ||
            string == "true" || string == "false" ||
            string == "null" || string == "~" ||
            string == "yes" || string == "no"
        if needsQuoting {
            let escaped = string
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            return "\"\(escaped)\""
        }
        return string
    }
}
