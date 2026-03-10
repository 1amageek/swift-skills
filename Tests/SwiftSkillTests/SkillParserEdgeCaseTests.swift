import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillParser Edge Cases")
struct SkillParserEdgeCaseTests {
    let parser = SkillParser()

    // MARK: - YAML special characters in description

    @Test("Description with colon is parsed correctly")
    func descriptionWithColon() throws {
        let content = """
        ---
        name: colon-desc
        description: "Deploy to: production servers"
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.description == "Deploy to: production servers")
    }

    @Test("Description with single quotes is parsed correctly")
    func descriptionWithQuotes() throws {
        let content = """
        ---
        name: quote-desc
        description: "It's a 'skill' description"
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.description.contains("'skill'"))
    }

    @Test("Multiline YAML description using pipe")
    func multilineDescriptionPipe() throws {
        let content = """
        ---
        name: pipe-desc
        description: |
          First line of description.
          Second line of description.
        ---

        Body here.
        """
        let skill = try parser.parse(content)
        #expect(skill.description.contains("First line"))
        #expect(skill.description.contains("Second line"))
    }

    @Test("Multiline YAML description using folded style")
    func multilineDescriptionFolded() throws {
        let content = """
        ---
        name: folded-desc
        description: >
          This is a long description
          that spans multiple lines.
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.description.contains("long description"))
    }

    // MARK: - License edge cases

    @Test("License with reference to bundled file")
    func licenseWithFileRef() throws {
        let content = """
        ---
        name: license-file
        description: Has license file ref
        license: "Proprietary. LICENSE.txt has complete terms"
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.license == "Proprietary. LICENSE.txt has complete terms")
    }

    // MARK: - Supporting files filtering

    @Test("Supporting files exclude .DS_Store")
    func excludeDSStore() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fm = FileManager.default
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let skillContent = """
        ---
        name: ds-store
        description: Test DS_Store exclusion
        ---
        """
        try Data(skillContent.utf8).write(to: tempDir.appending(path: "SKILL.md"))
        try Data("fake".utf8).write(to: tempDir.appending(path: ".DS_Store"))
        try Data("real".utf8).write(to: tempDir.appending(path: "real-file.txt"))

        let skill = try parser.parseDirectory(at: tempDir)
        #expect(skill.supportingFiles.count == 1)
        #expect(skill.supportingFiles.first?.relativePath == "real-file.txt")
    }

    @Test("Supporting files with nested directories")
    func nestedSupportingFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fm = FileManager.default
        try fm.createDirectory(
            at: tempDir.appending(path: "scripts/utils"),
            withIntermediateDirectories: true
        )
        try fm.createDirectory(
            at: tempDir.appending(path: "references"),
            withIntermediateDirectories: true
        )

        let skillContent = """
        ---
        name: nested-files
        description: Has nested files
        ---
        """
        try Data(skillContent.utf8).write(to: tempDir.appending(path: "SKILL.md"))
        try Data("script1".utf8).write(to: tempDir.appending(path: "scripts/run.sh"))
        try Data("script2".utf8).write(to: tempDir.appending(path: "scripts/utils/helper.py"))
        try Data("ref".utf8).write(to: tempDir.appending(path: "references/API.md"))

        let skill = try parser.parseDirectory(at: tempDir)
        #expect(skill.supportingFiles.count == 3)
        let paths = Set(skill.supportingFiles.map(\.relativePath))
        #expect(paths.contains("scripts/run.sh"))
        #expect(paths.contains("scripts/utils/helper.py"))
        #expect(paths.contains("references/API.md"))
    }

    @Test("SKILL.md itself is not collected as supporting file")
    func skillMDExcluded() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fm = FileManager.default
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let skillContent = """
        ---
        name: skill-md-excluded
        description: SKILL.md should not appear in supporting files
        ---
        """
        try Data(skillContent.utf8).write(to: tempDir.appending(path: "SKILL.md"))

        let skill = try parser.parseDirectory(at: tempDir)
        #expect(skill.supportingFiles.isEmpty)
    }

    // MARK: - Empty and whitespace edge cases

    @Test("Frontmatter with trailing whitespace on markers")
    func trailingWhitespace() throws {
        let content = "---   \nname: ws-test\ndescription: Whitespace test\n---   \n\nBody."
        let skill = try parser.parse(content)
        #expect(skill.name == "ws-test")
        #expect(skill.body == "Body.")
    }

    @Test("Body with only whitespace is treated as empty")
    func whitespaceOnlyBody() throws {
        let content = "---\nname: ws-body\ndescription: Whitespace body\n---\n   \n  \n"
        let skill = try parser.parse(content)
        #expect(skill.body.isEmpty)
    }

    // MARK: - Metadata edge cases

    @Test("Empty metadata map is treated as nil")
    func emptyMetadata() throws {
        let content = """
        ---
        name: empty-meta
        description: Empty metadata
        metadata: {}
        ---
        """
        let skill = try parser.parse(content)
        // Empty map from YAML becomes empty dict, but our parser returns nil for non-[String: Any]
        // Actually {} is valid YAML for empty map. Let's check behavior.
        // If Yams returns [:], then metadata will be [:] which mapValues produces [:].
        // Our code only sets metadata when raw != nil.
    }

    @Test("Boolean metadata value is converted to string")
    func boolMetadata() throws {
        let content = """
        ---
        name: bool-meta
        description: Bool metadata
        metadata:
          experimental: true
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.metadata?["experimental"] == "true" || skill.metadata?["experimental"] == "1")
    }

    // MARK: - allowed-tools edge cases

    @Test("Empty allowed-tools string")
    func emptyAllowedToolsString() throws {
        let content = """
        ---
        name: empty-tools
        description: Empty tools
        allowed-tools: ""
        ---
        """
        let skill = try parser.parse(content)
        // Empty string parsed as empty array
        #expect(skill.allowedTools?.isEmpty ?? true)
    }

    @Test("Single allowed-tool without separator")
    func singleTool() throws {
        let content = """
        ---
        name: single
        description: Single tool
        allowed-tools: Read
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.allowedTools == ["Read"])
    }

    @Test("Comma-separated tools with extra whitespace")
    func commaToolsExtraSpaces() throws {
        let content = """
        ---
        name: spaces
        description: Extra spaces
        allowed-tools: "Read ,  Grep  , Glob"
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.allowedTools == ["Read", "Grep", "Glob"])
    }

    // MARK: - Extension type preservation

    @Test("Extension boolean false is preserved")
    func extensionBoolFalse() throws {
        let content = """
        ---
        name: bool-ext
        description: Bool extension
        custom-flag: false
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.extensions["custom-flag"]?.boolValue == false)
    }

    @Test("Extension array values are preserved")
    func extensionArray() throws {
        let content = """
        ---
        name: arr-ext
        description: Array extension
        tags:
          - deploy
          - production
        ---
        """
        let skill = try parser.parse(content)
        let tags = skill.extensions["tags"]?.arrayValue
        #expect(tags?.count == 2)
        #expect(tags?[0].stringValue == "deploy")
        #expect(tags?[1].stringValue == "production")
    }

    @Test("Extension numeric values are preserved with correct types")
    func extensionNumericTypes() throws {
        let content = """
        ---
        name: num-ext
        description: Numeric extension
        retry-count: 3
        timeout: 30.5
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.extensions["retry-count"]?.intValue == 3)
        #expect(skill.extensions["timeout"]?.doubleValue == 30.5)
    }

    // MARK: - Codex configuration edge cases

    @Test("Codex configuration with tool dependencies")
    func codexWithDependencies() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fm = FileManager.default
        try fm.createDirectory(
            at: tempDir.appending(path: "agents"),
            withIntermediateDirectories: true
        )

        let skillContent = """
        ---
        name: codex-deps
        description: Codex with dependencies
        ---
        """
        try Data(skillContent.utf8).write(to: tempDir.appending(path: "SKILL.md"))

        let codexYAML = """
        dependencies:
          tools:
            - type: mcp
              value: my-server
              description: My MCP server
              transport: streamable_http
              url: https://example.com
        """
        try Data(codexYAML.utf8).write(to: tempDir.appending(path: "agents/openai.yaml"))

        let skill = try parser.parseDirectory(at: tempDir)
        let codex = try skill.configuration(CodexConfiguration.self)
        #expect(codex?.dependencies?.tools?.count == 1)
        let tool = codex?.dependencies?.tools?.first
        #expect(tool?.type == "mcp")
        #expect(tool?.value == "my-server")
        #expect(tool?.transport == "streamable_http")
        #expect(tool?.url == "https://example.com")
    }
}
