import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import UIKit

/// A rendered poster, ready for `ShareLink`.
///
/// Conforming to `Transferable` rather than sharing a raw `UIImage` is what
/// makes "Add to Notes", "Save to Photos", and Messages all offer sensible
/// things: each destination picks the representation it wants, and the file
/// arrives with a real name instead of `IMG_0001`.
public struct SharedPoster: Transferable, Sendable {
    public let pngData: Data
    public let pdfData: Data?
    public let filename: String

    public init(pngData: Data, pdfData: Data?, filename: String) {
        self.pngData = pngData
        self.pdfData = pdfData
        self.filename = filename
    }

    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { poster in
            poster.pngData
        }
        .suggestedFileName { "\($0.filename).png" }

        DataRepresentation(exportedContentType: .pdf) { poster in
            poster.pdfData ?? Data()
        }
        .suggestedFileName { "\($0.filename).pdf" }
    }
}

/// A CSV or JSON export, for the same reason.
public struct SharedDocument: Transferable, Sendable {
    public let data: Data
    public let filename: String
    public let type: UTType

    public init(data: Data, filename: String, type: UTType) {
        self.data = data
        self.filename = filename
        self.type = type
    }

    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .data) { document in
            document.data
        }
        .suggestedFileName { $0.filename }
    }
}
