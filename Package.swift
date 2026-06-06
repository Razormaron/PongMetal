// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PongMetal",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PongMetal",
            path: "Sources/PongMetal",
            resources: [.copy("Resources")],
            linkerSettings: [.linkedFramework("AVFoundation")]
        )
    ]
)
