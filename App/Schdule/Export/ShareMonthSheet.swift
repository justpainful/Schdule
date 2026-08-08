import SwiftUI
import SchduleDesign
import SchduleExport
import SchduleModel
import SchduleStats
import SchduleStore

/// Pick a style, see it, send it.
///
/// The preview is the real renderer at a smaller scale rather than an
/// approximation of it, so what gets shared is what was on screen.
struct ShareMonthSheet: View {
    let board: Board
    let month: MonthKey

    @Environment(\.appModel) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var style = PosterStyle.card
    @State private var poster: SharedPoster?
    @State private var isRendering = false

    private var calendar: Calendar { appModel?.calendar ?? .current }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                stylePicker

                ScrollView {
                    MonthPoster(snapshot: snapshot, style: style, calendar: calendar)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
                        .padding(.vertical, 10)
                        .accessibilityIdentifier("poster-preview")
                }
                .scrollIndicators(.hidden)

                shareButton
                    .padding(.horizontal, Metrics.screenMargin)
                    .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("Share Month"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
            .accessibilityIdentifier("share-sheet")
        }
        .task(id: style) { await render() }
    }

    private var stylePicker: some View {
        Picker(String(localized: "Style"), selection: $style) {
            ForEach(PosterStyle.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Metrics.screenMargin)
        .accessibilityIdentifier("poster-style")
    }

    @ViewBuilder
    private var shareButton: some View {
        if let poster {
            ShareLink(
                item: poster,
                preview: SharePreview(
                    "\(board.name) — \(monthTitle)",
                    image: Image(systemName: board.symbolName)
                )
            ) {
                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .accessibilityIdentifier("share-poster")
        } else {
            Button {} label: {
                Group {
                    if isRendering {
                        ProgressView()
                    } else {
                        Text("Preparing…")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glass)
            .disabled(true)
        }
    }

    // MARK: - Rendering

    private func render() async {
        isRendering = true
        defer { isRendering = false }
        poster = nil

        let current = snapshot
        let style = style
        let calendar = calendar

        guard let png = ExportRenderer.pngData(
            snapshot: current,
            style: style,
            calendar: calendar
        ) else { return }

        let pdf = ExportRenderer.pdfData(snapshot: current, style: style, calendar: calendar)
        poster = SharedPoster(pngData: png, pdfData: pdf, filename: filename)
    }

    // MARK: - Snapshot

    private var snapshot: MonthSnapshot {
        let counts = board.countsByDay
        var monthCounts: [Int: Int] = [:]
        for (day, count) in counts where day.monthKey == month {
            monthCounts[day.day] = count
        }

        let today = appModel?.today
        let streak = BoardStatistics.currentStreak(
            counts: counts,
            from: board.startDay,
            through: today ?? DayKey(date: .now),
            isInverted: board.isInverted,
            calendar: calendar
        )
        let logged = BoardStatistics.loggedDays(counts: counts, in: month, calendar: calendar)
        let total = BoardStatistics.total(counts: counts, in: month, calendar: calendar)

        return MonthSnapshot(
            boardName: board.name,
            symbolName: board.symbolName,
            tint: BoardTint(rawValue: board.tintRaw) ?? .orange,
            month: month,
            counts: monthCounts,
            isInverted: board.isInverted,
            today: today?.monthKey == month ? today?.day : nil,
            stats: [
                MonthSnapshot.Stat(
                    caption: board.isInverted
                        ? String(localized: "Days clean")
                        : String(localized: "Streak"),
                    value: String(streak)
                ),
                MonthSnapshot.Stat(
                    caption: board.isInverted
                        ? String(localized: "Slip days")
                        : String(localized: "Active days"),
                    value: String(logged)
                ),
                MonthSnapshot.Stat(
                    caption: String(localized: "Total"),
                    value: String(total)
                ),
            ],
            monthTitle: monthTitle
        )
    }

    private var monthTitle: String {
        CalendarFormatting.monthAndYear(month.startDate(calendar: calendar), calendar: calendar)
    }

    private var filename: String {
        let slug = board.name
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        return "\(slug)-\(month.year)-\(String(format: "%02d", month.month))"
    }
}
