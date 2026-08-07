import SwiftUI

/// The tint a board is drawn in. Twelve hues pulled from the system palette so
/// boards look like they belong next to Reminders lists and Calendar calendars
/// rather than like a third-party color picker exploded.
public enum BoardTint: String, Codable, Sendable, CaseIterable, Identifiable {
    case red, orange, yellow, green, mint, teal
    case cyan, blue, indigo, purple, pink, brown

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .cyan: .cyan
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .brown: .brown
        }
    }
}
