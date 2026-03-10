import Testing
import Foundation
@testable import SwiftSkill

@Suite("Integration")
struct SkillIntegrationTests {

    private func makeTempDir() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }

    // MARK: - End-to-end workflow

    @Test("Full workflow: create, validate, save, discover, modify, resave, read")
    func fullWorkflow() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let validator = SkillValidator()
        let store = SkillStore(rootURL: dir)

        // 1. Create
        var skill = Skill(
            name: "workflow-skill",
            description: "A skill for workflow testing",
            license: "MIT",
            allowedTools: ["Read", "Grep"],
            body: "## Steps\n\n1. Do something\n2. Done"
        )
        skill.disableModelInvocation = true

        // 2. Validate
        let errors = validator.validate(skill)
        #expect(errors.isEmpty)

        // 3. Save
        try store.save(skill)

        // 4. Discover
        let discovered = try store.discover()
        #expect(discovered.count == 1)
        #expect(discovered.first?.name == "workflow-skill")

        // 5. Modify
        var modified = discovered.first!
        modified.description = "Updated description"
        modified.disableModelInvocation = false
        modified.allowedTools = ["Read", "Grep", "Glob"]

        // 6. Re-validate
        #expect(validator.validate(modified).isEmpty)

        // 7. Resave
        try store.save(modified)

        // 8. Read
        let final = try store.skill(named: "workflow-skill")
        #expect(final?.description == "Updated description")
        #expect(final?.disableModelInvocation == false)
        #expect(final?.allowedTools == ["Read", "Grep", "Glob"])
        #expect(final?.license == "MIT")
        #expect(final?.body.contains("## Steps") == true)
    }

    // MARK: - Cross-format: YAML ↔ JSON

    @Test("Skill survives YAML → JSON → YAML round-trip")
    func yamlJsonYamlRoundTrip() throws {
        let parser = SkillParser()
        let writer = SkillWriter()

        // Start with YAML (SKILL.md format)
        let yamlContent = """
        ---
        name: cross-format
        description: Cross-format round-trip test
        license: Apache-2.0
        metadata:
          author: test-org
          version: "1.0"
        allowed-tools: Read, Grep
        disable-model-invocation: true
        context: fork
        ---

        Process data using the bundled script.
        """
        let skill1 = try parser.parse(yamlContent)

        // Convert to JSON
        let jsonData = try JSONEncoder().encode(skill1)

        // Convert back from JSON
        let skill2 = try JSONDecoder().decode(Skill.self, from: jsonData)

        // Convert back to YAML
        let yamlOutput = try writer.write(skill2)

        // Parse the YAML again
        let skill3 = try parser.parse(yamlOutput)

        // Verify all fields survived
        #expect(skill3.name == "cross-format")
        #expect(skill3.description == "Cross-format round-trip test")
        #expect(skill3.license == "Apache-2.0")
        #expect(skill3.metadata?["author"] == "test-org")
        #expect(skill3.allowedTools == ["Read", "Grep"])
        #expect(skill3.disableModelInvocation == true)
        #expect(skill3.skillContext == "fork")
        #expect(skill3.body.contains("Process data"))
    }

    // MARK: - Multi-skill store with mixed providers

    @Test("Store multiple skills with different extension profiles")
    func mixedSkillProfiles() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)

        // Pure standard skill
        try store.save(Skill(
            name: "standard-skill",
            description: "Standard only",
            license: "MIT",
            body: "Standard instructions."
        ))

        // Claude Code skill
        var claudeSkill = Skill(
            name: "claude-skill",
            description: "Claude Code skill",
            body: "Deploy to $ARGUMENTS."
        )
        claudeSkill.disableModelInvocation = true
        claudeSkill.skillContext = "fork"
        claudeSkill.agent = "Explore"
        try store.save(claudeSkill)

        // Codex skill
        var codexSkill = Skill(
            name: "codex-skill",
            description: "Codex skill",
            body: "Run codex tasks."
        )
        try codexSkill.setConfiguration(CodexConfiguration(
            interface: CodexConfiguration.Interface(displayName: "Codex Skill"),
            policy: CodexConfiguration.Policy(allowImplicitInvocation: false)
        ))
        try store.save(codexSkill)

        // Discover all
        let skills = try store.discover()
        #expect(skills.count == 3)

        // Verify each retains its profile
        let standard = skills.first { $0.name == "standard-skill" }
        #expect(standard?.license == "MIT")
        #expect(standard?.extensions.isEmpty == true)
        #expect(standard?.configurations.isEmpty == true)

        let claude = skills.first { $0.name == "claude-skill" }
        #expect(claude?.disableModelInvocation == true)
        #expect(claude?.skillContext == "fork")
        #expect(claude?.agent == "Explore")

        let codex = skills.first { $0.name == "codex-skill" }
        let codexConfig = try codex?.configuration(CodexConfiguration.self)
        #expect(codexConfig?.interface?.displayName == "Codex Skill")
        #expect(codexConfig?.policy?.allowImplicitInvocation == false)
    }

    // MARK: - Skill with complete supporting files

    @Test("Full skill with scripts, references, and assets round-trips through store")
    func fullSkillWithFiles() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SkillStore(rootURL: dir)
        let skill = Skill(
            name: "full-skill",
            description: "A complete skill with all file types",
            body: "See supporting files for details.",
            supportingFiles: [
                SupportingFile(relativePath: "scripts/extract.py", text: "#!/usr/bin/env python3\nprint('extract')"),
                SupportingFile(relativePath: "scripts/validate.sh", text: "#!/bin/bash\necho 'validate'"),
                SupportingFile(relativePath: "references/REFERENCE.md", text: "# API Reference\n\nDetails here."),
                SupportingFile(relativePath: "assets/template.json", text: "{\"key\": \"value\"}"),
            ]
        )
        try store.save(skill)

        let loaded = try store.skill(named: "full-skill")
        #expect(loaded != nil)
        #expect(loaded?.supportingFiles.count == 4)

        let paths = Set(loaded?.supportingFiles.map(\.relativePath) ?? [])
        #expect(paths.contains("scripts/extract.py"))
        #expect(paths.contains("scripts/validate.sh"))
        #expect(paths.contains("references/REFERENCE.md"))
        #expect(paths.contains("assets/template.json"))

        // Verify file content
        let template = loaded?.supportingFiles.first { $0.relativePath == "assets/template.json" }
        #expect(template?.textContent == "{\"key\": \"value\"}")
    }

    // MARK: - Provider path resolution

    @Test("SkillStore works with Claude Code provider paths")
    func claudeCodeProviderPaths() throws {
        let projectDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: projectDir) }

        let provider = SkillProvider.claudeCode
        let skillsURL = provider.projectSkillsURL(in: projectDir)

        let store = SkillStore(rootURL: skillsURL)
        try store.save(Skill(name: "claude-path", description: "Claude path test"))

        let skill = try store.skill(named: "claude-path")
        #expect(skill != nil)

        // Verify it's under .claude/skills/
        let skillPath = store.url(forSkillNamed: "claude-path").path(percentEncoded: false)
        #expect(skillPath.contains(".claude/skills/claude-path"))
    }

    @Test("SkillStore works with Codex provider paths")
    func codexProviderPaths() throws {
        let projectDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: projectDir) }

        let provider = SkillProvider.codex
        let skillsURL = provider.projectSkillsURL(in: projectDir)

        let store = SkillStore(rootURL: skillsURL)
        try store.save(Skill(name: "codex-path", description: "Codex path test"))

        let skill = try store.skill(named: "codex-path")
        #expect(skill != nil)

        let skillPath = store.url(forSkillNamed: "codex-path").path(percentEncoded: false)
        #expect(skillPath.contains(".agents/skills/codex-path"))
    }

    // MARK: - Validation prevents invalid saves

    @Test("Validator catches issues before saving to store")
    func validateBeforeSave() throws {
        let validator = SkillValidator()

        // Invalid skill
        let badSkill = Skill(name: "Bad--Name", description: "")
        let errors = validator.validate(badSkill)
        #expect(!errors.isEmpty)
        #expect(errors.contains { if case .nameInvalidCharacters = $0 { return true }; return false })
        #expect(errors.contains(.nameConsecutiveHyphens))
        #expect(errors.contains(.descriptionEmpty))
    }
}
