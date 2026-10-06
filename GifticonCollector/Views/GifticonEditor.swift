import SwiftUI
import SwiftData

struct GifticonEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let gifticon: Gifticon
    @State private var brand: String
    @State private var title: String
    @State private var barcode: String
    @State private var hasExpiry: Bool
    @State private var expiry: Date
    @State private var needsReview: Bool
    @State private var error: String?

    init(gifticon: Gifticon) {
        self.gifticon = gifticon
        _brand = State(initialValue: gifticon.brand)
        _title = State(initialValue: gifticon.title)
        _barcode = State(initialValue: gifticon.barcodeNumber ?? "")
        _hasExpiry = State(initialValue: gifticon.expiryDate != nil)
        _expiry = State(initialValue: gifticon.expiryDate ?? .now)
        _needsReview = State(initialValue: gifticon.needsReview)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("원본과 비교해 주세요") {
                    TextField("브랜드", text: $brand)
                    TextField("상품명", text: $title)
                    TextField("바코드 번호", text: $barcode).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Toggle("유효기간 있음", isOn: $hasExpiry)
                    if hasExpiry { DatePicker("유효기간", selection: $expiry, displayedComponents: .date) }
                }
                Section {
                    Toggle("확인 필요에 보관", isOn: $needsReview)
                    if gifticon.needsReview {
                        Button("기프티콘으로 확인하고 저장") { save(needsReview: false) }
                    }
                    Text("기프티콘이 맞으면 이 설정을 꺼주세요. 일반 바코드는 확인 필요에 남기거나 삭제할 수 있어요.").font(.footnote)
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
            }
            .navigationTitle("쿠폰 정보 수정").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        save(needsReview: needsReview)
                    }
                }
            }
        }
    }
    private func save(needsReview: Bool) {
        do {
            try PersistenceService(modelContext: modelContext).update(gifticon, brand: brand, title: title, barcode: barcode, expiryDate: hasExpiry ? expiry : nil, needsReview: needsReview)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }

}

