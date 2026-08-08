import SwiftUI
import SwiftData
import SchduleDesign
import SchduleModel
import SchduleStats
import SchduleStore

/// The long view: how this month compares, which days carry the week, and which
/// boards move together.
struct InsightsView: View {
    @Environment(\.appModel) private var appModel
    // Narrowed in Swift rather than with a `#Predicate`: the macro over two
    // optionals is expensive to type-check and the row count here is tiny.
    @Query(sort: [SortDescriptor(\Board.sortIndex)]) private var allBoards: [Board]

    private var calendar: Calendar { appModel?.calendar ?? .current }
    private var today: DayKey { appModel?.today ?? DayKey(date: .now) }
    private var month: MonthKey { today.monthKey }

    /// Locked boards are excluded wholesale. An aggregate that revealed a
    /// private board's shape would defeat locking it.
    private var visible: [Board] {
        allBoards
            .filter { $0.deletedAt == nil && $0.archivedAt == nil }
            .filter { appModel?.isUnlocked($0) ?? true }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(.horizontal, Metrics.screenMargin)
                    .padding(.bottom, Metrics.floatingBarClearance)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("Insights"))
            .accessibilityIdentifier("insights")
        }
    }

    @ViewBuilder
    private var content: some View {
        if visible.isEmpty {
            ContentUnavailableView(
                String(localized: "Nothing to Compare Yet"),
                systemImage: "chart.bar.xaxis",
                description: Text("Log a few days and patterns start showing up here.")
            )
            .padding(.top, 60)
        } else {
            VStack(alignment: .leading, spacing: 26) {
                header(String(localized: "This month"))
                ForEach(visible) { board in
                    MonthProgressCard(
                        board: board,
                        month: month,
                        today: today,
                        calendar: calendar
                    )
                }

                header(String(localized: "By weekday"))
                ForEach(visible) { board in
                    WeekdayCard(board: board, calendar: calendar)
                }

                if !pairs.isEmpty {
                    header(String(localized: "Moving together"))
                    ForEach(pairs) { pair in
                        OverlapCard(pair: pair)
                    }
                    Text("Days these landed on together. It is a prompt to go look, not proof that one causes the other.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
    }

    private var pairs: [BoardPair] {
        var result: [BoardPair] = []
        for i in visible.indices {
            for j in visible.indices where j > i {
                let overlap = BoardStatistics.dayOverlap(
                    visible[i].countsByDay,
                    visible[j].countsByDay
                )
                guard overlap >= 0.35 else { continue }
                result.append(BoardPair(a: visible[i], b: visible[j], overlap: overlap))
            }
        }
        return Array(result.sorted { $0.overlap > $1.overlap }.prefix(4))
    }
}

struct BoardPair: Identifiable {
    let a: Board
    let b: Board
    let overlap: Double
    var id: String { "\(a.id)-\(b.id)" }
}

// MARK: - Cards

private struct InsightCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
    }
}

private struct MonthProgressCard: View {
    let board: Board
    let month: MonthKey
    let today: DayKey
    let calendar: Calendar

    private var tint: BoardTint { BoardTint(rawValue: board.tintRaw) ?? .orange }

    private var rate: Double {
        BoardStatistics.completionRate(
            counts: board.countsByDay,
            in: month,
            upTo: today,
            isInverted: board.isInverted,
            calendar: calendar
        )
    }

    private var change: Double? {
        BoardStatistics.monthOverMonthChange(
            counts: board.countsByDay,
            month: month,
            calendar: calendar
        )
    }

    var body: some View {
        InsightCard {
            HStack(spacing: 12) {
                BoardGlyph(board: board, size: 32)

                VStack(alignment: .leading, spacing: 5) {
                    Text(board.name).font(.subheadline.weight(.medium))
                    ProgressView(value: rate).tint(tint.color)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text(rate, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    if let change {
                        TrendBadge(change: change, isInverted: board.isInverted)
                    }
                }
            }
        }
    }
}

/// Up is not automatically good. More workouts is progress; more TikTok is not,
/// and colouring both green would be a small lie told every month.
private struct TrendBadge: View {
    let change: Double
    let isInverted: Bool

    var body: some View {
        let rising = change > 0
        let good = isInverted ? !rising : rising
        Label {
            Text(abs(change), format: .percent.precision(.fractionLength(0)))
        } icon: {
            Image(systemName: rising ? "arrow.up.right" : "arrow.down.right")
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(good ? Color.green : Color.red)
    }
}

private struct WeekdayCard: View {
    let board: Board
    let calendar: Calendar

    private var tint: BoardTint { BoardTint(rawValue: board.tintRaw) ?? .orange }
    private var totals: [Int: Int] {
        BoardStatistics.weekdayTotals(counts: board.countsByDay, calendar: calendar)
    }
    private var peak: Int { max(totals.values.max() ?? 1, 1) }
    private var order: [Int] {
        let offset = calendar.firstWeekday - 1
        return (0..<7).map { ((offset + $0) % 7) + 1 }
    }

    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 7) {
                Text(board.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(order, id: \.self) { weekday in
                        bar(for: weekday)
                    }
                }
            }
        }
    }

    private func bar(for weekday: Int) -> some View {
        let value = totals[weekday] ?? 0
        let fraction = CGFloat(value) / CGFloat(peak)
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let label = weekday - 1 < symbols.count ? symbols[weekday - 1] : ""

        return VStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(tint.color.opacity(value == 0 ? 0.15 : 0.35 + 0.65 * Double(fraction)))
                .frame(height: 8 + 52 * fraction)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct OverlapCard: View {
    let pair: BoardPair

    var body: some View {
        InsightCard {
            HStack(spacing: 10) {
                BoardGlyph(board: pair.a, size: 26)
                Image(systemName: "arrow.left.and.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                BoardGlyph(board: pair.b, size: 26)

                Text("\(pair.a.name) and \(pair.b.name)")
                    .font(.subheadline)
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text(pair.overlap, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// The board's symbol on its tint, at whatever size the caller needs.
struct BoardGlyph: View {
    let board: Board
    var size: CGFloat = 32

    private var tint: BoardTint { BoardTint(rawValue: board.tintRaw) ?? .orange }

    var body: some View {
        Image(systemName: board.symbolName)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(tint.color)
            }
    }
}
