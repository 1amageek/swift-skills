import Testing
import Foundation
@testable import SwiftSkill

@Suite("Skill")
struct SkillTests {

    // MARK: - Identifiable

    @Test("Skill id equals name")
    func identifiable() {
        let skill = Skill(name: "my-skill", description: "Test")
        #expect(skill.id == "my-skill")
    }

    // MARK: - Hashable / Equatable

    @Test("Skills with same fields are equal")
    func equality() {
        let a = Skill(name: "equal", description: "Same", body: "Body")
        let b = Skill(name: "equal", description: "Same", body: "Body")
        #expect(a == b)
    }

    @Test("Skills with different names are not equal")
    func inequality() {
        let a = Skill(name: "one", description: "Same")
        let b = Skill(name: "two", description: "Same")
        #expect(a != b)
    }

    @Test("Skills can be used in a Set")
    func hashable() {
        let a = Skill(name: "skill-a", description: "A")
        let b = Skill(name: "skill-b", description: "B")
        let c = Skill(name: "skill-a", description: "A")
        let set: Set<Skill> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable (JSON round-trip)

    @Test("Skill JSON round-trip preserves all standard fields")
    func jsonRoundTrip() throws {
        let original = Skill(
            name: "json-rt",
            description: "JSON round-trip test",
            license: "MIT",
            compatibility: "Any",
            metadata: ["key": "value"],
            allowedTools: ["Read", "Write"],
            body: "Do things."
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let restored = try decoder.decode(Skill.self, from: data)

        #expect(restored.name == original.name)
        #expect(restored.description == original.description)
        #expect(restored.license == original.license)
        #expect(restored.compatibility == original.compatibility)
        #expect(restored.metadata == original.metadata)
        #expect(restored.allowedTools == original.allowedTools)
        #expect(restored.body == original.body)
    }

    @Test("Skill JSON round-trip preserves extensions")
    func jsonRoundTripExtensions() throws {
        let original = Skill(
            name: "ext-json",
            description: "Extensions JSON test",
            extensions: [
                "string-key": .string("hello"),
                "bool-key": .bool(true),
                "int-key": .int(42),
                "nested": .dictionary(["inner": .string("val")]),
            ]
        )
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(Skill.self, from: data)

        #expect(restored.extensions["string-key"]?.stringValue == "hello")
        #expect(restored.extensions["bool-key"]?.boolValue == true)
        #expect(restored.extensions["int-key"]?.intValue == 42)
        #expect(restored.extensions["nested"]?.dictionaryValue?["inner"]?.stringValue == "val")
    }

    @Test("Skill JSON round-trip preserves supporting files")
    func jsonRoundTripSupportingFiles() throws {
        let original = Skill(
            name: "files-json",
            description: "Files test",
            supportingFiles: [
                SupportingFile(relativePath: "scripts/run.sh", text: "echo hi"),
            ]
        )
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(Skill.self, from: data)

        #expect(restored.supportingFiles.count == 1)
        #expect(restored.supportingFiles.first?.relativePath == "scripts/run.sh")
        #expect(restored.supportingFiles.first?.textContent == "echo hi")
    }

    @Test("Skill JSON round-trip preserves configurations")
    func jsonRoundTripConfigurations() throws {
        var original = Skill(name: "codex-json", description: "Codex test")
        try original.setConfiguration(CodexConfiguration(
            interface: CodexConfiguration.Interface(
                displayName: "My Skill",
                brandColor: "#3B82F6"
            ),
            policy: CodexConfiguration.Policy(allowImplicitInvocation: false)
        ))
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(Skill.self, from: data)

        let codex = try restored.configuration(CodexConfiguration.self)
        #expect(codex?.interface?.displayName == "My Skill")
        #expect(codex?.interface?.brandColor == "#3B82F6")
        #expect(codex?.policy?.allowImplicitInvocation == false)
    }

    // MARK: - Claude Code properties

    @Test("Claude Code properties read from and write to extensions")
    func claudeProperties() {
        var skill = Skill(name: "claude", description: "Test")

        #expect(skill.disableModelInvocation == nil)
        #expect(skill.userInvocable == nil)
        #expect(skill.argumentHint == nil)
        #expect(skill.model == nil)
        #expect(skill.skillContext == nil)
        #expect(skill.agent == nil)

        skill.disableModelInvocation = true
        skill.userInvocable = false
        skill.argumentHint = "[env]"
        skill.model = "opus"
        skill.skillContext = "fork"
        skill.agent = "Explore"

        #expect(skill.disableModelInvocation == true)
        #expect(skill.userInvocable == false)
        #expect(skill.argumentHint == "[env]")
        #expect(skill.model == "opus")
        #expect(skill.skillContext == "fork")
        #expect(skill.agent == "Explore")

        // Verify stored in extensions
        #expect(skill.extensions["disable-model-invocation"] == .bool(true))
        #expect(skill.extensions["user-invocable"] == .bool(false))
        #expect(skill.extensions["argument-hint"] == .string("[env]"))
        #expect(skill.extensions["model"] == .string("opus"))
        #expect(skill.extensions["context"] == .string("fork"))
        #expect(skill.extensions["agent"] == .string("Explore"))
    }

    @Test("Setting Claude Code property to nil removes from extensions")
    func claudePropertyNil() {
        var skill = Skill(name: "nil-test", description: "Test")
        skill.disableModelInvocation = true
        #expect(skill.extensions["disable-model-invocation"] != nil)

        skill.disableModelInvocation = nil
        #expect(skill.extensions["disable-model-invocation"] == nil)
    }

    // MARK: - Codex properties

    @Test("Codex properties read from and write to configuration")
    func codexProperties() throws {
        var skill = Skill(name: "codex", description: "Test")

        #expect(skill.allowImplicitInvocation == nil)
        #expect(skill.codexDisplayName == nil)

        skill.allowImplicitInvocation = false
        skill.codexDisplayName = "Pretty Name"

        #expect(skill.allowImplicitInvocation == false)
        #expect(skill.codexDisplayName == "Pretty Name")
        #expect(skill.hasConfiguration(CodexConfiguration.self))
    }

    @Test("Codex property setter creates configuration lazily")
    func codexLazyCreation() throws {
        var skill = Skill(name: "lazy-codex", description: "Test")
        #expect(!skill.hasConfiguration(CodexConfiguration.self))

        skill.allowImplicitInvocation = true
        #expect(skill.hasConfiguration(CodexConfiguration.self))
        let codex = try skill.configuration(CodexConfiguration.self)
        #expect(codex?.policy?.allowImplicitInvocation == true)
    }

    // MARK: - Default values

    @Test("Default init produces empty optionals and collections")
    func defaultInit() {
        let skill = Skill(name: "default", description: "Test")
        #expect(skill.license == nil)
        #expect(skill.compatibility == nil)
        #expect(skill.metadata == nil)
        #expect(skill.allowedTools == nil)
        #expect(skill.body.isEmpty)
        #expect(skill.extensions.isEmpty)
        #expect(skill.supportingFiles.isEmpty)
        #expect(skill.configurations.isEmpty)
    }
}
