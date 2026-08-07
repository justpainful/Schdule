import Foundation
import Testing
import SchduleModel
import SchduleStats

private var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    calendar.firstWeekday = 1
    return calendar
}

private func day(_ value: Int) -> DayKey { DayKey(value: value) }

/// Builds a day→count map from `yyyyMMdd: count` pairs.
private func counts(_ pairs: [Int: Int]) -> [DayKey: Int] {
    Dictionary(uniqueKeysWithValues: pairs.map { (day($0.key), $0.value) })
}

@Suite("Current streak")
struct CurrentStreakTests {

    @Test("Counts consecutive logged days back from today")
    func habitStreak() {
        let data = counts([20260805: 1, 20260806: 2, 20260807: 1, 20260808: 1])
        let streak = BoardStatistics.currentStreak(
            counts: data,
            from: day(20260101),
            through: day(20260808),
            isInverted: false,
            calendar: utc
        )
        #expect(streak == 4)
    }

    @Test("A gap breaks it")
    func habitStreakWithGap() {
        let data = counts([20260805: 1, 20260807: 1, 20260808: 1])
        let streak = BoardStatistics.currentStreak(
            counts: data,
            from: day(20260101),
            through: day(20260808),
            isInverted: false,
            calendar: utc
        )
        #expect(streak == 2)
    }

    @Test("An unlogged today is grace, not a break")
    func habitGraceForToday() {
        // Nothing logged on the 8th yet; the run through the 7th should stand.
        let data = counts([20260805: 1, 20260806: 1, 20260807: 1])
        let streak = BoardStatistics.currentStreak(
            counts: data,
            from: day(20260101),
            through: day(20260808),
            isInverted: false,
            calendar: utc
        )
        #expect(streak == 3)
    }

    @Test("Two unlogged days is a break, not grace")
    func habitGraceIsOnlyOneDay() {
        let data = counts([20260805: 1, 20260806: 1])
        let streak = BoardStatistics.currentStreak(
            counts: data,
            from: day(20260101),
            through: day(20260808),
            isInverted: false,
            calendar: utc
        )
        #expect(streak == 0)
    }

    @Test("Streaks cross month boundaries")
    func acrossMonths() {
        let data = counts([20260730: 1, 20260731: 1, 20260801: 1, 20260802: 1])
        let streak = BoardStatistics.currentStreak(
            counts: data,
            from: day(20260101),
            through: day(20260802),
            isInverted: false,
            calendar: utc
        )
        #expect(streak == 4)
    }

    @Test("An anti-habit counts clean days and gets no grace")
    func avoidStreak() {
        // Slipped on the 4th; the 5th through the 8th are clean.
        let data = counts([20260801: 2, 20260804: 1])
        let streak = BoardStatistics.currentStreak(
            counts: data,
            from: day(20260801),
            through: day(20260808),
            isInverted: true,
            calendar: utc
        )
        #expect(streak == 4)
    }

    @Test("An anti-habit slip today means zero clean days")
    func avoidStreakSlipToday() {
        let data = counts([20260808: 1])
        let streak = BoardStatistics.currentStreak(
            counts: data,
            from: day(20260801),
            through: day(20260808),
            isInverted: true,
            calendar: utc
        )
        #expect(streak == 0)
    }

    @Test("A streak never reaches behind the board's start day")
    func boundedByStartDay() {
        let data = counts([20260801: 1, 20260802: 1, 20260803: 1])
        let streak = BoardStatistics.currentStreak(
            counts: data,
            from: day(20260802),
            through: day(20260803),
            isInverted: false,
            calendar: utc
        )
        #expect(streak == 2)
    }

    @Test("An anti-habit with no entries at all is clean for its whole life")
    func avoidWithNoData() {
        let streak = BoardStatistics.currentStreak(
            counts: [:],
            from: day(20260806),
            through: day(20260808),
            isInverted: true,
            calendar: utc
        )
        #expect(streak == 3)
    }
}

@Suite("Longest streak")
struct LongestStreakTests {

    @Test("Finds the best run, not the most recent one")
    func bestRun() {
        let data = counts([
            20260801: 1, 20260802: 1, 20260803: 1, 20260804: 1, 20260805: 1,
            20260807: 1, 20260808: 1,
        ])
        let best = BoardStatistics.longestStreak(
            counts: data,
            from: day(20260801),
            through: day(20260808),
            isInverted: false,
            calendar: utc
        )
        #expect(best == 5)
    }

    @Test("Empty data has no streak")
    func noData() {
        #expect(
            BoardStatistics.longestStreak(
                counts: [:],
                from: day(20260801),
                through: day(20260808),
                isInverted: false,
                calendar: utc
            ) == 0
        )
    }
}

@Suite("Month aggregates")
struct MonthAggregateTests {
    private let august = MonthKey(year: 2026, month: 8)
    private let data = counts([
        20260801: 2, 20260802: 1, 20260803: 4, 20260808: 3,
        20260901: 9, // next month — must not leak in
    ])

    @Test("Total sums occurrences within the month only")
    func total() {
        #expect(BoardStatistics.total(counts: data, in: august, calendar: utc) == 10)
    }

    @Test("Logged days counts days, not occurrences")
    func loggedDays() {
        #expect(BoardStatistics.loggedDays(counts: data, in: august, calendar: utc) == 4)
    }

    @Test("A month in progress is scored against days elapsed, not 31")
    func completionInProgress() {
        // Logged on 1, 2, 3, 8 of the first 8 days.
        let rate = BoardStatistics.completionRate(
            counts: data,
            in: august,
            upTo: day(20260808),
            isInverted: false,
            calendar: utc
        )
        #expect(abs(rate - 0.5) < 0.0001)
    }

    @Test("A finished month is scored against its full length")
    func completionFinished() {
        let rate = BoardStatistics.completionRate(
            counts: data,
            in: august,
            upTo: day(20261001),
            isInverted: false,
            calendar: utc
        )
        #expect(abs(rate - 4.0 / 31.0) < 0.0001)
    }

    @Test("An anti-habit scores its clean days")
    func completionInverted() {
        let rate = BoardStatistics.completionRate(
            counts: data,
            in: august,
            upTo: day(20260808),
            isInverted: true,
            calendar: utc
        )
        #expect(abs(rate - 0.5) < 0.0001)
    }

    @Test("A month that has not started yet scores zero rather than dividing by zero")
    func completionFutureMonth() {
        let rate = BoardStatistics.completionRate(
            counts: [:],
            in: MonthKey(year: 2027, month: 3),
            upTo: day(20260808),
            isInverted: false,
            calendar: utc
        )
        #expect(rate == 0)
    }
}

@Suite("Weekday and trend")
struct WeekdayTests {

    @Test("Totals land on the right weekday")
    func weekdayTotals() {
        // 2026-08-01 is a Saturday (weekday 7); 08-02 is a Sunday (weekday 1).
        let data = counts([20260801: 3, 20260808: 2, 20260802: 1])
        let totals = BoardStatistics.weekdayTotals(counts: data, calendar: utc)
        #expect(totals[7] == 5)
        #expect(totals[1] == 1)
    }

    @Test("A tie for the top weekday reports nothing rather than picking one")
    func dominantWeekdayTie() {
        let data = counts([20260801: 2, 20260802: 2])
        #expect(BoardStatistics.dominantWeekday(counts: data, calendar: utc) == nil)
    }

    @Test("A clear winner is reported")
    func dominantWeekdayWinner() {
        let data = counts([20260801: 5, 20260802: 2])
        #expect(BoardStatistics.dominantWeekday(counts: data, calendar: utc) == 7)
    }

    @Test("Month-over-month change is a signed fraction")
    func monthOverMonth() {
        let data = counts([20260701: 4, 20260801: 6])
        let change = BoardStatistics.monthOverMonthChange(
            counts: data,
            month: MonthKey(year: 2026, month: 8),
            calendar: utc
        )
        #expect(change != nil)
        #expect(abs((change ?? 0) - 0.5) < 0.0001)
    }

    @Test("No previous data means no comparison rather than a fake 100%")
    func monthOverMonthWithoutBaseline() {
        let data = counts([20260801: 6])
        let change = BoardStatistics.monthOverMonthChange(
            counts: data,
            month: MonthKey(year: 2026, month: 8),
            calendar: utc
        )
        #expect(change == nil)
    }

    @Test("Day overlap is a Jaccard ratio over logged days")
    func overlap() {
        let gym = counts([20260801: 1, 20260802: 1, 20260803: 1])
        let tiktok = counts([20260802: 4, 20260803: 2, 20260804: 1])
        // Shared: 2nd, 3rd. Union: 1st–4th.
        #expect(abs(BoardStatistics.dayOverlap(gym, tiktok) - 0.5) < 0.0001)
    }

    @Test("Overlap of nothing is zero, not a crash")
    func overlapEmpty() {
        #expect(BoardStatistics.dayOverlap([:], [:]) == 0)
    }
}
