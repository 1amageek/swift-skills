import Foundation

/// A file bundled within a skill directory (scripts, references, assets).
public struct SupportingFile: Sendable, Hashable, Codable, Identifiable {
    public var id: String { relativePath }

    /// Relative path from the skill directory root.
    public var relativePath: String

    /// Raw file content.
    public var content: Data

    public init(relativePath: String, content: Data) {
        self.relativePath = relativePath
        self.content = content
    }

    /// Convenience initializer for text files.
    public init(relativePath: String, text: String) {
        self.relativePath = relativePath
        self.content = Data(text.utf8)
    }

    /// File content decoded as UTF-8 text, if possible.
    public var textContent: String? {
        String(data: content, encoding: .utf8)
    }
}
