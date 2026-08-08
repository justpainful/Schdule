import SwiftUI
import SwiftData
import SchduleDesign
import SchduleModel
import SchduleStats
import SchduleStore

/// One board, one month. The screen the app is really about.
struct BoardDetailView: View {
    let board: Board

    @Environment(\.appModel) private var appModel
    @State private var month: MonthKey?
    @State private var editingDay: DayKey?
    @State private var isEditingBoard = false
    @State private var isSharing = false

    private var tint: BoardTint { BoardTint(rawValue: board.tintRaw) ?? .orange }
    private var calendar: Calendar { appModel?.calendar ?? .current }
    private var today: DayKey { appModel?.today ?? DayKey(date: .now) }
    private var shownMonth: MonthKey { month ?? today.monthKey }
    private var isUnlocked: Bool { appModel?.isUnlocked(board) ?? true }

    var body: some View {
        Group {
            if isUnlocked {
                content
            } else {
                lockedState
            }
        }
        .navigationTitle(Text(board.name))
        .navigationBarTitleDisplayMode(.large)
        // The month pager is itself a floating glass bar. Stacking it directly
        // above the floating tab bar put two glass pills within a few points of
        // each other, which reads as a mistake. A pushed detail screen hiding
        // the tab bar is ordinary iOS, and it leaves exactly one floating
        // element on screen.
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if isUnlocked {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { isEditingBoard = true } label: {
                            Label(String(localized: "Edit Board"), systemImage: "pencil")
                        }
                        Button { isSharing = true } label: {
                            Label(String(localized: "Share Month"), systemImage: "square.and.arrow.up")
                        }
                        Divider()
                        Button { board.isPinned.toggle() } label: {
                            Label(
                                board.isPinned ? String(localized: "Unpin") : String(localized: "Pin"),
                                systemImage: board.isPinned ? "pin.slash" : "pin"
                            )
                        }
                    } label: {
                        Label(String(localized: "More"), systemImage: "ellipsis")
                    }
                    .accessibilityIdentifier("board-menu")
                }
            }
        }
        .sheet(isPresented: $isEditingBoard) {
            BoardEditorView(board: board)
        }
        .sheet(item: $editingDay) { day in
            DayEditorSheet(board: board, day: day)
        }
        .sheet(isPresented: $isSharing) {
            ShareMonthSheet(board: board, month: shownMonth)
        }
    }

    // MARK: - Unlocked content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                statsCard

                MonthGrid(
                    month: shownMonth,
                    counts: dayCounts,
                    tint: tint,
                    today: shownMonth == today.monthKey ? today.day : nil,
                    isInverted: board.isInverted,
                    isFutureMonth: shownMonth > today.monthKey,
                    onTapDay: { day in
                        editingDay = DayKey(year: shownMonth.year, month: shownMonth.month, day: day)
                    }
                )
                .accessibilityIdentifier("month-grid")

                header(String(localized: "Recent months"))
                MonthStrip(months: recentMonths, counts: board.countsByDay, tint: tint)
                    .accessibilityIdentifier("month-strip")

                if let insight {
                    header(String(localized: "Pattern"))
                    Text(insight)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.bottom, Metrics.floatingBarClearance)
        }
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .bottom) {
            GlassMonthBar(
                month: shownMonth,
                onPrevious: { step(-1) },
                onNext: { step(1) }
            )
            .padding(.bottom, 18)
        }
    }

    private var lockedState: some View {
        ContentUnavailableView {
            Label(String(localized: "Locked"), systemImage: "lock.fill")
        } description: {
            Text("This board is private. Unlock it to see the month.")
        } actions: {
            Button(String(localized: "Unlock")) {
                Task { await appModel?.unlock(board) }
            }
            .buttonStyle(.glassProminent)
            .accessibilityIdentifier("unlock-board")
        }
        .accessibilityIdentifier("locked-state")
    }

    private func header(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    // MARK: - Stats

    private var statsCard: some View {
        HStack(spacing: 0) {
            stat(value: streak, caption: board.isInverted
                ? String(localized: "Days clean")
                : String(localized: "Streak"))
            Divider().frame(height: 32)
            stat(value: monthTotal, caption: String(localized: "This month"))
            Divider().frame(height: 32)
            stat(value: best, caption: String(localized: "Best"))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .accessibilityIdentifier("board-stats")
    }

    private func stat(value: Int, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Derived

    private var dayCounts: [Int: Int] {
        var result: [Int: Int] = [:]
        for (key, count) in board.countsByDay where key.monthKey == shownMonth {
            result[key.day] = count
        }
        return result
    }

    private var recentMonths: [MonthKey] {
        (-5...0).map { shownMonth.advanced(by: $0, calendar: calendar) }
    }

    private var streak: Int {
        BoardStatistics.currentStreak(
            counts: board.countsByDay,
            from: board.startDay,
            through: today,
            isInverted: board.isInverted,
            calendar: calendar
        )
    }

    private var best: Int {
        BoardStatistics.longestStreak(
            counts: board.countsByDay,
            from: board.startDay,
            through: today,
            isInverted: board.isInverted,
            calendar: calendar
        )
    }

    private var monthTotal: Int {
        BoardStatistics.total(counts: board.countsByDay, in: shownMonth, calendar: calendar)
    }

    /// One sentence, and only when there is something real to say. A "pattern"
    /// section that always speaks is noise; one that stays quiet until a weekday
    /// genuinely dominates is worth reading.
    private var insight: String? {
        guard let weekday = BoardStatistics.dominantWeekday(
            counts: board.countsByDay,
            calendar: calendar
        ) else { return nil }

        let symbols = calendar.standaloneWeekdaySymbols
        guard weekday >= 1, weekday <= symbols.count else { return nil }
        let name = symbols[weekday - 1]

        return board.isInverted
            ? String(localized: "\(name) is when this slips most.")
            : String(localized: "\(name) is your strongest day.")
    }

    private func step(_ delta: Int) {
        withAnimation(.smooth) {
            month = shownMonth.advanced(by: delta, calendar: calendar)
        }
    }
}
