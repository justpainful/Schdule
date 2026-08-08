import Foundation
import Testing
import SchduleModel
import SchduleExport

private func board(name: String, entries: [EntryExport]) -> BoardExport {
    BoardExport(
        name: name,
        symbolName: "star",
        tint: "orange",
        kind: .count,
        unit: nil,
        dailyGoal: nil,
        weeklyTargetDays: nil,
        folder: nil,
        startDay: DayKey(value: 20260801),
        entries: entries
    )
}

private func entry(_ day: Int, _ count: Int, note: String? = nil) -> EntryExport {
    EntryExport(day: DayKey(value: day), count: count, amount: nil, note: note, timestamps: [])
}

@Suite("CSV export")
struct CSVExportTests {

    @Test("Rows come out in date order with an ISO date")
    func ordering() {
        let csv = DataExport.csv([
            board(name: "Reading", entries: [entry(20260803, 2), entry(20260801, 1)])
        ])
        let lines = csv.split(separator: "\n").map(String.init)

        #expect(lines[0] == "board,kind,date,count,note")
        #expect(lines[1] == "Reading,count,2026-08-01,1,")
        #expect(lines[2] == "Reading,count,2026-08-03,2,")
    }

    @Test("A note containing a comma is quoted so later columns do not shift")
    func escapesCommas() {
        let csv = DataExport.csv([
            board(name: "Reading", entries: [entry(20260801, 1, note: "late, but done")])
        ])
        #expect(csv.contains("\"late, but done\""))
    }

    @Test("A quote inside a note is doubled, not dropped")
    func escapesQuotes() {
        let csv = DataExport.csv([
            board(name: "Reading", entries: [entry(20260801, 1, note: "said \"never again\"")])
        ])
        #expect(csv.contains("\"said \"\"never again\"\"\""))
    }

    @Test("A board name containing a comma is quoted too")
    func escapesBoardName() {
        let csv = DataExport.csv([
            board(name: "Gym, evening", entries: [entry(20260801, 1)])
        ])
        #expect(csv.contains("\"Gym, evening\""))
    }

    @Test("A board with no entries contributes only the header")
    func emptyBoard() {
        let csv = DataExport.csv([board(name: "Empty", entries: [])])
        #expect(csv.split(separator: "\n").count == 1)
    }
}

@Suite("JSON archive")
struct JSONArchiveTests {

    @Test("An archive survives a round trip unchanged")
    func roundTrip() throws {
        let original = [
            board(name: "Reading", entries: [entry(20260801, 1, note: "chapter 3"), entry(20260803, 2)]),
            board(name: "TikTok", entries: [entry(20260802, 7)]),
        ]

        let data = try DataExport.json(original)
        let restored = try DataExport.decode(data)

        #expect(restored == original)
    }

    @Test("Timestamps survive as dates rather than as numbers")
    func timestampsRoundTrip() throws {
        let stamp = Date(timeIntervalSince1970: 1_786_000_000)
        let source = [
            BoardExport(
                name: "Water", symbolName: "drop", tint: "cyan", kind: .quantity,
                unit: "glasses", dailyGoal: 8, weeklyTargetDays: nil, folder: "Health",
                startDay: DayKey(value: 20260801),
                entries: [
                    EntryExport(
                        day: DayKey(value: 20260808), count: 2, amount: 2,
                        note: nil, timestamps: [stamp]
                    )
                ]
            )
        ]

        let restored = try DataExport.decode(try DataExport.json(source))
        #expect(restored.first?.entries.first?.timestamps.first == stamp)
        #expect(restored.first?.unit == "glasses")
        #expect(restored.first?.folder == "Health")
    }

    @Test("Decoding something that is not an archive throws rather than silently emptying")
    func rejectsGarbage() {
        #expect(throws: (any Error).self) {
            try DataExport.decode(Data("not json".utf8))
        }
    }
}

@Suite("Poster snapshot")
struct MonthSnapshotTests {

    private var sample: MonthSnapshot {
        MonthSnapshot(
            boardName: "TikTok",
            symbolName: "iphone.gen3",
            tint: .red,
            month: MonthKey(year: 2026, month: 8),
            counts: [1: 2, 3: 4, 8: 1],
            isInverted: true,
            today: 8,
            stats: [],
            monthTitle: "August 2026"
        )
    }

    @Test("Totals and logged days are counted separately")
    func totals() {
        #expect(sample.total == 7)
        #expect(sample.loggedDays == 3)
    }

    @Test("Every poster style has a portrait aspect")
    func stylesArePortrait() {
        for style in PosterStyle.allCases {
            #expect(style.size.height > style.size.width)
        }
    }
}
