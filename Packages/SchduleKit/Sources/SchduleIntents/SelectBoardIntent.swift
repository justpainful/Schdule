import AppIntents
import Foundation

/// Which board a widget shows. Edited by long-pressing the widget.
public struct SelectBoardIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "Choose Board"
    public static let description = IntentDescription("Pick which board this widget shows.")

    @Parameter(title: "Board")
    public var board: BoardEntity?

    public init() {}

    public init(board: BoardEntity?) {
        self.board = board
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$board)")
    }
}

/// Which boards the multi-board widget shows, in order.
public struct SelectBoardsIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "Choose Boards"
    public static let description = IntentDescription("Pick which boards this widget shows.")

    @Parameter(title: "Boards")
    public var boards: [BoardEntity]?

    public init() {}

    public init(boards: [BoardEntity]?) {
        self.boards = boards
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$boards)")
    }
}
