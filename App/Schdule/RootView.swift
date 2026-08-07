import SwiftUI
import SchduleDesign
import SchduleModel

/// Scaffold screen. Its job is to put real content, real Liquid Glass, and real
/// RTL text on screen so the CI screenshot loop has something honest to
/// photograph. The Notes-style folder navigation replaces it in M3.
struct RootView: View {
    @State private var month = DemoFixture.month
    @State private var selectedBoardID = DemoFixture.boards[0].id

    private var board: DemoBoard {
        DemoFixture.boards.first { $0.id == selectedBoardID } ?? DemoFixture.boards[0]
    }

    private var isCurrentMonth: Bool { month == DemoFixture.month }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    boardPicker
                    summaryCard
                    MonthGrid(
                        month: month,
                        counts: isCurrentMonth ? board.counts : [:],
                        tint: board.tint,
                        today: isCurrentMonth ? DemoFixture.today : nil,
                        isInverted: board.isNegative
                    )
                    .accessibilityIdentifier("month-grid")

                    sectionHeader(String(localized: "Recent months"))
                    MonthStrip(
                        months: DemoFixture.recentMonths,
                        counts: board.historyCounts,
                        tint: board.tint
                    )
                    .accessibilityIdentifier("month-strip")
                }
                .padding(.horizontal, Metrics.screenMargin)
                // Enough room that the last row clears the floating bar when
                // scrolled to the bottom — and enough content above it that the
                // glass has something real to sample on the way past.
                .padding(.bottom, 140)
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
                .padding(.bottom, 18)
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    // MARK: - Board picker

    /// Habits and anti-habits are kept in separate, labelled runs. They are not
    /// the same kind of thing: a full row is a good month on one and a bad month
    /// on the other, and mixing them in one list invites misreading the grid.
    private var boardPicker: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: 12) {
                groupLabel(String(localized: "Habits"), systemImage: "checkmark.circle")
                ForEach(DemoFixture.positiveBoards) { chip(for: $0) }

                Divider().frame(height: 26).padding(.horizontal, 2)

                groupLabel(String(localized: "Avoiding"), systemImage: "xmark.circle")
                ForEach(DemoFixture.negativeBoards) { chip(for: $0) }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("board-picker")
    }

    private func groupLabel(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
    }

    private func chip(for item: DemoBoard) -> some View {
        let isSelected = item.id == selectedBoardID
        return Button {
            withAnimation(.snappy) { selectedBoardID = item.id }
        } label: {
            Label(item.name, systemImage: item.symbol)
                .font(.subheadline.weight(.medium))
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.white : item.tint.color)
        .background {
            Capsule().fill(
                isSelected
                    ? AnyShapeStyle(item.tint.color)
                    : AnyShapeStyle(item.tint.color.opacity(0.18))
            )
        }
        .accessibilityIdentifier("board-chip-\(item.id)")
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: 0) {
            stat(value: board.activeDays, caption: activeDaysCaption)
            Divider().frame(height: 32)
            stat(value: board.total, caption: String(localized: "Total"))
            Divider().frame(height: 32)
            stat(value: currentStreak, caption: streakCaption)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .accessibilityIdentifier("summary-card")
    }

    /// An anti-habit's streak counts days *without* the thing, so it needs its
    /// own wording — "streak: 8" would otherwise read as eight days of failure.
    private var streakCaption: String {
        board.isNegative ? String(localized: "Days clean") : String(localized: "Streak")
    }

    private var activeDaysCaption: String {
        board.isNegative ? String(localized: "Slip days") : String(localized: "Active days")
    }

    /// Numbers in the label colour rather than the board tint: three big tinted
    /// numerals fought with the grid for attention, and the tint already belongs
    /// to the data.
    private func stat(value: Int, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    /// Naive back-count from today; for an anti-habit it counts backwards over
    /// days with *no* entry. Replaced by the real engine in M1.
    private var currentStreak: Int {
        guard isCurrentMonth else { return 0 }
        var streak = 0
        var day = DemoFixture.today
        while day >= 1 {
            let logged = (board.counts[day] ?? 0) > 0
            guard logged != board.isNegative else { break }
            streak += 1
            day -= 1
        }
        return streak
    }
}

#Preview {
    RootView()
}
