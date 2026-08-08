import SwiftUI
import SchduleDesign
import SchduleModel
import SchduleStats
import SchduleStore

/// A board as it appears in a list: identity on the left, today's tally on the
/// right, and enough context underneath to know whether today matters.
struct BoardRow: View {
    let board: Board
    let count: Int
    let subtitle: String
    let isLocked: Bool
    var onIncrement: (() -> Void)?
    var onDecrement: (() -> Void)?

    private var tint: BoardTint { BoardTint(rawValue: board.tintRaw) ?? .orange }

    var body: some View {
        HStack(spacing: 14) {
            BoardGlyph(board: board, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(board.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if board.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isLocked {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.tertiary)
            } else {
                counter
            }
        }
        .padding(.vertical, 6)
    }

    private var counter: some View {
        HStack(spacing: 10) {
            // The minus keeps its slot at zero rather than disappearing. Letting
            // it vanish shifted the number sideways, so a column of rows no
            // longer lined up and the counts were harder to scan than they
            // should be.
            Group {
                if count > 0, let onDecrement {
                    stepButton(systemName: "minus", action: onDecrement)
                        .accessibilityLabel(Text("Remove one"))
                } else {
                    Color.clear.frame(width: 30, height: 30)
                }
            }

            Text(count, format: .number)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(count > 0 ? AnyShapeStyle(tint.color) : AnyShapeStyle(.tertiary))
                .frame(minWidth: 22)

            if let onIncrement {
                stepButton(systemName: "plus", action: onIncrement)
                    .accessibilityLabel(Text("Add one"))
            }
        }
        .accessibilityIdentifier("counter-\(board.name)")
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint.color)
                .frame(width: 30, height: 30)
                .background {
                    Circle().fill(tint.color.opacity(0.16))
                }
        }
        .buttonStyle(.plain)
    }
}
