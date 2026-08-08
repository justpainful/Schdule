// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SchduleKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        // One dynamic product carrying every module.
        //
        // Two reasons it is dynamic and singular rather than six static ones.
        // The AppIntents metadata processor refuses to build when an app and an
        // embedded extension both statically link a library declaring the same
        // App Entity ("App Entities names from dependencies must not conflict
        // with entities in the module being built"). And linking the SwiftData
        // model types statically into both binaries would put two copies of the
        // same @Model classes in one process, which is a far worse problem than
        // the one it would be solving.
        //
        // The modules still exist separately; callers keep importing
        // SchduleModel, SchduleStore, and so on.
        .library(
            name: "SchduleKit",
            type: .dynamic,
            targets: [
                "SchduleModel",
                "SchduleStats",
                "SchduleStore",
                "SchduleDesign",
                "SchduleExport",
                "SchduleIntents",
            ]
        ),
    ],
    targets: [
        // Value types and calendar arithmetic. No frameworks, no I/O.
        .target(
            name: "SchduleModel",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Pure functions over day-to-count maps. Deliberately independent of the
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
