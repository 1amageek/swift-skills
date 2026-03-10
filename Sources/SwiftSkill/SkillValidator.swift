import Foundation

/// Validates a `Skill` against the Agent Skills specification.
public struct SkillValidator: Sendable {

    public init() {}

    /// Validate a skill and return all detected errors.
    public func validate(_ skill: Skill) -> [SkillValidationError] {
        var errors: [SkillValidationError] = []
        errors.append(contentsOf: validateName(skill.name))
        errors.append(contentsOf: validateDescription(skill.description))
        if let compatibility = skill.compatibility {
            errors.append(contentsOf: validateCompatibility(compatibility))
        }
        return errors
    }

    /// Validate the skill name field.
    public func validateName(_ name: String) -> [SkillValidationError] {
        var errors: [SkillValidationError] = []

        if name.isEmpty {
            errors.append(.nameEmpty)
            return errors
        }

        if name.count > 64 {
            errors.append(.nameTooLong(name.count))
        }

        // Must only contain lowercase alphanumeric and hyphens
        let allowed = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "-"))
        let nameScalars = CharacterSet(charactersIn: name)
        if !allowed.isSuperset(of: nameScalars) {
            let invalidChars = name.unicodeScalars
                .filter { !allowed.contains($0) }
                .map { String($0) }
                .joined()
            errors.append(.nameInvalidCharacters(invalidChars))
        }

        if name.hasPrefix("-") || name.hasSuffix("-") {
            errors.append(.nameStartsOrEndsWithHyphen)
        }

        if name.contains("--") {
            errors.append(.nameConsecutiveHyphens)
        }

        return errors
    }

    /// Validate the description field.
    public func validateDescription(_ description: String) -> [SkillValidationError] {
        var errors: [SkillValidationError] = []

        if description.isEmpty {
            errors.append(.descriptionEmpty)
        }

        if description.count > 1024 {
            errors.append(.descriptionTooLong(description.count))
        }

        return errors
    }

    /// Validate the compatibility field.
    public func validateCompatibility(_ compatibility: String) -> [SkillValidationError] {
        if compatibility.count > 500 {
            return [.compatibilityTooLong(compatibility.count)]
        }
        return []
    }
}
