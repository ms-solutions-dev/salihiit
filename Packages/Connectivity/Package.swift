// swift-tools-version: 6.2
import PackageDescription

// Messages between phone and watch via WatchConnectivity.
//
// macOS is included so `swift test` answers in seconds on a Mac.
let package = Package(
    name: "Connectivity",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Connectivity", targets: ["Connectivity"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Storage"),
    ],
    targets: [
        .target(name: "Connectivity", dependencies: ["Core", "Storage"]),
        .testTarget(name: "KopplungTests", dependencies: ["Connectivity"]),
    ]
)
