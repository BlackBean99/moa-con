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
    @State private var draft: CouponImportDraft?

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
        .sheet(item: $draft) { source in
            CouponImportEditor(source: source) { message = "보관함에 추가했어요." }
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--import-draft-testing") {
                let image = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 500)).image { ctx in
                    UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 500))
                    ("테스트 원본 · 사용 불가" as NSString).draw(at: CGPoint(x: 20, y: 40), withAttributes: [.font: UIFont.systemFont(ofSize: 20)])
                }
                let multiple = ProcessInfo.processInfo.arguments.contains("--multiple-code-testing")
                draft = CouponImportDraft(data: image.jpegData(compressionQuality: 0.9)!,
                    parsed: multiple ? parser.parse(text: "스타벅스\n테스트 교환권", barcodeValues: ["CANDIDATE-A", "CANDIDATE-B"]) : nil)
            }
            #endif
        }
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

            let parsed: ParsedGifticon?
            do {
                let barcodes = try await ocrService.detectBarcodes(from: cgImage)
                let text = try await ocrService.recognizeText(from: cgImage)
                parsed = parser.parse(text: text, barcodeValues: barcodes)
            } catch { parsed = nil }
            draft = CouponImportDraft(data: data, parsed: parsed)

        } catch {
            message = "사진을 추가하지 못했어요. 다시 시도해 주세요."
        }
    }
}
