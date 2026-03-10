import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillWriter Edge Cases")
struct SkillWriterEdgeCaseTests {
    let writer = SkillWriter()
    let parser = SkillParser()

    // MARK: - Special characters in fields

    @Test("Round-trip preserves description with colons")
    func descriptionWithColons() throws {
        let original = Skill(
            name: "colon-test",
            description: "Use this when: you need to deploy"
        )
        let content = try writer.write(original)
        let restored = try parser.parse(content)
        #expect(restored.description == original.description)
    }

    @Test("Round-trip preserves license with special characters")
    func licenseSpecialChars() throws {
        let original = Skill(
            name: "license-chars",
            description: "Test",
            license: "Proprietary. See LICENSE.txt for terms & conditions"
        )
        let content = try writer.write(original)
        let restored = try parser.parse(content)
        #expect(restored.license == original.license)
    }

    @Test("Round-trip preserves metadata with special characters")
    func metadataSpecialChars() throws {
        let original = Skill(
            name: "meta-chars",
            description: "Test",
            metadata: [
                "url": "https://example.com/path?q=1&r=2",
                "note": "version: 1.0 (beta)",
            ]
        )
        let content = try writer.write(original)
        let restored = try parser.parse(content)
        #expect(restored.metadata?["url"] == original.metadata?["url"])
        #expect(restored.metadata?["note"] == original.metadata?["note"])
    }

    // MARK: - Extension value types

    @Test("Round-trip preserves double extension values")
    func extensionDoubleValue() throws {
        let original = Skill(
            name: "double-ext",
            description: "Test",
            extensions: ["timeout": .double(30.5)]
        )
        let content = try writer.write(original)
        let restored = try parser.parse(content)
        #expect(restored.extensions["timeout"]?.doubleValue == 30.5)
    }

    @Test("Round-trip preserves array extension values")
    func extensionArrayValue() throws {
        let original = Skill(
            name: "arr-ext",
            description: "Test",
            extensions: [
                "tags": .array([.string("deploy"), .string("ci")]),
            ]
        )
        let content = try writer.write(original)
        let restored = try parser.parse(content)
        let tags = restored.extensions["tags"]?.arrayValue
        #expect(tags?.count == 2)
        #expect(tags?[0].stringValue == "deploy")
        #expect(tags?[1].stringValue == "ci")
    }

    @Test("Round-trip preserves nested dictionary extensions")
    func extensionNestedDict() throws {
        let original = Skill(
            name: "nested-ext",
            description: "Test",
            extensions: [
                "hooks": .dictionary([
                    "pre": .string("echo pre"),
                    "post": .string("echo post"),
                ]),
            ]
        )
        let content = try writer.write(original)
        let restored = try parser.parse(content)
        let hooks = restored.extensions["hooks"]?.dictionaryValue
        #expect(hooks?["pre"]?.stringValue == "echo pre")
        #expect(hooks?["post"]?.stringValue == "echo post")
    }

    // MARK: - All nil optional fields

    @Test("Writing with all nil optional fields produces minimal output")
    func allNilOptionals() throws {
        let skill = Skill(name: "minimal", description: "Only required fields")
        let content = try writer.write(skill)
        let restored = try parser.parse(content)
        #expect(restored.name == "minimal")
        #expect(restored.description == "Only required fields")
        #expect(restored.license == nil)
        #expect(restored.compatibility == nil)
        #expect(restored.metadata == nil)
        #expect(restored.allowedTools == nil)
        #expect(restored.extensions.isEmpty)
    }

    // MARK: - Field ordering

    @Test("name appears before description in output")
    func nameBeforeDescription() throws {
        let skill = Skill(name: "order-test", description: "Testing order")
        let content = try writer.write(skill)
        let namePos = content.range(of: "name:")?.lowerBound
        let descPos = content.range(of: "description:")?.lowerBound
        #expect(namePos != nil)
        #expect(descPos != nil)
        if let n = namePos, let d = descPos {
            #expect(n < d)
        }
    }

    @Test("Standard fields appear before extensions in output")
    func standardBeforeExtensions() throws {
        var skill = Skill(
            name: "field-order",
            description: "Order test",
            license: "MIT"
        )
        skill.disableModelInvocation = true
        let content = try writer.write(skill)
        let licensePos = content.range(of: "license:")?.lowerBound
        let extPos = content.range(of: "disable-model-invocation:")?.lowerBound
        if let l = licensePos, let e = extPos {
            #expect(l < e)
        }
    }

    // MARK: - Body formatting

    @Test("Body with trailing newline does not add extra newline")
    func bodyTrailingNewline() throws {
        let skill = Skill(name: "trail", description: "Test", body: "Content\n")
        let content = try writer.write(skill)
        #expect(!content.hasSuffix("\n\n\n"))
    }

    @Test("Body without trailing newline gets one added")
    func bodyWithoutTrailingNewline() throws {
        let skill = Skill(name: "no-trail", description: "Test", body: "Content")
        let content = try writer.write(skill)
        #expect(content.hasSuffix("Content\n"))
    }

    // MARK: - Directory overwrite

    @Test("Write directory overwrites existing content")
    func overwriteDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let first = Skill(
            name: "overwrite",
            description: "First version",
            body: "Old instructions."
        )
        try writer.writeDirectory(first, to: tempDir)

        let second = Skill(
            name: "overwrite",
            description: "Second version",
            body: "New instructions."
        )
        try writer.writeDirectory(second, to: tempDir)

        let restored = try parser.parseDirectory(at: tempDir)
        #expect(restored.description == "Second version")
        #expect(restored.body == "New instructions.")
    }

    // MARK: - Write to file

    @Test("Write to file creates readable SKILL.md")
    func writeToFile() throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appending(path: "\(UUID().uuidString).md")
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let skill = Skill(name: "file-write", description: "Write to file test", body: "Body.")
        try writer.write(skill, to: tempFile)

        let restored = try parser.parse(at: tempFile)
        #expect(restored.name == "file-write")
        #expect(restored.body == "Body.")
    }
}
