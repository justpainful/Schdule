import Foundation
import SwiftData
import SchduleModel

/// Owns the SwiftData container and every mutation the app makes.
///
/// The container lives in an App Group so the widget and intents extensions read
/// and write the same file. There is no CloudKit configuration and no network
/// code anywhere in this module — the store is local by construction, not by
/// a setting someone could flip.
@MainActor
public final class SchduleStore {
    public static let appGroupID = "group.com.justpainful.schdule"

    public let container: ModelContainer

    public var context: ModelContext { container.mainContext }

    /// How long a deleted board waits in Recently Deleted before purging.
    public static let trashRetentionDays = 30

    public init(container: ModelContainer) {
        self.container = container
    }

    /// The shared on-disk store. Falls back to a container in the app's own
    /// sandbox if the App Group is unavailable — better a working app with
    /// stale widgets than a launch crash.
    public static func makeShared() throws -> SchduleStore {
        let schema = Schema([BoardFolder.self, Board.self, DayEntry.self])
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appending(path: "Schdule.sqlite")

        let configuration: ModelConfiguration = if let groupURL {
            ModelConfiguration(schema: schema, url: groupURL)
        } else {
            ModelConfiguration(schema: schema)
        }

        return SchduleStore(container: try ModelContainer(for: schema, configurations: configuration))
    }

    /// An in-memory store for tests and previews.
    public static func makeInMemory() throws -> SchduleStore {
        let schema = Schema([BoardFolder.self, Board.self, DayEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return SchduleStore(container: try ModelContainer(for: schema, configurations: configuration))
    }

    // MARK: - Reading

    /// Live boards, pinned first, then by the user's ordering.
    public func activeBoards() throws -> [Board] {
        let descriptor = FetchDescriptor<Board>(
            predicate: #Predicate { $0.deletedAt == nil && $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.createdAt)]
        )
        let boards = try context.fetch(descriptor)
        return boards.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.sortIndex < rhs.sortIndex
        }
    }

    public func trashedBoards() throws -> [Board] {
        try context.fetch(
            FetchDescriptor<Board>(
                predicate: #Predicate { $0.deletedAt != nil },
                sortBy: [SortDescriptor(\.deletedAt, order: .reverse)]
            )
        )
    }

    public func entry(for board: Board, on day: DayKey) -> DayEntry? {
        board.entries?.first { $0.dayValue == day.value }
    }

    public func count(for board: Board, on day: DayKey) -> Int {
        entry(for: board, on: day)?.count ?? 0
    }

    // MARK: - Logging

    /// Adds one occurrence to a day, creating the entry if needed.
    ///
    /// Returns the resulting count so a widget or intent can report it back
    /// without a second read.
    @discardableResult
    public func increment(
        board: Board,
        on day: DayKey,
        by delta: Int = 1,
        source: EntrySource = .app,
        at timestamp: Date = Date()
    ) throws -> Int {
        let existing = entry(for: board, on: day)
        let ceiling = board.kind.allowsMultiplePerDay ? Int.max : 1
        let target = min(max((existing?.count ?? 0) + delta, 0), ceiling)

        if let existing {
            existing.count = target
            existing.source = source
            if delta > 0 { existing.timestamps.append(timestamp) }
            else if !existing.timestamps.isEmpty { existing.timestamps.removeLast() }
            // A day back at zero holds no information; drop it so the store
            // stays proportional to what actually happened.
            if target == 0 { context.delete(existing) }
        } else if target > 0 {
            let entry = DayEntry(day: day, count: target, source: source, timestamps: [timestamp])
            entry.board = board
            context.insert(entry)
        }

        try context.save()
        return target
    }

    /// Sets a day to an exact count, for the long-press editor.
    @discardableResult
    public func setCount(
        board: Board,
        on day: DayKey,
        to newCount: Int,
        source: EntrySource = .app
    ) throws -> Int {
        let ceiling = board.kind.allowsMultiplePerDay ? Int.max : 1
        let target = min(max(newCount, 0), ceiling)
        let existing = entry(for: board, on: day)

        if target == 0 {
            if let existing { context.delete(existing) }
        } else if let existing {
            existing.count = target
            existing.source = source
            // Keep the timestamp list the same length as the count so the
            // "when do I do this" histogram stays honest after a manual edit.
            while existing.timestamps.count > target { existing.timestamps.removeLast() }
            while existing.timestamps.count < target { existing.timestamps.append(Date()) }
        } else {
            let entry = DayEntry(day: day, count: target, source: source, timestamps: [Date()])
            entry.board = board
            context.insert(entry)
        }

        try context.save()
        return target
    }

    public func setNote(_ note: String?, board: Board, on day: DayKey) throws {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = (trimmed?.isEmpty ?? true) ? nil : trimmed

        if let existing = entry(for: board, on: day) {
            existing.note = text
        } else if let text {
            // A note on an otherwise empty day is worth keeping even at count 0.
            let entry = DayEntry(day: day, count: 0, note: text)
            entry.board = board
            context.insert(entry)
        }
        try context.save()
    }

    // MARK: - Board lifecycle

    public func addBoard(_ board: Board) throws {
        context.insert(board)
        try context.save()
    }

    public func trash(_ board: Board, at date: Date = Date()) throws {
        board.deletedAt = date
        board.isPinned = false
        try context.save()
    }

    public func restore(_ board: Board) throws {
        board.deletedAt = nil
        try context.save()
    }

    public func archive(_ board: Board, at date: Date = Date()) throws {
        board.archivedAt = date
        board.isPinned = false
        try context.save()
    }

    public func unarchive(_ board: Board) throws {
        board.archivedAt = nil
        try context.save()
    }

    /// Permanently removes boards whose retention window has elapsed.
    /// Returns how many were purged.
    @discardableResult
    public func purgeExpiredTrash(now: Date = Date(), calendar: Calendar = .current) throws -> Int {
        let cutoff = calendar.date(byAdding: .day, value: -Self.trashRetentionDays, to: now) ?? now
        let expired = try trashedBoards().filter { board in
            guard let deletedAt = board.deletedAt else { return false }
            return deletedAt < cutoff
        }
        for board in expired { context.delete(board) }
        if !expired.isEmpty { try context.save() }
        return expired.count
    }
}
