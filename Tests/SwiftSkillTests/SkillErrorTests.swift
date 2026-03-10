import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillError")
struct SkillErrorTests {

    // MARK: - SkillParserError

    @Test("SkillParserError cases carry associated values")
    func parserErrorValues() {
        let url = URL(filePath: "/test/SKILL.md")
        let errors: [SkillParserError] = [
            .fileNotFound(url),
            .invalidEncoding,
            .missingFrontmatter,
            .invalidFrontmatter("bad yaml"),
            .missingRequiredField("name"),
        ]
        #expect(errors.count == 5)
    }

    // MARK: - SkillWriterError

    @Test("SkillWriterError cases carry associated values")
    func writerErrorValues() {
        let url = URL(filePath: "/test/SKILL.md")
        let underlying = NSError(domain: "test", code: 1)
        let errors: [SkillWriterError] = [
            .serializationFailed("reason"),
            .directoryCreationFailed(url),
            .fileWriteFailed(url, underlying: underlying),
        ]
        #expect(errors.count == 3)
    }

    // MARK: - SkillValidationError

    @Test("SkillValidationError Hashable conformance")
    func validationErrorHashable() {
        let set: Set<SkillValidationError> = [
            .nameEmpty,
            .nameEmpty,
            .nameTooLong(65),
            .descriptionEmpty,
        ]
        #expect(set.count == 3)
    }

    @Test("SkillValidationError equality")
    func validationErrorEquality() {
        #expect(SkillValidationError.nameEmpty == SkillValidationError.nameEmpty)
        #expect(SkillValidationError.nameTooLong(65) == SkillValidationError.nameTooLong(65))
        #expect(SkillValidationError.nameTooLong(65) != SkillValidationError.nameTooLong(66))
    }
}
