import SwiftUI
import SchduleDesign
import SchduleIntents
import WidgetKit

/// Lock Screen and StandBy.
///
/// Accessory families render as a monochrome vibrant stencil — the system throws
/// colour away — so these lean entirely on shape, weight, and the numeral. Any
/// design here that needed the board's tint to be readable would arrive as a
/// grey smudge.
struct LockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "LockScreenWidget",
            intent: SelectBoardIntent.self,
            provider: BoardTimelineProvider()
        ) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Board")
        .description("Today's count on the Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWidgetView: View {
    let entry: BoardEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: inline
        }
    }

    private var circular: some View {
        Group {
            if let board = entry.board {
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: -1) {
                        Image(systemName: board.symbolName)
                            .font(.system(size: 11, weight: .semibold))
                        Text(board.todayCount, format: .number)
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                }
            } else {
                Image(systemName: "square.grid.3x3")
            }
        }
    }

    private var rectangular: some View {
        Group {
            if let board = entry.board {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Image(systemName: board.symbolName)
                            .font(.system(size: 11, weight: .semibold))
                        Text(board.name)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                    }
                    Text(countLine(board))
                        .font(.system(size: 13, weight: .regular))
                        .monospacedDigit()
                    Text(streakLine(board))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Open Schdule to add a board")
                    .font(.system(size: 12))
            }
        }
    }

    private var inline: some View {
        Group {
            if let board = entry.board {
                Label(
                    "\(board.name) \(board.todayCount)",
                    systemImage: board.symbolName
                )
            } else {
                Label("Schdule", systemImage: "square.grid.3x3")
            }
        }
    }

    private func countLine(_ board: BoardWidgetData) -> String {
        if let goal = board.dailyGoal, goal > 0 {
            return String(localized: "\(board.todayCount) of \(goal) today")
        }
        return board.isInverted
            ? String(localized: "\(board.todayCount) slips today")
            : String(localized: "\(board.todayCount) today")
    }

    private func streakLine(_ board: BoardWidgetData) -> String {
        board.isInverted
            ? String(localized: "\(board.streak) days clean")
            : String(localized: "\(board.streak) day streak")
    }
}
