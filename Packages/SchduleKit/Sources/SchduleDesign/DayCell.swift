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
    private let showsDayNumber: Bool

    public init(
        day: Int,
        count: Int,
        tint: BoardTint,
        isToday: Bool = false,
        isInverted: Bool = false,
        showsDayNumber: Bool = true
    ) {
        self.day = day
        self.count = count
        self.tint = tint
        self.isToday = isToday
        self.isInverted = isInverted
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
                    .strokeBorder(tint.color, lineWidth: 2)
                    .padding(-3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var fillStyle: AnyShapeStyle {
        intensity == .none
            ? AnyShapeStyle(Color(.quaternarySystemFill))
            : AnyShapeStyle(tint.color.opacity(intensity.fillOpacity))
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
                    .foregroundStyle(.tertiary)
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
            return dayPart + todayPart + ", " + String(localized: "not logged")
        case .once:
            return dayPart + todayPart + ", " + String(localized: "logged once")
        case .twice, .many:
            return dayPart + todayPart + ", " + String(localized: "logged \(count) times")
        }
    }
}

#Preview("Intensity ramp", traits: .sizeThatFitsLayout) {
    HStack(spacing: Metrics.cellSpacing) {
        DayCell(day: 3, count: 0, tint: .indigo)
        DayCell(day: 4, count: 1, tint: .indigo)
        DayCell(day: 5, count: 2, tint: .indigo)
        DayCell(day: 6, count: 4, tint: .indigo, isToday: true)
    }
    .frame(width: 240)
    .padding()
}
