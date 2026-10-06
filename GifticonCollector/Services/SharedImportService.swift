import SwiftData
import UIKit

struct SharedImportSummary {
    var saved = 0
    var duplicates = 0
    var failed = 0
    var storageError: String?
    var message: String? {
        if let storageError { return storageError }
        guard saved + duplicates + failed > 0 else { return nil }
        return "가져오기 · 추가 \(saved)개 · 중복 \(duplicates)개 · 확인 필요 \(failed)개"
    }
}

@MainActor
final class SharedImportService {
    // Root task and scene activation can overlap; serialize the shared filesystem queue.
    private static var processing = false
    private let ocrService = OCRService()
    private let parser = GifticonParser()
    private let persistenceService: PersistenceService

    init(modelContext: ModelContext) { persistenceService = PersistenceService(modelContext: modelContext) }

    @discardableResult
    func processPending() async -> SharedImportSummary {
        guard !Self.processing else { return SharedImportSummary() }
        Self.processing = true
        defer { Self.processing = false }
        var summary = SharedImportSummary()
        let files: [URL]
        do {
            // Fetch must succeed before any archive can be considered unreferenced.
            let referenced = try persistenceService.referencedOriginalFilenames()
            summary.failed += try SharedImageInbox.recoverUnreferencedArchives(referenced: referenced)
            files = try SharedImageInbox.pendingFiles()
        }
        catch { summary.storageError = "가져오기 대기 목록을 열지 못했어요."; return summary }
        for file in files {
            if Task.isCancelled { break }
            do {
                let data = try Data(contentsOf: file, options: .mappedIfSafe)
                try SharedImageInbox.validateImage(data)
                guard let image = UIImage(data: data), let cgImage = image.cgImage else { throw SharedImageInbox.InboxError.invalidImage }
                let result = try await ocrService.recognize(from: cgImage)
                guard let parsed = parser.parse(text: result.text, barcodeValues: result.barcodeValues) else {
                    try SharedImageInbox.markFailed(file, message: "바코드를 찾지 못했어요. 직접 입력할 수 있습니다.")
                    summary.failed += 1
                    continue
                }
                if let barcode = parsed.barcodeNumber, try persistenceService.contains(barcode: barcode) {
                    try SharedImageInbox.remove(file)
                    summary.duplicates += 1
                    continue
                }
                // File commit precedes the DB reference. Roll back to a recoverable queue on DB failure.
                try SharedImageInbox.archive(file)
                _ = try persistenceService.save(parsed: parsed, assetLocalIdentifier: "shared:\(file.lastPathComponent)")
                summary.saved += 1
            } catch {
                if let source = SharedImageInbox.url(for: file.lastPathComponent) {
                    do { try SharedImageInbox.markFailed(source, message: "사진을 가져오지 못했어요. 재시도하거나 직접 입력해 주세요.") }
                    catch { summary.storageError = "가져오기 상태를 저장하지 못했어요. 원본 파일은 보존됩니다. 저장 공간을 확보한 뒤 다시 시도해 주세요." }
                }
                summary.failed += 1
            }
        }
        if summary.saved > 0 { NotificationService.postScanCompleted(count: summary.saved) }
        return summary
    }
}
