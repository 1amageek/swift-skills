import Testing
import Foundation
@testable import SwiftSkill

@Suite("SupportingFile")
struct SupportingFileTests {

    // MARK: - Initialization

    @Test("Data initializer stores raw content")
    func dataInit() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])
        let file = SupportingFile(relativePath: "test.bin", content: data)
        #expect(file.relativePath == "test.bin")
        #expect(file.content == data)
    }

    @Test("Text initializer converts to UTF-8 Data")
    func textInit() {
        let file = SupportingFile(relativePath: "readme.md", text: "Hello")
        #expect(file.textContent == "Hello")
        #expect(file.content == Data("Hello".utf8))
    }

    // MARK: - textContent

    @Test("textContent returns nil for non-UTF8 data")
    func nonUTF8() {
        let invalidUTF8 = Data([0xFF, 0xFE, 0x80])
        let file = SupportingFile(relativePath: "binary.dat", content: invalidUTF8)
        #expect(file.textContent == nil)
    }

    @Test("textContent returns empty string for empty data")
    func emptyContent() {
        let file = SupportingFile(relativePath: "empty.txt", content: Data())
        #expect(file.textContent == "")
    }

    // MARK: - Identifiable

    @Test("id equals relativePath")
    func identifiable() {
        let file = SupportingFile(relativePath: "scripts/run.sh", text: "echo hi")
        #expect(file.id == "scripts/run.sh")
    }

    // MARK: - Equatable / Hashable

    @Test("Files with same path and content are equal")
    func equality() {
        let a = SupportingFile(relativePath: "a.txt", text: "content")
        let b = SupportingFile(relativePath: "a.txt", text: "content")
        #expect(a == b)
    }

    @Test("Files with different paths are not equal")
    func inequalityPath() {
        let a = SupportingFile(relativePath: "a.txt", text: "content")
        let b = SupportingFile(relativePath: "b.txt", text: "content")
        #expect(a != b)
    }

    @Test("Files with different content are not equal")
    func inequalityContent() {
        let a = SupportingFile(relativePath: "a.txt", text: "one")
        let b = SupportingFile(relativePath: "a.txt", text: "two")
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("JSON round-trip preserves data")
    func jsonRoundTrip() throws {
        let original = SupportingFile(relativePath: "scripts/helper.py", text: "print('hi')")
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(SupportingFile.self, from: data)
        #expect(restored == original)
    }
}
