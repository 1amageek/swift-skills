import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillStore Edge Cases")
struct SkillStoreEdgeCaseTests {

    private func makeTempDir() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }

    // MARK: - Overwrite behavior

    @Test("Save overwrites existing skill with same name")
    func saveOverwrites() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        try store.save(Skill(name: "overwrite", description: "Version 1", body: "Old."))
        try store.save(Skill(name: "overwrite", description: "Version 2", body: "New."))

        let skills = try store.discover()
        #expect(skills.count == 1)
        #expect(skills.first?.description == "Version 2")
        #expect(skills.first?.body == "New.")
    }

    // MARK: - Malformed skills

    @Test("Discover skips skill with invalid YAML frontmatter")
    func discoverSkipsInvalidYAML() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let fm = FileManager.default

        // Valid skill
        let store = SkillStore(rootURL: dir)
        try store.save(Skill(name: "valid", description: "A valid skill"))

        // Malformed skill (invalid YAML in frontmatter)
        let badDir = dir.appending(path: "broken")
        try fm.createDirectory(at: badDir, withIntermediateDirectories: true)
        let badContent = "---\n: broken yaml [[\n---\n"
        try Data(badContent.utf8).write(to: badDir.appending(path: "SKILL.md"))

        let skills = try store.discover()
        #expect(skills.count == 1)
        #expect(skills.first?.name == "valid")
    }

    @Test("Discover skips skill with missing required fields")
    func discoverSkipsMissingFields() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let fm = FileManager.default

        let store = SkillStore(rootURL: dir)
        try store.save(Skill(name: "good", description: "Good skill"))

        // Skill missing description
        let badDir = dir.appending(path: "no-desc")
        try fm.createDirectory(at: badDir, withIntermediateDirectories: true)
        let badContent = "---\nname: no-desc\n---\n"
        try Data(badContent.utf8).write(to: badDir.appending(path: "SKILL.md"))

        let skills = try store.discover()
        #expect(skills.count == 1)
        #expect(skills.first?.name == "good")
    }

    // MARK: - CRUD workflow

    @Test("Full CRUD lifecycle: create, read, update, delete")
    func crudLifecycle() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)

        // Create
        let original = Skill(name: "crud-skill", description: "Original", body: "Original body.")
        try store.save(original)

        // Read
        let read = try store.skill(named: "crud-skill")
        #expect(read?.description == "Original")
        #expect(read?.body == "Original body.")

        // Update
        let updated = Skill(name: "crud-skill", description: "Updated", body: "Updated body.")
        try store.save(updated)
        let readUpdated = try store.skill(named: "crud-skill")
        #expect(readUpdated?.description == "Updated")
        #expect(readUpdated?.body == "Updated body.")

        // Delete
        try store.delete(named: "crud-skill")
        let readDeleted = try store.skill(named: "crud-skill")
        #expect(readDeleted == nil)

        // Verify discover is empty
        let skills = try store.discover()
        #expect(skills.isEmpty)
    }

    // MARK: - Multiple skills

    @Test("Store handles many skills")
    func manySkills() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        let count = 10
        for i in 0..<count {
            try store.save(Skill(name: "skill-\(String(format: "%02d", i))", description: "Skill \(i)"))
        }

        let skills = try store.discover()
        #expect(skills.count == count)
        // Verify sorted order
        for i in 0..<count {
            #expect(skills[i].name == "skill-\(String(format: "%02d", i))")
        }
    }

    @Test("Delete one skill does not affect others")
    func deleteDoesNotAffectOthers() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        try store.save(Skill(name: "keep-a", description: "Keep A"))
        try store.save(Skill(name: "remove-b", description: "Remove B"))
        try store.save(Skill(name: "keep-c", description: "Keep C"))

        try store.delete(named: "remove-b")

        let skills = try store.discover()
        #expect(skills.count == 2)
        #expect(skills.map(\.name) == ["keep-a", "keep-c"])
    }

    // MARK: - Skills with extensions and codex config

    @Test("Store preserves Claude Code extensions through save/load")
    func storeClaudeExtensions() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        var skill = Skill(name: "claude-store", description: "Claude store test")
        skill.disableModelInvocation = true
        skill.skillContext = "fork"
        try store.save(skill)

        let loaded = try store.skill(named: "claude-store")
        #expect(loaded?.disableModelInvocation == true)
        #expect(loaded?.skillContext == "fork")
    }

    @Test("Store preserves Codex configuration through save/load")
    func storeCodexConfig() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        var skill = Skill(name: "codex-store", description: "Codex store test")
        try skill.setConfiguration(CodexConfiguration(
            interface: CodexConfiguration.Interface(displayName: "Stored Skill"),
            policy: CodexConfiguration.Policy(allowImplicitInvocation: false)
        ))
        try store.save(skill)

        let loaded = try store.skill(named: "codex-store")
        let codex = try loaded?.configuration(CodexConfiguration.self)
        #expect(codex?.interface?.displayName == "Stored Skill")
        #expect(codex?.policy?.allowImplicitInvocation == false)
    }
}
