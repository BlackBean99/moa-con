import Foundation
import SwiftData

@MainActor
final class PersistenceService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(parsed: ParsedGifticon, assetLocalIdentifier: String) throws -> Gifticon {
        if let barcode = parsed.barcodeNumber, !barcode.isEmpty {
            let descriptor = FetchDescriptor<Gifticon>(predicate: #Predicate { $0.barcodeNumber == barcode })
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        }

        let gifticon = Gifticon(
            brand: parsed.brand,
            title: parsed.title,
            barcodeNumber: parsed.barcodeNumber,
            expiryDate: parsed.expiryDate,
            assetLocalIdentifier: assetLocalIdentifier
        )
        modelContext.insert(gifticon)
        try modelContext.save()
        return gifticon
    }

    func toggleUsed(_ gifticon: Gifticon) throws {
        gifticon.isUsed.toggle()
        try modelContext.save()
    }
}
