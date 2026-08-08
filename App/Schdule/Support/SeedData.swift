import Foundation
import SchduleModel
import SchduleStore

/// Populates a store with a believable August 2026.
///
/// Used for UI-test screenshots and for the first launch of a fresh install, so
/// the app never opens onto a blank screen with no way to tell what it does. The
/// data is generated from fixed arithmetic rather than `Int.random`, so every CI
/// run draws the same grid and a visual diff means something.
@MainActor
enum SeedData {
    static let month = MonthKey(year: 2026, month: 8)
    static let todayDay = 8
    static var today: DayKey { DayKey(year: month.year, month: month.month, day: todayDay) }

    private static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    struct Blueprint {
        let name: String
        let symbol: String
        let tint: String
        let kind: TrackerKind
        let folder: String
        /// Day-of-month → count for the current month.
        let currentMonth: [Int: Int]
        let historyDensity: Double
        let historyMax: Int
        let salt: Int
        var isPinned: Bool = false
        var isLocked: Bool = false
        var unit: String?
        var dailyGoal: Int?
    }

    static let blueprints: [Blueprint] = [
        Blueprint(
            name: "Workout",
            symbol: "figure.strengthtraining.traditional",
            tint: "orange",
            kind: .check,
            folder: "Health",
            currentMonth: [1: 1, 2: 1, 4: 1, 5: 1, 7: 1, 8: 1],
            historyDensity: 0.55,
            historyMax: 1,
            salt: 7,
            isPinned: true
        ),
        Blueprint(
            name: "Reading",
            symbol: "book.closed",
            tint: "teal",
            kind: .count,
            folder: "Mind",
            currentMonth: [1: 1, 3: 2, 4: 1, 6: 1, 7: 1, 8: 3],
            historyDensity: 0.40,
            historyMax: 3,
            salt: 19
        ),
        Blueprint(
            name: "Water",
            symbol: "drop",
            tint: "cyan",
            kind: .quantity,
            folder: "Health",
            currentMonth: [1: 6, 2: 8, 3: 5, 4: 8, 5: 7, 6: 4, 7: 8, 8: 3],
            historyDensity: 0.85,
            historyMax: 8,
            salt: 11,
            unit: "glasses",
            dailyGoal: 8
        ),
        Blueprint(
            name: "TikTok",
            symbol: "iphone.gen3",
            tint: "red",
            kind: .avoid,
            folder: "Screen time",
            currentMonth: [1: 2, 2: 1, 3: 4, 4: 1, 5: 3, 6: 1, 7: 7, 8: 2],
            historyDensity: 0.70,
            historyMax: 6,
            salt: 3,
            isPinned: true
        ),
        Blueprint(
            name: "Slept late",
            symbol: "moon.zzz",
            tint: "pink",
            kind: .avoid,
            folder: "Health",
            currentMonth: [2: 1, 3: 1, 5: 1, 6: 1],
            historyDensity: 0.45,
            historyMax: 1,
            salt: 23
        ),
        Blueprint(
            name: "Smoking",
            symbol: "smoke",
            tint: "brown",
            kind: .avoid,
            folder: "Screen time",
            currentMonth: [:],
            historyDensity: 0.10,
            historyMax: 2,
            salt: 31,
            isLocked: true
        ),
    ]

    /// Fills an empty store. Does nothing if any board already exists, so this
    /// can be called unconditionally at launch without ever trampling real data.
    @discardableResult
    static func seedIfEmpty(_ store: SchduleStore) throws -> Bool {
        guard try store.activeBoards().isEmpty, try store.trashedBoards().isEmpty else {
            return false
        }
        try seed(store)
        return true
    }

    static func seed(_ store: SchduleStore) throws {
        var folders: [String: BoardFolder] = [:]
        for (index, name) in ["Health", "Mind", "Screen time"].enumerated() {
            let folder = BoardFolder(
                name: name,
                symbolName: ["heart", "brain", "hourglass"][index],
                sortIndex: index
            )
            store.context.insert(folder)
            folders[name] = folder
        }

        let start = month.advanced(by: -5, calendar: gregorian)

        for (index, blueprint) in blueprints.enumerated() {
            let board = Board(
                name: blueprint.name,
                symbolName: blueprint.symbol,
                tintRaw: blueprint.tint,
                kind: blueprint.kind,
                startDay: DayKey(year: start.year, month: start.month, day: 1),
                sortIndex: index
            )
            board.folder = folders[blueprint.folder]
            board.isPinned = blueprint.isPinned
            board.isLocked = blueprint.isLocked
            board.unit = blueprint.unit
            board.dailyGoal = blueprint.dailyGoal
            store.context.insert(board)

            for (day, count) in blueprint.currentMonth {
                try store.setCount(
                    board: board,
                    on: DayKey(year: month.year, month: month.month, day: day),
                    to: count,
                    source: .importer
                )
            }

            for (day, count) in history(for: blueprint) {
                try store.setCount(board: board, on: day, to: count, source: .importer)
            }
        }

        try store.context.save()
    }

    /// Deterministic pseudo-random fill for the five months before the current
    /// one, using a fixed multiplier so the pattern is stable across runs.
    private static func history(for blueprint: Blueprint) -> [DayKey: Int] {
        var result: [DayKey: Int] = [:]
        for offset in -5..<0 {
            let key = month.advanced(by: offset, calendar: gregorian)
            for day in 1...key.dayCount(calendar: gregorian) {
                let hash = (day &* 2_654_435_761 &+ key.month &* 40_503 &+ blueprint.salt) & 0xFFFF
                let unit = Double(hash) / Double(0xFFFF)
                guard unit < blueprint.historyDensity else { continue }
                let count = 1 + Int(unit * Double(blueprint.historyMax * 2)) % blueprint.historyMax
                result[DayKey(year: key.year, month: key.month, day: day)] = count
            }
        }
        return result
    }
}
