import AppIntents
import Foundation
import SchduleModel
import SchduleStore

/// A board as the rest of the system sees it: in Shortcuts, in Spotlight, in a
/// widget's configuration sheet, and as something Siri can name.
public struct BoardEntity: AppEntity, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let symbolName: String
    public let isInverted: Bool

    public init(id: UUID, name: String, symbolName: String, isInverted: Bool) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.isInverted = isInverted
    }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Board")
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: isInverted ? "Avoiding" : "Habit",
            image: .init(systemName: symbolName)
        )
    }

    public static let defaultQuery = BoardEntityQuery()
}

public struct BoardEntityQuery: EntityQuery, EntityStringQuery {
    public init() {}

    @MainActor
    public func entities(for identifiers: [UUID]) async throws -> [BoardEntity] {
        try all().filter { identifiers.contains($0.id) }
    }

    @MainActor
    public func entities(matching string: String) async throws -> [BoardEntity] {
        try all().filter { $0.name.localizedStandardContains(string) }
    }

    @MainActor
    public func suggestedEntities() async throws -> [BoardEntity] {
        try all()
    }

    @MainActor
    public func defaultResult() async -> BoardEntity? {
        try? all().first
    }

    /// Locked boards are withheld from every system surface.
    ///
    /// A board behind Face ID that still shows up in Spotlight, in a widget
    /// picker, or in a Siri suggestion is not locked in any way the user would
    /// recognise — the name alone is usually the sensitive part.
    @MainActor
    private func all() throws -> [BoardEntity] {
        let store = try SchduleStore.makeShared()
        return try store.activeBoards()
            .filter { !$0.isLocked }
            .map {
                BoardEntity(
                    id: $0.id,
                    name: $0.name,
                    symbolName: $0.symbolName,
                    isInverted: $0.isInverted
                )
            }
    }
}
