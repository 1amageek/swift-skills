import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillProvider")
struct SkillProviderTests {

    // MARK: - Skills relative path

    @Test("Standard provider uses 'skills' path")
    func standardPath() {
        #expect(SkillProvider.standard.skillsRelativePath == "skills")
    }

    @Test("Claude Code provider uses '.claude/skills' path")
    func claudePath() {
        #expect(SkillProvider.claudeCode.skillsRelativePath == ".claude/skills")
    }

    @Test("Codex provider uses '.agents/skills' path")
    func codexPath() {
        #expect(SkillProvider.codex.skillsRelativePath == ".agents/skills")
    }

    // MARK: - Project skills URL

    @Test("Project skills URL appends relative path to project root")
    func projectURL() {
        let root = URL(filePath: "/project")
        let url = SkillProvider.claudeCode.projectSkillsURL(in: root)
        #expect(url.path(percentEncoded: false).contains(".claude/skills"))
    }

    // MARK: - Personal skills URL

    @Test("Personal skills URL is under home directory")
    func personalURL() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        for provider in SkillProvider.allCases {
            let url = provider.personalSkillsURL
            #expect(url.path(percentEncoded: false).hasPrefix(home))
        }
    }

    // MARK: - Discovery URLs

    @Test("Discovery URLs contain project and personal paths")
    func discoveryURLs() {
        let root = URL(filePath: "/project")
        for provider in SkillProvider.allCases {
            let urls = provider.discoveryURLs(projectRoot: root)
            #expect(urls.count >= 2)
            // First URL should be project-level
            #expect(urls.first!.path(percentEncoded: false).hasPrefix("/project"))
        }
    }

    // MARK: - Codable

    @Test("SkillProvider JSON round-trip")
    func jsonRoundTrip() throws {
        for provider in SkillProvider.allCases {
            let data = try JSONEncoder().encode(provider)
            let restored = try JSONDecoder().decode(SkillProvider.self, from: data)
            #expect(restored == provider)
        }
    }

    // MARK: - CaseIterable

    @Test("All cases are present")
    func allCases() {
        #expect(SkillProvider.allCases.count == 3)
        #expect(SkillProvider.allCases.contains(.standard))
        #expect(SkillProvider.allCases.contains(.claudeCode))
        #expect(SkillProvider.allCases.contains(.codex))
    }
}
