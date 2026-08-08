import Foundation
import SchduleDesign
import SchduleModel

/// Everything a poster, a CSV row, or a widget needs about one board-month,
/// flattened into a value type.
///
/// Export deliberately does not see SwiftData. A poster is a picture of a moment,
/// and a live model object that can change or fault mid-render is the wrong
/// thing to hand a renderer.
public struct MonthSnapshot: Sendable, Hashable {
    public struct Stat: Sendable, Hashable {
        public let caption: String
        public let value: String

        public init(caption: String, value: String) {
            self.caption = caption
            self.value = value
        }
    }

    public let boardName: String
    public let symbolName: String
    public let tint: BoardTint
    public let month: MonthKey
    /// Day of month → count.
    public let counts: [Int: Int]
    public let isInverted: Bool
    /// Day of month, when the snapshot covers the current month.
    public let today: Int?
    public let stats: [Stat]
    public let monthTitle: String

    public init(
        boardName: String,
        symbolName: String,
        tint: BoardTint,
        month: MonthKey,
        counts: [Int: Int],
        isInverted: Bool,
        today: Int?,
        stats: [Stat],
        monthTitle: String
    ) {
        self.boardName = boardName
        self.symbolName = symbolName
        self.tint = tint
        self.month = month
        self.counts = counts
        self.isInverted = isInverted
        self.today = today
        self.stats = stats
        self.monthTitle = monthTitle
    }

    public var total: Int { counts.values.reduce(0, +) }
    public var loggedDays: Int { counts.values.count { $0 > 0 } }
}
