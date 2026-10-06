import Foundation
import SwiftData

@MainActor
final class PersistenceService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func saveChanges() throws {
        do { try modelContext.save(); NotificationCenter.default.post(name: .couponStoreDidChange, object: nil) } catch { modelContext.rollback(); throw error }
    }

    func contains(barcode: String) throws -> Bool {
        let descriptor = FetchDescriptor<Gifticon>(predicate: #Predicate { $0.barcodeNumber == barcode })
        return try !modelContext.fetch(descriptor).isEmpty
    }

    func referencedOriginalFilenames() throws -> Set<String> {
        Set(try modelContext.fetch(FetchDescriptor<Gifticon>()).compactMap { item in
            item.assetLocalIdentifier.hasPrefix("shared:") ? String(item.assetLocalIdentifier.dropFirst(7)) : nil
        })
    }

    func save(parsed: ParsedGifticon, assetLocalIdentifier: String, sourcePhotoIdentifier: String? = nil) throws -> Gifticon {
        if let sourcePhotoIdentifier, let existing = try item(forPhoto: sourcePhotoIdentifier) { return existing }
        let barcode = parsed.barcodeNumber
        guard barcode?.isEmpty == false || (parsed.needsReview && parsed.barcodeCandidates.count > 1) else {
            throw PersistenceError.barcodeRequired
        }
        let matches: [Gifticon]
        if let barcode {
            matches = try modelContext.fetch(FetchDescriptor<Gifticon>(predicate: #Predicate { $0.barcodeNumber == barcode }))
        } else {
            matches = try modelContext.fetch(FetchDescriptor<Gifticon>(predicate: #Predicate { $0.assetLocalIdentifier == assetLocalIdentifier }))
        }
        if let existing = matches.first { return existing }

        let gifticon = Gifticon(
            brand: parsed.brand,
            title: parsed.title,
            barcodeNumber: parsed.barcodeNumber,
            expiryDate: parsed.expiryDate,
            assetLocalIdentifier: assetLocalIdentifier,
            originalAmount: parsed.couponKind == .storedValue ? parsed.amount : nil,
            remainingAmount: parsed.couponKind == .storedValue ? (parsed.remainingAmount ?? parsed.amount) : nil,
            barcodeCandidates: parsed.barcodeCandidates,
            couponKind: parsed.couponKind,
            productPrice: parsed.productPrice,
            discountAmount: parsed.discountAmount
        )
        gifticon.sourcePhotoIdentifier = sourcePhotoIdentifier
        gifticon.needsReview = parsed.needsReview
        if parsed.couponKind == .storedValue && gifticon.remainingAmount == 0 { gifticon.isUsed = true }
        modelContext.insert(gifticon)
        try saveChanges()
        return gifticon
    }

    func item(forPhoto identifier: String) throws -> Gifticon? {
        try modelContext.fetch(FetchDescriptor<Gifticon>(predicate: #Predicate {
            $0.sourcePhotoIdentifier == identifier || $0.assetLocalIdentifier == identifier
        })).first
    }

    func saveWithOriginal(parsed: ParsedGifticon, imageData: Data, sourcePhotoIdentifier: String? = nil) throws -> Gifticon {
        try SharedImageInbox.validateImage(imageData)
        let filename = try SharedImageInbox.enqueue(imageData: imageData)
        do {
            let url = SharedImageInbox.url(for: filename)!
            try SharedImageInbox.archive(url)
            let item = try save(parsed: parsed, assetLocalIdentifier: "shared:\(filename)", sourcePhotoIdentifier: sourcePhotoIdentifier)
            if item.assetLocalIdentifier != "shared:\(filename)", let url = SharedImageInbox.url(for: filename) { try SharedImageInbox.remove(url) }
            return item
        } catch {
            if let url = SharedImageInbox.url(for: filename) { try? SharedImageInbox.remove(url) }
            throw error
        }
    }

    func migrateLegacyAmountReview() throws {
        var changed = false
        for item in try modelContext.fetch(FetchDescriptor<Gifticon>()) where item.couponKindRaw.isEmpty {
            if item.originalAmount != nil && !item.allowsPartialRedemption { item.needsReview = true }
            item.couponKindRaw = item.couponKind.rawValue
            changed = true
        }
        if changed { try saveChanges() }
    }

    func update(_ item: Gifticon, brand: String, title: String, barcode: String, expiryDate: Date?, needsReview: Bool) throws {
        let cleanBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBarcode = GifticonParser.normalizeBarcode(barcode)
        guard !cleanBrand.isEmpty, !cleanTitle.isEmpty, !cleanBarcode.isEmpty else { throw PersistenceError.incompleteInformation }
        let matches = try modelContext.fetch(FetchDescriptor<Gifticon>(predicate: #Predicate { $0.barcodeNumber == cleanBarcode }))
        guard !matches.contains(where: { $0.id != item.id }) else { throw PersistenceError.duplicateBarcode }
        item.brand = cleanBrand
        item.title = cleanTitle
        item.barcodeNumber = cleanBarcode
        item.expiryDate = expiryDate
        item.needsReview = needsReview
        try saveChanges()
    }

    func update(_ item: Gifticon, from parsed: ParsedGifticon) throws {
        // Once a balance has been spent, editing metadata must not reset the ledger.
        if let original = item.originalAmount, let remaining = item.remainingAmount,
           remaining < original || item.isUsed {
            guard parsed.couponKind == item.couponKind, parsed.amount == original,
                  parsed.remainingAmount == remaining else { throw PersistenceError.amountAlreadySet }
        }
        guard parsed.amount == nil || (parsed.amount!.isFinite && parsed.amount! > 0),
              parsed.remainingAmount == nil || (parsed.amount != nil && parsed.remainingAmount!.isFinite && parsed.remainingAmount! >= 0 && parsed.remainingAmount! <= parsed.amount!) else {
            throw PersistenceError.insufficientBalance
        }
        let barcode = GifticonParser.normalizeBarcode(parsed.barcodeNumber ?? "")
        guard !parsed.brand.isEmpty, !parsed.title.isEmpty, !barcode.isEmpty else { throw PersistenceError.incompleteInformation }
        let matches = try modelContext.fetch(FetchDescriptor<Gifticon>(predicate: #Predicate { $0.barcodeNumber == barcode }))
        guard !matches.contains(where: { $0.id != item.id }) else { throw PersistenceError.duplicateBarcode }
        item.brand = parsed.brand
        item.title = parsed.title
        item.barcodeNumber = barcode
        item.expiryDate = parsed.expiryDate
        item.needsReview = parsed.needsReview
        item.couponKind = parsed.couponKind
        item.originalAmount = parsed.couponKind == .storedValue ? parsed.amount : nil
        item.remainingAmount = parsed.couponKind == .storedValue ? parsed.remainingAmount : nil
        item.productPrice = parsed.productPrice
        item.discountAmount = parsed.discountAmount
        if parsed.couponKind == .exchange { item.allowsPartialRedemption = false }
        if parsed.couponKind == .storedValue && item.remainingAmount == 0 { item.isUsed = true }
        try saveChanges()
    }

    func toggleUsed(_ gifticon: Gifticon) throws {
        guard !gifticon.needsReview else { throw PersistenceError.reviewRequired }
        guard !(gifticon.isUsed && gifticon.remainingAmount == 0) else { throw PersistenceError.balanceExhausted }
        gifticon.isUsed.toggle()
        try saveChanges()
    }

    func delete(_ gifticon: Gifticon) throws {
        let barcode = gifticon.barcodeNumber
        let source = gifticon.assetLocalIdentifier
        let sourcePhotoIdentifier = gifticon.sourcePhotoIdentifier
        modelContext.delete(gifticon)
        try saveChanges()
        if source.hasPrefix("shared:") {
            let references = try modelContext.fetch(FetchDescriptor<Gifticon>(predicate: #Predicate { $0.assetLocalIdentifier == source }))
            if references.isEmpty, let url = SharedImageInbox.url(for: String(source.dropFirst("shared:".count))) {
                // Delete the imported copy only after the database commit; never remove a Photos original.
                try? SharedImageInbox.remove(url)
            }
        }
        if let source = sourcePhotoIdentifier ?? (source.hasPrefix("shared:") ? nil : source) {
            var ignored = Set(UserDefaults.standard.stringArray(forKey: "scan.ignoredPhotoIdentifiers") ?? [])
            ignored.insert(source)
            UserDefaults.standard.set(Array(ignored), forKey: "scan.ignoredPhotoIdentifiers")
        }
        if let barcode {
            var ignored = Set(UserDefaults.standard.stringArray(forKey: "scan.ignoredBarcodes") ?? [])
            ignored.insert(barcode)
            UserDefaults.standard.set(Array(ignored), forKey: "scan.ignoredBarcodes")
        }
    }

    func isSourcePhotoIgnored(_ identifier: String) -> Bool {
        (UserDefaults.standard.stringArray(forKey: "scan.ignoredPhotoIdentifiers") ?? []).contains(identifier)
    }

    func isIgnoredByAutomaticScan(_ barcode: String) -> Bool {
        (UserDefaults.standard.stringArray(forKey: "scan.ignoredBarcodes") ?? []).contains(barcode)
    }

    func setPartialRedemption(_ enabled: Bool, for gifticon: Gifticon) throws {
        guard !enabled || gifticon.couponKind == .storedValue else { throw PersistenceError.notStoredValue }
        gifticon.allowsPartialRedemption = enabled
        try saveChanges()
    }

    func setInitialAmount(_ amount: Double, for gifticon: Gifticon) throws {
        guard amount.isFinite, amount > 0 else { throw PersistenceError.invalidDeduction }
        guard gifticon.couponKind == .storedValue else { throw PersistenceError.notStoredValue }
        guard gifticon.originalAmount == nil, !gifticon.isUsed else { throw PersistenceError.amountAlreadySet }
        gifticon.originalAmount = amount
        gifticon.remainingAmount = amount
        try saveChanges()
    }

    func deduct(_ amount: Double, from gifticon: Gifticon) throws {
        guard !gifticon.needsReview, !gifticon.isUsed else { throw PersistenceError.couponUnavailable }
        guard gifticon.couponKind == .storedValue else { throw PersistenceError.notStoredValue }
        guard gifticon.allowsPartialRedemption else { throw PersistenceError.partialRedemptionDisabled }
        guard amount.isFinite, amount > 0 else { throw PersistenceError.invalidDeduction }
        guard let remaining = gifticon.remainingAmount, amount <= remaining else { throw PersistenceError.insufficientBalance }
        gifticon.remainingAmount = remaining - amount
        if gifticon.remainingAmount == 0 { gifticon.isUsed = true }
        try saveChanges()
    }
}

enum PersistenceError: LocalizedError {
    case notStoredValue
    case couponUnavailable
    case amountAlreadySet
    case incompleteInformation
    case duplicateBarcode
    case reviewRequired
    case balanceExhausted
    case barcodeRequired
    case partialRedemptionDisabled
    case invalidDeduction
    case insufficientBalance

    var errorDescription: String? {
        switch self {
        case .notStoredValue: "금액권만 잔액을 차감할 수 있습니다."
        case .couponUnavailable: "사용 가능 상태의 쿠폰만 차감할 수 있습니다."
        case .amountAlreadySet: "설정된 금액을 덮어쓸 수 없습니다."
        case .incompleteInformation: "브랜드, 상품명과 바코드를 입력해 주세요."
        case .duplicateBarcode: "같은 바코드가 이미 보관함에 있어요."
        case .reviewRequired: "기프티콘인지 먼저 확인해 주세요."
        case .balanceExhausted: "잔액이 모두 차감된 쿠폰은 사용 취소할 수 없습니다."
        case .barcodeRequired: "바코드가 있는 기프티콘만 등록할 수 있습니다."
        case .partialRedemptionDisabled: "부분 차감을 먼저 허용해 주세요."
        case .invalidDeduction: "차감 금액은 0보다 커야 합니다."
        case .insufficientBalance: "남은 금액보다 많이 차감할 수 없습니다."
        }
    }
}
