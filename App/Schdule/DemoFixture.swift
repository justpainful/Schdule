import Foundation
import SchduleDesign
import SchduleModel

/// Stand-in data for M0, before the SwiftData store exists. Fixed values, so the
/// screenshots CI produces are byte-comparable between rounds.
struct DemoBoard: Identifiable, Sendable {
    let id: String
    let name: String
    let symbol: String
    let tint: BoardTint
    let kind: TrackerKind
    let counts: [Int: Int]

    var total: Int { counts.values.reduce(0, +) }
    var activeDays: Int { counts.values.count(where: { $0 > 0 }) }
}

enum DemoFixture {
    static let month = MonthKey(year: 2026, month: 8)
    static let today = 8

    static let boards: [DemoBoard] = [
        DemoBoard(
            id: "workout",
            name: "Workout",
            symbol: "figure.strengthtraining.traditional",
            tint: .green,
            kind: .check,
            counts: [1: 1, 2: 1, 4: 1, 5: 1, 7: 1, 8: 1]
        ),
        DemoBoard(
            id: "tiktok",
            name: "TikTok",
            symbol: "iphone.gen3",
            tint: .indigo,
            kind: .count,
            counts: [1: 2, 2: 1, 3: 4, 4: 1, 5: 3, 6: 1, 7: 7, 8: 2]
        ),
    ]
}
