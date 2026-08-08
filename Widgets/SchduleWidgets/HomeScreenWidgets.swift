import AppIntents
import SwiftUI
import SchduleDesign
import SchduleIntents
import SchduleModel
import WidgetKit

// MARK: - Month

/// The whole month at a glance, with a button that logs today without leaving
/// the Home Screen.
struct MonthWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "MonthWidget",
            intent: SelectBoardIntent.self,
            provider: BoardTimelineProvider()
        ) { entry in
            MonthWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Month")
        .description("This month's grid for one board.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MonthWidgetView: View {
    let entry: BoardEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let board = entry.board {
            VStack(alignment: .leading, spacing: 8) {
                WidgetBoardHeader(
                    name: board.name,
                    symbolName: board.symbolName,
                    tint: board.tint
                )

                if family == .systemMedium {
                    HStack(alignment: .top, spacing: 16) {
                        grid(for: board, dotSize: 9)
                        Spacer(minLength: 0)
                        VStack(alignment: .trailing, spacing: 6) {
                            WidgetTodayCount(
                                count: board.todayCount,
                                tint: board.tint,
                                isInverted: board.isInverted,
                                goal: board.dailyGoal
                            )
                            WidgetStreakLine(streak: board.streak, isInverted: board.isInverted)
                            logButton(for: board)
                        }
                    }
                } else {
                    grid(for: board, dotSize: 7)
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom) {
                        WidgetTodayCount(
                            count: board.todayCount,
                            tint: board.tint,
                            isInverted: board.isInverted,
                            goal: board.dailyGoal,
                            size: 26
                        )
                        Spacer()
                        logButton(for: board)
                    }
                }
            }
        } else {
            WidgetEmptyState()
        }
    }

    private func grid(for board: BoardWidgetData, dotSize: CGFloat) -> some View {
        WidgetMonthGrid(
            month: board.month,
            counts: board.monthCounts,
            tint: board.tint,
            today: board.todayDay,
            dotSize: dotSize
        )
    }

    private func logButton(for board: BoardWidgetData) -> some View {
        WidgetLogButton(board: board)
    }
}

// MARK: - Today

/// Just today's number and one button. The smallest useful thing.
struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "TodayWidget",
            intent: SelectBoardIntent.self,
            provider: BoardTimelineProvider()
        ) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Today's count, with a button to log one more.")
        .supportedFamilies([.systemSmall])
    }
}

struct TodayWidgetView: View {
    let entry: BoardEntry

    var body: some View {
        if let board = entry.board {
            VStack(alignment: .leading, spacing: 6) {
                WidgetBoardHeader(
                    name: board.name,
                    symbolName: board.symbolName,
                    tint: board.tint
                )
                Spacer(minLength: 0)
                WidgetTodayCount(
                    count: board.todayCount,
                    tint: board.tint,
                    isInverted: board.isInverted,
                    goal: board.dailyGoal,
                    size: 44
                )
                WidgetStreakLine(streak: board.streak, isInverted: board.isInverted)
                Spacer(minLength: 0)
                WidgetLogButton(board: board, expanded: true)
            }
        } else {
            WidgetEmptyState()
        }
    }
}

// MARK: - Stack

/// Several boards at once, each with its own button. The large family is where
/// the app's daily list actually fits on the Home Screen.
struct BoardStackWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "BoardStackWidget",
            intent: SelectBoardsIntent.self,
            provider: MultiBoardTimelineProvider(limit: 6)
        ) { entry in
            BoardStackWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Boards")
        .description("Several boards, each one tap from being logged.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct BoardStackWidgetView: View {
    let entry: MultiBoardEntry
    @Environment(\.widgetFamily) private var family

    private var limit: Int { family == .systemLarge ? 6 : 3 }

    var body: some View {
        if entry.boards.isEmpty {
            WidgetEmptyState()
        } else {
            VStack(spacing: 8) {
                ForEach(entry.boards.prefix(limit), id: \.id) { board in
                    HStack(spacing: 9) {
                        Image(systemName: board.symbolName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(board.tint.color)
                            .frame(width: 18)
                        Text(board.name)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(board.todayCount, format: .number)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        WidgetLogButton(board: board, compact: true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Shared pieces

/// The one-tap log button. `Button(intent:)` runs in place, so the count changes
/// without the Home Screen ever leaving the screen.
struct WidgetLogButton: View {
    let board: BoardWidgetData
    var expanded = false
    var compact = false

    var body: some View {
        Button(intent: LogEntryIntent(
            board: BoardEntity(
                id: board.id,
                name: board.name,
                symbolName: board.symbolName,
                isInverted: board.isInverted
            )
        )) {
            if expanded {
                Label(String(localized: "Log"), systemImage: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            } else {
                Image(systemName: "plus")
                    .font(.system(size: compact ? 11 : 12, weight: .bold))
                    .frame(width: compact ? 24 : 28, height: compact ? 24 : 28)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(board.tint.color)
        .background {
            Capsule().fill(board.tint.color.opacity(0.18))
        }
        .accessibilityLabel(Text("Log one on \(board.name)"))
    }
}

/// Shown when there is nothing to display: no boards yet, or every board locked.
struct WidgetEmptyState: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 20))
                .foregroundStyle(.tertiary)
            Text("Open Schdule to add a board")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
