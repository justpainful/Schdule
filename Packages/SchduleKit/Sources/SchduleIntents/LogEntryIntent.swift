import AppIntents
import Foundation
import SchduleModel
import SchduleStore
import WidgetKit

/// Adds one occurrence to today.
///
/// This is the intent behind every one-tap surface: the button inside a widget,
/// the Control Centre control, the Action button, "Hey Siri, log a workout", and
/// the action a Shortcut can call. One implementation, so they cannot drift.
public struct LogEntryIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log Entry"
    public static let description = IntentDescription("Adds one to today's count on a board.")

    /// False so a widget button logs in place instead of throwing the user into
    /// the app. Being able to log without leaving the Home Screen is most of
    /// the point of the widget.
    public static let openAppWhenRun: Bool = false

    @Parameter(title: "Board")
    public var board: BoardEntity

    @Parameter(title: "Amount", default: 1)
    public var amount: Int

    public init() {}

    public init(board: BoardEntity, amount: Int = 1) {
        self.board = board
        self.amount = amount
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) on \(\.$board)")
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = try SchduleStore.makeShared()
        guard let target = try store.activeBoards().first(where: { $0.id == board.id }) else {
            throw LogError.boardNotFound
        }
        guard !target.isLocked else { throw LogError.boardLocked }

        let today = DayKey(date: .now)
        let result = try store.increment(
            board: target,
            on: today,
            by: amount,
            source: .siri
        )

        WidgetCenter.shared.reloadAllTimelines()

        let dialog: IntentDialog = if target.isInverted {
            "Logged. \(result) today."
        } else {
            "Done. \(result) today."
        }
        return .result(dialog: dialog)
    }
}

/// Reports today's count without changing anything.
public struct CheckBoardIntent: AppIntent {
    public static let title: LocalizedStringResource = "Check Board"
    public static let description = IntentDescription("Reports today's count on a board.")
    public static let openAppWhenRun: Bool = false

    @Parameter(title: "Board")
    public var board: BoardEntity

    public init() {}
    public init(board: BoardEntity) { self.board = board }

    public static var parameterSummary: some ParameterSummary {
        Summary("Check \(\.$board)")
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let store = try SchduleStore.makeShared()
        guard let target = try store.activeBoards().first(where: { $0.id == board.id }) else {
            throw LogError.boardNotFound
        }
        guard !target.isLocked else { throw LogError.boardLocked }

        let count = store.count(for: target, on: DayKey(date: .now))
        return .result(value: count, dialog: "\(count) so far today.")
    }
}

public enum LogError: Error, CustomLocalizedStringResourceConvertible {
    case boardNotFound
    case boardLocked

    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .boardNotFound: "That board no longer exists."
        case .boardLocked: "That board is locked. Open Schdule to unlock it."
        }
    }
}
