import Foundation
import SchduleDesign
import SchduleModel
import SchduleStats
import SchduleStore

/// A flattened read of one board, sized for a widget timeline entry.
///
/// Timeline entries are archived and handed back to the extension later, so they
/// hold values rather than SwiftData objects — a faulted model object on the
/// other side of a process boundary is not a thing worth debugging.
public struct BoardWidgetData: Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let symbolName: String
    public let tint: BoardTint
    public let isInverted: Bool
    public let todayCount: Int
    public let streak: Int
    public let month: MonthKey
    public let monthCounts: [Int: Int]
    public let todayDay: Int
    public let dailyGoal: Int?

    public init(
        id: UUID,
        name: String,
        symbolName: String,
        tint: BoardTint,
        isInverted: Bool,
        todayCount: Int,
        streak: Int,
        month: MonthKey,
        monthCounts: [Int: Int],
        todayDay: Int,
        dailyGoal: Int?
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.tint = tint
        self.isInverted = isInverted
        self.todayCount = todayCount
        self.streak = streak
        self.month = month
        self.monthCounts = monthCounts
        self.todayDay = todayDay
        self.dailyGoal = dailyGoal
    }

    /// Sample content for previews, the widget gallery, and the placeholder that
    /// shows before real data arrives.
    public static func placeholder(name: String = "Workout", inverted: Bool = false) -> BoardWidgetData {
        BoardWidgetData(
            id: UUID(),
            name: name,
            symbolName: inverted ? "iphone.gen3" : "figure.strengthtraining.traditional",
            tint: inverted ? .red : .orange,
            isInverted: inverted,
            todayCount: inverted ? 2 : 1,
            streak: inverted ? 3 : 6,
            month: MonthKey(year: 2026, month: 8),
            monthCounts: [1: 1, 2: 1, 4: 1, 5: 2, 7: 1, 8: inverted ? 2 : 1],
            todayDay: 8,
            dailyGoal: nil
        )
    }
}

/// Reads the shared store on behalf of the widget extension.
public enum WidgetData {

    /// Locked boards are never returned. A widget sits on the Home Screen where
    /// anyone can see it, which is precisely the situation locking is for.
    @MainActor
    public static func load(
        boardID: UUID?,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> BoardWidgetData? {
        guard let store = try? SchduleStore.makeShared(),
              let boards = try? store.activeBoards()
        else { return nil }

        let candidates = boards.filter { !$0.isLocked }
        let board = candidates.first { $0.id == boardID } ?? candidates.first
        guard let board else { return nil }

        return make(board: board, store: store, calendar: calendar, now: now)
    }

    @MainActor
    public static func loadMany(
        boardIDs: [UUID]?,
        limit: Int,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> [BoardWidgetData] {
        guard let store = try? SchduleStore.makeShared(),
              let boards = try? store.activeBoards()
        else { return [] }

        let unlocked = boards.filter { !$0.isLocked }
        let chosen: [Board] = if let boardIDs, !boardIDs.isEmpty {
            boardIDs.compactMap { id in unlocked.first { $0.id == id } }
        } else {
            unlocked
        }

        return chosen.prefix(limit).map {
            make(board: $0, store: store, calendar: calendar, now: now)
        }
    }

    @MainActor
    private static func make(
        board: Board,
        store: SchduleStore,
        calendar: Calendar,
        now: Date
    ) -> BoardWidgetData {
        let today = DayKey(date: now, calendar: calendar)
        let counts = board.countsByDay

        var monthCounts: [Int: Int] = [:]
        for (day, count) in counts where day.monthKey == today.monthKey {
            monthCounts[day.day] = count
        }

        return BoardWidgetData(
            id: board.id,
            name: board.name,
            symbolName: board.symbolName,
            tint: BoardTint(rawValue: board.tintRaw) ?? .orange,
            isInverted: board.isInverted,
            todayCount: counts[today] ?? 0,
            streak: BoardStatistics.currentStreak(
                counts: counts,
                from: board.startDay,
                through: today,
                isInverted: board.isInverted,
                calendar: calendar
            ),
            month: today.monthKey,
            monthCounts: monthCounts,
            todayDay: today.day,
            dailyGoal: board.dailyGoal
        )
    }
}
