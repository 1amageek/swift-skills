import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillWriter")
struct SkillWriterTests {
    let writer = SkillWriter()
    let parser = SkillParser()

    // MARK: - Basic writing

    @Test("Write minimal skill produces valid SKILL.md format")
    func writeMinimal() throws {
        let skill = Skill(
            name: "test-skill",
            description: "A test skill",
            body: "Do the thing."
        )
        let output = try writer.write(skill)
        #expect(output.hasPrefix("---\n"))
        #expect(output.contains("name: test-skill"))
        #expect(output.contains("description: A test skill"))
        #expect(output.contains("Do the thing."))
    }

    @Test("Write skill with empty body ends after closing frontmatter")
    func writeEmptyBody() throws {
        let skill = Skill(name: "no-body", description: "No body")
        let output = try writer.write(skill)
        #expect(output.hasSuffix("---\n"))
        #expect(!output.contains("\n\n"))
    }

    // MARK: - Round-trip consistency

    @Test("Round-trip: parse then write preserves all standard fields")
    func roundTripStandard() throws {
        let original = Skill(
            name: "round-trip",
            description: "Test round-trip serialization",
            license: "MIT",
            compatibility: "Requires git",
            metadata: ["author": "test", "version": "2.0"],
            allowedTools: ["Read", "Grep"],
            body: "Instructions here."
        )
        let content = try writer.write(original)
        let restored = try parser.parse(content)

        #expect(restored.name == original.name)
        #expect(restored.description == original.description)
        #expect(restored.license == original.license)
        #expect(restored.compatibility == original.compatibility)
        #expect(restored.metadata == original.metadata)
        #expect(restored.allowedTools == original.allowedTools)
        #expect(restored.body == original.body)
    }

    @Test("Round-trip: Claude Code extensions are preserved")
    func roundTripClaude() throws {
        var original = Skill(
            name: "claude-rt",
            description: "Claude round-trip",
            body: "Steps."
        )
        original.disableModelInvocation = true
        original.userInvocable = false
        original.skillContext = "fork"
        original.agent = "Explore"
        original.model = "opus"
        original.argumentHint = "[env]"

        let content = try writer.write(original)
        let restored = try parser.parse(content)

        #expect(restored.disableModelInvocation == true)
        #expect(restored.userInvocable == false)
        #expect(restored.skillContext == "fork")
        #expect(restored.agent == "Explore")
        #expect(restored.model == "opus")
        #expect(restored.argumentHint == "[env]")
    }

    @Test("Round-trip: custom extension values are preserved")
    func roundTripExtensions() throws {
        let original = Skill(
            name: "ext-rt",
            description: "Extension round-trip",
            extensions: [
                "custom-string": .string("hello"),
                "custom-bool": .bool(true),
                "custom-int": .int(42),
            ]
        )
        let content = try writer.write(original)
        let restored = try parser.parse(content)

        #expect(restored.extensions["custom-string"]?.stringValue == "hello")
        #expect(restored.extensions["custom-bool"]?.boolValue == true)
        #expect(restored.extensions["custom-int"]?.intValue == 42)
    }

    // MARK: - Output format

    @Test("Output contains frontmatter markers")
    func frontmatterMarkers() throws {
        let skill = Skill(name: "markers", description: "Test")
        let output = try writer.write(skill)
        let lines = output.components(separatedBy: "\n")
        #expect(lines.first == "---")
        #expect(lines.contains("---"))
    }

    @Test("Extensions are written with correct YAML keys")
    func extensionYAMLKeys() throws {
        var skill = Skill(name: "keys", description: "Test keys")
        skill.disableModelInvocation = true
        let output = try writer.write(skill)
        #expect(output.contains("disable-model-invocation"))
    }

    // MARK: - Directory writing

    @Test("Write directory creates SKILL.md and supporting files")
    func writeDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let skill = Skill(
            name: "dir-test",
            description: "Directory test",
            body: "Instructions.",
            supportingFiles: [
                SupportingFile(relativePath: "scripts/helper.py", text: "print('hello')"),
                SupportingFile(relativePath: "references/REFERENCE.md", text: "# Reference"),
            ]
        )

        try writer.writeDirectory(skill, to: tempDir)

        let fm = FileManager.default
        #expect(fm.fileExists(atPath: tempDir.appending(path: "SKILL.md").path(percentEncoded: false)))
        #expect(fm.fileExists(atPath: tempDir.appending(path: "scripts/helper.py").path(percentEncoded: false)))
        #expect(fm.fileExists(atPath: tempDir.appending(path: "references/REFERENCE.md").path(percentEncoded: false)))
    }

    @Test("Write directory with Codex configuration creates agents/openai.yaml")
    func writeDirectoryWithCodex() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        var skill = Skill(name: "codex-write", description: "Codex write test")
        try skill.setConfiguration(CodexConfiguration(
            interface: CodexConfiguration.Interface(displayName: "My Skill"),
            policy: CodexConfiguration.Policy(allowImplicitInvocation: false)
        ))

        try writer.writeDirectory(skill, to: tempDir)

        let codexPath = tempDir.appending(path: "agents/openai.yaml").path(percentEncoded: false)
        #expect(FileManager.default.fileExists(atPath: codexPath))
    }

    @Test("Write then parse directory round-trip preserves everything")
    func writeParseDirectoryRoundTrip() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        var original = Skill(
            name: "full-rt",
            description: "Full directory round-trip",
            license: "MIT",
            body: "Do stuff.",
            supportingFiles: [
                SupportingFile(relativePath: "scripts/run.sh", text: "#!/bin/bash\necho hi"),
            ]
        )
        try original.setConfiguration(CodexConfiguration(
            interface: CodexConfiguration.Interface(
                displayName: "Full RT",
                brandColor: "#FF0000"
            ),
            policy: CodexConfiguration.Policy(allowImplicitInvocation: true)
        ))

        try writer.writeDirectory(original, to: tempDir)
        let restored = try parser.parseDirectory(at: tempDir)

        #expect(restored.name == original.name)
        #expect(restored.description == original.description)
        #expect(restored.license == original.license)
        #expect(restored.body == original.body)
        #expect(restored.supportingFiles.count == 1)
        #expect(restored.supportingFiles.first?.relativePath == "scripts/run.sh")
        let codex = try restored.configuration(CodexConfiguration.self)
        #expect(codex?.interface?.displayName == "Full RT")
        #expect(codex?.policy?.allowImplicitInvocation == true)
    }
}
