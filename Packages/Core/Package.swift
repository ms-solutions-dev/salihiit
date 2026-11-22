// swift-tools-version: 6.2
import PackageDescription

// Template, phase plan, timekeeper. Pure Swift without UI; everything phone, watch and island must compute identically.
//
// macOS is included so `swift test` answers in seconds on a Mac.
let package = Package(
    name: "Core",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Core", targets: ["Core"])
    ],
    dependencies: [],
    targets: [
        .target(name: "Core", dependencies: []),
        .testTarget(name: "KernTests", dependencies: ["Core"]),
    ]
)
