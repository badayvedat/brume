// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Brume",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "Brume",
            path: "Sources/Brume"
        )
    ]
)
