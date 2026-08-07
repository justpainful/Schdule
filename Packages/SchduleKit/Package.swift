// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SchduleKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SchduleModel", targets: ["SchduleModel"]),
        .library(name: "SchduleDesign", targets: ["SchduleDesign"]),
    ],
    targets: [
        .target(
            name: "SchduleModel",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "SchduleDesign",
            dependencies: ["SchduleModel"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Tests deliberately live in the Xcode project (Tests/SchduleKitTests)
        // rather than here: the package is iOS-only, so `swift test` could never
        // run them, and one test location beats two.
    ]
)
