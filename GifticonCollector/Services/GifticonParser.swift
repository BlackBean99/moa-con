import Foundation

struct GifticonParser: Sendable {
    private let classifier = GifticonClassifier()

    func parse(text: String, barcodeValues: [String]) -> ParsedGifticon? {
        guard let rawBarcode = barcodeValues.first else { return nil }
        let barcode = Self.normalizeBarcode(rawBarcode)
        guard !barcode.isEmpty else { return nil }
        let classification = classifier.classify(text: text, barcodeValues: barcodeValues)

        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        let brand = parseBrand(from: lines)
        let title = parseTitle(from: lines, excluding: brand)
        let expiryDate = parseExpiryDate(from: text)
        let kind: CouponKind = text.contains("금액권") || text.contains("잔액") || text.contains("권면금액") ? .storedValue : .exchange
        let productPrice = labeledAmount(in: lines, labels: ["상품 가격", "상품가격", "판매가", "정가"])
        let discount = labeledAmount(in: lines, labels: ["할인", "할인액"])
        let balance = kind == .storedValue ? labeledAmount(in: lines, labels: ["잔액", "사용가능금액", "사용 가능 금액"]) : nil
        let amount = kind == .storedValue ? (labeledAmount(in: lines, labels: ["권면금액", "금액권", "충전금액"]) ?? balance) : nil
        var candidates: [String] = []
        for value in barcodeValues.map(Self.normalizeBarcode) where !value.isEmpty && !candidates.contains(value) { candidates.append(value) }

        return ParsedGifticon(
            brand: brand,
            title: title,
            barcodeNumber: candidates.count == 1 ? barcode : nil,
            expiryDate: expiryDate,
            amount: amount,
            confidence: classification.confidence,
            needsReview: !classification.isLikelyGifticon || brand == "브랜드 확인 필요" || title == "상품명 미상" || expiryDate == nil || (balance != nil && amount != nil && balance! > amount!),
            barcodeCandidates: candidates,
            couponKind: kind,
            remainingAmount: balance,
            productPrice: productPrice,
            discountAmount: discount
        )
    }

    static func normalizeBarcode(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "-" }) {
            return trimmed.filter(\.isNumber)
        }
        return trimmed
    }

    private func parseBrand(from lines: [String]) -> String {
        let brands = ["스타벅스", "투썸플레이스", "이디야", "메가커피", "컴포즈커피", "배스킨라빈스", "파리바게뜨", "뚜레쥬르", "올리브영", "교촌치킨", "BBQ", "BHC", "맥도날드", "CU", "GS25", "세븐일레븐"]
        if let known = brands.first(where: { brand in lines.contains { $0.localizedCaseInsensitiveContains(brand) } }) { return known }
        for line in lines where line.contains("교환처") || line.contains("사용처") {
            let value = line.replacingOccurrences(of: "교환처", with: "").replacingOccurrences(of: "사용처", with: "")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ":：")))
            if !value.isEmpty { return value }
        }
        return "브랜드 확인 필요"
    }

    private func parseTitle(from lines: [String], excluding brand: String) -> String {
        let pricePattern = #"^(?:₩|￦)?\s?[0-9,]+\s?원?$"#
        return lines.first {
            $0 != brand && $0.range(of: pricePattern, options: .regularExpression) == nil
                && !$0.contains("유효기간") && !$0.contains("교환처")
                && !$0.contains("사용기한") && !$0.contains("발행일")
                && !$0.contains("쿠폰번호") && !$0.contains("선물하기")
        } ?? "상품명 미상"
    }

    private func labeledAmount(in lines: [String], labels: [String]) -> Double? {
        for (index, line) in lines.enumerated() where labels.contains(where: line.contains) {
            if let value = parseAmount(from: line) { return value }
            if index + 1 < lines.count, let value = parseAmount(from: lines[index + 1]) { return value }
        }
        return nil
    }

    private func parseAmount(from text: String) -> Double? {
        let pattern = #"(?:₩|￦)?\s?([0-9]+(?:,[0-9]{3})*)\s?원"#
        guard let match = text.range(of: pattern, options: .regularExpression) else { return nil }
        let raw = String(text[match]).filter { $0.isNumber }
        guard let amount = Double(raw), amount.isFinite, amount > 0 else { return nil }
        return amount
    }

    private func parseExpiryDate(from text: String) -> Date? {
        let patterns = [
            #"20\d{2}[.\-/년]\s?\d{1,2}[.\-/월]\s?\d{1,2}"#,
            #"20\d{2}\s?년\s?\d{1,2}\s?월\s?\d{1,2}\s?일"#
        ]
        let lines = text.components(separatedBy: .newlines)
        var expiryLines: [String] = []
        for (index, line) in lines.enumerated() where line.contains("유효기간") || line.contains("사용기한") || line.contains("유효기한") {
            expiryLines.append(line)
            if line.range(of: "20[0-9]{2}", options: .regularExpression) == nil, index + 1 < lines.count {
                expiryLines.append(lines[index + 1])
            }
        }
        let source = expiryLines.joined(separator: "\n")
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: source, range: NSRange(source.startIndex..., in: source))
            for match in matches.reversed() {
                guard let range = Range(match.range, in: source) else { continue }
                let raw = String(source[range])
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
                guard let result = date.date else { continue }
                let check = date.calendar!.dateComponents([.year, .month, .day], from: result)
                guard check.year == date.year, check.month == date.month, check.day == date.day else { continue }
                return result
            }
        }
        return nil
    }
}
