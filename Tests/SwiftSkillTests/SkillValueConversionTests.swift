import Testing
import Foundation
@testable import SwiftSkill

@Suite("SkillValue Conversion")
struct SkillValueConversionTests {

    // MARK: - fromAny

    @Test("fromAny with String")
    func fromAnyString() {
        let v = SkillValue(fromAny: "hello" as Any)
        #expect(v == .string("hello"))
    }

    @Test("fromAny with empty String")
    func fromAnyEmptyString() {
        let v = SkillValue(fromAny: "" as Any)
        #expect(v == .string(""))
    }

    @Test("fromAny with Bool true")
    func fromAnyBoolTrue() {
        let v = SkillValue(fromAny: true as Any)
        #expect(v == .bool(true))
    }

    @Test("fromAny with Bool false")
    func fromAnyBoolFalse() {
        let v = SkillValue(fromAny: false as Any)
        #expect(v == .bool(false))
    }

    @Test("fromAny with Int")
    func fromAnyInt() {
        let v = SkillValue(fromAny: 42 as Any)
        #expect(v == .int(42))
    }

    @Test("fromAny with negative Int")
    func fromAnyNegativeInt() {
        let v = SkillValue(fromAny: -7 as Any)
        #expect(v == .int(-7))
    }

    @Test("fromAny with zero Int")
    func fromAnyZeroInt() {
        let v = SkillValue(fromAny: 0 as Any)
        #expect(v == .int(0))
    }

    @Test("fromAny with Double")
    func fromAnyDouble() {
        let v = SkillValue(fromAny: 3.14 as Any)
        #expect(v == .double(3.14))
    }

    @Test("fromAny with Array")
    func fromAnyArray() {
        let v = SkillValue(fromAny: ["a", "b"] as Any)
        #expect(v.arrayValue?.count == 2)
        #expect(v.arrayValue?[0] == .string("a"))
        #expect(v.arrayValue?[1] == .string("b"))
    }

    @Test("fromAny with empty Array")
    func fromAnyEmptyArray() {
        let v = SkillValue(fromAny: [Any]() as Any)
        #expect(v == .array([]))
    }

    @Test("fromAny with Dictionary")
    func fromAnyDictionary() {
        let v = SkillValue(fromAny: ["key": "val"] as Any)
        #expect(v.dictionaryValue?["key"] == .string("val"))
    }

    @Test("fromAny with empty Dictionary")
    func fromAnyEmptyDictionary() {
        let v = SkillValue(fromAny: [String: Any]() as Any)
        #expect(v == .dictionary([:]))
    }

    @Test("fromAny with NSNull")
    func fromAnyNSNull() {
        let v = SkillValue(fromAny: NSNull() as Any)
        #expect(v == .null)
    }

    @Test("fromAny with nested structure")
    func fromAnyNested() {
        let input: [String: Any] = [
            "list": [1, 2, 3],
            "flag": true,
        ]
        let v = SkillValue(fromAny: input as Any)
        let dict = v.dictionaryValue
        #expect(dict?["flag"] == .bool(true))
        #expect(dict?["list"]?.arrayValue?.count == 3)
    }

    @Test("fromAny with unknown type falls back to null")
    func fromAnyUnknown() {
        struct CustomType {}
        let v = SkillValue(fromAny: CustomType() as Any)
        #expect(v == .null)
    }

    // MARK: - toAny

    @Test("toAny String round-trip")
    func toAnyString() {
        let v = SkillValue.string("test")
        let any = v.toAny
        #expect(any as? String == "test")
    }

    @Test("toAny Bool round-trip")
    func toAnyBool() {
        let v = SkillValue.bool(true)
        let any = v.toAny
        #expect(any as? Bool == true)
    }

    @Test("toAny Int round-trip")
    func toAnyInt() {
        let v = SkillValue.int(42)
        let any = v.toAny
        #expect(any as? Int == 42)
    }

    @Test("toAny Double round-trip")
    func toAnyDouble() {
        let v = SkillValue.double(3.14)
        let any = v.toAny
        #expect(any as? Double == 3.14)
    }

    @Test("toAny Array round-trip")
    func toAnyArray() {
        let v = SkillValue.array([.string("a"), .int(1)])
        let any = v.toAny as? [Any]
        #expect(any?.count == 2)
        #expect(any?[0] as? String == "a")
        #expect(any?[1] as? Int == 1)
    }

    @Test("toAny Dictionary round-trip")
    func toAnyDictionary() {
        let v = SkillValue.dictionary(["k": .string("v")])
        let any = v.toAny as? [String: Any]
        #expect(any?["k"] as? String == "v")
    }

    @Test("toAny null returns NSNull")
    func toAnyNull() {
        let v = SkillValue.null
        #expect(v.toAny is NSNull)
    }

    // MARK: - fromAny → toAny round-trip

    @Test("fromAny then toAny preserves String")
    func roundTripString() {
        let original: Any = "hello"
        let v = SkillValue(fromAny: original)
        #expect(v.toAny as? String == "hello")
    }

    @Test("fromAny then toAny preserves Int")
    func roundTripInt() {
        let original: Any = 99
        let v = SkillValue(fromAny: original)
        #expect(v.toAny as? Int == 99)
    }

    @Test("fromAny then toAny preserves Bool")
    func roundTripBool() {
        let original: Any = false
        let v = SkillValue(fromAny: original)
        #expect(v.toAny as? Bool == false)
    }
}
