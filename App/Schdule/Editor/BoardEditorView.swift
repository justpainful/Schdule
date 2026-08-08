import SwiftUI
import SwiftData
import SchduleDesign
import SchduleModel
import SchduleStore

/// Creates or edits a board. Passing `nil` means create.
struct BoardEditorView: View {
    let board: Board?

    @Environment(\.appModel) private var appModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\BoardFolder.sortIndex)]) private var folders: [BoardFolder]

    @State private var name = ""
    @State private var symbol = "checkmark.circle"
    @State private var tint = BoardTint.orange
    @State private var kind = TrackerKind.check
    @State private var unit = ""
    @State private var dailyGoal = 0
    @State private var weeklyTarget = 0
    @State private var folderID: UUID?
    @State private var isLocked = false
    @State private var didLoad = false

    private var isCreating: Bool { board == nil }

    var body: some View {
        NavigationStack {
            Form {
                if isCreating, name.isEmpty {
                    templateSection
                }

                Section {
                    HStack(spacing: 14) {
                        Image(systemName: symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.color)
                            }
                        TextField(String(localized: "Board name"), text: $name)
                            .font(.body)
                            .accessibilityIdentifier("board-name-field")
                    }
                }

                Section(String(localized: "Kind")) {
                    Picker(String(localized: "Kind"), selection: $kind) {
                        ForEach(TrackerKind.allCases, id: \.self) { kind in
                            Text(title(for: kind)).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                    Text(explanation(for: kind))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if kind == .quantity || kind == .duration {
                    Section(String(localized: "Unit")) {
                        TextField(String(localized: "glasses, km, pages"), text: $unit)
                    }
                }

                Section(String(localized: "Goal")) {
                    Stepper(
                        dailyGoal == 0
                            ? String(localized: "No daily goal")
                            : String(localized: "\(dailyGoal) per day"),
                        value: $dailyGoal,
                        in: 0...50
                    )
                    Stepper(
                        weeklyTarget == 0
                            ? String(localized: "No weekly target")
                            : String(localized: "\(weeklyTarget) days per week"),
                        value: $weeklyTarget,
                        in: 0...7
                    )
                }

                Section(String(localized: "Colour")) {
                    tintGrid
                }

                Section(String(localized: "Symbol")) {
                    symbolPicker
                }

                Section {
                    Picker(String(localized: "Folder"), selection: $folderID) {
                        Text("None").tag(UUID?.none)
                        ForEach(folders) { folder in
                            Text(folder.name).tag(UUID?.some(folder.id))
                        }
                    }
                    Toggle(isOn: $isLocked) {
                        Label(String(localized: "Require Face ID"), systemImage: "lock.fill")
                    }
                } footer: {
                    Text("A locked board is hidden from widgets and search, and asks for Face ID every time the app returns to the foreground.")
                }
            }
            .navigationTitle(Text(isCreating ? "New Board" : "Edit Board"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("board-save")
                }
            }
            .task { load() }
        }
    }

    // MARK: - Templates

    private var templateSection: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(BoardTemplate.positive + BoardTemplate.negative) { template in
                        Button { apply(template) } label: {
                            VStack(spacing: 6) {
                                Image(systemName: template.symbol)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill((BoardTint(rawValue: template.tint) ?? .orange).color)
                                    }
                                Text(template.name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        } header: {
            Text("Start from")
        } footer: {
            Text("Or just type a name below.")
        }
    }

    private func apply(_ template: BoardTemplate) {
        withAnimation(.snappy) {
            name = template.name
            symbol = template.symbol
            tint = BoardTint(rawValue: template.tint) ?? .orange
            kind = template.kind
            unit = template.unit ?? ""
            dailyGoal = template.dailyGoal ?? 0
        }
    }

    // MARK: - Pickers

    private var tintGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
            ForEach(BoardTint.allCases) { option in
                Button {
                    tint = option
                } label: {
                    Circle()
                        .fill(option.color)
                        .frame(height: 32)
                        .overlay {
                            if option == tint {
                                Circle().strokeBorder(Color.primary, lineWidth: 2.5).padding(-3)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(option.rawValue))
            }
        }
        .padding(.vertical, 4)
    }

    private var symbolPicker: some View {
        ForEach(SymbolCatalog.groups, id: \.title) { group in
            VStack(alignment: .leading, spacing: 8) {
                Text(group.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 10) {
                    ForEach(group.symbols, id: \.self) { candidate in
                        Button { symbol = candidate } label: {
                            Image(systemName: candidate)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .foregroundStyle(candidate == symbol ? Color.white : Color.primary)
                                .background {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(candidate == symbol ? tint.color : Color(.tertiarySystemFill))
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Copy

    private func title(for kind: TrackerKind) -> String {
        switch kind {
        case .check: String(localized: "Did it")
        case .count: String(localized: "How many times")
        case .quantity: String(localized: "Amount")
        case .duration: String(localized: "Time spent")
        case .rating: String(localized: "Rating out of five")
        case .avoid: String(localized: "Trying to avoid")
        }
    }

    private func explanation(for kind: TrackerKind) -> String {
        switch kind {
        case .check: String(localized: "One mark a day. Either you did it or you didn't.")
        case .count: String(localized: "Counts every time. Three times in a day shows as a 3.")
        case .quantity: String(localized: "Records an amount against a unit you choose.")
        case .duration: String(localized: "Times a session with a live timer.")
        case .rating: String(localized: "One to five, for things that are not yes or no.")
        case .avoid: String(localized: "Counts slips. A day with nothing logged is the good day, and the streak counts days clean.")
        }
    }

    // MARK: - Load and save

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        guard let board else { return }
        name = board.name
        symbol = board.symbolName
        tint = BoardTint(rawValue: board.tintRaw) ?? .orange
        kind = board.kind
        unit = board.unit ?? ""
        dailyGoal = board.dailyGoal ?? 0
        weeklyTarget = board.weeklyTargetDays ?? 0
        folderID = board.folder?.id
        isLocked = board.isLocked
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let target: Board
        if let board {
            target = board
        } else {
            let today = appModel?.today ?? DayKey(date: .now)
            target = Board(name: trimmed, kind: kind, startDay: today)
            context.insert(target)
        }

        target.name = trimmed
        target.symbolName = symbol
        target.tintRaw = tint.rawValue
        target.kind = kind
        target.unit = unit.isEmpty ? nil : unit
        target.dailyGoal = dailyGoal == 0 ? nil : dailyGoal
        target.weeklyTargetDays = weeklyTarget == 0 ? nil : weeklyTarget
        target.isLocked = isLocked
        target.folder = folders.first { $0.id == folderID }

        try? context.save()
        dismiss()
    }
}
