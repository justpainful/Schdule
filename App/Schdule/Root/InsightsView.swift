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
    @Query(
        filter: #Predicate<Board> { $0.deletedAt == nil && $0.archivedAt == nil },
        sort: [SortDescriptor(\Board.sortIndex)]
    )
    private var boards: [Board]

    private var calendar: Calendar { appModel?.calendar ?? .current }
    private var today: DayKey { appModel?.today ?? DayKey(date: .now) }
    private var month: MonthKey { today.monthKey }

    /// Locked boards are excluded wholesale. An insight that reveals a private
    /// board's shape would defeat locking it.
    private var visible: [Board] {
        boards.filter { appModel?.isUnlocked($0) ?? true }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    if visible.isEmpty {
                        ContentUnavailableView(
                            String(localized: "Nothing to Compare Yet"),
                            systemImage: "chart.bar.xaxis",
                            description: Text("Log a few days and patterns start showing up here.")
                        )
                        .padding(.top, 60)
                    } else {
                        section(String(localized: "This month")) { monthCards }
                        section(String(localized: "By weekday")) { weekdayChart }
                        if pairs.count >= 1 {
                            section(String(localized: "Moving together")) { overlapList }
                        }
                    }
                }
                .padding(.horizontal, Metrics.screenMargin)
                .padding(.bottom, Metrics.floatingBarClearance)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("Insights"))
            .accessibilityIdentifier("insights")
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
            content()
        }
    }

    // MARK: - Month cards

    private var monthCards: some View {
        VStack(spacing: 10) {
            ForEach(visible) { board in
                let counts = board.countsByDay
                let rate = BoardStatistics.completionRate(
                    counts: counts, in: month, upTo: today,
                    isInverted: board.isInverted, calendar: calendar
                )
                let change = BoardStatistics.monthOverMonthChange(
                    counts: counts, month: month, calendar: calendar
                )
                let tint = BoardTint(rawValue: board.tintRaw) ?? .orange

                HStack(spacing: 12) {
                    Image(systemName: board.symbolName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background { RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tint.color) }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(board.name).font(.subheadline.weight(.medium))
                        ProgressView(value: rate)
                            .tint(tint.color)
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(rate, format: .percent.precision(.fractionLength(0)))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        if let change {
                            trendBadge(change: change, isInverted: board.isInverted)
                        }
                    }
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }
        }
    }

    /// Up is not automatically good. More workouts is progress; more TikTok is
    /// not, and colouring both green would be a small lie told every month.
    private func trendBadge(change: Double, isInverted: Bool) -> some View {
        let rising = change > 0
        let good = isInverted ? !rising : rising
        return Label(
            abs(change).formatted(.percent.precision(.fractionLength(0))),
            systemImage: rising ? "arrow.up.right" : "arrow.down.right"
        )
        .font(.caption2.weight(.medium))
        .foregroundStyle(good ? Color.green : Color.red)
        .labelStyle(.titleAndIcon)
    }

    // MARK: - Weekday chart

    private var weekdayChart: some View {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        let order = (0..<7).map { ((offset + $0) % 7) + 1 }

        return VStack(spacing: 12) {
            ForEach(visible) { board in
                let totals = BoardStatistics.weekdayTotals(counts: board.countsByDay, calendar: calendar)
                let peak = max(totals.values.max() ?? 1, 1)
                let tint = BoardTint(rawValue: board.tintRaw) ?? .orange

                VStack(alignment: .leading, spacing: 7) {
                    Text(board.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(order, id: \.self) { weekday in
                            let value = totals[weekday] ?? 0
                            VStack(spacing: 5) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(tint.color.opacity(value == 0 ? 0.15 : 0.35 + 0.65 * Double(value) / Double(peak)))
                                    .frame(height: 8 + 52 * CGFloat(value) / CGFloat(peak))
                                Text(symbols[weekday - 1])
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }
        }
    }

    // MARK: - Overlap

    private struct Pair: Identifiable {
        let a: Board
        let b: Board
        let overlap: Double
        var id: String { "\(a.id)-\(b.id)" }
    }

    private var pairs: [Pair] {
        var result: [Pair] = []
        for i in visible.indices {
            for j in visible.indices where j > i {
                let overlap = BoardStatistics.dayOverlap(
                    visible[i].countsByDay,
                    visible[j].countsByDay
                )
                guard overlap >= 0.35 else { continue }
                result.append(Pair(a: visible[i], b: visible[j], overlap: overlap))
            }
        }
        return result.sorted { $0.overlap > $1.overlap }.prefix(4).map { $0 }
    }

    private var overlapList: some View {
        VStack(spacing: 10) {
            ForEach(pairs) { pair in
                HStack(spacing: 12) {
                    Image(systemName: pair.a.symbolName)
                        .foregroundStyle((BoardTint(rawValue: pair.a.tintRaw) ?? .orange).color)
                    Image(systemName: "arrow.left.and.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Image(systemName: pair.b.symbolName)
                        .foregroundStyle((BoardTint(rawValue: pair.b.tintRaw) ?? .orange).color)

                    Text("\(pair.a.name) and \(pair.b.name)")
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    Text(pair.overlap, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }

            Text("Days these landed on together. It is a prompt to go look, not proof one causes the other.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
