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
    }
}
#endif
