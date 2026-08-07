import SwiftUI
import SchduleModel

/// The floating month pager.
///
/// This is one of the few surfaces that *should* be glass: it sits above the
/// scrolling grid, so it has opaque content underneath to sample. Grouping the
/// three controls in a `GlassEffectContainer` lets their shapes blend instead of
/// stacking three separate panes of glass on top of each other.
public struct GlassMonthBar: View {
    private let month: MonthKey
    private let onPrevious: () -> Void
    private let onNext: () -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(month: MonthKey, onPrevious: @escaping () -> Void, onNext: @escaping () -> Void) {
        self.month = month
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    private var title: String {
        month.startDate(calendar: calendar)
            .formatted(.dateTime.year().month(.wide).locale(.autoupdatingCurrent))
    }

    public var body: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 14) {
                stepButton(systemName: "chevron.backward", action: onPrevious)
                    .accessibilityLabel(Text("Previous month"))
                    .accessibilityIdentifier("month-previous")

                Text(title)
                    .font(.headline)
                    .monospacedDigit()
                    .frame(minWidth: 150)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .glassEffect(.regular, in: .capsule)

                stepButton(systemName: "chevron.forward", action: onNext)
                    .accessibilityLabel(Text("Next month"))
                    .accessibilityIdentifier("month-next")
            }
        }
        // Reduce Transparency users get a solid material instead of glass.
        .opacity(1)
        .background {
            if reduceTransparency {
                Capsule().fill(.regularMaterial)
            }
        }
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
}
