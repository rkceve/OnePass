// swift-tools-version: 6.0
import PackageDescription

// Owned by the orchestrator (see docs/CONTRACTS.md §1). Agents request changes instead of editing.
let package = Package(
    name: "OnePassCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "OnePassModels", targets: ["OnePassModels"]),
        .library(name: "OnePassStorage", targets: ["OnePassStorage"]),
        .library(name: "OnePassMail", targets: ["OnePassMail"]),
        .library(name: "OnePassAuth", targets: ["OnePassAuth"]),
        .library(name: "OnePassAuthUI", targets: ["OnePassAuthUI"]),
        .library(name: "OnePassExtraction", targets: ["OnePassExtraction"]),
        .library(name: "OnePassServerClient", targets: ["OnePassServerClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/SwiftMail.git", exact: "1.12.0"),
        .package(url: "https://github.com/openid/AppAuth-iOS.git", exact: "3.0.0"),
    ],
    targets: [
        .target(name: "OnePassModels"),
        .target(name: "OnePassStorage", dependencies: ["OnePassModels"]),
        .target(name: "OnePassMail", dependencies: [
            "OnePassModels", "OnePassExtraction",
            .product(name: "SwiftMail", package: "SwiftMail"),
        ]),
        // Extension-safe: token refresh only (AppAuthCore). Interactive sign-in lives in OnePassAuthUI (app only).
        .target(name: "OnePassAuth", dependencies: [
            "OnePassModels", "OnePassStorage", "OnePassMail",
            .product(name: "AppAuthCore", package: "AppAuth-iOS"),
        ]),
        .target(name: "OnePassAuthUI", dependencies: [
            "OnePassAuth", "OnePassModels",
            .product(name: "AppAuthCore", package: "AppAuth-iOS"),
            .product(name: "AppAuth", package: "AppAuth-iOS"),
        ]),
        .target(name: "OnePassExtraction", dependencies: ["OnePassModels"], resources: [.process("Resources")]),
        .target(name: "OnePassServerClient", dependencies: ["OnePassModels"]),
        .testTarget(name: "OnePassStorageTests", dependencies: ["OnePassStorage"]),
        .testTarget(name: "OnePassMailTests", dependencies: ["OnePassMail"]),
        .testTarget(name: "OnePassExtractionTests", dependencies: ["OnePassExtraction"], resources: [.copy("Fixtures")]),
        .testTarget(name: "OnePassServerClientTests", dependencies: ["OnePassServerClient"]),
        .testTarget(name: "OnePassAuthTests", dependencies: ["OnePassAuth", "OnePassMail", "OnePassModels", "OnePassStorage"]),
    ]
)
