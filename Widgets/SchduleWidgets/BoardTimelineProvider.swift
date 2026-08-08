import AppIntents
import Foundation
import SchduleIntents
import WidgetKit

struct BoardEntry: TimelineEntry {
    let date: Date
    let board: BoardWidgetData?
}

struct MultiBoardEntry: TimelineEntry {
    let date: Date
    let boards: [BoardWidgetData]
}

/// Timelines for a single configured board.
struct BoardTimelineProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> BoardEntry {
        BoardEntry(date: .now, board: .placeholder())
    }

    func snapshot(for configuration: SelectBoardIntent, in context: Context) async -> BoardEntry {
        // The gallery preview must never be empty, or the widget looks broken
        // before it has been configured even once.
        guard !context.isPreview else {
            return BoardEntry(date: .now, board: .placeholder())
        }
        return await entry(for: configuration)
    }

    func timeline(
        for configuration: SelectBoardIntent,
        in context: Context
    ) async -> Timeline<BoardEntry> {
        let current = await entry(for: configuration)
        // Refresh at the next local midnight: the only thing that changes on its
        // own is which day is "today", and everything else arrives through an
        // explicit reload after a log.
        return Timeline(entries: [current], policy: .after(nextMidnight()))
    }

    @MainActor
    private func entry(for configuration: SelectBoardIntent) -> BoardEntry {
        BoardEntry(date: .now, board: WidgetData.load(boardID: configuration.board?.id))
    }
}

/// Timelines for a list of boards.
struct MultiBoardTimelineProvider: AppIntentTimelineProvider {
    let limit: Int

    func placeholder(in context: Context) -> MultiBoardEntry {
        MultiBoardEntry(
            date: .now,
            boards: [.placeholder(), .placeholder(name: "TikTok", inverted: true)]
        )
    }

    func snapshot(for configuration: SelectBoardsIntent, in context: Context) async -> MultiBoardEntry {
        guard !context.isPreview else { return placeholder(in: context) }
        return await entry(for: configuration)
    }

    func timeline(
        for configuration: SelectBoardsIntent,
        in context: Context
    ) async -> Timeline<MultiBoardEntry> {
        let current = await entry(for: configuration)
        return Timeline(entries: [current], policy: .after(nextMidnight()))
    }

    @MainActor
    private func entry(for configuration: SelectBoardsIntent) -> MultiBoardEntry {
        MultiBoardEntry(
            date: .now,
            boards: WidgetData.loadMany(
                boardIDs: configuration.boards?.map(\.id),
                limit: limit
            )
        )
    }
}

/// Start of tomorrow, local time. Falls forward an hour if the calendar cannot
/// produce it, rather than returning a date in the past and spinning.
func nextMidnight(from now: Date = .now, calendar: Calendar = .current) -> Date {
    calendar.nextDate(
        after: now,
        matching: DateComponents(hour: 0, minute: 0),
        matchingPolicy: .nextTime
    ) ?? now.addingTimeInterval(3600)
}
