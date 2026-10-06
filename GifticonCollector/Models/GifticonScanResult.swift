import Foundation

struct GifticonScanResult: Sendable, Equatable {
    let sourceAssetIdentifier: String
    let text: String
    let barcodeValues: [String]
    let confidence: Double
}

struct ParsedGifticon: Sendable, Equatable {
    let brand: String
    let title: String
    let barcodeNumber: String?
    let expiryDate: Date?
    let amount: Double?
    let confidence: Double
    var needsReview: Bool = false
    var barcodeCandidates: [String] = []
    var couponKind: CouponKind = .exchange
    var remainingAmount: Double? = nil
    var productPrice: Double? = nil
    var discountAmount: Double? = nil
}


enum CouponKind: String, Codable, CaseIterable, Sendable {
    case exchange
    case storedValue
    var title: String { self == .exchange ? "상품 교환권" : "금액권" }
}
