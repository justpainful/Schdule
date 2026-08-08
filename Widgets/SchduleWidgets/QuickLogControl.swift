import AppIntents
import SwiftUI
import SchduleIntents
import WidgetKit

/// A Control Centre / Lock Screen / Action button control.
///
/// This is the fastest surface the app has: pressing the Action button logs a
/// slip without unlocking the phone. For an anti-habit that matters — the moment
/// you want to record is the moment you are least inclined to open an app about
/// it.
struct QuickLogControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: "QuickLogControl",
            provider: QuickLogControlProvider()
        ) { value in
            ControlWidgetButton(action: LogEntryIntent(board: value.board)) {
                Label(value.board.name, systemImage: value.board.symbolName)
                Text(value.countDescription)
            }
        }
        .displayName("Quick Log")
        .description("Log one on a board without opening the app.")
    }
}

struct QuickLogValue {
    let board: BoardEntity
    let count: Int

    var countDescription: String {
        String(localized: "\(count) today")
    }
}

struct QuickLogControlProvider: AppIntentControlValueProvider {

    func previewValue(configuration: SelectBoardControlIntent) -> QuickLogValue {
        QuickLogValue(
            board: configuration.board ?? .placeholder,
            count: 0
        )
    }

    @MainActor
    func currentValue(configuration: SelectBoardControlIntent) async throws -> QuickLogValue {
        // The await is hoisted out of the coalescing chain on purpose: the
        // right-hand side of `??` is a non-async autoclosure, so awaiting inside
        // one does not compile.
        var entity = configuration.board
        if entity == nil {
            entity = await BoardEntityQuery().defaultResult()
        }
        let resolved = entity ?? .placeholder
        return QuickLogValue(
            board: resolved,
            count: WidgetData.load(boardID: resolved.id)?.todayCount ?? 0
        )
    }
}

extension BoardEntity {
    /// Stand-in for the control gallery, before a board has been chosen.
    static var placeholder: BoardEntity {
        BoardEntity(
            id: UUID(),
            name: String(localized: "Board"),
            symbolName: "square.grid.3x3",
            isInverted: false
        )
    }
}
