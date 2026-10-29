// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Breaker",
    platforms: [.macOS(.v13)],
    targets: [
        // Platform-independent logic: config, pf rule generation, parsers, decisions.
        .target(name: "BreakerCore"),
        // Root LaunchDaemon that owns the pf anchor.
        .executableTarget(
            name: "breakerd",
            dependencies: ["BreakerCore"],
            linkerSettings: [.linkedFramework("SystemConfiguration")]
        ),
        // Menu-bar app.
        .executableTarget(
            name: "Breaker",
            dependencies: ["BreakerCore"]
        ),
        .testTarget(
            name: "BreakerCoreTests",
            dependencies: ["BreakerCore"]
        ),
    ]
)
