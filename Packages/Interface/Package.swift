// swift-tools-version: 6.2
import PackageDescription

// All screens of the iPhone. iOS only: logic that needs tests belongs in Core or Storage;
// the simulator build compiles this package.
let package = Package(
    name: "Interface",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Interface", targets: ["Interface"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Design"),
        .package(path: "../Signals"),
        .package(path: "../Storage"),
        .package(path: "../Connectivity"),
        .package(path: "../Control"),
    ],
    targets: [
        .target(
            name: "Interface",
            dependencies: ["Core", "Design", "Signals", "Storage", "Connectivity", "Control"])
    ]
)
