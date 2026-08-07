import SwiftUI

/// Shared spacing and radius values. Kept in one place so the app, the widgets,
/// and the export posters agree on proportions without copy-pasted magic numbers.
public enum Metrics {
    public static let cellCornerRadius: CGFloat = 8
    public static let cellSpacing: CGFloat = 6
    public static let cardCornerRadius: CGFloat = 20
    public static let glassCornerRadius: CGFloat = 22
    public static let screenMargin: CGFloat = 20
}
