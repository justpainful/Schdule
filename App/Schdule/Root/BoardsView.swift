import SwiftUI
import SwiftData
import SchduleDesign
import SchduleModel
import SchduleStats
import SchduleStore

/// What subset of boards the list is showing.
enum BoardScope: Hashable {
    case all
    case pinned
    case folder(UUID)
    case archived
    case trash

    var isTrash: Bool { self == .trash }
}

/// Notes-style browsing: folders on the left, boards in the middle, the month
/// on the right. Collapses to a drill-down stack on iPhone.
struct BoardsView: View {
    @Environment(\.appModel) private var appModel
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\BoardFolder.sortIndex)]) private var folders: [BoardFolder]
    @Query private var allBoards: [Board]

    @State private var scope: BoardScope? = .all
    @State private var selectedBoardID: UUID?
    @State private var searchText = ""
    @State private var isCreating = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } content: {
            boardList
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $isCreating) {
            BoardEditorView(board: nil)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $scope) {
            Section {
                label(String(localized: "All Boards"), "square.grid.3x3.fill", count: liveBoards.count)
                    .tag(BoardScope.all)
                label(String(localized: "Pinned"), "pin.fill", count: liveBoards.count(where: \.isPinned))
                    .tag(BoardScope.pinned)
            }

            if !folders.isEmpty {
                Section(String(localized: "Folders")) {
                    ForEach(folders) { folder in
                        label(folder.name, folder.symbolName, count: boardCount(in: folder))
                            .tag(BoardScope.folder(folder.id))
                    }
                }
            }

            Section {
                label(String(localized: "Archive"), "archivebox", count: archivedBoards.count)
                    .tag(BoardScope.archived)
                label(String(localized: "Recently Deleted"), "trash", count: trashedBoards.count)
                    .tag(BoardScope.trash)
            }
        }
        .navigationTitle(Text("Boards"))
        .accessibilityIdentifier("folders-sidebar")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isCreating = true
                } label: {
                    Label(String(localized: "New Board"), systemImage: "plus")
                }
                .accessibilityIdentifier("new-board")
            }
        }
    }

    private func label(_ title: String, _ symbol: String, count: Int) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text(count, format: .number)
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Board list

    private var boardList: some View {
        List(selection: $selectedBoardID) {
            ForEach(scopedBoards) { board in
                BoardRow(
                    board: board,
                    count: countToday(board),
                    subtitle: summary(for: board),
                    isLocked: !(appModel?.isUnlocked(board) ?? true)
                )
                .tag(board.id)
                .swipeActions(edge: .trailing) {
                    if scope?.isTrash == true {
                        Button {
                            try? appModel?.store.restore(board)
                        } label: {
                            Label(String(localized: "Restore"), systemImage: "arrow.uturn.backward")
                        }
                        .tint(.blue)
                    } else {
                        Button(role: .destructive) {
                            try? appModel?.store.trash(board)
                        } label: {
                            Label(String(localized: "Delete"), systemImage: "trash")
                        }
                        Button {
                            try? appModel?.store.archive(board)
                        } label: {
                            Label(String(localized: "Archive"), systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
                }
                .swipeActions(edge: .leading) {
                    if scope?.isTrash != true {
                        Button {
                            board.isPinned.toggle()
                            try? context.save()
                        } label: {
                            Label(
                                board.isPinned ? String(localized: "Unpin") : String(localized: "Pin"),
                                systemImage: board.isPinned ? "pin.slash" : "pin"
                            )
                        }
                        .tint(.yellow)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: Text("Search boards"))
        .navigationTitle(Text(scopeTitle))
        .accessibilityIdentifier("board-list")
        .overlay {
            if scopedBoards.isEmpty {
                emptyState
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if scope?.isTrash == true {
            ContentUnavailableView(
                String(localized: "Nothing Deleted"),
                systemImage: "trash",
                description: Text("Boards you delete rest here for 30 days before they go for good.")
            )
        } else if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            ContentUnavailableView {
                Label(String(localized: "No Boards"), systemImage: "square.grid.3x3")
            } description: {
                Text("A board is one thing you want to track — a habit to build, or one to drop.")
            } actions: {
                Button(String(localized: "New Board")) { isCreating = true }
                    .buttonStyle(.glassProminent)
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let board = scopedBoards.first(where: { $0.id == selectedBoardID }) {
            BoardDetailView(board: board)
        } else {
            ContentUnavailableView(
                String(localized: "No Board Selected"),
                systemImage: "square.grid.3x3",
                description: Text("Pick a board to see its month.")
            )
        }
    }

    // MARK: - Filtering

    private var liveBoards: [Board] {
        allBoards.filter { $0.deletedAt == nil && $0.archivedAt == nil }
    }

    private var archivedBoards: [Board] {
        allBoards.filter { $0.deletedAt == nil && $0.archivedAt != nil }
    }

    private var trashedBoards: [Board] {
        allBoards.filter { $0.deletedAt != nil }
    }

    private func boardCount(in folder: BoardFolder) -> Int {
        liveBoards.count { $0.folder?.id == folder.id }
    }

    private var scopedBoards: [Board] {
        let base: [Board] = switch scope ?? .all {
        case .all: liveBoards
        case .pinned: liveBoards.filter(\.isPinned)
        case .folder(let id): liveBoards.filter { $0.folder?.id == id }
        case .archived: archivedBoards
        case .trash: trashedBoards
        }

        let searched = searchText.isEmpty
            ? base
            : base.filter { $0.name.localizedStandardContains(searchText) }

        return searched.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            if lhs.sortIndex != rhs.sortIndex { return lhs.sortIndex < rhs.sortIndex }
            return lhs.createdAt < rhs.createdAt
        }
    }

    private var scopeTitle: String {
        switch scope ?? .all {
        case .all: String(localized: "All Boards")
        case .pinned: String(localized: "Pinned")
        case .folder(let id):
            folders.first { $0.id == id }?.name ?? String(localized: "Folder")
        case .archived: String(localized: "Archive")
        case .trash: String(localized: "Recently Deleted")
        }
    }

    private func countToday(_ board: Board) -> Int {
        guard let appModel else { return 0 }
        return board.countsByDay[appModel.today] ?? 0
    }

    private func summary(for board: Board) -> String {
        guard let appModel else { return "" }
        if board.isTrashed, let deletedAt = board.deletedAt {
            let days = Calendar.current.dateComponents([.day], from: deletedAt, to: .now).day ?? 0
            return String(localized: "Deleted \(SchduleStore.trashRetentionDays - days) days left")
        }

        let counts = board.countsByDay
        let streak = BoardStatistics.currentStreak(
            counts: counts,
            from: board.startDay,
            through: appModel.today,
            isInverted: board.isInverted,
            calendar: appModel.calendar
        )
        let monthTotal = BoardStatistics.total(
            counts: counts,
            in: appModel.currentMonth,
            calendar: appModel.calendar
        )

        let streakText = board.isInverted
            ? String(localized: "\(streak) days clean")
            : String(localized: "\(streak) day streak")
        return streakText + " · " + String(localized: "\(monthTotal) this month")
    }
}
