import Foundation
import SchduleModel
import UserNotifications

/// Local notifications only.
///
/// There is no push server, no device token, and no APNs entitlement anywhere in
/// this project. Every reminder is scheduled on the device by the device, which
/// is what lets the app claim to be fully local without an asterisk.
public struct ReminderRequest: Sendable, Hashable {
    public enum Kind: String, Sendable {
        /// "Time to log this" at a chosen hour.
        case daily
        /// "You have not logged today and your streak is at risk", late evening.
        case streakAtRisk
        /// "Here is how last month went", on the 1st.
        case monthlyRecap
    }

    public let boardID: UUID
    public let boardName: String
    public let kind: Kind
    public let hour: Int
    public let minute: Int
    /// 1 = Sunday … 7 = Saturday. Empty means every day.
    public let weekdays: Set<Int>
    public let isInverted: Bool

    public init(
        boardID: UUID,
        boardName: String,
        kind: Kind,
        hour: Int,
        minute: Int = 0,
        weekdays: Set<Int> = [],
        isInverted: Bool = false
    ) {
        self.boardID = boardID
        self.boardName = boardName
        self.kind = kind
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.isInverted = isInverted
    }

    public var identifierPrefix: String { "\(boardID.uuidString).\(kind.rawValue)" }
}

/// Turns reminder requests into `UNNotificationRequest`s.
///
/// Split out from the scheduler so the tricky part — which triggers a request
/// produces, and what each one says — is testable without a notification centre
/// or an authorization prompt.
public enum ReminderBuilder {

    /// Action identifiers, matched in the app's delegate.
    public enum Action {
        public static let log = "SCHDULE_LOG"
        public static let skip = "SCHDULE_SKIP"
        public static let category = "SCHDULE_REMINDER"
    }

    public static func content(for request: ReminderRequest) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = Action.category
        content.userInfo = ["boardID": request.boardID.uuidString, "kind": request.kind.rawValue]
        content.sound = .default
        // Deliberately not time-sensitive: a habit reminder that pierces a Focus
        // is a habit reminder that gets the app's notifications turned off.
        content.interruptionLevel = .active

        switch request.kind {
        case .daily:
            content.title = request.boardName
            content.body = request.isInverted
                ? String(localized: "Anything to log today?")
                : String(localized: "Time to log this.")
        case .streakAtRisk:
            content.title = request.boardName
            content.body = request.isInverted
                ? String(localized: "Still clean today. Confirm before midnight?")
                : String(localized: "Your streak is still open today.")
        case .monthlyRecap:
            content.title = String(localized: "Last month")
            content.body = String(localized: "See how \(request.boardName) went.")
            content.sound = nil
        }

        return content
    }

    /// One trigger per selected weekday, because `UNCalendarNotificationTrigger`
    /// matches a single set of components — a request for Mondays and Thursdays
    /// is two triggers, not one with two weekdays.
    public static func triggers(for request: ReminderRequest) -> [UNCalendarNotificationTrigger] {
        switch request.kind {
        case .monthlyRecap:
            var components = DateComponents()
            components.day = 1
            components.hour = request.hour
            components.minute = request.minute
            return [UNCalendarNotificationTrigger(dateMatching: components, repeats: true)]

        case .daily, .streakAtRisk:
            guard !request.weekdays.isEmpty else {
                var components = DateComponents()
                components.hour = request.hour
                components.minute = request.minute
                return [UNCalendarNotificationTrigger(dateMatching: components, repeats: true)]
            }
            return request.weekdays.sorted().map { weekday in
                var components = DateComponents()
                components.weekday = weekday
                components.hour = request.hour
                components.minute = request.minute
                return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            }
        }
    }

    public static func requests(for request: ReminderRequest) -> [UNNotificationRequest] {
        let content = content(for: request)
        return triggers(for: request).enumerated().map { index, trigger in
            UNNotificationRequest(
                identifier: "\(request.identifierPrefix).\(index)",
                content: content,
                trigger: trigger
            )
        }
    }

    public static var category: UNNotificationCategory {
        UNNotificationCategory(
            identifier: Action.category,
            actions: [
                UNNotificationAction(
                    identifier: Action.log,
                    title: String(localized: "Log it"),
                    options: []
                ),
                UNNotificationAction(
                    identifier: Action.skip,
                    title: String(localized: "Not today"),
                    options: []
                ),
            ],
            intentIdentifiers: [],
            options: []
        )
    }
}

/// Talks to `UNUserNotificationCenter`.
public struct ReminderScheduler: Sendable {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func registerCategories() {
        center.setNotificationCategories([ReminderBuilder.category])
    }

    /// Asks once. Returns whether reminders can actually be delivered, so the
    /// UI can offer a route to Settings instead of silently scheduling into a
    /// void.
    public func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    public func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    public func schedule(_ request: ReminderRequest) async throws {
        await cancel(prefix: request.identifierPrefix)
        for notification in ReminderBuilder.requests(for: request) {
            try await center.add(notification)
        }
    }

    public func cancel(prefix: String) async {
        let pending = await center.pendingNotificationRequests()
        let matching = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: matching)
    }

    /// Removes every reminder belonging to a board — used when it is deleted, or
    /// when it gains a lock, since a notification that names a locked board on
    /// the Lock Screen would leak exactly what the lock is for.
    public func cancelAll(boardID: UUID) async {
        await cancel(prefix: boardID.uuidString)
    }
}
