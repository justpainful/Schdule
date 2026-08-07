import SwiftUI

@main
struct SchduleApp: App {
    private let testConfig = UITestConfiguration.current

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(testConfig.colorScheme)
                // Screenshots must not drift between CI runs, so under test the
                // app runs against a frozen calendar rather than the wall clock.
                .environment(\.calendar, testConfig.calendar)
        }
    }
}
