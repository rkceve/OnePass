// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OnePassUI",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "OnePassUI", targets: ["OnePassUI"])
    ],
    targets: [
        .target(name: "OnePassUI")
    ]
)
