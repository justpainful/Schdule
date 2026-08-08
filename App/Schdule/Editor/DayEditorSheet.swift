import SwiftUI
import SchduleDesign
import SchduleModel
import SchduleStore

/// Editing one day: the exact count, a note, and nothing else.
///
/// Tapping a cell in the grid increments; this is where you land when the tap
/// was not enough — you forgot Tuesday, or you opened TikTok eleven times and
/// tapping eleven times is absurd.
struct DayEditorSheet: View {
    let board: Board
    let day: DayKey

    @Environment(\.appModel) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var count = 0
    @State private var note = ""
    @State private var didLoad = false

    private var tint: BoardTint { BoardTint(rawValue: board.tintRaw) ?? .orange }
    private var calendar: Calendar { appModel?.calendar ?? .current }
    private var allowsMultiple: Bool { board.kind.allowsMultiplePerDay }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    counter
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .frame(maxWidth: .infinity)
                }

                Section(String(localized: "Note")) {
                    TextField(
                        String(localized: "What happened?"),
                        text: $note,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .accessibilityIdentifier("day-note")
                }

                if count > 0 {
                    Section {
                        Button(role: .destructive) {
                            count = 0
                        } label: {
                            Label(String(localized: "Clear this day"), systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(Text(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { save() }
                        .accessibilityIdentifier("day-editor-done")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            guard !didLoad else { return }
            didLoad = true
            let entry = appModel?.store.entry(for: board, on: day)
            count = entry?.count ?? 0
            note = entry?.note ?? ""
        }
    }

    private var counter: some View {
        VStack(spacing: 18) {
            HStack(spacing: 26) {
                roundButton("minus", enabled: count > 0) {
                    count = max(0, count - 1)
                }
                .accessibilityIdentifier("day-decrement")

                VStack(spacing: 2) {
                    Text(count, format: .number)
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(count > 0 ? tint.color : .secondary)
                    Text(unitCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 110)

                roundButton("plus", enabled: allowsMultiple || count == 0) {
                    count += 1
                }
                .accessibilityIdentifier("day-increment")
            }

            if board.isInverted, count == 0 {
                Label(String(localized: "Clean day"), systemImage: "checkmark.seal.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
    }

    private func roundButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.glass)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    private var unitCaption: String {
        if let unit = board.unit, !unit.isEmpty { return unit }
        return board.isInverted
            ? String(localized: "slips")
            : String(localized: "times")
    }

    private var title: String {
        day.date(calendar: calendar).formatted(
            Date.FormatStyle(locale: .autoupdatingCurrent, calendar: calendar, timeZone: calendar.timeZone)
                .weekday(.abbreviated)
                .day()
                .month(.wide)
        )
    }

    private func save() {
        guard let appModel else { return dismiss() }
        try? appModel.store.setCount(board: board, on: day, to: count)
        try? appModel.store.setNote(note, board: board, on: day)
        dismiss()
    }
}
