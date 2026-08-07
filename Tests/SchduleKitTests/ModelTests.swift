import Foundation
import Testing
import SchduleModel

private var gregorianUTC: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    calendar.firstWeekday = 1 // Sunday
    return calendar
}

@Suite("MonthKey")
struct MonthKeyTests {

    @Test("Day counts cover every month length, including leap February")
    func dayCounts() {
        let calendar = gregorianUTC
        #expect(MonthKey(year: 2026, month: 8).dayCount(calendar: calendar) == 31)
        #expect(MonthKey(year: 2026, month: 4).dayCount(calendar: calendar) == 30)
        #expect(MonthKey(year: 2026, month: 2).dayCount(calendar: calendar) == 28)
        #expect(MonthKey(year: 2028, month: 2).dayCount(calendar: calendar) == 29)
    }

    @Test("August 2026 starts on a Saturday, so a Sunday-first grid needs six blanks")
    func leadingBlanks() {
        #expect(MonthKey(year: 2026, month: 8).leadingBlankCount(calendar: gregorianUTC) == 6)
    }

    @Test("Advancing across a year boundary rolls the year")
    func advancing() {
        let december = MonthKey(year: 2026, month: 12)
        #expect(december.advanced(by: 1, calendar: gregorianUTC) == MonthKey(year: 2027, month: 1))
        #expect(MonthKey(year: 2026, month: 1).advanced(by: -1, calendar: gregorianUTC) == MonthKey(year: 2025, month: 12))
    }

    @Test("Ordering is chronological, not lexicographic")
    func ordering() {
        #expect(MonthKey(year: 2026, month: 9) < MonthKey(year: 2027, month: 1))
        #expect(MonthKey(year: 2026, month: 2) < MonthKey(year: 2026, month: 10))
    }
}

@Suite("DayIntensity")
struct DayIntensityTests {

    @Test("Counts map onto the four rungs of the ramp")
    func mapping() {
        #expect(DayIntensity(count: 0) == .none)
        #expect(DayIntensity(count: -3) == .none)
        #expect(DayIntensity(count: 1) == .once)
        #expect(DayIntensity(count: 2) == .twice)
        #expect(DayIntensity(count: 3) == .many)
        #expect(DayIntensity(count: 97) == .many)
    }

    @Test("Only saturated rungs invert their glyph")
    func glyphInversion() {
        #expect(DayIntensity.none.needsInvertedGlyph == false)
        #expect(DayIntensity.once.needsInvertedGlyph == false)
        #expect(DayIntensity.twice.needsInvertedGlyph)
        #expect(DayIntensity.many.needsInvertedGlyph)
    }
}

@Suite("TrackerKind")
struct TrackerKindTests {

    @Test("Only avoid boards invert their success condition")
    func inversion() {
        #expect(TrackerKind.avoid.isInverted)
        for kind in TrackerKind.allCases where kind != .avoid {
            #expect(kind.isInverted == false)
        }
    }

    @Test("Check and rating boards hold at most one value per day")
    func multiplicity() {
        #expect(TrackerKind.check.allowsMultiplePerDay == false)
        #expect(TrackerKind.rating.allowsMultiplePerDay == false)
        #expect(TrackerKind.count.allowsMultiplePerDay)
    }
}
