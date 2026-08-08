import Foundation
import SwiftUI
import UserNotifications
import WidgetKit
import SchduleModel
import SchduleStore

/// Handles the buttons on a reminder banner.
///
/// "Log it" writes the entry without the app ever coming to the foreground,
/// which is the whole reason for putting a button on the banner: a reminder you
/// have to open an app to answer is a reminder you dismiss.
@MainActor
final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    private let store: SchduleStore

    init(store: SchduleStore) {
        self.store = store
        super.init()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        guard let raw = info["boardID"] as? String, let id = UUID(uuidString: raw) else { return }
        let action = response.actionIdentifier

        await MainActor.run {
            guard action == ReminderBuilder.Action.log else { return }
            guard let board = try? store.activeBoards().first(where: { $0.id == id }) else { return }
            // A locked board must not be loggable from the Lock Screen; that is
            // exactly the surface the lock exists to defend.
            guard !board.isLocked else { return }

            try? store.increment(board: board, on: DayKey(date: .now), source: .notification)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Reminders still show while the app is open. Suppressing them would make
    /// the app feel like it swallowed something the user asked for.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
