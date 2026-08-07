import SwiftUI
import SchduleModel

/// A month laid out as a real calendar — weekday columns, blank leading cells —
/// rather than a bare run of 31 boxes. Matching Calendar's shape is what makes a
/// glance at the grid mean something: you can see that every gap is a weekend.
public struct MonthGrid: View {
    private let month: MonthKey
    private let counts: [Int: Int]
    private let tint: BoardTint
    private let today: Int?
    private let isInverted: Bool
    private let onTapDay: ((Int) -> Void)?

    @Environment(\.calendar) private var calendar

    public init(
        month: MonthKey,
        counts: [Int: Int],
        tint: BoardTint,
        today: Int? = nil,
        isInverted: Bool = false,
        onTapDay: ((Int) -> Void)? = nil
    ) {
        self.month = month
        self.counts = counts
        self.tint = tint
        self.today = today
        self.isInverted = isInverted
        self.onTapDay = onTapDay
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Metrics.cellSpacing), count: 7)
    }

    /// Weekday initials rotated to start at the calendar's `firstWeekday`, so a
    /// Saudi locale reads Sun-first and a European one Mon-first without a branch.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        guard symbols.count == 7 else { return symbols }
        return Array(symbols[offset...] + symbols[..<offset])
    }

    public var body: some View {
        VStack(spacing: Metrics.cellSpacing) {
            HStack(spacing: Metrics.cellSpacing) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            LazyVGrid(columns: columns, spacing: Metrics.cellSpacing) {
                ForEach(0..<month.leadingBlankCount(calendar: calendar), id: \.self) { index in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityHidden(true)
                        .id("blank-\(index)")
                }

                ForEach(1...month.dayCount(calendar: calendar), id: \.self) { day in
                    let cell = DayCell(
                        day: day,
                        count: counts[day] ?? 0,
                        tint: tint,
                        isToday: day == today,
                        isInverted: isInverted
                    )

                    if let onTapDay {
                        Button { onTapDay(day) } label: { cell }
                            .buttonStyle(.plain)
                    } else {
                        cell
                    }
                }
            }
        }
    }
}

#Preview("August 2026") {
    MonthGrid(
        month: MonthKey(year: 2026, month: 8),
        counts: [2: 1, 3: 2, 4: 1, 6: 3, 9: 1, 10: 1, 11: 4, 14: 2, 17: 1, 18: 1, 19: 1, 22: 5, 25: 2],
        tint: .indigo,
        today: 8
    )
    .padding()
}
