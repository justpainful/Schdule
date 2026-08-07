import SwiftUI
import SchduleModel

/// A compact run of recent months, each drawn as a dense column of days.
///
/// The month grid answers "how was August"; this answers "is August normal".
/// Keeping it on the same screen means the long view costs no navigation.
public struct MonthStrip: View {
    private let months: [MonthKey]
    private let counts: [DayKey: Int]
    private let tint: BoardTint

    @Environment(\.calendar) private var calendar

    public init(months: [MonthKey], counts: [DayKey: Int], tint: BoardTint) {
        self.months = months
        self.counts = counts
        self.tint = tint
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(months, id: \.self) { month in
                    VStack(spacing: 6) {
                        weekColumns(for: month)
                        Text(label(for: month))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func weekColumns(for month: MonthKey) -> some View {
        let days = DayKey.days(in: month, calendar: calendar)
        let leading = month.leadingBlankCount(calendar: calendar)
        let slots = leading + days.count
        let weeks = Int(ceil(Double(slots) / 7.0))

        return HStack(spacing: 2) {
            ForEach(0..<weeks, id: \.self) { week in
                VStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { weekday in
                        let index = week * 7 + weekday - leading
                        if index >= 0, index < days.count {
                            let day = days[index]
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .fill(color(for: counts[day] ?? 0))
                                .frame(width: 5, height: 5)
                        } else {
                            Color.clear.frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label(for: month)))
    }

    private func color(for count: Int) -> Color {
        let intensity = DayIntensity(count: count)
        return intensity == .none
            ? Color(.quaternarySystemFill)
            : tint.color.opacity(intensity.fillOpacity)
    }

    private func label(for month: MonthKey) -> String {
        CalendarFormatting.month(month.startDate(calendar: calendar), calendar: calendar)
    }
}
