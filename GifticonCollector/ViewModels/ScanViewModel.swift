import Photos
import SwiftData
import SwiftUI

@MainActor
final class ScanViewModel: ObservableObject {
    @Published private(set) var isScanning = false
    @Published private(set) var processedCount = 0
    @Published private(set) var totalCount = 0
    @Published private(set) var candidateCount = 0
    @Published private(set) var resultMessage: String?
    @Published private(set) var phaseTitle = "바코드 찾는 중"
    @Published var errorMessage: String?

    private let photoLibraryService: PhotoLibraryService
    private let ocrService = OCRService()
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
        guard [.authorized, .limited].contains(photoLibraryService.authorizationStatus) else { return }
        isScanning = true
        defer { isScanning = false }
        errorMessage = nil
        resultMessage = nil
        phaseTitle = "바코드 찾는 중"
        processedCount = 0
        let assets = photoLibraryService.fetchImageAssets()
        totalCount = assets.count

        let candidates = await candidateService.findCandidates(in: assets) { [weak self] processed in
            self?.processedCount = processed
        }
        phaseTitle = "쿠폰 확인 중"
        candidateCount = candidates.count
        processedCount = 0
        totalCount = candidates.count

        var savedCount = 0
        var reviewCount = 0
        var duplicateCount = 0
        for index in 0..<candidates.count {
            if Task.isCancelled { break }
            let candidate = candidates[index]
            let asset = candidate.asset
            do {
                let image = try await photoLibraryService.loadCGImage(for: asset)
                let text = try await ocrService.recognizeText(from: image)
                if let parsed = parser.parse(text: text, barcodeValues: candidate.barcodeValues) {
                    if persistenceService.isIgnoredByAutomaticScan(parsed.barcodeNumber ?? "") { processedCount = index + 1; continue }
                    let existing = try persistenceService.contains(barcode: parsed.barcodeNumber ?? "")
                    _ = try persistenceService.save(parsed: parsed, assetLocalIdentifier: asset.localIdentifier)
                    if existing { duplicateCount += 1 }
                    else if parsed.needsReview { reviewCount += 1 }
                    else { savedCount += 1 }
                }
            } catch {
                // One unreadable asset should not abort a full-library scan.
                errorMessage = "일부 사진을 처리하지 못했습니다."
            }
            processedCount = index + 1
        }
        resultMessage = (Task.isCancelled ? "검색 중단 · " : "검색 완료 · ") + "쿠폰 \(savedCount)개 추가 · 확인 필요 \(reviewCount)개 · 중복 \(duplicateCount)개"
    }
}
