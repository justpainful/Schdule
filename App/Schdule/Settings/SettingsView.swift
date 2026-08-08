import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import SchduleDesign
import SchduleExport
import SchduleModel
import SchduleStore

/// Everything that is not a board.
struct SettingsView: View {
    @Environment(\.appModel) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Query private var allBoards: [Board]

    @AppStorage("mirrorToCalendar") private var mirrorToCalendar = false
    @AppStorage("appearance") private var appearance = AppearanceSetting.dark.rawValue

    @State private var notificationsAllowed: Bool?
    @State private var calendarError: String?
    @State private var archive: SharedDocument?
    @State private var csv: SharedDocument?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                notificationsSection
                calendarSection
                exportSection
                privacySection
            }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
            .task { await refreshNotificationStatus() }
            .accessibilityIdentifier("settings")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section(String(localized: "Appearance")) {
            Picker(String(localized: "Theme"), selection: $appearance) {
                ForEach(AppearanceSetting.allCases, id: \.rawValue) { option in
                    Text(option.title).tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Notifications

    @ViewBuilder
    private var notificationsSection: some View {
        Section {
            switch notificationsAllowed {
            case .none:
                ProgressView()
            case .some(true):
                Label(String(localized: "Reminders are on"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .some(false):
                Button(String(localized: "Turn on reminders")) {
                    Task {
                        let granted = await ReminderScheduler().requestAuthorization()
                        notificationsAllowed = granted
                        if !granted { openSettings() }
                    }
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Reminders are scheduled on this device. Schdule has no server and sends nothing anywhere.")
        }
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        Section {
            Toggle(isOn: $mirrorToCalendar) {
                Label(String(localized: "Mirror to Calendar"), systemImage: "calendar")
            }
            .onChange(of: mirrorToCalendar) { _, enabled in
                Task { await handleMirrorToggle(enabled) }
            }
            if let calendarError {
                Text(calendarError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("Logged days appear as all-day events in a calendar called Schdule. Delete that calendar and every trace is gone.")
        }
    }

    private func handleMirrorToggle(_ enabled: Bool) async {
        calendarError = nil
        guard enabled else { return }
        do {
            try await CalendarMirror().requestAccess()
        } catch {
            mirrorToCalendar = false
            calendarError = error.localizedDescription
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        Section {
            if let archive {
                ShareLink(item: archive, preview: SharePreview("Schdule backup")) {
                    Label(String(localized: "Export backup (JSON)"), systemImage: "arrow.down.doc")
                }
            }
            if let csv {
                ShareLink(item: csv, preview: SharePreview("Schdule data")) {
                    Label(String(localized: "Export spreadsheet (CSV)"), systemImage: "tablecells")
                }
            }
        } header: {
            Text("Your data")
        } footer: {
            Text("Nothing syncs, so an export is the only copy that outlives this phone. Worth doing occasionally.")
        }
        .task { buildExports() }
    }

    private func buildExports() {
        let boards = allBoards.filter { $0.deletedAt == nil }.map(export)
        csv = SharedDocument(
            data: Data(DataExport.csv(boards).utf8),
            filename: "schdule.csv",
            type: .commaSeparatedText
        )
        if let json = try? DataExport.json(boards) {
            archive = SharedDocument(data: json, filename: "schdule-backup.json", type: .json)
        }
    }

    private func export(_ board: Board) -> BoardExport {
        BoardExport(
            name: board.name,
            symbolName: board.symbolName,
            tint: board.tintRaw,
            kind: board.kind,
            unit: board.unit,
            dailyGoal: board.dailyGoal,
            weeklyTargetDays: board.weeklyTargetDays,
            folder: board.folder?.name,
            startDay: board.startDay,
            entries: (board.entries ?? []).map {
                EntryExport(
                    day: $0.day,
                    count: $0.count,
                    amount: $0.amount,
                    note: $0.note,
                    timestamps: $0.timestamps
                )
            }
        )
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section {
            Label(String(localized: "No account, no sync, no network"), systemImage: "lock.shield")
            Label(String(localized: "Everything stays on this device"), systemImage: "iphone")
        } header: {
            Text("Privacy")
        } footer: {
            Text("Schdule has no analytics and makes no network requests. There is nowhere for your data to go.")
        }
    }

    private func refreshNotificationStatus() async {
        let status = await ReminderScheduler().authorizationStatus()
        notificationsAllowed = status == .authorized || status == .provisional
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

enum AppearanceSetting: String, CaseIterable {
    case dark, light, system

    var title: String {
        switch self {
        case .dark: String(localized: "Dark")
        case .light: String(localized: "Light")
        case .system: String(localized: "System")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        case .system: nil
        }
    }
}
