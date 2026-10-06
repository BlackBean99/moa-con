import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ManualImportView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var photoLibraryService: PhotoLibraryService
    @State private var selectedItem: PhotosPickerItem?
    @State private var isImporting = false
    @State private var message: String?

    private let ocrService = OCRService()
    private let parser = GifticonParser()

    var body: some View {
        VStack(spacing: 20) {
            ClayIcon(systemName: "photo.badge.exclamationmark", color: ClayTheme.butter, size: 74)
            Text("사진으로 쿠폰 추가")
                .font(.title2.bold())
                .foregroundStyle(ClayTheme.ink)
            Text("한 장을 선택하면 이 기기에서 인식해요. 확실하지 않은 바코드는 확인 필요에 보관합니다.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("사진 한 장 선택", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ClayPrimaryButtonStyle(color: ClayTheme.coral))
            .disabled(isImporting)
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task { await importSinglePhoto(newItem) }
            }
            if isImporting {
                ProgressView("사진 인식 중…")
            }
            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if photoLibraryService.authorizationStatus == .denied {
                Text("자동 스캔을 사용하려면 설정에서 사진 접근 권한을 변경할 수 있습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .background(ClayTheme.canvas.ignoresSafeArea())
    }

    private func importSinglePhoto(_ item: PhotosPickerItem) async {
        isImporting = true
        message = nil
        defer {
            isImporting = false
            selectedItem = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let cgImage = image.cgImage else {
                message = "선택한 사진을 읽을 수 없습니다."
                return
            }

            let barcodes = try await ocrService.detectBarcodes(from: cgImage)
            guard !barcodes.isEmpty else {
                message = "바코드가 있는 기프트콘 사진만 등록할 수 있습니다."
                return
            }
            let text = try await ocrService.recognizeText(from: cgImage)
            guard let parsed = parser.parse(text: text, barcodeValues: barcodes) else {
                message = "기프트콘으로 인식할 수 있는 정보를 찾지 못했습니다."
                return
            }

            let persistenceService = PersistenceService(modelContext: modelContext)
            let filename = try SharedImageInbox.enqueue(imageData: data)
            guard let storedURL = SharedImageInbox.url(for: filename) else { throw SharedImageInbox.InboxError.unavailable }
            try SharedImageInbox.archive(storedURL)
            _ = try persistenceService.save(
                parsed: parsed,
                assetLocalIdentifier: "shared:\(filename)"
            )
            message = parsed.needsReview ? "확인 필요에 보관했어요. 보관함에서 원본을 확인해 주세요." : "보관함에 추가했어요. 같은 바코드는 중복 저장하지 않습니다."
        } catch {
            message = "사진 인식에 실패했습니다. 다시 시도해 주세요."
        }
    }
}
