import Foundation

struct GifticonClassifier: Sendable {
    struct Classification: Sendable, Equatable {
        let isLikelyGifticon: Bool
        let confidence: Double
        let matchedSignals: [String]
    }

    func classify(text: String, barcodeValues: [String]) -> Classification {
        let normalized = text.lowercased().replacingOccurrences(of: " ", with: "")
        let coupon = ["교환권", "상품권", "기프티콘", "기프트콘", "기프티쇼", "모바일쿠폰", "금액권", "교환처", "사용처"]
            .contains { normalized.contains($0) }
        let expiry = normalized.contains("유효기간") || normalized.contains("사용기한")
        let unrelated = ["멤버십", "회원번호", "적립카드", "영수증", "운송장", "배송조회"]
            .contains { normalized.contains($0) }
        let values = Set(barcodeValues.map(GifticonParser.normalizeBarcode).filter { !$0.isEmpty })
        let likely = values.count == 1 && coupon && !unrelated
        var signals: [String] = []
        if !values.isEmpty { signals.append("barcode") }
        if coupon { signals.append("coupon-context") }
        if expiry { signals.append("expiry-label") }
        if unrelated { signals.append("non-coupon-context") }
        return Classification(isLikelyGifticon: likely,
                              confidence: likely ? (expiry ? 0.95 : 0.8) : 0.3,
                              matchedSignals: signals)
    }
}
