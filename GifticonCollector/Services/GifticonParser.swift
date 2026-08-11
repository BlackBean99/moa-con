import Foundation

struct GifticonParser: Sendable {
    private let classifier = GifticonClassifier()

    func parse(text: String, barcodeValues: [String]) -> ParsedGifticon? {
        guard let rawBarcode = barcodeValues.first else { return nil }
        let barcode = Self.normalizeBarcode(rawBarcode)
        guard !barcode.isEmpty else { return nil }
        let classification = classifier.classify(text: text, barcodeValues: barcodeValues)
        guard classification.isLikelyGifticon else { return nil }

        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        let brand = parseBrand(from: lines)
        let title = parseTitle(from: lines, excluding: brand)
        let expiryDate = parseExpiryDate(from: text)
        let amount = parseAmount(from: text)

        return ParsedGifticon(
            brand: brand,
            title: title,
            barcodeNumber: barcode,
            expiryDate: expiryDate,
            amount: amount,
            confidence: classification.confidence
        )
    }

    static func normalizeBarcode(_ value: String) -> String {
        value.filter { $0.isLetter || $0.isNumber }
    }

    private func parseBrand(from lines: [String]) -> String {
        // TODO: Use a maintained issuer dictionary and OCR normalization rules.
        return lines.first(where: { !$0.isEmpty }) ?? "브랜드 미상"
    }

    private func parseTitle(from lines: [String], excluding brand: String) -> String {
        let pricePattern = #"(?:₩|￦)?\s?[0-9,]+\s?원?"#
        return lines.first {
            $0 != brand && $0.range(of: pricePattern, options: .regularExpression) == nil
                && !$0.contains("유효기간") && !$0.contains("교환처")
        } ?? "상품명 미상"
    }

    private func parseAmount(from text: String) -> Double? {
        let pattern = #"(?:₩|￦)?\s?([0-9]{1,3}(?:,[0-9]{3})*)\s?원"#
        guard let match = text.range(of: pattern, options: .regularExpression) else { return nil }
        let raw = String(text[match]).filter { $0.isNumber }
        return Double(raw)
    }

    private func parseExpiryDate(from text: String) -> Date? {
        let patterns = [
            #"20\d{2}[.\-/년]\s?\d{1,2}[.\-/월]\s?\d{1,2}"#,
            #"20\d{2}\s?년\s?\d{1,2}\s?월\s?\d{1,2}\s?일"#
        ]
        for pattern in patterns {
            guard let range = text.range(of: pattern, options: .regularExpression) else { continue }
            let raw = String(text[range])
                .replacingOccurrences(of: "년", with: ".")
                .replacingOccurrences(of: "월", with: ".")
                .replacingOccurrences(of: "일", with: "")
                .replacingOccurrences(of: "/", with: ".")
                .replacingOccurrences(of: "-", with: ".")
            let components = raw.split(separator: ".").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            guard components.count == 3 else { continue }
            var date = DateComponents()
            date.calendar = Calendar(identifier: .gregorian)
            date.year = components[0]
            date.month = components[1]
            date.day = components[2]
            return date.date
        }
        return nil
    }
}
