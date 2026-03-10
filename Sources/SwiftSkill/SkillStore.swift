import Foundation

/// File-system backed storage for discovering, reading, and writing skills.
public struct SkillStore: Sendable {
    /// Root directory where skills are stored.
    public let rootURL: URL

    private let parser: SkillParser
    private let writer: SkillWriter

    public init(rootURL: URL, parser: SkillParser = SkillParser(), writer: SkillWriter = SkillWriter()) {
        self.rootURL = rootURL
        self.parser = parser
        self.writer = writer
    }

    // MARK: - Discovery

    /// Discover all skills in the root directory.
    ///
    /// Each immediate subdirectory containing a SKILL.md is treated as a skill.
    public func discover() throws -> [Skill] {
        let fm = FileManager.default
        let rootPath = rootURL.path(percentEncoded: false)
        guard fm.fileExists(atPath: rootPath) else { return [] }

        let contents = try fm.contentsOfDirectory(atPath: rootPath)
        var skills: [Skill] = []

        for name in contents.sorted() {
            let dirURL = rootURL.appending(path: name, directoryHint: .isDirectory)
            let skillMD = dirURL.appending(path: "SKILL.md")
            guard fm.fileExists(atPath: skillMD.path(percentEncoded: false)) else { continue }

            do {
                let skill = try parser.parseDirectory(at: dirURL)
                skills.append(skill)
            } catch {
                // Skip malformed skills
                continue
            }
        }
        return skills
    }

    /// Get a specific skill by name.
    public func skill(named name: String) throws -> Skill? {
        let dirURL = rootURL.appending(path: name, directoryHint: .isDirectory)
        let skillMD = dirURL.appending(path: "SKILL.md")
        guard FileManager.default.fileExists(atPath: skillMD.path(percentEncoded: false)) else {
            return nil
        }
        return try parser.parseDirectory(at: dirURL)
    }

    /// Save a skill, creating its directory structure.
    ///
    /// The skill is written to `rootURL/<skill.name>/`.
    public func save(_ skill: Skill) throws {
        let dirURL = rootURL.appending(path: skill.name, directoryHint: .isDirectory)
        try writer.writeDirectory(skill, to: dirURL)
    }

    /// Delete a skill directory by name.
    public func delete(named name: String) throws {
        let dirURL = rootURL.appending(path: name, directoryHint: .isDirectory)
        let fm = FileManager.default
        if fm.fileExists(atPath: dirURL.path(percentEncoded: false)) {
            try fm.removeItem(at: dirURL)
        }
    }

    /// URL for a skill directory by name.
    public func url(forSkillNamed name: String) -> URL {
        rootURL.appending(path: name, directoryHint: .isDirectory)
    }
}
