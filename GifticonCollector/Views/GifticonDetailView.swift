import SwiftData
import SwiftUI
import Photos
import UIKit

struct GifticonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let gifticon: Gifticon
    let photoLibraryService: PhotoLibraryService
    @State private var expandedImage: UIImage?
    @State private var showEditor = false
    @State private var showDeleteConfirmation = false
    @State private var initialAmountText = ""
    @State private var deductionText = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                GifticonHeroImage(gifticon: gifticon, photoLibraryService: photoLibraryService) { expandedImage = $0 }
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .accessibilityIdentifier("coupon.original")
            }
            if gifticon.needsReview {
                Section {
                    Label("쿠폰 확인", systemImage: "questionmark.circle")
                    Button("정보 확인") { showEditor = true }
                }
            }
            Section {
                Button(gifticon.isUsed ? "사용 취소" : "사용 완료") {
                    do {
                        try PersistenceService(modelContext: modelContext).toggleUsed(gifticon)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .disabled(gifticon.needsReview)
            }

            Section("쿠폰 정보") {
                infoRow("브랜드", gifticon.brand)
                infoRow("상품", gifticon.title)
                infoRow("바코드", gifticon.barcodeNumber ?? "-")
                if let expiryDate = gifticon.expiryDate {
                    infoRow("유효기간", expiryDate.formatted(date: .numeric, time: .omitted))
                }
            }

            if !gifticon.needsReview {
                Section("금액") {
                    if let remainingAmount = gifticon.remainingAmount {
                        infoRow("남은 금액", formatAmount(remainingAmount))
                        if let originalAmount = gifticon.originalAmount {
                            infoRow("처음 금액", formatAmount(originalAmount))
                        }
                        Button(gifticon.allowsPartialRedemption ? "부분 차감 끄기" : "부분 차감 허용") {
                            updatePartialRedemption(!gifticon.allowsPartialRedemption)
                        }
                        if gifticon.allowsPartialRedemption && !gifticon.isUsed {
                            HStack {
                                TextField("차감할 금액", text: $deductionText)
                                    .keyboardType(.decimalPad)
                                Button("차감") { deduct() }
                                    .buttonStyle(MoaconPrimaryButtonStyle())
                            }
                        }
                    } else {
                        HStack {
                            TextField("처음 금액", text: $initialAmountText)
                                .keyboardType(.decimalPad)
                            Button("저장") { setInitialAmount() }
                                .buttonStyle(MoaconPrimaryButtonStyle())
                        }
                    }
                }
            }

            Section {
                Button("보관함에서 삭제", role: .destructive) { showDeleteConfirmation = true }
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(MoaconTheme.canvas)
        .tint(MoaconTheme.accent)
        .navigationTitle(gifticon.brand)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("수정") { showEditor = true } } }
        .sheet(isPresented: $showEditor) { GifticonEditor(gifticon: gifticon) }
        .fullScreenCover(isPresented: Binding(get: { expandedImage != nil }, set: { if !$0 { expandedImage = nil } })) {
            NavigationStack {
                ZoomableCouponImage(image: expandedImage).background(.white)
                    .navigationTitle("원본").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { expandedImage = nil } } }
            }
        }
        .alert("보관함에서 삭제할까요?", isPresented: $showDeleteConfirmation) {
            Button("삭제", role: .destructive) {
                do { try PersistenceService(modelContext: modelContext).delete(gifticon); dismiss() }
                catch { errorMessage = "삭제하지 못했어요. 다시 시도해 주세요." }
            }
            Button("취소", role: .cancel) {}
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).multilineTextAlignment(.trailing).textSelection(.enabled)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        "\(amount.formatted(.number.precision(.fractionLength(0))))원"
    }

    private func updatePartialRedemption(_ enabled: Bool) {
        do {
            try PersistenceService(modelContext: modelContext).setPartialRedemption(enabled, for: gifticon)
            errorMessage = nil
        } catch {
            errorMessage = "차감 설정을 저장하지 못했습니다."
        }
    }

    private func setInitialAmount() {
        guard let amount = Double(initialAmountText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)), amount > 0 else {
            errorMessage = "처음 금액을 숫자로 입력해 주세요."
            return
        }
        do {
            try PersistenceService(modelContext: modelContext).setInitialAmount(amount, for: gifticon)
            initialAmountText = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deduct() {
        guard let amount = Double(deductionText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)), amount > 0 else {
            errorMessage = "차감 금액을 숫자로 입력해 주세요."
            return
        }
        do {
            try PersistenceService(modelContext: modelContext).deduct(amount, from: gifticon)
            deductionText = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct GifticonHeroImage: View {
    let gifticon: Gifticon
    let photoLibraryService: PhotoLibraryService
    @State private var image: UIImage?
    let onExpand: (UIImage) -> Void
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let image {
                Button { onExpand(image) } label: {
                    VStack(spacing: 8) {
                        Image(uiImage: image).resizable().scaledToFit()
                        Label("원본 크게 보기", systemImage: "arrow.up.left.and.arrow.down.right").font(.caption)
                    }
                }.buttonStyle(.plain)
            } else {
                ContentUnavailableView(loadFailed ? "원본 없음" : "불러오는 중", systemImage: "photo", description: Text(loadFailed ? "사진 권한 또는 원본을 확인해 주세요." : ""))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 260)
        .background(MoaconTheme.surface)
        .task {
            if gifticon.assetLocalIdentifier.hasPrefix("shared:") {
                image = try? photoLibraryService.loadSharedUIImage(filename: String(gifticon.assetLocalIdentifier.dropFirst("shared:".count)))
                loadFailed = image == nil
                return
            }
            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [gifticon.assetLocalIdentifier], options: nil).firstObject else { loadFailed = true; return }
            image = try? await photoLibraryService.loadUIImage(for: asset, targetSize: CGSize(width: 2_048, height: 2_048))
            loadFailed = image == nil
        }
        .accessibilityLabel("원본 크게 보기")
        .accessibilityHint("\(gifticon.brand) 기프티콘 원본 사진을 확대합니다")

    }
}
