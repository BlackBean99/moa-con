import Foundation
import SwiftData

@Model
final class Gifticon {
    @Attribute(.unique) var barcodeNumber: String?
    var id: UUID
    var brand: String
    var title: String
    var expiryDate: Date?
    var assetLocalIdentifier: String
    var isUsed: Bool
    var originalAmount: Double?
    var remainingAmount: Double?
    var allowsPartialRedemption: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        brand: String,
        title: String,
        barcodeNumber: String? = nil,
        expiryDate: Date? = nil,
        assetLocalIdentifier: String,
        isUsed: Bool = false,
        originalAmount: Double? = nil,
        remainingAmount: Double? = nil,
        allowsPartialRedemption: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.title = title
        self.barcodeNumber = barcodeNumber
        self.expiryDate = expiryDate
        self.assetLocalIdentifier = assetLocalIdentifier
        self.isUsed = isUsed
        self.originalAmount = originalAmount
        self.remainingAmount = remainingAmount ?? originalAmount
        self.allowsPartialRedemption = allowsPartialRedemption
        self.createdAt = createdAt
    }
}
