// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftImageAnalyzer",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SwiftImageAnalyzer",
            targets: ["SwiftImageAnalyzer"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftImageAnalyzer",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftImageAnalyzerTests",
            dependencies: ["SwiftImageAnalyzer"]
        ),
    ]
)
