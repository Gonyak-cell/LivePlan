// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AppCore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AppCore",
            targets: ["AppCore"]
        )
    ],
    targets: [
        .target(
            name: "AppCore",
            dependencies: [],
            path: "Sources/AppCore"
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: ["AppCore"],
            path: "Tests/AppCoreTests"
        )
    ]
)
