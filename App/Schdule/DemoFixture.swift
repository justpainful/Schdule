import Foundation
import SchduleDesign
import SchduleModel

/// Stand-in data for the scaffold, before the SwiftData store exists. Fixed
/// values, so the screenshots CI produces are comparable between rounds.
struct DemoBoard: Identifiable, Sendable {
    let id: String
    let name: String
    let symbol: String
    let tint: BoardTint
    let kind: TrackerKind
    /// Day-of-month → count, for the month on screen.
    let counts: [Int: Int]
    /// Day → count across the preceding months, for the strip.
    let history: [DayKey: Int]

    var total: Int { counts.values.reduce(0, +) }
    var activeDays: Int { counts.values.count(where: { $0 > 0 }) }
    var isNegative: Bool { kind.isInverted }

    /// The strip wants this month's data folded in with the older months.
    var historyCounts: [DayKey: Int] {
        var merged = history
        for (day, count) in counts {
            merged[DayKey(year: DemoFixture.month.year, month: DemoFixture.month.month, day: day)] = count
        }
        return merged
    }
}

enum DemoFixture {
    static let month = MonthKey(year: 2026, month: 8)
    static let today = 8

    static var recentMonths: [MonthKey] {
        (-5...0).map { month.advanced(by: $0, calendar: gregorian) }
    }

    private static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    static let boards: [DemoBoard] = [
        DemoBoard(
            id: "workout",
            name: "Workout",
            symbol: "figure.strengthtraining.traditional",
            tint: .orange,
            kind: .check,
            counts: [1: 1, 2: 1, 4: 1, 5: 1, 7: 1, 8: 1],
            history: seededHistory(density: 0.55, maxCount: 1, salt: 7)
        ),
        DemoBoard(
            id: "reading",
            name: "Reading",
            symbol: "book.closed",
            tint: .teal,
            kind: .count,
            counts: [1: 1, 3: 2, 4: 1, 6: 1, 7: 1, 8: 3],
            history: seededHistory(density: 0.40, maxCount: 3, salt: 19)
        ),
        DemoBoard(
            id: "tiktok",
            name: "TikTok",
            symbol: "iphone.gen3",
            tint: .red,
            kind: .avoid,
            counts: [1: 2, 2: 1, 3: 4, 4: 1, 5: 3, 6: 1, 7: 7, 8: 2],
            history: seededHistory(density: 0.70, maxCount: 6, salt: 3)
        ),
        DemoBoard(
            id: "latenight",
            name: "Slept late",
            symbol: "moon.zzz",
            tint: .pink,
            kind: .avoid,
            counts: [2: 1, 3: 1, 5: 1, 6: 1, 8: 1],
            history: seededHistory(density: 0.45, maxCount: 1, salt: 23)
        ),
    ]

    static var positiveBoards: [DemoBoard] { boards.filter { !$0.isNegative } }
    static var negativeBoards: [DemoBoard] { boards.filter(\.isNegative) }

    /// A deterministic pseudo-random fill for the five months before the current
    /// one. Uses a fixed multiplier rather than `Int.random` so every CI run
    /// draws the same strip and visual diffs mean something.
    private static func seededHistory(density: Double, maxCount: Int, salt: Int) -> [DayKey: Int] {
        var result: [DayKey: Int] = [:]
        for offset in -5..<0 {
            let key = month.advanced(by: offset, calendar: gregorian)
            for day in 1...key.dayCount(calendar: gregorian) {
                let hash = (day &* 2_654_435_761 &+ key.month &* 40_503 &+ salt) & 0xFFFF
                let unit = Double(hash) / Double(0xFFFF)
                guard unit < density else { continue }
                let count = 1 + Int(unit * Double(maxCount * 2)) % maxCount
                result[DayKey(year: key.year, month: key.month, day: day)] = count
            }
        }
        return result
    }
}
