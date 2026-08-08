// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SchduleKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SchduleModel", targets: ["SchduleModel"]),
        .library(name: "SchduleStats", targets: ["SchduleStats"]),
        .library(name: "SchduleStore", targets: ["SchduleStore"]),
        .library(name: "SchduleDesign", targets: ["SchduleDesign"]),
        .library(name: "SchduleExport", targets: ["SchduleExport"]),
        .library(name: "SchduleIntents", targets: ["SchduleIntents"]),
    ],
    targets: [
        // Value types and calendar arithmetic. No frameworks, no I/O.
        .target(
            name: "SchduleModel",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Pure functions over day→count maps. Deliberately independent of the
        // store so the fiddly parts can be tested without a container.
        .target(
            name: "SchduleStats",
            dependencies: ["SchduleModel"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // SwiftData models and every mutation. Local-only by construction.
        .target(
            name: "SchduleStore",
            dependencies: ["SchduleModel"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Design tokens and the views shared by the app, widgets, and exports.
        .target(
            name: "SchduleDesign",
            dependencies: ["SchduleModel", "SchduleStats"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Posters, PDF, CSV, JSON. Sees value types only, never SwiftData: a
        // poster is a picture of a moment, and a live model object that can
        // change mid-render is the wrong thing to hand a renderer.
        .target(
            name: "SchduleExport",
            dependencies: ["SchduleModel", "SchduleDesign"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // App Intents plus the flattened reads the widget timelines need.
        // Linked by the app and the widget extension both, so the one-tap
        // surfaces cannot drift apart.
        .target(
            name: "SchduleIntents",
            dependencies: ["SchduleModel", "SchduleStore", "SchduleStats", "SchduleDesign"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Tests deliberately live in the Xcode project (Tests/SchduleKitTests)
        // rather than here: the package is iOS-only, so `swift test` could never
        // run them, and one test location beats two.
    ]
)
