import Photos
import UIKit
import SwiftData

@MainActor
final class PhotoLibraryService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: PHAuthorizationStatus
    @Published private(set) var lastChangeDate: Date?

    private let imageManager = PHCachingImageManager()

    override init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestReadWriteAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status
    }

    func presentLimitedLibraryPicker(from viewController: UIViewController) {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
    }

    func fetchImageAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .image, options: options)
    }

    func loadCGImage(for asset: PHAsset, targetSize: CGSize = CGSize(width: 2_048, height: 2_048)) async throws -> CGImage {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            options.resizeMode = .fast

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                } else if let image, let cgImage = image.cgImage {
                    continuation.resume(returning: cgImage)
                } else if (info?[PHImageCancelledKey] as? Bool) == true {
                    continuation.resume(throwing: CancellationError())
                } else {
                    continuation.resume(throwing: PhotoLibraryError.imageUnavailable)
                }
            }
        }
    }

    func loadOriginalData(for asset: PHAsset) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }
                if let error = info?[PHImageErrorKey] as? Error { continuation.resume(throwing: error) }
                else if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: PhotoLibraryError.imageUnavailable) }
            }
        }
    }

    func preserveAccessibleOriginals(in context: ModelContext) async {
        guard [.authorized, .limited].contains(authorizationStatus) else { return }
        guard let items = try? context.fetch(FetchDescriptor<Gifticon>()) else { return }
        for item in items where !item.assetLocalIdentifier.hasPrefix("shared:") {
            if Task.isCancelled { return }
            let source = item.assetLocalIdentifier
            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [source], options: nil).firstObject else { continue }
            var copiedFilename: String?
            do {
                let data = try await loadOriginalData(for: asset)
                try SharedImageInbox.validateImage(data)
                let filename = try SharedImageInbox.enqueue(imageData: data)
                copiedFilename = filename
                try SharedImageInbox.archive(SharedImageInbox.url(for: filename)!)
                // A concurrent refresh may have already preserved this original.
                guard item.assetLocalIdentifier == source else {
                    try SharedImageInbox.remove(SharedImageInbox.url(for: filename)!); continue
                }
                item.sourcePhotoIdentifier = source
                item.assetLocalIdentifier = "shared:\(filename)"
                try context.save()
            } catch {
                context.rollback()
                if let filename = copiedFilename, let url = SharedImageInbox.url(for: filename) { try? SharedImageInbox.remove(url) }
            }
        }
    }

    func loadUIImage(for asset: PHAsset, targetSize: CGSize) async throws -> UIImage {
        UIImage(cgImage: try await loadCGImage(for: asset, targetSize: targetSize))
    }

    func loadSharedUIImage(filename: String) throws -> UIImage {
        guard let url = SharedImageInbox.url(for: filename), let image = UIImage(contentsOfFile: url.path) else {
            throw PhotoLibraryError.imageUnavailable
        }
        return image
    }
}

extension PhotoLibraryService: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [weak self] in
            self?.lastChangeDate = .now
        }
    }
}

enum PhotoLibraryError: LocalizedError {
    case imageUnavailable

    var errorDescription: String? {
        switch self {
        case .imageUnavailable: "사진 이미지를 불러올 수 없습니다."
        }
    }
}
