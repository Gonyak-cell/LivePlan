// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AppStorage",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AppStorage",
            targets: ["AppStorage"]
        )
    ],
    dependencies: [
        .package(path: "../AppCore")
    ],
    targets: [
        .target(
            name: "AppStorage",
            dependencies: ["AppCore"],
            path: "Sources/AppStorage"
        ),
        .testTarget(
            name: "AppStorageTests",
            dependencies: ["AppStorage"],
            path: "Tests/AppStorageTests"
        )
    ]
)
