import SwiftUI
import SchduleDesign
import SchduleModel

/// M0 scaffold screen. Its only job is to put real content, real Liquid Glass,
/// and real RTL text on screen so the CI screenshot loop has something honest to
/// photograph. The Notes-style navigation replaces it in M3.
struct RootView: View {
    @State private var month = DemoFixture.month
    @State private var selectedBoardID = DemoFixture.boards[1].id

    private var board: DemoBoard {
        DemoFixture.boards.first { $0.id == selectedBoardID } ?? DemoFixture.boards[0]
    }

    private var isCurrentMonth: Bool { month == DemoFixture.month }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    boardPicker
                    summaryCard
                    MonthGrid(
                        month: month,
                        counts: isCurrentMonth ? board.counts : [:],
                        tint: board.tint,
                        today: isCurrentMonth ? DemoFixture.today : nil,
                        isInverted: board.kind.isInverted
                    )
                    .accessibilityIdentifier("month-grid")
                    legend
                }
                .padding(.horizontal, Metrics.screenMargin)
                .padding(.top, 8)
                // Room for the floating bar to hover over content, not clip it.
                .padding(.bottom, 120)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text(verbatim: "Schdule"))
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottom) {
                GlassMonthBar(
                    month: month,
                    onPrevious: { withAnimation(.smooth) { month = month.advanced(by: -1) } },
                    onNext: { withAnimation(.smooth) { month = month.advanced(by: 1) } }
                )
                .padding(.bottom, 16)
                .accessibilityIdentifier("month-bar")
            }
        }
    }

    private var boardPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(DemoFixture.boards) { item in
                    Button {
                        withAnimation(.snappy) { selectedBoardID = item.id }
                    } label: {
                        Label(item.name, systemImage: item.symbol)
                            .font(.subheadline.weight(.medium))
                            .padding(.vertical, 9)
                            .padding(.horizontal, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(item.id == selectedBoardID ? Color.white : Color.primary)
                    .background {
                        Capsule().fill(
                            item.id == selectedBoardID ? item.tint.color : Color(.secondarySystemGroupedBackground)
                        )
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("board-picker")
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            stat(value: "\(board.activeDays)", caption: String(localized: "Active days"))
            Divider().frame(height: 34)
            stat(value: "\(board.total)", caption: String(localized: "Total"))
            Divider().frame(height: 34)
            stat(value: "\(currentStreak)", caption: String(localized: "Streak"))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .accessibilityIdentifier("summary-card")
    }

    private func stat(value: String, caption: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(board.tint.color)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    /// Naive back-count from today. Replaced by the real engine in M1.
    private var currentStreak: Int {
        guard isCurrentMonth else { return 0 }
        var streak = 0
        var day = DemoFixture.today
        while day >= 1, (board.counts[day] ?? 0) > 0 {
            streak += 1
            day -= 1
        }
        return streak
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach([0, 1, 2, 4], id: \.self) { count in
                HStack(spacing: 6) {
                    DayCell(day: count, count: count, tint: board.tint)
                        .frame(width: 26, height: 26)
                    Text(count == 0 ? String(localized: "None") : "×\(count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("legend")
    }
}

#Preview {
    RootView()
}
