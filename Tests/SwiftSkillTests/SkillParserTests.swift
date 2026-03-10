import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillParser")
struct SkillParserTests {
    let parser = SkillParser()

    // MARK: - Minimal parsing

    @Test("Parse minimal SKILL.md with only required fields")
    func parseMinimal() throws {
        let content = """
        ---
        name: test-skill
        description: A test skill
        ---

        Some instructions here.
        """
        let skill = try parser.parse(content)
        #expect(skill.name == "test-skill")
        #expect(skill.description == "A test skill")
        #expect(skill.body == "Some instructions here.")
        #expect(skill.license == nil)
        #expect(skill.compatibility == nil)
        #expect(skill.metadata == nil)
        #expect(skill.allowedTools == nil)
        #expect(skill.extensions.isEmpty)
        #expect(skill.supportingFiles.isEmpty)
        #expect(skill.codexConfiguration == nil)
    }

    // MARK: - Full standard fields

    @Test("Parse all Agent Skills standard fields")
    func parseFullStandard() throws {
        let content = """
        ---
        name: pdf-processing
        description: Extract text and tables from PDF files.
        license: Apache-2.0
        compatibility: Requires Python 3.10+
        metadata:
          author: example-org
          version: "1.0"
        allowed-tools: Read, Grep, Glob
        ---

        ## Instructions

        Process PDF files using the bundled script.
        """
        let skill = try parser.parse(content)
        #expect(skill.name == "pdf-processing")
        #expect(skill.description == "Extract text and tables from PDF files.")
        #expect(skill.license == "Apache-2.0")
        #expect(skill.compatibility == "Requires Python 3.10+")
        #expect(skill.metadata?["author"] == "example-org")
        #expect(skill.metadata?["version"] == "1.0")
        #expect(skill.allowedTools == ["Read", "Grep", "Glob"])
        #expect(skill.body.contains("## Instructions"))
        #expect(skill.body.contains("Process PDF files"))
    }

    // MARK: - Claude Code extensions

    @Test("Parse Claude Code extension fields into extensions dictionary")
    func parseClaude() throws {
        let content = """
        ---
        name: deploy
        description: Deploy the application
        disable-model-invocation: true
        user-invocable: true
        argument-hint: "[environment]"
        model: opus
        context: fork
        agent: Explore
        ---

        Deploy to $ARGUMENTS.
        """
        let skill = try parser.parse(content)
        #expect(skill.disableModelInvocation == true)
        #expect(skill.userInvocable == true)
        #expect(skill.argumentHint == "[environment]")
        #expect(skill.model == "opus")
        #expect(skill.skillContext == "fork")
        #expect(skill.agent == "Explore")
        #expect(skill.body == "Deploy to $ARGUMENTS.")
    }

    @Test("Parse disable-model-invocation false")
    func parseDisableModelInvocationFalse() throws {
        let content = """
        ---
        name: auto-skill
        description: Auto triggerable
        disable-model-invocation: false
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.disableModelInvocation == false)
    }

    // MARK: - allowed-tools formats

    @Test("Parse comma-separated allowed-tools")
    func parseCommaTools() throws {
        let content = """
        ---
        name: comma-tools
        description: Comma tools
        allowed-tools: Read, Grep, Glob
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.allowedTools == ["Read", "Grep", "Glob"])
    }

    @Test("Parse space-delimited allowed-tools with parentheses")
    func parseSpaceDelimitedTools() throws {
        let content = """
        ---
        name: space-tools
        description: Space tools
        allowed-tools: Bash(git:*) Bash(jq:*) Read
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.allowedTools == ["Bash(git:*)", "Bash(jq:*)", "Read"])
    }

    @Test("Parse YAML array format allowed-tools")
    func parseArrayTools() throws {
        let content = """
        ---
        name: array-tools
        description: Array tools
        allowed-tools:
          - Read
          - Grep
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.allowedTools == ["Read", "Grep"])
    }

    @Test("Parse single allowed-tool with spaces in parentheses")
    func parseSingleToolWithSpaces() throws {
        let content = """
        ---
        name: single-tool
        description: Single tool
        allowed-tools: Bash(python *)
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.allowedTools == ["Bash(python *)"])
    }

    // MARK: - Body handling

    @Test("Parse empty body")
    func parseEmptyBody() throws {
        let content = """
        ---
        name: empty-body
        description: Has no body
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.body.isEmpty)
    }

    @Test("Parse multiline body preserves content")
    func parseMultilineBody() throws {
        let content = """
        ---
        name: multiline
        description: Multiline body
        ---

        Line 1
        Line 2

        Line 4
        """
        let skill = try parser.parse(content)
        #expect(skill.body.contains("Line 1"))
        #expect(skill.body.contains("Line 2"))
        #expect(skill.body.contains("Line 4"))
    }

    @Test("Parse body with markdown code blocks containing ---")
    func parseBodyWithCodeBlock() throws {
        let content = """
        ---
        name: code-body
        description: Has code in body
        ---

        Example:

        ```yaml
        key: value
        ```
        """
        let skill = try parser.parse(content)
        #expect(skill.body.contains("```yaml"))
        #expect(skill.body.contains("key: value"))
    }

    // MARK: - Unknown extension fields

    @Test("Unknown frontmatter fields go to extensions")
    func unknownFieldsToExtensions() throws {
        let content = """
        ---
        name: extended
        description: Has custom fields
        custom-field: hello
        numeric-field: 42
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.extensions["custom-field"]?.stringValue == "hello")
        #expect(skill.extensions["numeric-field"]?.intValue == 42)
    }

    @Test("Nested extension values are preserved")
    func nestedExtensionValues() throws {
        let content = """
        ---
        name: nested
        description: Has nested values
        hooks:
          pre-run: echo hello
          post-run: echo bye
        ---
        """
        let skill = try parser.parse(content)
        let hooks = skill.extensions["hooks"]?.dictionaryValue
        #expect(hooks?["pre-run"]?.stringValue == "echo hello")
        #expect(hooks?["post-run"]?.stringValue == "echo bye")
    }

    // MARK: - metadata edge cases

    @Test("Numeric metadata values are converted to strings")
    func numericMetadata() throws {
        let content = """
        ---
        name: meta-numeric
        description: Numeric metadata
        metadata:
          version: 2
          pi: 3.14
        ---
        """
        let skill = try parser.parse(content)
        #expect(skill.metadata?["version"] == "2")
        #expect(skill.metadata?["pi"] == "3.14")
    }

    // MARK: - Error cases

    @Test("Missing frontmatter throws missingFrontmatter")
    func missingFrontmatter() {
        let content = "No frontmatter here"
        #expect(throws: SkillParserError.self) {
            try parser.parse(content)
        }
    }

    @Test("Unclosed frontmatter throws missingFrontmatter")
    func unclosedFrontmatter() {
        let content = """
        ---
        name: broken
        description: Never closed
        """
        #expect(throws: SkillParserError.self) {
            try parser.parse(content)
        }
    }

    @Test("Missing name field throws missingRequiredField")
    func missingName() {
        let content = """
        ---
        description: Only description
        ---
        """
        #expect(throws: SkillParserError.self) {
            try parser.parse(content)
        }
    }

    @Test("Missing description field throws missingRequiredField")
    func missingDescription() {
        let content = """
        ---
        name: no-desc
        ---
        """
        #expect(throws: SkillParserError.self) {
            try parser.parse(content)
        }
    }

    @Test("Empty frontmatter throws missingRequiredField")
    func emptyFrontmatter() {
        let content = """
        ---
        ---
        """
        #expect(throws: SkillParserError.self) {
            try parser.parse(content)
        }
    }

    @Test("File not found throws fileNotFound")
    func fileNotFound() {
        let url = URL(filePath: "/nonexistent/path/SKILL.md")
        #expect(throws: SkillParserError.self) {
            try parser.parse(at: url)
        }
    }

    // MARK: - Directory parsing

    @Test("Parse directory collects supporting files")
    func parseDirectoryWithSupportingFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fm = FileManager.default
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try fm.createDirectory(
            at: tempDir.appending(path: "scripts"),
            withIntermediateDirectories: true
        )

        let skillContent = """
        ---
        name: dir-skill
        description: A directory skill
        ---

        Use scripts/helper.py
        """
        try Data(skillContent.utf8).write(to: tempDir.appending(path: "SKILL.md"))
        try Data("print('hello')".utf8).write(to: tempDir.appending(path: "scripts/helper.py"))

        let skill = try parser.parseDirectory(at: tempDir)
        #expect(skill.name == "dir-skill")
        #expect(skill.supportingFiles.count == 1)
        #expect(skill.supportingFiles.first?.relativePath == "scripts/helper.py")
        #expect(skill.supportingFiles.first?.textContent == "print('hello')")
    }

    @Test("Parse directory with Codex configuration")
    func parseDirectoryWithCodex() throws {
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
        name: codex-skill
        description: A codex skill
        ---
        """
        try Data(skillContent.utf8).write(to: tempDir.appending(path: "SKILL.md"))

        let codexYAML = """
        interface:
          display_name: My Skill
          brand_color: "#3B82F6"
        policy:
          allow_implicit_invocation: false
        """
        try Data(codexYAML.utf8).write(to: tempDir.appending(path: "agents/openai.yaml"))

        let skill = try parser.parseDirectory(at: tempDir)
        #expect(skill.codexConfiguration?.interface?.displayName == "My Skill")
        #expect(skill.codexConfiguration?.interface?.brandColor == "#3B82F6")
        #expect(skill.codexConfiguration?.policy?.allowImplicitInvocation == false)
    }

    @Test("Parse directory without Codex config leaves codexConfiguration nil")
    func parseDirectoryNoCodex() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fm = FileManager.default
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let skillContent = """
        ---
        name: no-codex
        description: No codex config
        ---
        """
        try Data(skillContent.utf8).write(to: tempDir.appending(path: "SKILL.md"))

        let skill = try parser.parseDirectory(at: tempDir)
        #expect(skill.codexConfiguration == nil)
    }
}
