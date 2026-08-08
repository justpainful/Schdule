import Foundation
import Observation
import SwiftUI
import SchduleModel
import SchduleStore

/// App-wide state that is not persisted: which day the app treats as today,
/// which locked boards have been unlocked this session, and the store itself.
@MainActor
@Observable
final class AppModel {
    let store: SchduleStore
    let calendar: Calendar
    /// Frozen under UI test, live otherwise.
    let today: DayKey

    private(set) var unlockedBoardIDs: Set<UUID> = []
    var authenticator: BoardAuthenticating

    init(store: SchduleStore, calendar: Calendar, today: DayKey, authenticator: BoardAuthenticating) {
        self.store = store
        self.calendar = calendar
        self.today = today
        self.authenticator = authenticator
    }

    var currentMonth: MonthKey { today.monthKey }

    func isUnlocked(_ board: Board) -> Bool {
        !board.isLocked || unlockedBoardIDs.contains(board.id)
    }

    /// Asks for biometrics and remembers the result for this session only. The
    /// set is never persisted, so backgrounding and returning re-locks — which
    /// is the point of locking a board in the first place.
    @discardableResult
    func unlock(_ board: Board) async -> Bool {
        guard board.isLocked else { return true }
        if unlockedBoardIDs.contains(board.id) { return true }

        let granted = await authenticator.authenticate(
            reason: String(localized: "Unlock \(board.name)")
        )
        if granted { unlockedBoardIDs.insert(board.id) }
        return granted
    }

    func lockAll() {
        unlockedBoardIDs.removeAll()
    }

    /// Boards the user can see right now. A locked board stays in the list — it
    /// would be odd for it to vanish — but its contents do not render.
    func visibleBoards() -> [Board] {
        (try? store.activeBoards()) ?? []
    }
}

extension EnvironmentValues {
    @Entry var appModel: AppModel?
}
