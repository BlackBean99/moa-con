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
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("사진 접근이 제한되어 있어요")
                .font(.title2.bold())
            Text("사진을 전체 공개하지 않아도 한 장씩 선택해 기프트콘을 등록할 수 있습니다.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("사진 한 장 선택", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
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

            let result = try await ocrService.recognize(from: cgImage)
            guard let parsed = parser.parse(text: result.text, barcodeValues: result.barcodeValues) else {
                message = "기프트콘으로 인식할 수 있는 정보를 찾지 못했습니다."
                return
            }

            let persistenceService = PersistenceService(modelContext: modelContext)
            _ = try persistenceService.save(
                parsed: parsed,
                assetLocalIdentifier: "manual-\(UUID().uuidString)"
            )
            message = "기프트콘을 등록했습니다."
        } catch {
            message = "사진 인식에 실패했습니다. 다시 시도해 주세요."
        }
    }
}
