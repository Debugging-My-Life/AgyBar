// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AgyBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AgyBar", targets: ["AgyBar"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AgyBar",
            dependencies: [],
            path: "Sources/AgyBar"
        )
    ]
)
