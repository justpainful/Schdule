import Foundation

/// A year+month pair, used as the unit of navigation and the key for grouping
/// entries. Comparable so month paging is plain arithmetic rather than date math.
public struct MonthKey: Hashable, Codable, Sendable, Comparable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public init(date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month], from: date)
        self.year = parts.year ?? 1
        self.month = parts.month ?? 1
    }

    /// First moment of this month in the given calendar.
    public func startDate(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? .distantPast
    }

    /// Number of days, correct for leap years and any calendar identifier.
    public func dayCount(calendar: Calendar = .current) -> Int {
        let start = startDate(calendar: calendar)
        return calendar.range(of: .day, in: .month, for: start)?.count ?? 30
    }

    /// Weekday index (0-based, relative to the calendar's `firstWeekday`) that
    /// day 1 falls on — i.e. how many blank cells the grid needs up front.
    public func leadingBlankCount(calendar: Calendar = .current) -> Int {
        let weekday = calendar.component(.weekday, from: startDate(calendar: calendar))
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    public func advanced(by months: Int, calendar: Calendar = .current) -> MonthKey {
        let base = startDate(calendar: calendar)
        guard let moved = calendar.date(byAdding: .month, value: months, to: base) else { return self }
        return MonthKey(date: moved, calendar: calendar)
    }

    public static func < (lhs: MonthKey, rhs: MonthKey) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}
