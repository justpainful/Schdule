import Foundation

/// What a board measures. Determines how a day's value is entered and displayed.
///
/// `count` is the flagship case — the paper-schedule problem this app exists to
/// solve is that a hand-drawn `X` cannot say "three times today".
public enum TrackerKind: String, Codable, Sendable, CaseIterable {
    /// Did it or didn't: one mark per day.
    case check
    /// How many times today. Unbounded.
    case count
    /// A measured amount with a unit (glasses, km, pages).
    case quantity
    /// Elapsed time, driven by a live timer.
    case duration
    /// A 1–5 subjective scale.
    case rating
    /// An anti-habit. A day with zero is the *good* day, and the streak counts
    /// consecutive days at zero.
    case avoid

    /// Whether a day can hold more than one occurrence.
    public var allowsMultiplePerDay: Bool {
        switch self {
        case .check, .rating: false
        case .count, .quantity, .duration, .avoid: true
        }
    }

    /// Whether zero is the desired outcome. Inverts streaks and completion math.
    public var isInverted: Bool { self == .avoid }
}
