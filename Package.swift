// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Brume",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        // Copie locale corrigée, préparée par scripts/setup.sh (version figée dans le script).
        .package(path: "Vendor/libghostty-spm"),
        // Même version que les outils de publication de scripts/setup.sh.
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        .target(name: "BrumeCore"),
        .executableTarget(
            name: "Brume",
            dependencies: [
                "BrumeCore",
                .product(name: "GhosttyTerminal", package: "libghostty-spm"),
                .product(name: "GhosttyTheme", package: "libghostty-spm"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Brume",
            // scripts/build-app.sh range Sparkle.framework dans Contents/Frameworks.
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        ),
        .testTarget(name: "BrumeCoreTests", dependencies: ["BrumeCore"]),
        .testTarget(name: "BrumeTests", dependencies: ["Brume"])
    ]
)
