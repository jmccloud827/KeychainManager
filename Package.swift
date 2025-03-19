// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "KeychainManager",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "KeychainManager",
            targets: ["KeychainManager"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KeychainManager",
            dependencies: [])
    ]
)
