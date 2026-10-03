// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Brume",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        // Copie locale corrigée, préparée par setup.sh (version figée dans le script).
        .package(path: "Vendor/libghostty-spm")
    ],
    targets: [
        .target(name: "BrumeCore"),
        .executableTarget(
            name: "Brume",
            dependencies: [
                "BrumeCore",
                .product(name: "GhosttyTerminal", package: "libghostty-spm"),
                .product(name: "GhosttyTheme", package: "libghostty-spm")
            ],
            path: "Sources/Brume"
        ),
        .testTarget(name: "BrumeCoreTests", dependencies: ["BrumeCore"])
    ]
)
