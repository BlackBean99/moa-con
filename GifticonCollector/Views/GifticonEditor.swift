import SwiftUI
import SwiftData
import UIKit

struct GifticonEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let gifticon: Gifticon
    @State private var draft: CouponDraft
    @State private var needsReview: Bool
    @State private var error: String?

    init(gifticon: Gifticon) {
        self.gifticon = gifticon
        _draft = State(initialValue: CouponDraft(parsed: ParsedGifticon(brand: gifticon.brand,
            title: gifticon.title, barcodeNumber: gifticon.barcodeNumber, expiryDate: gifticon.expiryDate,
            amount: gifticon.originalAmount, confidence: 1, barcodeCandidates: gifticon.barcodeCandidates,
            couponKind: gifticon.couponKind, remainingAmount: gifticon.remainingAmount,
            productPrice: gifticon.productPrice, discountAmount: gifticon.discountAmount)))
        _needsReview = State(initialValue: gifticon.needsReview)
    }

    var body: some View {
        NavigationStack {
            Form {
                if gifticon.assetLocalIdentifier.hasPrefix("shared:"),
                   let url = SharedImageInbox.url(for: String(gifticon.assetLocalIdentifier.dropFirst(7))),
                   let image = UIImage(contentsOfFile: url.path) {
                    Section { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 200).accessibilityLabel("쿠폰 원본") }
                }
                CouponFields(draft: $draft)
                Section {
                    Toggle("확인 필요에 보관", isOn: $needsReview)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if gifticon.needsReview {
                    Button("쿠폰으로 보관") { save(needsReview: false) }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(MoaconPrimaryButtonStyle())
                        .padding().background(MoaconTheme.canvas)
                }
            }
            .tint(MoaconTheme.accent)
            .navigationTitle("정보 수정").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("저장") { save(needsReview: needsReview) } }
            }
        }
        .alert("저장하지 못했어요", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("확인", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }

    private func save(needsReview: Bool) {
        do {
            try PersistenceService(modelContext: modelContext).update(gifticon, from: draft.parsed(needsReview: needsReview))
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
