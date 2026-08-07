import Foundation

/// How a single day's tally renders in the month grid.
///
/// The rung carries the *decoration* (tint strength); the glyph carries the
/// *information*. That split is deliberate — it keeps the grid readable with
/// color-blindness, Increase Contrast, and at 60pt widget scale, where a tint
/// ramp alone would be guesswork.
public enum DayIntensity: Int, Sendable, Comparable, CaseIterable {
    case none = 0
    case once = 1
    case twice = 2
    case many = 3

    public init(count: Int) {
        switch count {
        case ..<1: self = .none
        case 1: self = .once
        case 2: self = .twice
        default: self = .many
        }
    }

    /// Fill opacity applied to the board's tint.
    public var fillOpacity: Double {
        switch self {
        case .none: 0.0
        case .once: 0.35
        case .twice: 0.70
        case .many: 1.0
        }
    }

    /// Whether the glyph needs to sit on a saturated fill (and so must be white).
    public var needsInvertedGlyph: Bool { self >= .twice }

    public static func < (lhs: DayIntensity, rhs: DayIntensity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
