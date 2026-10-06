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
        ScrollView {
            VStack(spacing: MoaconTheme.Space.large) {
                Image(systemName: "photo.on.rectangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("사진 한 장 선택", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(MoaconPrimaryButtonStyle())
                .disabled(isImporting)
                .onChange(of: selectedItem) { _, newItem in
                    guard let newItem else { return }
                    Task { await importSinglePhoto(newItem) }
                }
                if isImporting { ProgressView("인식 중") }
                if let message {
                    Text(message).font(.subheadline).multilineTextAlignment(.center)
                        .accessibilityIdentifier("import.result")
                }
            }
            .frame(maxWidth: 440)
            .padding(MoaconTheme.Space.page)
            .frame(maxWidth: .infinity)
        }
        .background(MoaconTheme.canvas)
        .navigationTitle("사진 추가")
        .navigationBarTitleDisplayMode(.inline)
        .tint(MoaconTheme.accent)
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
                message = "바코드를 찾지 못했어요."
                return
            }
            let text = try await ocrService.recognizeText(from: cgImage)
            guard let parsed = parser.parse(text: text, barcodeValues: barcodes) else {
                message = "쿠폰 정보를 찾지 못했어요."
                return
            }

            let persistenceService = PersistenceService(modelContext: modelContext)
            if try persistenceService.contains(barcode: parsed.barcodeNumber ?? "") {
                message = "이미 보관한 쿠폰입니다."
                return
            }
            let filename = try SharedImageInbox.enqueue(imageData: data)
            guard let storedURL = SharedImageInbox.url(for: filename) else { throw SharedImageInbox.InboxError.unavailable }
            try SharedImageInbox.archive(storedURL)
            _ = try persistenceService.save(
                parsed: parsed,
                assetLocalIdentifier: "shared:\(filename)"
            )
            message = parsed.needsReview ? "확인 필요에 추가했어요." : "보관함에 추가했어요."
        } catch {
            message = "사진을 추가하지 못했어요. 다시 시도해 주세요."
        }
    }
}
