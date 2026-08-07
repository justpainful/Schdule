import SwiftUI

/// Shared spacing and radius values. Kept in one place so the app, the widgets,
/// and the export posters agree on proportions without copy-pasted magic numbers.
public enum Metrics {
    public static let cellCornerRadius: CGFloat = 8
    public static let cellSpacing: CGFloat = 6
    public static let cardCornerRadius: CGFloat = 20
    public static let glassCornerRadius: CGFloat = 22
    public static let screenMargin: CGFloat = 20
    /// Clearance under scrolling content for the floating glass bar. The bar is
    /// an overlay rather than a safe-area inset on purpose — it needs content
    /// passing beneath it to have anything to sample — so the space it occupies
    /// has to be reserved by hand.
    public static let floatingBarClearance: CGFloat = 180
}

/// Formats dates in a specific calendar rather than whichever one the locale
/// prefers.
///
/// This exists because of a real mismatch: an `ar_SA` locale formats dates in
/// the Islamic calendar by default, so the month bar read "صفر ١٤٤٨" while the
/// grid below it laid out a 31-day Gregorian August. The header and the grid
/// have to agree, and the grid's calendar is the one that wins. A proper Hijri
/// mode — where *both* switch together — is M8 work.
public enum CalendarFormatting {
    public static func monthAndYear(_ date: Date, calendar: Calendar, wide: Bool = true) -> String {
        var style = Date.FormatStyle(
            locale: .autoupdatingCurrent,
            calendar: calendar,
            timeZone: calendar.timeZone
        )
        style = style.year().month(wide ? .wide : .abbreviated)
        return date.formatted(style)
    }

    public static func month(_ date: Date, calendar: Calendar) -> String {
        var style = Date.FormatStyle(
            locale: .autoupdatingCurrent,
            calendar: calendar,
            timeZone: calendar.timeZone
        )
        style = style.month(.abbreviated)
        return date.formatted(style)
    }
}
