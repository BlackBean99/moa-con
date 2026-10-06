import Foundation
import SwiftData

@Model
final class Gifticon {
    @Attribute(.unique) var barcodeNumber: String?
    var needsReview: Bool = true
    var id: UUID
    var brand: String
    var title: String
    var expiryDate: Date?
    var assetLocalIdentifier: String
    var isUsed: Bool
    var originalAmount: Double?
    var remainingAmount: Double?
    var allowsPartialRedemption: Bool
    var sourcePhotoIdentifier: String?
    var barcodeCandidates: [String] = []
    var couponKindRaw: String = ""
    var productPrice: Double?
    var discountAmount: Double?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        needsReview: Bool = false,
        brand: String,
        title: String,
        barcodeNumber: String? = nil,
        expiryDate: Date? = nil,
        assetLocalIdentifier: String,
        isUsed: Bool = false,
        originalAmount: Double? = nil,
        remainingAmount: Double? = nil,
        allowsPartialRedemption: Bool = false,
        createdAt: Date = .now,
        barcodeCandidates: [String] = [],
        couponKind: CouponKind? = nil,
        productPrice: Double? = nil,
        discountAmount: Double? = nil
    ) {
        self.needsReview = needsReview
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
        self.barcodeCandidates = barcodeCandidates
        self.couponKindRaw = (couponKind ?? (originalAmount == nil ? .exchange : .storedValue)).rawValue
        self.productPrice = productPrice
        self.discountAmount = discountAmount
    }

    var couponKind: CouponKind {
        get { CouponKind(rawValue: couponKindRaw) ?? (originalAmount == nil ? .exchange : .storedValue) }
        set { couponKindRaw = newValue.rawValue }
    }

    func isExpired(on date: Date = .now) -> Bool {
        guard let expiryDate else { return false }
        return Calendar.current.startOfDay(for: expiryDate) < Calendar.current.startOfDay(for: date)
    }
}
