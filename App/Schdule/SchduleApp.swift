import SwiftUI
import SwiftData
import SchduleModel
import SchduleStore

@main
struct SchduleApp: App {
    private let testConfig = UITestConfiguration.current
    @State private var appModel: AppModel?
    @State private var launchFailure: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let appModel {
                    AppRootView()
                        .environment(\.appModel, appModel)
                        .modelContainer(appModel.store.container)
                } else if let launchFailure {
                    LaunchFailureView(message: launchFailure)
                } else {
                    ProgressView().task { start() }
                }
            }
            // Dark is the app's house style, not the system's choice. This
            // becomes a three-way setting (Dark / Light / System) in M9; until
            // then the default stands.
            .preferredColorScheme(testConfig.colorScheme ?? .dark)
            // Screenshots must not drift between CI runs, so under test the app
            // runs against a frozen calendar rather than the wall clock.
            .environment(\.calendar, testConfig.calendar)
        }
    }

    @MainActor
    private func start() {
        do {
            // A UI-test run gets a throwaway in-memory store: screenshots must
            // not depend on what a previous run left on disk.
            let store = testConfig.isUITesting
                ? try SchduleStore.makeInMemory()
                : try SchduleStore.makeShared()

            if testConfig.isUITesting {
                try SeedData.seed(store)
            } else {
                try SeedData.seedIfEmpty(store)
                try store.purgeExpiredTrash()
            }

            appModel = AppModel(
                store: store,
                calendar: testConfig.calendar,
                today: testConfig.isUITesting ? SeedData.today : DayKey(date: .now),
                authenticator: testConfig.authenticator
            )
        } catch {
            launchFailure = error.localizedDescription
        }
    }
}

/// Shown when the store cannot be opened at all. Rare, but a blank white screen
/// with no explanation is worse than an honest one.
private struct LaunchFailureView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "Couldn't Open Your Data"), systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        }
    }
}
