import Foundation
import SwiftData
import Testing
import SchduleModel
import SchduleStore

@MainActor
@Suite("Store logging")
struct StoreLoggingTests {

    private func makeStore() throws -> (SchduleStore, Board) {
        let store = try SchduleStore.makeInMemory()
        let board = Board(
            name: "TikTok",
            kind: .avoid,
            startDay: DayKey(value: 20260801)
        )
        try store.addBoard(board)
        return (store, board)
    }

    @Test("Incrementing an untouched day creates the entry")
    func firstIncrement() throws {
        let (store, board) = try makeStore()
        let day = DayKey(value: 20260808)
        let result = try store.increment(board: board, on: day)
        #expect(result == 1)
        #expect(store.count(for: board, on: day) == 1)
    }

    @Test("Repeated increments accumulate, which is the whole point")
    func repeatedIncrements() throws {
        let (store, board) = try makeStore()
        let day = DayKey(value: 20260808)
        for _ in 0..<3 { try store.increment(board: board, on: day) }
        #expect(store.count(for: board, on: day) == 3)
        #expect(store.entry(for: board, on: day)?.timestamps.count == 3)
    }

    @Test("A check board is capped at one per day")
    func checkBoardCap() throws {
        let store = try SchduleStore.makeInMemory()
        let board = Board(name: "Workout", kind: .check, startDay: DayKey(value: 20260801))
        try store.addBoard(board)
        let day = DayKey(value: 20260808)

        try store.increment(board: board, on: day)
        try store.increment(board: board, on: day)
        #expect(store.count(for: board, on: day) == 1)
    }

    @Test("Decrementing to zero removes the entry rather than storing a zero")
    func decrementToZeroPrunes() throws {
        let (store, board) = try makeStore()
        let day = DayKey(value: 20260808)
        try store.increment(board: board, on: day)
        try store.increment(board: board, on: day, by: -1)

        #expect(store.count(for: board, on: day) == 0)
        #expect(store.entry(for: board, on: day) == nil)
    }

    @Test("A multi-step increment records one timestamp per occurrence")
    func bulkIncrementTimestamps() throws {
        let (store, board) = try makeStore()
        let day = DayKey(value: 20260808)
        try store.increment(board: board, on: day, by: 3)
        #expect(store.count(for: board, on: day) == 3)
        #expect(store.entry(for: board, on: day)?.timestamps.count == 3)
    }

    @Test("Counts never go negative")
    func noNegativeCounts() throws {
        let (store, board) = try makeStore()
        let day = DayKey(value: 20260808)
        let result = try store.increment(board: board, on: day, by: -5)
        #expect(result == 0)
    }

    @Test("Setting an exact count keeps timestamps in step with it")
    func setCountSyncsTimestamps() throws {
        let (store, board) = try makeStore()
        let day = DayKey(value: 20260808)

        try store.setCount(board: board, on: day, to: 4)
        #expect(store.entry(for: board, on: day)?.timestamps.count == 4)

        try store.setCount(board: board, on: day, to: 2)
        #expect(store.entry(for: board, on: day)?.timestamps.count == 2)
        #expect(store.count(for: board, on: day) == 2)
    }

    @Test("Setting a count to zero clears the day")
    func setCountZero() throws {
        let (store, board) = try makeStore()
        let day = DayKey(value: 20260808)
        try store.setCount(board: board, on: day, to: 3)
        try store.setCount(board: board, on: day, to: 0)
        #expect(store.entry(for: board, on: day) == nil)
    }

    @Test("A note survives on a day with no occurrences")
    func noteWithoutCount() throws {
        let (store, board) = try makeStore()
        let day = DayKey(value: 20260808)
        try store.setNote("travelling", board: board, on: day)

        #expect(store.entry(for: board, on: day)?.note == "travelling")
        #expect(store.count(for: board, on: day) == 0)
    }

    @Test("A whitespace-only note is treated as no note")
    func blankNoteIsNil() throws {
        let (store, board) = try makeStore()
        let day = DayKey(value: 20260808)
        try store.setNote("   \n ", board: board, on: day)
        #expect(store.entry(for: board, on: day)?.note == nil)
    }

    @Test("Days are independent of one another")
    func daysAreIndependent() throws {
        let (store, board) = try makeStore()
        try store.setCount(board: board, on: DayKey(value: 20260807), to: 2)
        try store.setCount(board: board, on: DayKey(value: 20260808), to: 5)

        #expect(store.count(for: board, on: DayKey(value: 20260807)) == 2)
        #expect(store.count(for: board, on: DayKey(value: 20260808)) == 5)
        #expect(board.countsByDay.count == 2)
    }
}

@MainActor
@Suite("Board lifecycle")
struct BoardLifecycleTests {

    private func makeStore() throws -> SchduleStore {
        try SchduleStore.makeInMemory()
    }

    @Test("Trashed boards leave the active list but stay recoverable")
    func trashAndRestore() throws {
        let store = try makeStore()
        let board = Board(name: "Reading", startDay: DayKey(value: 20260801))
        try store.addBoard(board)

        try store.trash(board)
        #expect(try store.activeBoards().isEmpty)
        #expect(try store.trashedBoards().count == 1)

        try store.restore(board)
        #expect(try store.activeBoards().count == 1)
        #expect(try store.trashedBoards().isEmpty)
    }

    @Test("Archived boards leave the active list too")
    func archive() throws {
        let store = try makeStore()
        let board = Board(name: "Reading", startDay: DayKey(value: 20260801))
        try store.addBoard(board)

        try store.archive(board)
        #expect(try store.activeBoards().isEmpty)
        #expect(board.isArchived)

        try store.unarchive(board)
        #expect(try store.activeBoards().count == 1)
    }

    @Test("Trashing unpins, so a board cannot come back holding its old slot")
    func trashUnpins() throws {
        let store = try makeStore()
        let board = Board(name: "Reading", startDay: DayKey(value: 20260801))
        board.isPinned = true
        try store.addBoard(board)

        try store.trash(board)
        #expect(board.isPinned == false)
    }

    @Test("Pinned boards sort ahead of the rest")
    func pinnedSortFirst() throws {
        let store = try makeStore()
        let first = Board(name: "A", startDay: DayKey(value: 20260801), sortIndex: 0)
        let second = Board(name: "B", startDay: DayKey(value: 20260801), sortIndex: 1)
        second.isPinned = true
        try store.addBoard(first)
        try store.addBoard(second)

        #expect(try store.activeBoards().first?.name == "B")
    }

    @Test("Trash purges only after the retention window")
    func purgeRespectsRetention() throws {
        let store = try makeStore()
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()

        let stale = Board(name: "Old", startDay: DayKey(value: 20260801))
        let fresh = Board(name: "New", startDay: DayKey(value: 20260801))
        try store.addBoard(stale)
        try store.addBoard(fresh)

        try store.trash(stale, at: calendar.date(byAdding: .day, value: -45, to: now)!)
        try store.trash(fresh, at: calendar.date(byAdding: .day, value: -2, to: now)!)

        let purged = try store.purgeExpiredTrash(now: now, calendar: calendar)
        #expect(purged == 1)
        #expect(try store.trashedBoards().map(\.name) == ["New"])
    }

    @Test("Deleting a board takes its entries with it")
    func cascadeDelete() throws {
        let store = try makeStore()
        let board = Board(name: "Reading", startDay: DayKey(value: 20260801))
        try store.addBoard(board)
        try store.setCount(board: board, on: DayKey(value: 20260808), to: 2)

        store.context.delete(board)
        try store.context.save()

        let remaining = try store.context.fetch(FetchDescriptor<DayEntry>())
        #expect(remaining.isEmpty)
    }
}
