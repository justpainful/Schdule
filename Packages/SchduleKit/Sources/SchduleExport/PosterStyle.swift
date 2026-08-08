import CoreGraphics
import Foundation

/// The shapes a shared month can take.
///
/// Three, not one, because the places a schedule gets shown are different
/// shapes: a card lands in a chat, a story is full-bleed and vertical, and a
/// receipt is a joke that happens to be very readable.
public enum PosterStyle: String, CaseIterable, Identifiable, Sendable {
    case card
    case story
    case receipt

    public var id: String { rawValue }

    /// Point size at 1x. Renderers scale up from here.
    public var size: CGSize {
        switch self {
        case .card: CGSize(width: 400, height: 500)
        case .story: CGSize(width: 360, height: 640)
        case .receipt: CGSize(width: 330, height: 620)
        }
    }

    public var title: String {
        switch self {
        case .card: String(localized: "Card")
        case .story: String(localized: "Story")
        case .receipt: String(localized: "Receipt")
        }
    }

    public var symbolName: String {
        switch self {
        case .card: "rectangle.portrait"
        case .story: "rectangle.portrait.on.rectangle.portrait"
        case .receipt: "doc.plaintext"
        }
    }
}
