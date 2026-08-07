import Foundation
import SchduleModel

/// Pure functions over a day→count map.
///
/// Nothing here touches SwiftData. The statistics are the part most likely to be
/// subtly wrong — streaks across month boundaries, anti-habits, a day that has
/// not happened yet — so they are kept free of persistence and exercised
/// directly by the unit suite without standing up a container.
public enum BoardStatistics {

    /// Whether a day counts as a success for this kind of board.
    ///
    /// For an anti-habit the polarity flips: a day you logged nothing is the day
    /// that went well.
    public static func isSuccess(count: Int, isInverted: Bool) -> Bool {
        isInverted ? count == 0 : count > 0
    }

    /// Consecutive successful days ending at `today`.
    ///
    /// A habit gets grace for the current day: not having gone to the gym *yet*
    /// at 9am should not read as a broken streak, so an unlogged today is
    /// skipped rather than counted as a failure. An anti-habit gets no such
    /// grace — a clean today is exactly what is being counted, and skipping it
    /// would undercount by one.
    public static func currentStreak(
        counts: [DayKey: Int],
        from startDay: DayKey,
        through today: DayKey,
        isInverted: Bool,
        calendar: Calendar = .current
    ) -> Int {
        guard startDay <= today else { return 0 }

        var cursor = today
        var streak = 0

        if !isInverted, !isSuccess(count: counts[today] ?? 0, isInverted: false) {
            guard today > startDay else { return 0 }
            cursor = today.advanced(by: -1, calendar: calendar)
        }

        while cursor >= startDay, isSuccess(count: counts[cursor] ?? 0, isInverted: isInverted) {
            streak += 1
            guard cursor > startDay else { break }
            cursor = cursor.advanced(by: -1, calendar: calendar)
        }

        return streak
    }

    /// The longest run of successful days anywhere in `startDay...endDay`.
    public static func longestStreak(
        counts: [DayKey: Int],
        from startDay: DayKey,
        through endDay: DayKey,
        isInverted: Bool,
        calendar: Calendar = .current
    ) -> Int {
        guard startDay <= endDay else { return 0 }

        var best = 0
        var run = 0
        var cursor = startDay

        while cursor <= endDay {
            if isSuccess(count: counts[cursor] ?? 0, isInverted: isInverted) {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
            guard cursor < endDay else { break }
            cursor = cursor.advanced(by: 1, calendar: calendar)
        }

        return best
    }

    /// Sum of every occurrence in the month.
    public static func total(counts: [DayKey: Int], in month: MonthKey, calendar: Calendar = .current) -> Int {
        DayKey.days(in: month, calendar: calendar).reduce(0) { $0 + (counts[$1] ?? 0) }
    }

    /// Days in the month with at least one occurrence. Note this is *logged*
    /// days, not successful days — for an anti-habit these are the slip days.
    public static func loggedDays(counts: [DayKey: Int], in month: MonthKey, calendar: Calendar = .current) -> Int {
        DayKey.days(in: month, calendar: calendar).count { (counts[$0] ?? 0) > 0 }
    }

    /// Successful days over days elapsed, in `0...1`.
    ///
    /// Bounded by `upTo` so a month in progress is not scored against days that
    /// have not happened: on the 8th of August a perfect record is 8/8, not 8/31.
    public static func completionRate(
        counts: [DayKey: Int],
        in month: MonthKey,
        upTo today: DayKey?,
        isInverted: Bool,
        calendar: Calendar = .current
    ) -> Double {
        let days = DayKey.days(in: month, calendar: calendar)
        let elapsed: [DayKey]
        if let today, today.monthKey == month {
            elapsed = days.filter { $0 <= today }
        } else if let today, today.monthKey < month {
            elapsed = []
        } else {
            elapsed = days
        }

        guard !elapsed.isEmpty else { return 0 }
        let wins = elapsed.count { isSuccess(count: counts[$0] ?? 0, isInverted: isInverted) }
        return Double(wins) / Double(elapsed.count)
    }

    /// Total occurrences per weekday (1 = Sunday … 7 = Saturday).
    public static func weekdayTotals(
        counts: [DayKey: Int],
        calendar: Calendar = .current
    ) -> [Int: Int] {
        var totals: [Int: Int] = [:]
        for (day, count) in counts where count > 0 {
            totals[day.weekday(calendar: calendar), default: 0] += count
        }
        return totals
    }

    /// The weekday with the most occurrences, or nil when there is no data or a
    /// tie at the top — a "best day" that is really a coin flip is worse than
    /// none at all.
    public static func dominantWeekday(
        counts: [DayKey: Int],
        calendar: Calendar = .current
    ) -> Int? {
        let totals = weekdayTotals(counts: counts, calendar: calendar)
        guard let peak = totals.values.max(), peak > 0 else { return nil }
        let leaders = totals.filter { $0.value == peak }
        return leaders.count == 1 ? leaders.first?.key : nil
    }

    /// Change in total occurrences against the previous month, as a fraction.
    /// Nil when the previous month has nothing to compare against.
    public static func monthOverMonthChange(
        counts: [DayKey: Int],
        month: MonthKey,
        calendar: Calendar = .current
    ) -> Double? {
        let previous = month.advanced(by: -1, calendar: calendar)
        let before = total(counts: counts, in: previous, calendar: calendar)
        guard before > 0 else { return nil }
        let now = total(counts: counts, in: month, calendar: calendar)
        return (Double(now) - Double(before)) / Double(before)
    }

    /// How often two boards land on the same day, as a Jaccard overlap in
    /// `0...1`. Not a correlation coefficient and not evidence of anything
    /// causal — it is a prompt to go look, which is all the UI claims for it.
    public static func dayOverlap(
        _ first: [DayKey: Int],
        _ second: [DayKey: Int]
    ) -> Double {
        let a = Set(first.filter { $0.value > 0 }.keys)
        let b = Set(second.filter { $0.value > 0 }.keys)
        let union = a.union(b)
        guard !union.isEmpty else { return 0 }
        return Double(a.intersection(b).count) / Double(union.count)
    }
}
