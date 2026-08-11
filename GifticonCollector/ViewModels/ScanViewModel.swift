import Photos
import SwiftData
import SwiftUI

@MainActor
final class ScanViewModel: ObservableObject {
    @Published private(set) var isScanning = false
    @Published private(set) var processedCount = 0
    @Published private(set) var totalCount = 0
    @Published var errorMessage: String?

    private let photoLibraryService: PhotoLibraryService
    private let ocrService = OCRService()
    private let classifier = GifticonClassifier()
    private let parser = GifticonParser()
    private let persistenceService: PersistenceService

    init(photoLibraryService: PhotoLibraryService, modelContext: ModelContext) {
        self.photoLibraryService = photoLibraryService
        persistenceService = PersistenceService(modelContext: modelContext)
    }

    func scanAll() async {
        guard !isScanning else { return }
        isScanning = true
        errorMessage = nil
        processedCount = 0
        let assets = photoLibraryService.fetchImageAssets()
        totalCount = assets.count

        for index in 0..<assets.count {
            if Task.isCancelled { break }
            let asset = assets.object(at: index)
            do {
                let image = try await photoLibraryService.loadCGImage(for: asset)
                let result = try await ocrService.recognize(from: image)
                if classifier.classify(text: result.text, barcodeValues: result.barcodeValues).isLikelyGifticon,
                   let parsed = parser.parse(text: result.text, barcodeValues: result.barcodeValues) {
                    _ = try persistenceService.save(parsed: parsed, assetLocalIdentifier: asset.localIdentifier)
                }
            } catch {
                // One unreadable asset should not abort a full-library scan.
                errorMessage = "일부 사진을 처리하지 못했습니다."
            }
            processedCount = index + 1
        }
        isScanning = false
    }
}
