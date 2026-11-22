// swift-tools-version: 6.2
import PackageDescription

// Templates (JSON file) and settings, both in the App Group.
//
// macOS is included so `swift test` answers in seconds on a Mac.
let package = Package(
    name: "Storage",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Storage", targets: ["Storage"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(name: "Storage", dependencies: ["Core"]),
        .testTarget(name: "StorageTests", dependencies: ["Storage"]),
    ]
)
