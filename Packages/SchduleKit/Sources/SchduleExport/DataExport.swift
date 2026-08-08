import Foundation
import SchduleModel

/// Machine-readable exports.
///
/// The app keeps everything on device and syncs nowhere, which makes a real
/// export obligatory rather than a nice extra: without one, the only copy of a
/// year's tracking lives in one place and leaves with the phone.
public enum DataExport {

    /// One row per logged day, per board. Opens in Numbers, Excel, anything.
    public static func csv(_ boards: [BoardExport]) -> String {
        var lines = ["board,kind,date,count,note"]
        for board in boards {
            for entry in board.entries.sorted(by: { $0.day < $1.day }) {
                let date = String(
                    format: "%04d-%02d-%02d",
                    entry.day.year, entry.day.month, entry.day.day
                )
                lines.append(
                    [
                        escape(board.name),
                        board.kind.rawValue,
                        date,
                        String(entry.count),
                        escape(entry.note ?? ""),
                    ].joined(separator: ",")
                )
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Full-fidelity backup, including everything the CSV flattens away.
    public static func json(_ boards: [BoardExport]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(Archive(version: 1, boards: boards))
    }

    public static func decode(_ data: Data) throws -> [BoardExport] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Archive.self, from: data).boards
    }

    /// Wraps a comma or a quote so one note cannot shift every later column.
    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private struct Archive: Codable {
        let version: Int
        let boards: [BoardExport]
    }
}

public struct BoardExport: Codable, Sendable, Hashable {
    public let name: String
    public let symbolName: String
    public let tint: String
    public let kind: TrackerKind
    public let unit: String?
    public let dailyGoal: Int?
    public let weeklyTargetDays: Int?
    public let folder: String?
    public let startDay: DayKey
    public let entries: [EntryExport]

    public init(
        name: String,
        symbolName: String,
        tint: String,
        kind: TrackerKind,
        unit: String?,
        dailyGoal: Int?,
        weeklyTargetDays: Int?,
        folder: String?,
        startDay: DayKey,
        entries: [EntryExport]
    ) {
        self.name = name
        self.symbolName = symbolName
        self.tint = tint
        self.kind = kind
        self.unit = unit
        self.dailyGoal = dailyGoal
        self.weeklyTargetDays = weeklyTargetDays
        self.folder = folder
        self.startDay = startDay
        self.entries = entries
    }
}

public struct EntryExport: Codable, Sendable, Hashable {
    public let day: DayKey
    public let count: Int
    public let amount: Double?
    public let note: String?
    public let timestamps: [Date]

    public init(day: DayKey, count: Int, amount: Double?, note: String?, timestamps: [Date]) {
        self.day = day
        self.count = count
        self.amount = amount
        self.note = note
        self.timestamps = timestamps
    }
}
