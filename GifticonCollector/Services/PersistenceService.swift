import Foundation
import SwiftData

@MainActor
final class PersistenceService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(parsed: ParsedGifticon, assetLocalIdentifier: String) throws -> Gifticon {
        guard let barcode = parsed.barcodeNumber, !barcode.isEmpty else {
            throw PersistenceError.barcodeRequired
        }
        do {
            let descriptor = FetchDescriptor<Gifticon>(predicate: #Predicate { $0.barcodeNumber == barcode })
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        } catch {
            throw error
        }

        let gifticon = Gifticon(
            brand: parsed.brand,
            title: parsed.title,
            barcodeNumber: parsed.barcodeNumber,
            expiryDate: parsed.expiryDate,
            assetLocalIdentifier: assetLocalIdentifier,
            originalAmount: parsed.amount,
            remainingAmount: parsed.amount
        )
        modelContext.insert(gifticon)
        try modelContext.save()
        return gifticon
    }

    func toggleUsed(_ gifticon: Gifticon) throws {
        gifticon.isUsed.toggle()
        try modelContext.save()
    }

    func delete(_ gifticon: Gifticon) throws {
        modelContext.delete(gifticon)
        try modelContext.save()
    }

    func setPartialRedemption(_ enabled: Bool, for gifticon: Gifticon) throws {
        gifticon.allowsPartialRedemption = enabled
        if !enabled, let originalAmount = gifticon.originalAmount {
            gifticon.remainingAmount = gifticon.isUsed ? 0 : originalAmount
        }
        try modelContext.save()
    }

    func setInitialAmount(_ amount: Double, for gifticon: Gifticon) throws {
        guard amount > 0 else { throw PersistenceError.invalidDeduction }
        guard gifticon.originalAmount == nil || gifticon.isUsed == false else { return }
        gifticon.originalAmount = amount
        gifticon.remainingAmount = amount
        try modelContext.save()
    }

    func deduct(_ amount: Double, from gifticon: Gifticon) throws {
        guard gifticon.allowsPartialRedemption else { throw PersistenceError.partialRedemptionDisabled }
        guard amount > 0 else { throw PersistenceError.invalidDeduction }
        guard let remaining = gifticon.remainingAmount, amount <= remaining else { throw PersistenceError.insufficientBalance }
        gifticon.remainingAmount = remaining - amount
        if gifticon.remainingAmount == 0 { gifticon.isUsed = true }
        try modelContext.save()
    }
}

enum PersistenceError: LocalizedError {
    case barcodeRequired
    case partialRedemptionDisabled
    case invalidDeduction
    case insufficientBalance

    var errorDescription: String? {
        switch self {
        case .barcodeRequired: "바코드가 있는 기프트콘만 등록할 수 있습니다."
        case .partialRedemptionDisabled: "부분 차감을 먼저 허용해 주세요."
        case .invalidDeduction: "차감 금액은 0보다 커야 합니다."
        case .insufficientBalance: "남은 금액보다 많이 차감할 수 없습니다."
        }
    }
}
