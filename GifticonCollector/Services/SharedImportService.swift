import SwiftData
import UIKit

@MainActor
final class SharedImportService {
    private let ocrService = OCRService()
    private let parser = GifticonParser()
    private let persistenceService: PersistenceService

    init(modelContext: ModelContext) {
        persistenceService = PersistenceService(modelContext: modelContext)
    }

    func processPending() async {
        guard let files = try? SharedImageInbox.pendingFiles() else { return }
        var savedCount = 0
        for file in files {
            do {
                guard let image = UIImage(contentsOfFile: file.path), let cgImage = image.cgImage else { continue }
                let result = try await ocrService.recognize(from: cgImage)
                guard let parsed = parser.parse(text: result.text, barcodeValues: result.barcodeValues) else { continue }
                let existing = try persistenceService.contains(barcode: parsed.barcodeNumber ?? "")
                _ = try persistenceService.save(parsed: parsed, assetLocalIdentifier: "shared:\(file.lastPathComponent)")
                if !existing { savedCount += 1 }
                try SharedImageInbox.archive(file)
            } catch {
                // Keep unreadable files for a later retry instead of discarding user data.
            }
        }
        if savedCount > 0 { NotificationService.postScanCompleted(count: savedCount) }
    }
}
