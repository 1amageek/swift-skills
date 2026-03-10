// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftSkill",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "SwiftSkill",
            targets: ["SwiftSkill"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftSkill",
            dependencies: ["Yams"]
        ),
        .testTarget(
            name: "SwiftSkillTests",
            dependencies: ["SwiftSkill"]
        ),
    ]
)
