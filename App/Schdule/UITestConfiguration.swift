import Foundation
import SwiftUI

/// Launch-argument switches that make the app deterministic under XCUITest.
///
/// Without this, every screenshot round would differ from the last (today moves,
/// seeded data drifts) and visual review would be comparing noise. Real runs see
/// `isUITesting == false` and none of it applies.
struct UITestConfiguration: Sendable {
    let isUITesting: Bool
    let colorScheme: ColorScheme?
    /// The date the app should treat as "today". Frozen under test.
    let referenceDate: Date

    static let current = UITestConfiguration(arguments: ProcessInfo.processInfo.arguments)

    init(arguments: [String]) {
        isUITesting = arguments.contains("-UITestMode")

        if let index = arguments.firstIndex(of: "-UITestAppearance"),
           index + 1 < arguments.count {
            colorScheme = arguments[index + 1] == "dark" ? .dark : .light
        } else {
            colorScheme = nil
        }

        // Saturday 8 August 2026, 12:00 UTC — the month the user described.
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 8
        components.hour = 12
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        referenceDate = isUITesting ? (utc.date(from: components) ?? .now) : .now
    }

    /// A calendar pinned to UTC under test so the grid's day boundaries do not
    /// shift with the runner's timezone. Locale-driven traits (weekday symbols,
    /// first day of the week) are kept live — those are exactly what the Arabic
    /// screenshots need to exercise.
    var calendar: Calendar {
        guard isUITesting else { return .autoupdatingCurrent }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.locale = .autoupdatingCurrent
        // `Calendar(identifier:)` ignores the locale when picking firstWeekday,
        // so carry it over explicitly.
        calendar.firstWeekday = Calendar.autoupdatingCurrent.firstWeekday
        return calendar
    }
}
