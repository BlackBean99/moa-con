import Photos

/// Performs a cheap barcode-only pass before the expensive OCR pass.
@MainActor
final class BarcodeCandidateService {
    private let photoLibraryService: PhotoLibraryService
    private let ocrService = OCRService()

    init(photoLibraryService: PhotoLibraryService) {
        self.photoLibraryService = photoLibraryService
    }

    func findCandidates(in assets: PHFetchResult<PHAsset>, progress: (Int) -> Void) async -> [BarcodeCandidate] {
        var candidates: [BarcodeCandidate] = []
        candidates.reserveCapacity(min(assets.count, 100))

        for index in 0..<assets.count {
            if Task.isCancelled { break }
            let asset = assets.object(at: index)
            do {
                let thumbnail = try await photoLibraryService.loadCGImage(
                    for: asset,
                    targetSize: CGSize(width: 640, height: 640)
                )
                let barcodes = try await ocrService.detectBarcodes(from: thumbnail)
                    .map(GifticonParser.normalizeBarcode)
                    .filter { !$0.isEmpty }
                if !barcodes.isEmpty {
                    candidates.append(BarcodeCandidate(asset: asset, barcodeValues: barcodes))
                }
            } catch {
                // An unreadable photo is excluded from the OCR candidate set.
            }
            progress(index + 1)
        }
        return candidates
    }
}

struct BarcodeCandidate {
    let asset: PHAsset
    let barcodeValues: [String]
}
