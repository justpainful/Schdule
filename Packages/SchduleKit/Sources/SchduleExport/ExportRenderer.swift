import CoreGraphics
import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Turns a poster into something shareable.
@MainActor
public enum ExportRenderer {
    /// 3x, so the image survives being viewed full-screen on a modern phone and
    /// still looks like a screenshot rather than an upscale.
    public static let defaultScale: CGFloat = 3

    public static func image(
        snapshot: MonthSnapshot,
        style: PosterStyle,
        calendar: Calendar,
        scale: CGFloat = defaultScale
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: MonthPoster(snapshot: snapshot, style: style, calendar: calendar)
        )
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }

    public static func pngData(
        snapshot: MonthSnapshot,
        style: PosterStyle,
        calendar: Calendar,
        scale: CGFloat = defaultScale
    ) -> Data? {
        image(snapshot: snapshot, style: style, calendar: calendar, scale: scale)?.pngData()
    }

    /// A vector PDF, which is what you want if the schedule is going to be
    /// printed or dropped into a document rather than posted.
    public static func pdfData(
        snapshot: MonthSnapshot,
        style: PosterStyle,
        calendar: Calendar
    ) -> Data? {
        let renderer = ImageRenderer(
            content: MonthPoster(snapshot: snapshot, style: style, calendar: calendar)
        )
        let data = NSMutableData()

        var box = CGRect(origin: .zero, size: style.size)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &box, nil)
        else { return nil }

        renderer.render { _, draw in
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
        }

        return data as Data
    }
}
