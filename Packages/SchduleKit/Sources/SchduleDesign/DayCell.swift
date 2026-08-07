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

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(day: Int, count: Int, tint: BoardTint, isToday: Bool = false, isInverted: Bool = false) {
        self.day = day
        self.count = count
        self.tint = tint
        self.isToday = isToday
        self.isInverted = isInverted
    }

    private var intensity: DayIntensity { DayIntensity(count: count) }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Metrics.cellCornerRadius, style: .continuous)
                .fill(tint.color.opacity(intensity.fillOpacity))

            RoundedRectangle(cornerRadius: Metrics.cellCornerRadius, style: .continuous)
                .strokeBorder(strokeColor, lineWidth: isToday ? 2 : 1)

            glyph
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var glyph: some View {
        switch intensity {
        case .none:
            // An empty day shows only its date, quietly.
            Text(day, format: .number)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.tertiary)
        case .once:
            Image(systemName: isInverted ? "xmark" : "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint.color)
        case .twice, .many:
            Text(count, format: .number)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
    }

    private var strokeColor: Color {
        if isToday { return tint.color }
        if reduceTransparency { return Color(.separator) }
        return Color(.separator).opacity(0.6)
    }

    // Localized properly in M8 once the string catalogs land; these keys are the
    // ones the catalog will be seeded from.
    private var accessibilityText: String {
        let dayPart = String(localized: "Day \(day)", comment: "VoiceOver prefix for a month-grid cell")
        switch intensity {
        case .none:
            return dayPart + ", " + String(localized: "not logged")
        case .once:
            return dayPart + ", " + String(localized: "logged once")
        case .twice, .many:
            return dayPart + ", " + String(localized: "logged \(count) times")
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
