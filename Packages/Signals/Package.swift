// swift-tools-version: 6.2
import PackageDescription

// Sounds, voice and haptics for the events from Core.
//
// macOS is included so `swift test` answers in seconds on a Mac.
let package = Package(
    name: "Signals",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Signals", targets: ["Signals"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Storage"),
        .package(path: "../Design"),
    ],
    targets: [
        .target(name: "Signals", dependencies: ["Core", "Storage", "Design"]),
        .testTarget(name: "SignaleTests", dependencies: ["Signals"]),
    ]
)
