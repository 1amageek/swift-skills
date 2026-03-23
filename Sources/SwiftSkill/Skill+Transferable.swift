#if canImport(CoreTransferable) && canImport(UniformTypeIdentifiers)
import CoreTransferable
import UniformTypeIdentifiers

extension UTType {
    /// Uniform type identifier for Agent Skills.
    public static let agentSkill = UTType(exportedAs: "io.agentskills.skill")
}

extension Skill: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .agentSkill)

        FileRepresentation(contentType: .agentSkill) { skill in
            let tempDir = FileManager.default.temporaryDirectory
                .appending(path: "swift-skill-transfer", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let bundleURL = tempDir.appending(path: "\(skill.name).skill", directoryHint: .isDirectory)
            if FileManager.default.fileExists(atPath: bundleURL.path) {
                try FileManager.default.removeItem(at: bundleURL)
            }

            let writer = SkillWriter()
            try writer.writeDirectory(skill, to: bundleURL)
            return SentTransferredFile(bundleURL)
        } importing: { received in
            let parser = SkillParser()
            return try parser.parseDirectory(at: received.file)
        }
    }
}
#endif
