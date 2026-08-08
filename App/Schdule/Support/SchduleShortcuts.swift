import AppIntents
import SchduleIntents

/// Phrases Siri and Spotlight accept without the user opening Shortcuts first.
///
/// Both languages are listed because the app ships in both, and a Saudi user
/// saying "سجل" should not have to switch to English to log a workout. Every
/// phrase has to contain `${applicationName}`; App Intents rejects the ones
/// that do not.
struct SchduleShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogEntryIntent(),
            phrases: [
                "Log a board in \(.applicationName)",
                "Add one in \(.applicationName)",
                "Mark it in \(.applicationName)",
                "سجل في \(.applicationName)",
                "ضف واحد في \(.applicationName)",
            ],
            shortTitle: "Log Entry",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: CheckBoardIntent(),
            phrases: [
                "Check a board in \(.applicationName)",
                "How many times in \(.applicationName)",
                "كم مرة في \(.applicationName)",
                "افحص جدول في \(.applicationName)",
            ],
            shortTitle: "Check Board",
            systemImageName: "questionmark.circle.fill"
        )
    }
}
