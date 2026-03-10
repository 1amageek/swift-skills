import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillStore")
struct SkillStoreTests {

    private func makeTempDir() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }

    // MARK: - Discovery

    @Test("Discover returns empty for missing directory")
    func discoverMissingDir() throws {
        let store = SkillStore(rootURL: makeTempDir())
        let skills = try store.discover()
        #expect(skills.isEmpty)
    }

    @Test("Discover returns empty for empty directory")
    func discoverEmptyDir() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let store = SkillStore(rootURL: dir)
        let skills = try store.discover()
        #expect(skills.isEmpty)
    }

    @Test("Discover skips directories without SKILL.md")
    func discoverSkipsMalformed() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let fm = FileManager.default
        try fm.createDirectory(
            at: dir.appending(path: "no-skill-md"),
            withIntermediateDirectories: true
        )
        try Data("not a skill".utf8).write(
            to: dir.appending(path: "no-skill-md/README.md")
        )

        let store = SkillStore(rootURL: dir)
        #expect(try store.discover().isEmpty)
    }

    @Test("Discover returns skills sorted by directory name")
    func discoverSorted() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        try store.save(Skill(name: "zebra", description: "Z"))
        try store.save(Skill(name: "alpha", description: "A"))
        try store.save(Skill(name: "middle", description: "M"))

        let skills = try store.discover()
        #expect(skills.map(\.name) == ["alpha", "middle", "zebra"])
    }

    // MARK: - Save and retrieve

    @Test("Save and discover round-trip")
    func saveAndDiscover() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        let skill = Skill(
            name: "test-skill",
            description: "A test skill for store",
            body: "Instructions."
        )
        try store.save(skill)

        let discovered = try store.discover()
        #expect(discovered.count == 1)
        #expect(discovered.first?.name == "test-skill")
        #expect(discovered.first?.body == "Instructions.")
    }

    @Test("Save skill with supporting files")
    func saveWithSupportingFiles() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        let skill = Skill(
            name: "with-files",
            description: "Has files",
            supportingFiles: [
                SupportingFile(relativePath: "scripts/run.sh", text: "echo hi"),
            ]
        )
        try store.save(skill)

        let restored = try store.skill(named: "with-files")
        #expect(restored?.supportingFiles.count == 1)
        #expect(restored?.supportingFiles.first?.textContent == "echo hi")
    }

    // MARK: - Get by name

    @Test("Get skill by name returns correct skill")
    func getByName() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        try store.save(Skill(name: "alpha", description: "Alpha skill"))
        try store.save(Skill(name: "beta", description: "Beta skill"))

        let alpha = try store.skill(named: "alpha")
        #expect(alpha?.description == "Alpha skill")

        let beta = try store.skill(named: "beta")
        #expect(beta?.description == "Beta skill")
    }

    @Test("Get nonexistent skill returns nil")
    func getMissing() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        #expect(try store.skill(named: "nonexistent") == nil)
    }

    // MARK: - Delete

    @Test("Delete removes skill directory")
    func deleteSkill() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        try store.save(Skill(name: "to-delete", description: "Will be deleted"))
        #expect(try store.skill(named: "to-delete") != nil)

        try store.delete(named: "to-delete")
        #expect(try store.skill(named: "to-delete") == nil)
    }

    @Test("Delete nonexistent skill does not throw")
    func deleteNonexistent() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let store = SkillStore(rootURL: dir)
        try store.delete(named: "does-not-exist")
    }

    // MARK: - URL resolution

    @Test("URL for skill name resolves correctly")
    func urlForSkillName() {
        let dir = URL(filePath: "/tmp/skills")
        let store = SkillStore(rootURL: dir)
        let url = store.url(forSkillNamed: "my-skill")
        #expect(url.path(percentEncoded: false).contains("my-skill"))
    }
}
