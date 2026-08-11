import Foundation

struct GifticonClassifier: Sendable {
    struct Classification: Sendable, Equatable {
        let isLikelyGifticon: Bool
        let confidence: Double
        let matchedSignals: [String]
    }

    func classify(text: String, barcodeValues: [String]) -> Classification {
        let normalized = text.lowercased()
        var score = 0.0
        var signals: [String] = []

        if !barcodeValues.isEmpty {
            score += 0.35
            signals.append("barcode")
        }
        if containsAny(normalized, keywords: ["유효기간", "교환처", "사용처", "교환권", "상품권"]) {
            score += 0.30
            signals.append("gifticon-keyword")
        }
        if normalized.range(of: #"(?:₩|￦|원)\s?[0-9,]+|[0-9,]+\s?원"#, options: .regularExpression) != nil {
            score += 0.20
            signals.append("price")
        }
        if normalized.range(of: #"20\d{2}[.\-/년]\s?\d{1,2}[.\-/월]\s?\d{1,2}"#, options: .regularExpression) != nil {
            score += 0.15
            signals.append("expiry-date")
        }

        // TODO: Replace generic signals with a reviewed brand/issuer dictionary.
        return Classification(
            isLikelyGifticon: score >= 0.45,
            confidence: min(score, 1.0),
            matchedSignals: signals
        )
    }

    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
