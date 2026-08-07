import Foundation
import SwiftData
import SchduleModel

/// A Notes-style folder. Boards live in exactly one, or in none (which the UI
/// shows as "All Boards").
@Model
public final class BoardFolder {
    public var id: UUID = UUID()
    public var name: String = ""
    public var symbolName: String = "folder"
    public var sortIndex: Int = 0
    public var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Board.folder)
    public var boards: [Board]? = []

    public init(name: String, symbolName: String = "folder", sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.sortIndex = sortIndex
        self.createdAt = Date()
    }
}

/// One tracked thing: a column in the old paper schedule.
@Model
public final class Board {
    public var id: UUID = UUID()
    public var name: String = ""
    public var symbolName: String = "checkmark.circle"
    /// Stored as the raw string so a future enum case cannot corrupt the store.
    public var tintRaw: String = "orange"
    public var kindRaw: String = TrackerKind.check.rawValue
    /// For `quantity` boards: "glasses", "km", "pages".
    public var unit: String?
    /// Target occurrences per day, if the board has one.
    public var dailyGoal: Int?
    /// Target successful days per week, if the board has one.
    public var weeklyTargetDays: Int?

    public var isPinned: Bool = false
    /// Requires Face ID to open, and is withheld from widgets and Spotlight.
    public var isLocked: Bool = false
    public var archivedAt: Date?
    /// Set when the user deletes; purged after 30 days. Nil means live.
    public var deletedAt: Date?
    public var sortIndex: Int = 0
    public var createdAt: Date = Date()
    /// The first day this board is meaningful. Streaks never reach behind it.
    public var startDayValue: Int = 0

    public var folder: BoardFolder?

    @Relationship(deleteRule: .cascade, inverse: \DayEntry.board)
    public var entries: [DayEntry]? = []

    public init(
        name: String,
        symbolName: String = "checkmark.circle",
        tintRaw: String = "orange",
        kind: TrackerKind = .check,
        startDay: DayKey,
        sortIndex: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.tintRaw = tintRaw
        self.kindRaw = kind.rawValue
        self.startDayValue = startDay.value
        self.sortIndex = sortIndex
        self.createdAt = Date()
    }

    public var kind: TrackerKind {
        get { TrackerKind(rawValue: kindRaw) ?? .check }
        set { kindRaw = newValue.rawValue }
    }

    public var startDay: DayKey {
        get { DayKey(value: startDayValue) }
        set { startDayValue = newValue.value }
    }

    public var isArchived: Bool { archivedAt != nil }
    /// Not `isDeleted` — `PersistentModel` already defines that, and it means
    /// something else entirely (removed from the context, not in the user's
    /// Recently Deleted).
    public var isTrashed: Bool { deletedAt != nil }
    public var isInverted: Bool { kind.isInverted }

    /// Day → count for every entry on this board.
    public var countsByDay: [DayKey: Int] {
        var result: [DayKey: Int] = [:]
        for entry in entries ?? [] {
            result[DayKey(value: entry.dayValue)] = entry.count
        }
        return result
    }
}

/// One day's tally on one board. Absent means zero — the store holds only days
/// that were actually touched, so an untouched year costs nothing.
@Model
public final class DayEntry {
    #Index<DayEntry>([\.dayValue])

    public var id: UUID = UUID()
    /// `DayKey.value`, i.e. `yyyyMMdd`.
    public var dayValue: Int = 0
    public var count: Int = 0
    /// For `quantity` and `duration` boards.
    public var amount: Double?
    public var note: String?
    /// One timestamp per occurrence, so "when do I actually open TikTok" is
    /// answerable later without a second table.
    public var timestamps: [Date] = []
    public var sourceRaw: String = EntrySource.app.rawValue

    public var board: Board?

    public init(
        day: DayKey,
        count: Int = 1,
        amount: Double? = nil,
        note: String? = nil,
        source: EntrySource = .app,
        timestamps: [Date] = []
    ) {
        self.id = UUID()
        self.dayValue = day.value
        self.count = count
        self.amount = amount
        self.note = note
        self.sourceRaw = source.rawValue
        self.timestamps = timestamps
    }

    public var day: DayKey {
        get { DayKey(value: dayValue) }
        set { dayValue = newValue.value }
    }

    public var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .app }
        set { sourceRaw = newValue.rawValue }
    }
}
