import Testing
import Foundation
@testable import SwiftSkill

@Suite("Skill Mutation")
struct SkillMutationTests {

    // MARK: - Claude Code property mutation

    @Test("Setting Claude property multiple times preserves last value")
    func claudePropertyMultipleMutations() {
        var skill = Skill(name: "mutate", description: "Test")

        skill.disableModelInvocation = true
        #expect(skill.disableModelInvocation == true)

        skill.disableModelInvocation = false
        #expect(skill.disableModelInvocation == false)

        skill.disableModelInvocation = true
        #expect(skill.disableModelInvocation == true)
    }

    @Test("Setting all Claude properties independently")
    func independentClaudeProperties() {
        var skill = Skill(name: "independent", description: "Test")

        skill.model = "opus"
        skill.agent = "Explore"
        #expect(skill.model == "opus")
        #expect(skill.agent == "Explore")

        // Changing one doesn't affect the other
        skill.model = "sonnet"
        #expect(skill.model == "sonnet")
        #expect(skill.agent == "Explore")
    }

    @Test("Clearing all Claude properties leaves empty extensions")
    func clearAllClaudeProperties() {
        var skill = Skill(name: "clear-all", description: "Test")
        skill.disableModelInvocation = true
        skill.userInvocable = false
        skill.argumentHint = "[env]"
        skill.model = "opus"
        skill.skillContext = "fork"
        skill.agent = "Explore"

        #expect(skill.extensions.count == 6)

        skill.disableModelInvocation = nil
        skill.userInvocable = nil
        skill.argumentHint = nil
        skill.model = nil
        skill.skillContext = nil
        skill.agent = nil

        #expect(skill.extensions.isEmpty)
    }

    // MARK: - Codex property mutation

    @Test("Setting Codex properties multiple times preserves last value")
    func codexMultipleMutations() {
        var skill = Skill(name: "codex-mutate", description: "Test")

        skill.allowImplicitInvocation = true
        #expect(skill.allowImplicitInvocation == true)

        skill.allowImplicitInvocation = false
        #expect(skill.allowImplicitInvocation == false)
    }

    @Test("Setting Codex display name and policy independently")
    func independentCodexProperties() {
        var skill = Skill(name: "codex-indep", description: "Test")

        skill.codexDisplayName = "First"
        skill.allowImplicitInvocation = true
        #expect(skill.codexDisplayName == "First")
        #expect(skill.allowImplicitInvocation == true)

        skill.codexDisplayName = "Second"
        #expect(skill.codexDisplayName == "Second")
        #expect(skill.allowImplicitInvocation == true)
    }

    // MARK: - Mixed mutations

    @Test("Claude and Codex properties coexist independently")
    func claudeAndCodexCoexist() throws {
        var skill = Skill(name: "mixed", description: "Test")

        skill.disableModelInvocation = true
        skill.allowImplicitInvocation = false

        #expect(skill.disableModelInvocation == true)
        #expect(skill.allowImplicitInvocation == false)

        // Extensions and configurations are separate stores
        #expect(skill.extensions["disable-model-invocation"] == .bool(true))
        let codex = try skill.configuration(CodexConfiguration.self)
        #expect(codex?.policy?.allowImplicitInvocation == false)
    }

    // MARK: - Standard field mutations

    @Test("Mutating standard fields preserves other fields")
    func mutateStandardFields() {
        var skill = Skill(
            name: "std-mutate",
            description: "Original",
            license: "MIT",
            body: "Body."
        )

        skill.description = "Changed"
        #expect(skill.description == "Changed")
        #expect(skill.license == "MIT")
        #expect(skill.body == "Body.")
    }

    @Test("Adding and removing allowed tools")
    func mutateAllowedTools() {
        var skill = Skill(name: "tools", description: "Test")
        #expect(skill.allowedTools == nil)

        skill.allowedTools = ["Read"]
        #expect(skill.allowedTools == ["Read"])

        skill.allowedTools?.append("Grep")
        #expect(skill.allowedTools == ["Read", "Grep"])

        skill.allowedTools = nil
        #expect(skill.allowedTools == nil)
    }

    @Test("Adding and removing metadata entries")
    func mutateMetadata() {
        var skill = Skill(name: "meta-mut", description: "Test")

        skill.metadata = ["author": "alice"]
        #expect(skill.metadata?["author"] == "alice")

        skill.metadata?["version"] = "2.0"
        #expect(skill.metadata?.count == 2)

        skill.metadata?["author"] = nil
        #expect(skill.metadata?.count == 1)
        #expect(skill.metadata?["version"] == "2.0")
    }

    @Test("Adding and removing supporting files")
    func mutateSupportingFiles() {
        var skill = Skill(name: "files-mut", description: "Test")
        #expect(skill.supportingFiles.isEmpty)

        skill.supportingFiles.append(
            SupportingFile(relativePath: "scripts/run.sh", text: "echo hi")
        )
        #expect(skill.supportingFiles.count == 1)

        skill.supportingFiles.append(
            SupportingFile(relativePath: "references/API.md", text: "# API")
        )
        #expect(skill.supportingFiles.count == 2)

        skill.supportingFiles.removeAll { $0.relativePath == "scripts/run.sh" }
        #expect(skill.supportingFiles.count == 1)
        #expect(skill.supportingFiles.first?.relativePath == "references/API.md")
    }

    // MARK: - Extensions dictionary direct manipulation

    @Test("Direct extensions manipulation is reflected in Claude properties")
    func directExtensionManipulation() {
        var skill = Skill(name: "direct-ext", description: "Test")

        skill.extensions["disable-model-invocation"] = .bool(true)
        #expect(skill.disableModelInvocation == true)

        skill.extensions["context"] = .string("fork")
        #expect(skill.skillContext == "fork")

        skill.extensions.removeValue(forKey: "disable-model-invocation")
        #expect(skill.disableModelInvocation == nil)
    }

    @Test("Wrong type in extensions returns nil for typed accessor")
    func wrongTypeInExtensions() {
        var skill = Skill(name: "wrong-type", description: "Test")

        // Store a string where bool is expected
        skill.extensions["disable-model-invocation"] = .string("not-a-bool")
        #expect(skill.disableModelInvocation == nil)

        // Store an int where string is expected
        skill.extensions["model"] = .int(42)
        #expect(skill.model == nil)
    }
}
