import SwiftUI
import SwiftData
import SchduleDesign
import SchduleModel
import SchduleStats
import SchduleStore

/// The daily driver: everything you might log today, one tap from logging it.
struct TodayView: View {
    @Environment(\.appModel) private var appModel
    @Query(
        filter: #Predicate<Board> { $0.deletedAt == nil && $0.archivedAt == nil },
        sort: [SortDescriptor(\Board.sortIndex), SortDescriptor(\Board.createdAt)]
    )
    private var boards: [Board]

    @State private var editing: DayEditorTarget?

    private var habits: [Board] { boards.filter { !$0.isInverted } }
    private var avoiding: [Board] { boards.filter(\.isInverted) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TodaySummaryCard(boards: boards, day: today, calendar: calendar)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 10, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if !habits.isEmpty {
                    Section(String(localized: "Habits")) {
                        ForEach(habits) { row(for: $0) }
                    }
                }

                if !avoiding.isEmpty {
                    Section {
                        ForEach(avoiding) { row(for: $0) }
                    } header: {
                        Text("Avoiding")
                    } footer: {
                        Text("A day you log nothing here is a day that went well.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text(dayTitle))
            .navigationBarTitleDisplayMode(.large)
            .accessibilityIdentifier("today-list")
            .sheet(item: $editing) { target in
                DayEditorSheet(board: target.board, day: target.day)
            }
        }
    }

    @ViewBuilder
    private func row(for board: Board) -> some View {
        let locked = !(appModel?.isUnlocked(board) ?? true)
        BoardRow(
            board: board,
            count: locked ? 0 : count(for: board),
            subtitle: locked ? String(localized: "Locked") : subtitle(for: board),
            isLocked: locked,
            onIncrement: locked ? nil : { adjust(board, by: 1) },
            onDecrement: locked ? nil : { adjust(board, by: -1) }
        )
        .contentShape(.rect)
        .onTapGesture {
            if locked {
                Task { await appModel?.unlock(board) }
            } else {
                editing = DayEditorTarget(board: board, day: today)
            }
        }
        .accessibilityIdentifier("today-row-\(board.name)")
    }

    // MARK: - Data

    private var calendar: Calendar { appModel?.calendar ?? .current }
    private var today: DayKey { appModel?.today ?? DayKey(date: .now) }

    private var dayTitle: String {
        today.date(calendar: calendar).formatted(
            Date.FormatStyle(locale: .autoupdatingCurrent, calendar: calendar, timeZone: calendar.timeZone)
                .weekday(.wide)
                .day()
                .month(.wide)
        )
    }

    private func count(for board: Board) -> Int {
        appModel?.store.count(for: board, on: today) ?? 0
    }

    /// Says the most useful true thing about this board right now, which differs
    /// by kind: a goal if there is one, otherwise a streak, otherwise nothing.
    private func subtitle(for board: Board) -> String {
        let counts = board.countsByDay

        if let goal = board.dailyGoal, goal > 0 {
            let done = count(for: board)
            return String(localized: "\(done) of \(goal) \(board.unit ?? "")")
                .trimmingCharacters(in: .whitespaces)
        }

        let streak = BoardStatistics.currentStreak(
            counts: counts,
            from: board.startDay,
            through: today,
            isInverted: board.isInverted,
            calendar: calendar
        )

        if streak == 0 {
            return board.isInverted
                ? String(localized: "Logged today")
                : String(localized: "No streak yet")
        }
        return board.isInverted
            ? String(localized: "\(streak) days clean")
            : String(localized: "\(streak) day streak")
    }

    private func adjust(_ board: Board, by delta: Int) {
        guard let appModel else { return }
        try? appModel.store.increment(board: board, on: today, by: delta)
    }
}

/// Identifies which board/day the editor sheet is opened for.
struct DayEditorTarget: Identifiable {
    let board: Board
    let day: DayKey
    var id: String { "\(board.id)-\(day.value)" }
}

/// A one-line read on the day: how many habits are done and whether anything
/// has been slipped on.
private struct TodaySummaryCard: View {
    let boards: [Board]
    let day: DayKey
    let calendar: Calendar

    private var habits: [Board] { boards.filter { !$0.isInverted } }
    private var avoiding: [Board] { boards.filter(\.isInverted) }

    private var habitsDone: Int {
        habits.count { ($0.countsByDay[day] ?? 0) > 0 }
    }

    private var slips: Int {
        avoiding.count { ($0.countsByDay[day] ?? 0) > 0 }
    }

    var body: some View {
        HStack(spacing: 0) {
            metric(
                value: "\(habitsDone)/\(habits.count)",
                caption: String(localized: "Habits done"),
                symbol: "checkmark.circle.fill",
                tint: .accentColor
            )
            Divider().frame(height: 34)
            metric(
                value: "\(slips)",
                caption: String(localized: "Slips today"),
                symbol: "xmark.circle.fill",
                tint: slips == 0 ? .secondary : .red
            )
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .accessibilityIdentifier("today-summary")
    }

    private func metric(value: String, caption: String, symbol: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.footnote)
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
