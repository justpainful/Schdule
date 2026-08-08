import EventKit
import Foundation
import SchduleModel

/// Mirrors logged days into the system Calendar.
///
/// Writes into a dedicated "Schdule" calendar rather than the user's default
/// one, so the whole mirror can be switched off by deleting a single calendar
/// and nothing else the user owns is ever touched.
///
/// EventKit is local to the device. Whether those events then sync anywhere is
/// the user's own iCloud setting, not something this app arranges.
public actor CalendarMirror {
    public static let calendarTitle = "Schdule"

    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    public enum MirrorError: Error, LocalizedError {
        case accessDenied
        case noWritableSource

        public var errorDescription: String? {
            switch self {
            case .accessDenied:
                String(localized: "Schdule needs permission to add events to your calendar.")
            case .noWritableSource:
                String(localized: "No calendar account is available to write to.")
            }
        }
    }

    /// Write-only access, because that is genuinely all this needs.
    ///
    /// Full access would let the app read every event the user owns in order to
    /// add its own, which is a wildly disproportionate ask for a habit tracker.
    public func requestAccess() async throws {
        let granted = try await store.requestWriteOnlyAccessToEvents()
        guard granted else { throw MirrorError.accessDenied }
    }

    public nonisolated var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    /// Finds or creates the dedicated calendar.
    private func schduleCalendar() throws -> EKCalendar {
        if let existing = store.calendars(for: .event).first(where: { $0.title == Self.calendarTitle }) {
            return existing
        }

        guard let source = store.defaultCalendarForNewEvents?.source
            ?? store.sources.first(where: { $0.sourceType == .local })
            ?? store.sources.first
        else { throw MirrorError.noWritableSource }

        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = Self.calendarTitle
        calendar.source = source
        try store.saveCalendar(calendar, commit: true)
        return calendar
    }

    /// Writes one all-day event for a logged day, replacing any previous mirror
    /// of the same board and day.
    public func mirror(
        boardName: String,
        boardID: UUID,
        day: DayKey,
        count: Int,
        isInverted: Bool,
        calendar: Calendar = .current
    ) throws {
        let target = try schduleCalendar()
        let start = day.date(calendar: calendar)
        guard let dayStart = calendar.dateInterval(of: .day, for: start)?.start else { return }

        removeExisting(boardID: boardID, on: dayStart, in: target, calendar: calendar)

        // A zero-count day carries no information worth an event; removing the
        // old one and stopping is the correct outcome.
        guard count > 0 else {
            try store.commit()
            return
        }

        let event = EKEvent(eventStore: store)
        event.calendar = target
        event.isAllDay = true
        event.startDate = dayStart
        event.endDate = dayStart
        event.title = count == 1 ? boardName : "\(boardName) ×\(count)"
        event.notes = "schdule-board:\(boardID.uuidString)"
        event.availability = .free

        try store.save(event, span: .thisEvent, commit: true)
    }

    private func removeExisting(
        boardID: UUID,
        on dayStart: Date,
        in target: EKCalendar,
        calendar: Calendar
    ) {
        let end = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let predicate = store.predicateForEvents(withStart: dayStart, end: end, calendars: [target])
        // Matched by the marker in `notes`, not by title: a rename would
        // otherwise orphan every event the board had already written.
        let marker = "schdule-board:\(boardID.uuidString)"
        for event in store.events(matching: predicate) where event.notes?.contains(marker) == true {
            try? store.remove(event, span: .thisEvent, commit: false)
        }
    }

    /// Deletes the whole mirror calendar. The one-tap way to undo all of this.
    public func removeCalendar() throws {
        guard let existing = store.calendars(for: .event)
            .first(where: { $0.title == Self.calendarTitle })
        else { return }
        try store.removeCalendar(existing, commit: true)
    }
}
