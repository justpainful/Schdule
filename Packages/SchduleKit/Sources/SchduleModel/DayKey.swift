import Foundation

/// A calendar day encoded as `yyyyMMdd`.
///
/// Storing days as an integer rather than a `Date` is deliberate. A `Date` is an
/// instant, and "which day is this" depends on the timezone you ask in — so a
/// user who logs a workout at 11pm and then flies west would watch that entry
/// slide into the previous day. `20260808` means the eighth of August wherever
/// you are. It also sorts, indexes, and groups by month (`value / 100`) without
/// touching `Calendar` at all.
public struct DayKey: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let value: Int

    public init(value: Int) {
        self.value = value
    }

    public init(year: Int, month: Int, day: Int) {
        self.value = year * 10_000 + month * 100 + day
    }

    public init(date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    public var year: Int { value / 10_000 }
    public var month: Int { (value / 100) % 100 }
    public var day: Int { value % 100 }
    public var monthKey: MonthKey { MonthKey(year: year, month: month) }

    public var description: String { String(value) }

    /// Midday, not midnight — a day's representative instant should survive a
    /// DST transition that deletes 00:00.
    public func date(calendar: Calendar = .current) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components) ?? .distantPast
    }

    public func advanced(by days: Int, calendar: Calendar = .current) -> DayKey {
        guard days != 0 else { return self }
        let moved = calendar.date(byAdding: .day, value: days, to: date(calendar: calendar))
        return DayKey(date: moved ?? date(calendar: calendar), calendar: calendar)
    }

    /// 1 = Sunday … 7 = Saturday, matching `Calendar.component(.weekday:)`.
    public func weekday(calendar: Calendar = .current) -> Int {
        calendar.component(.weekday, from: date(calendar: calendar))
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool { lhs.value < rhs.value }

    /// Every day in a month, in order.
    public static func days(in month: MonthKey, calendar: Calendar = .current) -> [DayKey] {
        (1...month.dayCount(calendar: calendar)).map {
            DayKey(year: month.year, month: month.month, day: $0)
        }
    }
}
