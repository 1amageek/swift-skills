import Testing
import Foundation
@testable import SwiftSkill

@Suite("CodexConfiguration")
struct CodexConfigurationTests {

    // MARK: - JSON round-trip

    @Test("Full configuration JSON round-trip")
    func jsonRoundTrip() throws {
        let original = CodexConfiguration(
            interface: CodexConfiguration.Interface(
                displayName: "My Skill",
                shortDescription: "Does things",
                iconSmall: "./small.svg",
                iconLarge: "./large.png",
                brandColor: "#3B82F6",
                defaultPrompt: "Do the thing"
            ),
            policy: CodexConfiguration.Policy(allowImplicitInvocation: false),
            dependencies: CodexConfiguration.Dependencies(
                tools: [
                    CodexConfiguration.ToolDependency(
                        type: "mcp",
                        value: "my-server",
                        description: "My MCP server",
                        transport: "streamable_http",
                        url: "https://example.com"
                    ),
                ]
            )
        )
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(CodexConfiguration.self, from: data)

        #expect(restored.interface?.displayName == "My Skill")
        #expect(restored.interface?.shortDescription == "Does things")
        #expect(restored.interface?.iconSmall == "./small.svg")
        #expect(restored.interface?.iconLarge == "./large.png")
        #expect(restored.interface?.brandColor == "#3B82F6")
        #expect(restored.interface?.defaultPrompt == "Do the thing")
        #expect(restored.policy?.allowImplicitInvocation == false)
        #expect(restored.dependencies?.tools?.count == 1)
        #expect(restored.dependencies?.tools?.first?.type == "mcp")
        #expect(restored.dependencies?.tools?.first?.value == "my-server")
        #expect(restored.dependencies?.tools?.first?.url == "https://example.com")
    }

    @Test("Empty configuration JSON round-trip")
    func emptyRoundTrip() throws {
        let original = CodexConfiguration()
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(CodexConfiguration.self, from: data)
        #expect(restored.interface == nil)
        #expect(restored.policy == nil)
        #expect(restored.dependencies == nil)
    }

    @Test("Partial configuration JSON round-trip")
    func partialRoundTrip() throws {
        let original = CodexConfiguration(
            policy: CodexConfiguration.Policy(allowImplicitInvocation: true)
        )
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(CodexConfiguration.self, from: data)
        #expect(restored.interface == nil)
        #expect(restored.policy?.allowImplicitInvocation == true)
        #expect(restored.dependencies == nil)
    }

    // MARK: - Equatable / Hashable

    @Test("Same configurations are equal")
    func equality() {
        let a = CodexConfiguration(
            interface: CodexConfiguration.Interface(displayName: "X")
        )
        let b = CodexConfiguration(
            interface: CodexConfiguration.Interface(displayName: "X")
        )
        #expect(a == b)
    }

    @Test("Different configurations are not equal")
    func inequality() {
        let a = CodexConfiguration(
            interface: CodexConfiguration.Interface(displayName: "X")
        )
        let b = CodexConfiguration(
            interface: CodexConfiguration.Interface(displayName: "Y")
        )
        #expect(a != b)
    }

    // MARK: - ToolDependency

    @Test("ToolDependency JSON round-trip")
    func toolDependencyRoundTrip() throws {
        let original = CodexConfiguration.ToolDependency(
            type: "mcp",
            value: "server-id",
            description: "A server",
            transport: "stdio",
            url: nil
        )
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(
            CodexConfiguration.ToolDependency.self, from: data
        )
        #expect(restored.type == "mcp")
        #expect(restored.value == "server-id")
        #expect(restored.description == "A server")
        #expect(restored.transport == "stdio")
        #expect(restored.url == nil)
    }
}
