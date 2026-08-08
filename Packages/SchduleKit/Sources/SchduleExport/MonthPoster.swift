import SwiftUI
import SchduleDesign
import SchduleModel

/// The shareable picture of a month.
///
/// No Liquid Glass anywhere in here, and that is deliberate rather than an
/// omission: glass renders by sampling the backdrop it is composited over, and
/// an exported image has no backdrop and no live surface behind it. Glass in a
/// poster would come out as flat grey.
public struct MonthPoster: View {
    private let snapshot: MonthSnapshot
    private let style: PosterStyle
    private let calendar: Calendar

    public init(snapshot: MonthSnapshot, style: PosterStyle, calendar: Calendar) {
        self.snapshot = snapshot
        self.style = style
        self.calendar = calendar
    }

    public var body: some View {
        Group {
            switch style {
            case .card: card
            case .story: story
            case .receipt: receipt
            }
        }
        .frame(width: style.size.width, height: style.size.height)
        .environment(\.calendar, calendar)
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 18) {
            header(titleFont: .system(size: 24, weight: .bold, design: .rounded))
            grid
            Spacer(minLength: 0)
            statRow
            footer
        }
        .padding(24)
        .background(cardBackground)
    }

    // MARK: - Story

    private var story: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 20) {
                header(titleFont: .system(size: 28, weight: .bold, design: .rounded))
                grid
                statRow
            }
            .padding(26)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.black.opacity(0.28))
            }
            Spacer(minLength: 0)
            footer
        }
        .padding(22)
        .background {
            LinearGradient(
                colors: [
                    snapshot.tint.color.opacity(0.85),
                    snapshot.tint.color.opacity(0.35),
                    .black,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Receipt

    /// A monospaced till roll. Sillier than the others and, because every day
    /// gets its own line, the most precise of the three.
    private var receipt: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "SCHDULE")
                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                .frame(maxWidth: .infinity)
            Text(snapshot.monthTitle.uppercased())
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.top, 2)

            dashes.padding(.vertical, 10)

            Text(snapshot.boardName.uppercased())
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .padding(.bottom, 8)

            ForEach(loggedLines, id: \.day) { line in
                HStack(spacing: 0) {
                    Text(String(format: "%02d", line.day))
                    Text(verbatim: " ")
                    Text(String(repeating: ".", count: 18))
                        .foregroundStyle(.tertiary)
                    Spacer(minLength: 4)
                    Text(line.mark)
                }
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .padding(.vertical, 1)
            }

            dashes.padding(.vertical, 10)

            ForEach(snapshot.stats, id: \.caption) { stat in
                HStack {
                    Text(stat.caption.uppercased())
                    Spacer()
                    Text(stat.value)
                }
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .padding(.vertical, 1)
            }

            dashes.padding(.vertical, 10)

            Text(verbatim: "*** KEPT ON DEVICE ***")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(22)
        .background(Color(white: 0.97))
        .environment(\.colorScheme, .light)
        .foregroundStyle(.black)
    }

    private var dashes: some View {
        Text(String(repeating: "-", count: 34))
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
    }

    private struct ReceiptLine { let day: Int; let mark: String }

    private var loggedLines: [ReceiptLine] {
        snapshot.counts
            .filter { $0.value > 0 }
            .sorted { $0.key < $1.key }
            .map { day, count in
                ReceiptLine(
                    day: day,
                    mark: count == 1
                        ? (snapshot.isInverted ? "X" : "OK")
                        : String(repeating: "X", count: min(count, 5))
                )
            }
    }

    // MARK: - Shared pieces

    private func header(titleFont: Font) -> some View {
        HStack(spacing: 12) {
            Image(systemName: snapshot.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(snapshot.tint.color)
                }
            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.boardName)
                    .font(titleFont)
                Text(snapshot.monthTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var grid: some View {
        MonthGrid(
            month: snapshot.month,
            counts: snapshot.counts,
            tint: snapshot.tint,
            today: snapshot.today,
            isInverted: snapshot.isInverted
        )
    }

    private var statRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(snapshot.stats.enumerated()), id: \.offset) { index, stat in
                if index > 0 {
                    Divider().frame(height: 26)
                }
                VStack(spacing: 1) {
                    Text(stat.value)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text(stat.caption)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 5) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 10, weight: .semibold))
            Text(verbatim: "Schdule")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            Spacer(minLength: 0)
        }
        .foregroundStyle(.tertiary)
    }

    private var cardBackground: some View {
        ZStack {
            Color(.systemBackground)
            LinearGradient(
                colors: [snapshot.tint.color.opacity(0.16), .clear],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}
