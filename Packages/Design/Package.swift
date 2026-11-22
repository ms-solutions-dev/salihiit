// swift-tools-version: 6.2
import PackageDescription

// Phase colors, fonts (Barlow, OFL) and text helpers. The only place with color values.
//
// macOS is included so `swift test` answers in seconds on a Mac.
let package = Package(
    name: "Design",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Design", targets: ["Design"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "Design", dependencies: ["Core"],
            resources: [.copy("Fonts")]),
        .testTarget(name: "GestaltungTests", dependencies: ["Design"]),
    ]
)
