import Foundation

/// Identifies which agent platform a skill targets.
public enum SkillProvider: String, Sendable, CaseIterable, Codable {
    /// Agent Skills open standard (agentskills.io).
    case standard

    /// Claude Code (.claude/skills/).
    case claudeCode

    /// OpenAI Codex (.agents/skills/).
    case codex

    /// Relative path from a project or home root to the skills directory.
    public var skillsRelativePath: String {
        switch self {
        case .standard:  return "skills"
        case .claudeCode: return ".claude/skills"
        case .codex:      return ".agents/skills"
        }
    }

    /// Personal (user-level) skills directory URL.
    public var personalSkillsURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appending(path: skillsRelativePath, directoryHint: .isDirectory)
    }

    /// Project-level skills directory URL for a given project root.
    public func projectSkillsURL(in projectRoot: URL) -> URL {
        projectRoot.appending(path: skillsRelativePath, directoryHint: .isDirectory)
    }

    /// All candidate directories to scan for skills, ordered by priority (highest first).
    public func discoveryURLs(projectRoot: URL) -> [URL] {
        switch self {
        case .standard:
            return [
                projectRoot.appending(path: "skills", directoryHint: .isDirectory),
                personalSkillsURL,
            ]
        case .claudeCode:
            return [
                projectRoot.appending(path: ".claude/skills", directoryHint: .isDirectory),
                personalSkillsURL,
            ]
        case .codex:
            return [
                projectRoot.appending(path: ".agents/skills", directoryHint: .isDirectory),
                FileManager.default.homeDirectoryForCurrentUser
                    .appending(path: ".agents/skills", directoryHint: .isDirectory),
            ]
        }
    }
}
