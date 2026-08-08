import Foundation
import SchduleModel

/// Ready-made boards offered when creating a new one.
///
/// A blank "name your tracker" field is a small wall: it asks the user to invent
/// both the thing and its shape before they have seen either. A template answers
/// the shape question so only the interesting decision is left.
struct BoardTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let tint: String
    let kind: TrackerKind
    var unit: String?
    var dailyGoal: Int?

    static let positive: [BoardTemplate] = [
        BoardTemplate(id: "workout", name: String(localized: "Workout"),
                      symbol: "figure.strengthtraining.traditional", tint: "orange", kind: .check),
        BoardTemplate(id: "prayer", name: String(localized: "Prayer"),
                      symbol: "moon.stars", tint: "teal", kind: .count, dailyGoal: 5),
        BoardTemplate(id: "water", name: String(localized: "Water"),
                      symbol: "drop", tint: "cyan", kind: .quantity,
                      unit: String(localized: "glasses"), dailyGoal: 8),
        BoardTemplate(id: "reading", name: String(localized: "Reading"),
                      symbol: "book.closed", tint: "brown", kind: .duration,
                      unit: String(localized: "minutes"), dailyGoal: 30),
        BoardTemplate(id: "walk", name: String(localized: "Walk"),
                      symbol: "figure.walk", tint: "mint", kind: .check),
        BoardTemplate(id: "mood", name: String(localized: "Mood"),
                      symbol: "face.smiling", tint: "yellow", kind: .rating),
    ]

    static let negative: [BoardTemplate] = [
        BoardTemplate(id: "social", name: String(localized: "Social apps"),
                      symbol: "iphone.gen3", tint: "red", kind: .avoid),
        BoardTemplate(id: "smoking", name: String(localized: "Smoking"),
                      symbol: "smoke", tint: "brown", kind: .avoid),
        BoardTemplate(id: "latenight", name: String(localized: "Slept late"),
                      symbol: "moon.zzz", tint: "pink", kind: .avoid),
        BoardTemplate(id: "junkfood", name: String(localized: "Junk food"),
                      symbol: "takeoutbag.and.cup.and.straw", tint: "orange", kind: .avoid),
        BoardTemplate(id: "spending", name: String(localized: "Impulse buy"),
                      symbol: "creditcard", tint: "indigo", kind: .avoid),
    ]
}

/// SF Symbols offered in the picker, grouped so the list is browsable rather
/// than a wall of two thousand glyphs.
enum SymbolCatalog {
    static let groups: [(title: String, symbols: [String])] = [
        (String(localized: "Body"), [
            "figure.strengthtraining.traditional", "figure.run", "figure.walk",
            "figure.yoga", "figure.pool.swim", "dumbbell", "heart", "bed.double",
        ]),
        (String(localized: "Mind"), [
            "book.closed", "brain", "pencil", "graduationcap", "text.book.closed",
            "lightbulb", "moon.stars", "face.smiling",
        ]),
        (String(localized: "Daily"), [
            "drop", "cup.and.saucer", "fork.knife", "pills", "sun.max",
            "moon.zzz", "shower", "leaf",
        ]),
        (String(localized: "Screens"), [
            "iphone.gen3", "laptopcomputer", "gamecontroller", "tv",
            "play.rectangle", "message", "camera", "headphones",
        ]),
        (String(localized: "Other"), [
            "smoke", "creditcard", "cart", "car", "airplane",
            "takeoutbag.and.cup.and.straw", "star", "flag",
        ]),
    ]
}
