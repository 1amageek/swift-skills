import Foundation

/// Dynamic value type for representing arbitrary YAML frontmatter values.
public enum SkillValue: Sendable, Hashable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case array([SkillValue])
    case dictionary([String: SkillValue])
    case null

    public var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }

    public var intValue: Int? {
        if case .int(let v) = self { return v }
        return nil
    }

    public var doubleValue: Double? {
        if case .double(let v) = self { return v }
        return nil
    }

    public var arrayValue: [SkillValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    public var dictionaryValue: [String: SkillValue]? {
        if case .dictionary(let v) = self { return v }
        return nil
    }

    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}

// MARK: - Codable

extension SkillValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([SkillValue].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: SkillValue].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported SkillValue type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .dictionary(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Conversion from Any (Yams output)

extension SkillValue {
    /// Convert from an untyped YAML-parsed value.
    package init(fromAny value: Any) {
        // Bool must be checked before Int because NSNumber(bool:) can cast to Int.
        if let b = value as? Bool {
            self = .bool(b)
        } else if let i = value as? Int {
            self = .int(i)
        } else if let d = value as? Double {
            self = .double(d)
        } else if let s = value as? String {
            self = .string(s)
        } else if let arr = value as? [Any] {
            self = .array(arr.map { SkillValue(fromAny: $0) })
        } else if let dict = value as? [String: Any] {
            self = .dictionary(dict.mapValues { SkillValue(fromAny: $0) })
        } else {
            self = .null
        }
    }

    /// Convert back to an untyped value for Yams serialization.
    package var toAny: Any {
        switch self {
        case .string(let v): return v
        case .bool(let v): return v
        case .int(let v): return v
        case .double(let v): return v
        case .array(let v): return v.map(\.toAny)
        case .dictionary(let v): return v.mapValues(\.toAny)
        case .null: return NSNull()
        }
    }
}

// MARK: - ExpressibleBy Literals

extension SkillValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}

extension SkillValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

extension SkillValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .int(value) }
}

extension SkillValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension SkillValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: SkillValue...) { self = .array(elements) }
}

extension SkillValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, SkillValue)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}
