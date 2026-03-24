// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SlapBook",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SlapBook",
            path: "Sources/SlapBook",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("AVFoundation"),
            ]
        )
    ]
)
