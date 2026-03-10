import Foundation

/// Errors that can occur when parsing a skill.
public enum SkillParserError: Error, Sendable {
    case fileNotFound(URL)
    case invalidEncoding
    case missingFrontmatter
    case invalidFrontmatter(String)
    case missingRequiredField(String)
}

/// Errors that can occur when writing a skill.
public enum SkillWriterError: Error, Sendable {
    case serializationFailed(String)
    case directoryCreationFailed(URL)
    case fileWriteFailed(URL, underlying: Error)
}

/// Errors that can occur during skill validation.
public enum SkillValidationError: Error, Sendable, Hashable {
    case nameEmpty
    case nameTooLong(Int)
    case nameInvalidCharacters(String)
    case nameStartsOrEndsWithHyphen
    case nameConsecutiveHyphens
    case descriptionEmpty
    case descriptionTooLong(Int)
    case compatibilityTooLong(Int)
}
