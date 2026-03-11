import Foundation
import YAML

/// Parses SKILL.md files and skill directories into `Skill` instances.
public struct SkillParser: Sendable {

    /// Default configuration file mappings for parsing directories.
    public static let defaultConfigurationMappings: [ConfigurationFileMapping] = ConfigurationFileMapping.defaults

    public init() {}

    // MARK: - Public API

    /// Parse a SKILL.md content string.
    public func parse(_ content: String) throws -> Skill {
        let (frontmatterYAML, body) = try splitFrontmatterAndBody(content)
        let dict = try parseFrontmatter(frontmatterYAML)
        return try extractSkill(from: dict, body: body)
    }

    /// Parse a SKILL.md file at the given URL.
    public func parse(at url: URL) throws -> Skill {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw SkillParserError.fileNotFound(url)
        }
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw SkillParserError.invalidEncoding
        }
        return try parse(content)
    }

    /// Parse a full skill directory (SKILL.md + supporting files + configurations).
    ///
    /// Configuration files are discovered using the provided mappings and stored
    /// as raw data in ``Skill/configurations``, keyed by the mapping's ``ConfigurationFileMapping/key``.
    /// Use ``Skill/configuration(_:)`` to decode them into typed representations.
    public func parseDirectory(
        at url: URL,
        configurationMappings: [ConfigurationFileMapping] = SkillParser.defaultConfigurationMappings
    ) throws -> Skill {
        let skillMDURL = url.appending(path: "SKILL.md")
        var skill = try parse(at: skillMDURL)

        let configPaths = Set(configurationMappings.map(\.relativePath))

        // Collect supporting files, excluding configuration file paths
        skill.supportingFiles = try collectSupportingFiles(in: url, excludingPaths: configPaths)

        // Collect configurations as raw data, keyed by mapping key
        for mapping in configurationMappings {
            let configURL = url.appending(path: mapping.relativePath)
            if FileManager.default.fileExists(atPath: configURL.path(percentEncoded: false)) {
                let data = try Data(contentsOf: configURL)
                skill.configurations[mapping.key] = data
            }
        }

        return skill
    }

    // MARK: - Frontmatter splitting

    private func splitFrontmatterAndBody(_ content: String) throws -> (String, String) {
        let lines = content.components(separatedBy: "\n")
        guard !lines.isEmpty,
              lines[0].trimmingCharacters(in: .whitespaces) == "---" else {
            throw SkillParserError.missingFrontmatter
        }

        var closingIndex: Int?
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = i
                break
            }
        }

        guard let closing = closingIndex else {
            throw SkillParserError.missingFrontmatter
        }

        let frontmatter = lines[1..<closing].joined(separator: "\n")
        let body = lines[(closing + 1)...].joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (frontmatter, body)
    }

    // MARK: - YAML parsing

    private func parseFrontmatter(_ yaml: String) throws -> [String: Any] {
        do {
            guard let node = try compose(yaml: yaml) else {
                throw SkillParserError.invalidFrontmatter("Empty YAML")
            }
            guard case .mapping(let mapping) = node else {
                throw SkillParserError.invalidFrontmatter("Expected a YAML mapping")
            }
            return nodeToDict(mapping)
        } catch let error as SkillParserError {
            throw error
        } catch {
            throw SkillParserError.invalidFrontmatter(error.localizedDescription)
        }
    }

    // MARK: - Node conversion

    private func nodeToDict(_ mapping: Node.Mapping) -> [String: Any] {
        var dict = [String: Any]()
        for (keyNode, valueNode) in mapping {
            guard let key = keyNode.scalar?.string else { continue }
            dict[key] = nodeToAny(valueNode)
        }
        return dict
    }

    private func nodeToAny(_ node: Node) -> Any {
        switch node {
        case .scalar(let s):
            return inferScalarType(s.string)
        case .mapping(let m):
            return nodeToDict(m)
        case .sequence(let s):
            return s.map { nodeToAny($0) }
        }
    }

    private func inferScalarType(_ string: String) -> Any {
        switch string {
        case "true", "True", "TRUE", "yes", "Yes", "YES": return true
        case "false", "False", "FALSE", "no", "No", "NO": return false
        case "null", "Null", "NULL", "~": return NSNull()
        default: break
        }
        if let i = Int(string) { return i }
        if string.contains("."), let d = Double(string) { return d }
        return string
    }

    // MARK: - Field extraction

    private static let standardKeys: Set<String> = [
        "name", "description", "license", "compatibility", "metadata", "allowed-tools",
    ]

    private func extractSkill(from dict: [String: Any], body: String) throws -> Skill {
        guard let name = dict["name"] as? String else {
            throw SkillParserError.missingRequiredField("name")
        }
        guard let description = dict["description"] as? String else {
            throw SkillParserError.missingRequiredField("description")
        }

        let license = dict["license"] as? String
        let compatibility = dict["compatibility"] as? String

        let metadata: [String: String]?
        if let raw = dict["metadata"] as? [String: Any] {
            metadata = raw.mapValues { "\($0)" }
        } else {
            metadata = nil
        }

        let allowedTools: [String]?
        if let toolsString = dict["allowed-tools"] as? String {
            allowedTools = parseAllowedToolsString(toolsString)
        } else if let toolsArray = dict["allowed-tools"] as? [String] {
            allowedTools = toolsArray
        } else {
            allowedTools = nil
        }

        // Remaining keys go to extensions
        var extensions: [String: SkillValue] = [:]
        for (key, value) in dict where !Self.standardKeys.contains(key) {
            extensions[key] = SkillValue(fromAny: value)
        }

        return Skill(
            name: name,
            description: description,
            license: license,
            compatibility: compatibility,
            metadata: metadata,
            allowedTools: allowedTools,
            body: body,
            extensions: extensions
        )
    }

    // MARK: - allowed-tools parsing

    /// Parse allowed-tools string handling both comma-separated and space-separated formats.
    private func parseAllowedToolsString(_ value: String) -> [String] {
        if value.contains(",") {
            return value.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        // Split by space, respecting parentheses
        var tools: [String] = []
        var current = ""
        var depth = 0
        for char in value {
            if char == "(" { depth += 1 }
            if char == ")" { depth = max(0, depth - 1) }
            if char == " " && depth == 0 {
                if !current.isEmpty { tools.append(current) }
                current = ""
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { tools.append(current) }
        return tools
    }

    // MARK: - Supporting files

    private func collectSupportingFiles(
        in directoryURL: URL,
        excludingPaths configPaths: Set<String>
    ) throws -> [SupportingFile] {
        let fm = FileManager.default
        let dirPath = directoryURL.path(percentEncoded: false)
        guard let enumerator = fm.enumerator(atPath: dirPath) else { return [] }

        var files: [SupportingFile] = []
        let skipNames: Set<String> = ["SKILL.md"]
        let skipDirs: Set<String> = [".git", ".DS_Store"]

        while let relativePath = enumerator.nextObject() as? String {
            let fullURL = directoryURL.appending(path: relativePath)
            let fullPath = fullURL.path(percentEncoded: false)

            let fileName = (relativePath as NSString).lastPathComponent
            if skipNames.contains(fileName) || skipDirs.contains(fileName) { continue }
            if configPaths.contains(relativePath) { continue }

            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), !isDir.boolValue else {
                continue
            }

            let data = try Data(contentsOf: fullURL)
            files.append(SupportingFile(relativePath: relativePath, content: data))
        }
        return files
    }
}
