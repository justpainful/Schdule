import SwiftUI
import SchduleDesign

/// Top-level shell.
///
/// Tabs rather than a bare split view: the daily act of logging deserves a
/// permanent home, and burying it one level inside a folder hierarchy would put
/// three taps between the user and the thing they open the app to do. The
/// Notes-style folder structure lives inside the Boards tab, where browsing
/// actually belongs.
struct AppRootView: View {
    @Environment(\.appModel) private var appModel

    var body: some View {
        TabView {
            Tab(String(localized: "Today"), systemImage: "checklist") {
                TodayView()
            }
            Tab(String(localized: "Boards"), systemImage: "square.grid.3x3.fill") {
                BoardsView()
            }
            Tab(String(localized: "Insights"), systemImage: "chart.bar.xaxis") {
                InsightsView()
            }
        }
        // The iOS 26 tab bar shrinks out of the way on the way down the page and
        // comes back on the way up.
        .tabBarMinimizeBehavior(.onScrollDown)
        .onChange(of: scenePhase) { _, phase in
            // Locked boards re-lock the moment the app leaves the foreground.
            // Session-only unlocking is the whole guarantee.
            if phase != .active { appModel?.lockAll() }
        }
    }

    @Environment(\.scenePhase) private var scenePhase
}
