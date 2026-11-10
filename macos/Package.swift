// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KobeanQAUtils",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "KobeanQAUtils",
            targets: ["KobeanQAUtils"]
        )
    ],
    targets: [
        .executableTarget(
            name: "KobeanQAUtils",
            path: "Sources/KobeanQAUtils"
        )
    ]
)
