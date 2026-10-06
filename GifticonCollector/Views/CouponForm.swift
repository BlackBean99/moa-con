import SwiftUI
import SwiftData
import UIKit

struct CouponDraft {
    var brand = ""
    var title = ""
    var barcode = ""
    var candidates: [String] = []
    var kind = CouponKind.exchange
    var hasExpiry = false
    var expiry = Date.now
    var faceValue = ""
    var balance = ""
    var price = ""
    var discount = ""

    init(parsed: ParsedGifticon? = nil) {
        guard let parsed else { return }
        brand = parsed.brand == "브랜드 확인 필요" ? "" : parsed.brand
        title = parsed.title == "상품명 미상" ? "" : parsed.title
        barcode = parsed.barcodeNumber ?? ""
        candidates = parsed.barcodeCandidates
        kind = parsed.couponKind
        hasExpiry = parsed.expiryDate != nil
        expiry = parsed.expiryDate ?? .now
        faceValue = Self.text(parsed.amount)
        balance = Self.text(parsed.remainingAmount ?? parsed.amount)
        price = Self.text(parsed.productPrice)
        discount = Self.text(parsed.discountAmount)
    }

    static func text(_ value: Double?) -> String { value.map { String(format: "%.0f", $0) } ?? "" }
    static func number(_ value: String) throws -> Double? {
        let clean = value.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        guard let amount = Double(clean), amount.isFinite, amount >= 0 else { throw PersistenceError.invalidDeduction }
        return amount
    }

    func parsed(needsReview: Bool) throws -> ParsedGifticon {
        let cleanBarcode = GifticonParser.normalizeBarcode(barcode)
        guard !brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !cleanBarcode.isEmpty else {
            throw PersistenceError.incompleteInformation
        }
        let original = kind == .storedValue ? try Self.number(faceValue) : nil
        let remaining = kind == .storedValue ? try Self.number(balance) ?? original : nil
        guard original == nil || original! > 0,
              remaining == nil || (original != nil && remaining! <= original!) else { throw PersistenceError.insufficientBalance }
        return ParsedGifticon(brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines), barcodeNumber: cleanBarcode,
            expiryDate: hasExpiry ? expiry : nil, amount: original, confidence: 1,
            needsReview: needsReview, barcodeCandidates: candidates, couponKind: kind,
            remainingAmount: remaining, productPrice: try Self.number(price), discountAmount: try Self.number(discount))
    }
}

struct CouponFields: View {
    @Binding var draft: CouponDraft
    @State private var selectedCandidate = ""

    var body: some View {
        Section("쿠폰 정보") {
            TextField("브랜드", text: $draft.brand)
            TextField("상품명", text: $draft.title)
            if draft.candidates.count > 1 {
                Picker("쿠폰 번호 선택", selection: $selectedCandidate) {
                    Text("직접 입력").tag("")
                    ForEach(draft.candidates, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.inline)
                .onChange(of: selectedCandidate) { _, value in if !value.isEmpty { draft.barcode = value } }
            }
            TextField("바코드 번호", text: $draft.barcode)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .onChange(of: draft.barcode) { _, value in
                    if selectedCandidate != value { selectedCandidate = "" }
                }
            Toggle("유효기간 있음", isOn: $draft.hasExpiry)
            if draft.hasExpiry { DatePicker("유효기간", selection: $draft.expiry, displayedComponents: .date) }
        }
        Section("쿠폰 종류") {
            Picker("종류", selection: $draft.kind) {
                ForEach(CouponKind.allCases, id: \.self) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented)
            if draft.kind == .storedValue {
                TextField("권면금액", text: $draft.faceValue).keyboardType(.decimalPad)
                TextField("현재 잔액", text: $draft.balance).keyboardType(.decimalPad)
            }
        }
        Section("가격 정보") {
            TextField("상품 가격", text: $draft.price).keyboardType(.decimalPad)
            TextField("할인 금액", text: $draft.discount).keyboardType(.decimalPad)
        }
    }
}

struct CouponImportDraft: Identifiable {
    let id = UUID()
    let data: Data
    var parsed: ParsedGifticon?
    var sourceFilename: String? = nil
}

struct CouponImportEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let source: CouponImportDraft
    var onSaved: () -> Void = {}
    @State private var draft: CouponDraft
    @State private var needsReview = false
    @State private var error: String?

    init(source: CouponImportDraft, onSaved: @escaping () -> Void = {}) {
        self.source = source
        self.onSaved = onSaved
        _draft = State(initialValue: CouponDraft(parsed: source.parsed))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let image = UIImage(data: source.data) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 260)
                            .accessibilityLabel("등록할 쿠폰 원본")
                    }
                    if source.parsed == nil { Text("인식하지 못한 정보는 직접 입력해 주세요.").foregroundStyle(.secondary) }
                }
                CouponFields(draft: $draft)
                Section { Toggle("확인 필요에 보관", isOn: $needsReview) }
            }
            .tint(MoaconTheme.accent)
            .navigationTitle("쿠폰 등록").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("보관") { save() }.accessibilityIdentifier("import.save")
                }
            }
        }
        .alert("등록하지 못했어요", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("확인", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }

    private func save() {
        var createdFilename: String?
        do {
            let parsed = try draft.parsed(needsReview: needsReview)
            let service = PersistenceService(modelContext: context)
            guard !(try service.contains(barcode: parsed.barcodeNumber!)) else { throw PersistenceError.duplicateBarcode }
            let filename: String
            if let existing = source.sourceFilename { filename = existing }
            else { filename = try SharedImageInbox.enqueue(imageData: source.data); createdFilename = filename }
            guard let url = SharedImageInbox.url(for: filename) else { throw SharedImageInbox.InboxError.unavailable }
            try SharedImageInbox.archive(url)
            _ = try service.save(parsed: parsed, assetLocalIdentifier: "shared:\(filename)")
            onSaved()
            dismiss()
        } catch {
            if let filename = createdFilename, let url = SharedImageInbox.url(for: filename) { try? SharedImageInbox.remove(url) }
            if createdFilename == nil, let filename = source.sourceFilename, let url = SharedImageInbox.url(for: filename) {
                try? SharedImageInbox.markFailed(url, message: "등록하지 못했어요. 다시 입력해 주세요.")
            }
            self.error = error.localizedDescription
        }
    }
}
