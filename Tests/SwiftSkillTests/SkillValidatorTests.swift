import Testing
@testable import SwiftSkill

@Suite("SkillValidator")
struct SkillValidatorTests {
    let validator = SkillValidator()

    // MARK: - Name validation

    @Test("Valid names pass validation")
    func validNames() {
        #expect(validator.validateName("my-skill-123").isEmpty)
        #expect(validator.validateName("a").isEmpty)
        #expect(validator.validateName("pdf-processing").isEmpty)
        #expect(validator.validateName("x").isEmpty)
    }

    @Test("Empty name fails")
    func emptyName() {
        let errors = validator.validateName("")
        #expect(errors.contains(.nameEmpty))
    }

    @Test("Name exceeding 64 characters fails")
    func nameTooLong() {
        let name = String(repeating: "a", count: 65)
        let errors = validator.validateName(name)
        #expect(errors.contains { if case .nameTooLong(65) = $0 { return true }; return false })
    }

    @Test("Name at exactly 64 characters passes")
    func nameExact64() {
        let name = String(repeating: "a", count: 64)
        #expect(validator.validateName(name).isEmpty)
    }

    @Test("Uppercase characters fail")
    func uppercaseName() {
        let errors = validator.validateName("MySkill")
        #expect(errors.contains { if case .nameInvalidCharacters = $0 { return true }; return false })
    }

    @Test("Spaces in name fail")
    func spacesInName() {
        let errors = validator.validateName("my skill")
        #expect(errors.contains { if case .nameInvalidCharacters = $0 { return true }; return false })
    }

    @Test("Underscores in name fail")
    func underscoresInName() {
        let errors = validator.validateName("my_skill")
        #expect(errors.contains { if case .nameInvalidCharacters = $0 { return true }; return false })
    }

    @Test("Name starting with hyphen fails")
    func leadingHyphen() {
        let errors = validator.validateName("-skill")
        #expect(errors.contains(.nameStartsOrEndsWithHyphen))
    }

    @Test("Name ending with hyphen fails")
    func trailingHyphen() {
        let errors = validator.validateName("skill-")
        #expect(errors.contains(.nameStartsOrEndsWithHyphen))
    }

    @Test("Consecutive hyphens fail")
    func consecutiveHyphens() {
        let errors = validator.validateName("my--skill")
        #expect(errors.contains(.nameConsecutiveHyphens))
    }

    @Test("Multiple name errors are all reported")
    func multipleNameErrors() {
        let errors = validator.validateName("-My--Skill-")
        #expect(errors.count >= 3)
    }

    // MARK: - Description validation

    @Test("Valid description passes")
    func validDescription() {
        #expect(validator.validateDescription("A useful skill").isEmpty)
    }

    @Test("Empty description fails")
    func emptyDescription() {
        let errors = validator.validateDescription("")
        #expect(errors.contains(.descriptionEmpty))
    }

    @Test("Description exceeding 1024 characters fails")
    func descriptionTooLong() {
        let desc = String(repeating: "x", count: 1025)
        let errors = validator.validateDescription(desc)
        #expect(errors.contains { if case .descriptionTooLong(1025) = $0 { return true }; return false })
    }

    @Test("Description at exactly 1024 characters passes")
    func descriptionExact1024() {
        let desc = String(repeating: "x", count: 1024)
        #expect(validator.validateDescription(desc).isEmpty)
    }

    // MARK: - Compatibility validation

    @Test("Valid compatibility passes")
    func validCompatibility() {
        #expect(validator.validateCompatibility("Requires Python 3.10+").isEmpty)
    }

    @Test("Compatibility exceeding 500 characters fails")
    func compatibilityTooLong() {
        let compat = String(repeating: "y", count: 501)
        let errors = validator.validateCompatibility(compat)
        #expect(errors.contains { if case .compatibilityTooLong(501) = $0 { return true }; return false })
    }

    // MARK: - Full skill validation

    @Test("Valid skill passes full validation")
    func validSkill() {
        let skill = Skill(name: "valid-skill", description: "A valid skill")
        #expect(validator.validate(skill).isEmpty)
    }

    @Test("Full validation aggregates all errors")
    func fullValidationAggregates() {
        let skill = Skill(
            name: "",
            description: "",
            compatibility: String(repeating: "z", count: 501)
        )
        let errors = validator.validate(skill)
        #expect(errors.contains(.nameEmpty))
        #expect(errors.contains(.descriptionEmpty))
        #expect(errors.contains { if case .compatibilityTooLong = $0 { return true }; return false })
    }

    @Test("Nil compatibility is not validated")
    func nilCompatibility() {
        let skill = Skill(name: "no-compat", description: "No compatibility field")
        let errors = validator.validate(skill)
        #expect(errors.isEmpty)
    }
}
