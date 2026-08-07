import SwiftUI
import SchduleModel

/// One day in the month grid.
///
/// Deliberately *not* a glass surface: glass cannot sample glass, and 31 of them
/// per board would be both wrong-looking and expensive. The grid is the opaque
/// content that the floating glass chrome above it samples.
public struct DayCell: View {
    private let day: Int
    private let count: Int
    private let tint: BoardTint
    private let isToday: Bool
    private let isInverted: Bool
    /// A day that has not arrived yet. Rendered as absence rather than as a
    /// quiet box, because in the first screenshot round a *missed* day and a day
    /// that simply had not happened yet were indistinguishable — which made a
    /// month in progress look like a month full of failures.
    private let isFuture: Bool
    private let showsDayNumber: Bool

    public init(
        day: Int,
        count: Int,
        tint: BoardTint,
        isToday: Bool = false,
        isInverted: Bool = false,
        isFuture: Bool = false,
        showsDayNumber: Bool = true
    ) {
        self.day = day
        self.count = count
        self.tint = tint
        self.isToday = isToday
        self.isInverted = isInverted
        self.isFuture = isFuture
        self.showsDayNumber = showsDayNumber
    }

    private var intensity: DayIntensity { DayIntensity(count: count) }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Metrics.cellCornerRadius, style: .continuous)
                .fill(fillStyle)
            glyph
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay {
            // An outset ring rather than an inset border: on a saturated cell an
            // inset stroke of the same hue is invisible, which is exactly what
            // happened to "today" in the first screenshot round.
            if isToday {
                RoundedRectangle(cornerRadius: Metrics.cellCornerRadius + 3, style: .continuous)
                    .strokeBorder(tint.color, lineWidth: 2.5)
                    .padding(-3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var fillStyle: AnyShapeStyle {
        if intensity != .none {
            return AnyShapeStyle(tint.color.opacity(intensity.fillOpacity))
        }
        // Past and empty is a fact worth showing; future and empty is not yet a
        // fact at all.
        return isFuture
            ? AnyShapeStyle(Color.clear)
            : AnyShapeStyle(Color(.quaternarySystemFill))
    }

    @ViewBuilder
    private var glyph: some View {
        switch intensity {
        case .none:
            // An untouched day states its date and nothing more. No stroke, no
            // outline — an empty grid should read as quiet paper, not graph paper.
            if showsDayNumber {
                Text(day, format: .number)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isFuture ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.tertiary))
            }
        case .once:
            Image(systemName: isInverted ? "xmark" : "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint.color)
        case .twice, .many:
            Text(count, format: .number)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
    }

    // Localized properly in M8 once the string catalogs land; these keys are the
    // ones the catalog will be seeded from.
    private var accessibilityText: String {
        let dayPart = String(localized: "Day \(day)", comment: "VoiceOver prefix for a month-grid cell")
        let todayPart = isToday ? ", " + String(localized: "today") : ""
        switch intensity {
        case .none:
            let state = isFuture ? String(localized: "upcoming") : String(localized: "not logged")
            return dayPart + todayPart + ", " + state
        case .once:
            return dayPart + todayPart + ", " + String(localized: "logged once")
        case .twice, .many:
            return dayPart + todayPart + ", " + String(localized: "logged \(count) times")
        }
    }
}

#Preview("Intensity ramp", traits: .sizeThatFitsLayout) {
    HStack(spacing: Metrics.cellSpacing) {
        DayCell(day: 3, count: 0, tint: .orange)
        DayCell(day: 4, count: 1, tint: .orange)
        DayCell(day: 5, count: 2, tint: .orange)
        DayCell(day: 6, count: 4, tint: .orange, isToday: true)
        DayCell(day: 7, count: 0, tint: .orange, isFuture: true)
    }
    .frame(width: 300)
    .padding()
}
