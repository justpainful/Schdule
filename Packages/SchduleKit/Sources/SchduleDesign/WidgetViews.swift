import SwiftUI
import SchduleModel

/// Compact renderings of a board, shared by the widget extension and by the
/// snapshot tests that photograph them.
///
/// No Liquid Glass in any of these, for the same reason the export posters have
/// none: a widget is composited by the system onto a wallpaper it cannot sample,
/// and iOS 26 already applies its own material to the widget's container. Adding
/// glass inside would fight it.
public enum WidgetPalette {
    /// A widget's own tint has to survive being desaturated or accented by the
    /// Home Screen's rendering mode, so content leans on shape and weight rather
    /// than on colour alone.
    public static func fill(for count: Int, tint: BoardTint) -> Color {
        let intensity = DayIntensity(count: count)
        return intensity == .none
            ? Color.primary.opacity(0.10)
            : tint.color.opacity(intensity.fillOpacity)
    }
}

/// A month as a dense grid of dots, for the small and medium widget.
public struct WidgetMonthGrid: View {
    private let month: MonthKey
    private let counts: [Int: Int]
    private let tint: BoardTint
    private let today: Int?
    private let dotSize: CGFloat

    @Environment(\.calendar) private var calendar

    public init(
        month: MonthKey,
        counts: [Int: Int],
        tint: BoardTint,
        today: Int?,
        dotSize: CGFloat = 7
    ) {
        self.month = month
        self.counts = counts
        self.tint = tint
        self.today = today
        self.dotSize = dotSize
    }

    public var body: some View {
        let leading = month.leadingBlankCount(calendar: calendar)
        let days = month.dayCount(calendar: calendar)
        let weeks = Int(ceil(Double(leading + days) / 7.0))

        HStack(spacing: dotSize * 0.32) {
            ForEach(0..<weeks, id: \.self) { week in
                VStack(spacing: dotSize * 0.32) {
                    ForEach(0..<7, id: \.self) { weekday in
                        cell(index: week * 7 + weekday - leading, days: days)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(index: Int, days: Int) -> some View {
        if index >= 0, index < days {
            let day = index + 1
            RoundedRectangle(cornerRadius: dotSize * 0.28, style: .continuous)
                .fill(WidgetPalette.fill(for: counts[day] ?? 0, tint: tint))
                .frame(width: dotSize, height: dotSize)
                .overlay {
                    if day == today {
                        RoundedRectangle(cornerRadius: dotSize * 0.28 + 1, style: .continuous)
                            .strokeBorder(tint.color, lineWidth: 1.2)
                            .padding(-1.5)
                    }
                }
        } else {
            Color.clear.frame(width: dotSize, height: dotSize)
        }
    }
}

/// The header every home-screen widget shares.
public struct WidgetBoardHeader: View {
    private let name: String
    private let symbolName: String
    private let tint: BoardTint
    private let detail: String?

    public init(name: String, symbolName: String, tint: BoardTint, detail: String? = nil) {
        self.name = name
        self.symbolName = symbolName
        self.tint = tint
        self.detail = detail
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint.color)
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            Spacer(minLength: 2)
            if let detail {
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// The big number, with wording that changes for anti-habits.
public struct WidgetTodayCount: View {
    private let count: Int
    private let tint: BoardTint
    private let isInverted: Bool
    private let goal: Int?
    private let size: CGFloat

    public init(count: Int, tint: BoardTint, isInverted: Bool, goal: Int?, size: CGFloat = 34) {
        self.count = count
        self.tint = tint
        self.isInverted = isInverted
        self.goal = goal
        self.size = size
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(count, format: .number)
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(numberColor)
            if let goal, goal > 0 {
                Text(verbatim: "/\(goal)")
                    .font(.system(size: size * 0.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// On an anti-habit a zero is the good outcome, so it is the zero that gets
    /// the colour and any positive number that goes quiet-but-present. Colouring
    /// "7 slips" in the board's accent would read as a score.
    private var numberColor: Color {
        if isInverted {
            return count == 0 ? tint.color : .primary
        }
        return count > 0 ? tint.color : .secondary
    }
}

/// A streak or clean-day count, phrased for the board's polarity.
public struct WidgetStreakLine: View {
    private let streak: Int
    private let isInverted: Bool

    public init(streak: Int, isInverted: Bool) {
        self.streak = streak
        self.isInverted = isInverted
    }

    public var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: isInverted ? "checkmark.seal.fill" : "flame.fill")
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var text: String {
        isInverted
            ? String(localized: "\(streak) days clean")
            : String(localized: "\(streak) day streak")
    }
}
