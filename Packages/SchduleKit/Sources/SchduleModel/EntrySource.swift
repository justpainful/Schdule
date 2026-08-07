import Foundation

/// Where a log came from. Recorded so the app can tell an entry the user tapped
/// in the grid from one a widget or Siri produced — useful when reconciling a
/// double-tap on the Lock Screen, and for the "how do you actually log" stat.
public enum EntrySource: String, Codable, Sendable, CaseIterable {
    case app
    case widget
    case control
    case siri
    case shortcut
    case notification
    case liveActivity
    case importer
}
