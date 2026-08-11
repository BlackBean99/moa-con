import Photos
import SwiftData
import SwiftUI

@MainActor
final class ScanViewModel: ObservableObject {
    @Published private(set) var isScanning = false
    @Published private(set) var processedCount = 0
    @Published private(set) var totalCount = 0
    @Published private(set) var candidateCount = 0
    @Published var errorMessage: String?

    private let photoLibraryService: PhotoLibraryService
    private let ocrService = OCRService()
    private let classifier = GifticonClassifier()
    private let parser = GifticonParser()
    private let persistenceService: PersistenceService
    private let candidateService: BarcodeCandidateService

    init(photoLibraryService: PhotoLibraryService, modelContext: ModelContext) {
        self.photoLibraryService = photoLibraryService
        persistenceService = PersistenceService(modelContext: modelContext)
        candidateService = BarcodeCandidateService(photoLibraryService: photoLibraryService)
    }

    func scanAll() async {
        guard !isScanning else { return }
        isScanning = true
        errorMessage = nil
        processedCount = 0
        let assets = photoLibraryService.fetchImageAssets()
        totalCount = assets.count

        let candidates = await candidateService.findCandidates(in: assets) { [weak self] processed in
            self?.processedCount = processed
        }
        candidateCount = candidates.count
        processedCount = 0
        totalCount = candidates.count

        var savedCount = 0
        for index in 0..<candidates.count {
            if Task.isCancelled { break }
            let candidate = candidates[index]
            let asset = candidate.asset
            do {
                let image = try await photoLibraryService.loadCGImage(for: asset)
                let text = try await ocrService.recognizeText(from: image)
                if classifier.classify(text: text, barcodeValues: candidate.barcodeValues).isLikelyGifticon,
                   let parsed = parser.parse(text: text, barcodeValues: candidate.barcodeValues) {
                    let saved = try persistenceService.save(parsed: parsed, assetLocalIdentifier: asset.localIdentifier)
                    if saved.createdAt.timeIntervalSinceNow > -2 { savedCount += 1 }
                }
            } catch {
                // One unreadable asset should not abort a full-library scan.
                errorMessage = "일부 사진을 처리하지 못했습니다."
            }
            processedCount = index + 1
        }
        isScanning = false
        NotificationService.postScanCompleted(count: savedCount)
    }
}
