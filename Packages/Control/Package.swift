// swift-tools-version: 6.2
import PackageDescription

// The flow of a workout for phone and watch: start, pause, end, summary, signals.
//
// macOS is included so `swift test` answers in seconds on a Mac.
let package = Package(
    name: "Control",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Control", targets: ["Control"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Storage"),
        .package(path: "../Signals"),
    ],
    targets: [
        .target(name: "Control", dependencies: ["Core", "Storage", "Signals"]),
        .testTarget(name: "SteuerungTests", dependencies: ["Control"]),
    ]
)
