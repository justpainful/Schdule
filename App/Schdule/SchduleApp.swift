import SwiftUI

@main
struct SchduleApp: App {
    private let testConfig = UITestConfiguration.current

    var body: some Scene {
        WindowGroup {
            RootView()
                // Dark is the app's house style, not the system's choice. This
                // becomes a three-way setting (Dark / Light / System) in M9;
                // until then the default stands.
                .preferredColorScheme(testConfig.colorScheme ?? .dark)
                // Screenshots must not drift between CI runs, so under test the
                // app runs against a frozen calendar rather than the wall clock.
                .environment(\.calendar, testConfig.calendar)
        }
    }
}
