import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillValue")
struct SkillValueTests {

    // MARK: - Value accessors

    @Test("String value accessor")
    func stringAccessor() {
        let v = SkillValue.string("hello")
        #expect(v.stringValue == "hello")
        #expect(v.boolValue == nil)
        #expect(v.intValue == nil)
    }

    @Test("Bool value accessor")
    func boolAccessor() {
        let v = SkillValue.bool(true)
        #expect(v.boolValue == true)
        #expect(v.stringValue == nil)
    }

    @Test("Int value accessor")
    func intAccessor() {
        let v = SkillValue.int(42)
        #expect(v.intValue == 42)
        #expect(v.doubleValue == nil)
    }

    @Test("Double value accessor")
    func doubleAccessor() {
        let v = SkillValue.double(3.14)
        #expect(v.doubleValue == 3.14)
        #expect(v.intValue == nil)
    }

    @Test("Array value accessor")
    func arrayAccessor() {
        let v = SkillValue.array([.string("a"), .int(1)])
        #expect(v.arrayValue?.count == 2)
        #expect(v.dictionaryValue == nil)
    }

    @Test("Dictionary value accessor")
    func dictionaryAccessor() {
        let v = SkillValue.dictionary(["key": .string("val")])
        #expect(v.dictionaryValue?["key"]?.stringValue == "val")
        #expect(v.arrayValue == nil)
    }

    @Test("Null value accessor")
    func nullAccessor() {
        let v = SkillValue.null
        #expect(v.isNull)
        #expect(v.stringValue == nil)
        #expect(v.boolValue == nil)
    }

    // MARK: - Literal conformance

    @Test("ExpressibleByStringLiteral")
    func stringLiteral() {
        let v: SkillValue = "hello"
        #expect(v == .string("hello"))
    }

    @Test("ExpressibleByBooleanLiteral")
    func boolLiteral() {
        let v: SkillValue = true
        #expect(v == .bool(true))
    }

    @Test("ExpressibleByIntegerLiteral")
    func intLiteral() {
        let v: SkillValue = 42
        #expect(v == .int(42))
    }

    @Test("ExpressibleByFloatLiteral")
    func floatLiteral() {
        let v: SkillValue = 3.14
        #expect(v == .double(3.14))
    }

    @Test("ExpressibleByArrayLiteral")
    func arrayLiteral() {
        let v: SkillValue = ["a", "b"]
        #expect(v.arrayValue?.count == 2)
    }

    @Test("ExpressibleByDictionaryLiteral")
    func dictionaryLiteral() {
        let v: SkillValue = ["key": "val"]
        #expect(v.dictionaryValue?["key"] == .string("val"))
    }

    // MARK: - Codable (JSON round-trip)

    @Test("String JSON round-trip")
    func stringJSON() throws {
        let original = SkillValue.string("hello")
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(SkillValue.self, from: data)
        #expect(restored == original)
    }

    @Test("Bool JSON round-trip")
    func boolJSON() throws {
        let original = SkillValue.bool(true)
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(SkillValue.self, from: data)
        #expect(restored == original)
    }

    @Test("Int JSON round-trip")
    func intJSON() throws {
        let original = SkillValue.int(42)
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(SkillValue.self, from: data)
        #expect(restored == original)
    }

    @Test("Double JSON round-trip")
    func doubleJSON() throws {
        let original = SkillValue.double(3.14)
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(SkillValue.self, from: data)
        #expect(restored == original)
    }

    @Test("Array JSON round-trip")
    func arrayJSON() throws {
        let original = SkillValue.array([.string("a"), .int(1), .bool(true)])
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(SkillValue.self, from: data)
        #expect(restored == original)
    }

    @Test("Dictionary JSON round-trip")
    func dictionaryJSON() throws {
        let original = SkillValue.dictionary(["key": .string("val"), "num": .int(1)])
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(SkillValue.self, from: data)
        #expect(restored == original)
    }

    @Test("Null JSON round-trip")
    func nullJSON() throws {
        let original = SkillValue.null
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(SkillValue.self, from: data)
        #expect(restored == original)
    }

    @Test("Nested structure JSON round-trip")
    func nestedJSON() throws {
        let original = SkillValue.dictionary([
            "hooks": .dictionary([
                "pre": .string("echo pre"),
                "post": .array([.string("a"), .string("b")]),
            ]),
            "count": .int(3),
        ])
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(SkillValue.self, from: data)
        #expect(restored == original)
    }

    // MARK: - Equatable / Hashable

    @Test("Same values are equal")
    func equality() {
        #expect(SkillValue.string("a") == SkillValue.string("a"))
        #expect(SkillValue.bool(true) == SkillValue.bool(true))
        #expect(SkillValue.null == SkillValue.null)
    }

    @Test("Different values are not equal")
    func inequality() {
        #expect(SkillValue.string("a") != SkillValue.string("b"))
        #expect(SkillValue.string("1") != SkillValue.int(1))
        #expect(SkillValue.bool(true) != SkillValue.int(1))
    }

    @Test("Values can be used in a Set")
    func hashableSet() {
        let set: Set<SkillValue> = [.string("a"), .string("a"), .int(1)]
        #expect(set.count == 2)
    }
}
