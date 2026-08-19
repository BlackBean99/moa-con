import SwiftData
import UIKit

@MainActor
final class SharedImportService {
    private let ocrService = OCRService()
    private let classifier = GifticonClassifier()
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
                guard classifier.classify(text: result.text, barcodeValues: result.barcodeValues).isLikelyGifticon,
                      let parsed = parser.parse(text: result.text, barcodeValues: result.barcodeValues) else { continue }
                _ = try persistenceService.save(parsed: parsed, assetLocalIdentifier: "shared:\(file.lastPathComponent)")
                savedCount += 1
                try SharedImageInbox.remove(file)
            } catch {
                // Keep unreadable files for a later retry instead of discarding user data.
            }
        }
        if savedCount > 0 { NotificationService.postScanCompleted(count: savedCount) }
    }
}
