import XCTest
import UIKit
import CoreImage
@testable import GifticonCollector

final class GifticonParserTests: XCTestCase {
    func testParsesLikelyGifticonFields() {
        let parser = GifticonParser()
        let result = parser.parse(
            text: "스타벅스\n아메리카노 Tall\n5,000원\n유효기간 2026.08.31\n교환처 스타벅스",
            barcodeValues: ["8801234567890"]
        )

        XCTAssertEqual(result?.brand, "스타벅스")
        XCTAssertFalse(result?.needsReview ?? true)
        XCTAssertEqual(result?.barcodeNumber, "8801234567890")
        XCTAssertEqual(result?.amount, 5_000)
        XCTAssertNotNil(result?.expiryDate)
        XCTAssertGreaterThan(result?.confidence ?? 0, 0.45)
    }

    func testRejectsUnrelatedImageText() {
        let parser = GifticonParser()
        XCTAssertNil(parser.parse(text: "오늘의 일기\n맑은 날씨", barcodeValues: []))
    }

    func testRejectsGifticonTextWithoutDetectedBarcode() {
        let parser = GifticonParser()
        XCTAssertNil(parser.parse(
            text: "스타벅스\n아메리카노\n5,000원\n유효기간 2026.08.31",
            barcodeValues: []
        ))
    }

    func testNormalizesDetectedBarcodeBeforePersistence() {
        let parser = GifticonParser()
        let result = parser.parse(
            text: "브랜드\n상품\n교환처",
            barcodeValues: ["  880-123-456-7890  "]
        )

        XCTAssertEqual(result?.barcodeNumber, "8801234567890")
    }
    func testRetailAndMembershipBarcodesRequireReview() {
        for text in ["우유\n2500원\n2026.12.01", "멤버십\n회원번호 123\n사용처 매장", "영수증\n교환권\n5000원"] {
            let result = GifticonParser().parse(text: text, barcodeValues: ["123456789"])
            XCTAssertTrue(result?.needsReview ?? false)
        }
    }

    func testMultipleBarcodesRequireReview() {
        let result = GifticonParser().parse(text: "스타벅스\n교환권", barcodeValues: ["123", "456"])
        XCTAssertTrue(result?.needsReview ?? false)
    }

    func testExpiryUsesLabelAndAmountWithoutComma() {
        let result = GifticonParser().parse(text: "선물하기\n스타벅스\n아메리카노 Tall\n발행일 2026.01.01\n유효기간 2026.12.31\n50000원\n교환권", barcodeValues: ["123"])
        XCTAssertEqual(result?.brand, "스타벅스")
        XCTAssertEqual(result?.title, "아메리카노 Tall")
        XCTAssertEqual(result?.amount, 50000)
        XCTAssertEqual(Calendar.current.component(.month, from: result!.expiryDate!), 12)
    }

    func testInvalidExpiryDoesNotRollIntoNextMonth() {
        let result = GifticonParser().parse(text: "상품권\n유효기간 2026.02.31", barcodeValues: ["123"])
        XCTAssertNil(result?.expiryDate)
    }
    func testPreservesStructuredBarcodePayload() {
        XCTAssertEqual(GifticonParser.normalizeBarcode(" https://example.com/a?b=1 "), "https://example.com/a?b=1")
        XCTAssertNotEqual(GifticonParser.normalizeBarcode("ABC-123"), GifticonParser.normalizeBarcode("ABC123"))
    }

    @MainActor
    func testVisionRecognizesRenderedCouponEndToEnd() async throws {
        let filter = try XCTUnwrap(CIFilter(name: "CICode128BarcodeGenerator"))
        filter.setValue(Data("123456789012".utf8), forKey: "inputMessage")
        filter.setValue(20, forKey: "inputQuietSpace")
        let output = try XCTUnwrap(filter.outputImage).transformed(by: CGAffineTransform(scaleX: 4, y: 6))
        let barcode = try XCTUnwrap(CIContext().createCGImage(output, from: output.extent))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1000, height: 1200), format: format)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1000, height: 1200))
            ("스타벅스\n아메리카노 Tall\n교환권\n5000원\n유효기간 2026.12.31" as NSString).draw(in: CGRect(x: 70, y: 80, width: 860, height: 600), withAttributes: [.font: UIFont.systemFont(ofSize: 48), .foregroundColor: UIColor.black])
            context.cgContext.interpolationQuality = .none
            UIImage(cgImage: barcode).draw(in: CGRect(x: 70, y: 750, width: barcode.width, height: barcode.height))
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "Synthetic-Code128-Coupon"
        attachment.lifetime = .keepAlways
        add(attachment)
        let result = try await OCRService().recognize(from: XCTUnwrap(image.cgImage))
        XCTAssertTrue(result.barcodeValues.contains("123456789012"), "Synthetic detections: \(result.barcodeValues)")
        let parsed = try XCTUnwrap(GifticonParser().parse(text: result.text, barcodeValues: result.barcodeValues))
        XCTAssertFalse(parsed.needsReview)
        XCTAssertEqual(parsed.brand, "스타벅스")
        XCTAssertEqual(parsed.amount, 5000)
        XCTAssertNotNil(parsed.expiryDate)
    }
    func testExpiryRangeUsesLastDayAndFollowingLine() {
        for expiry in ["유효기간 2026.01.01 ~ 2026.12.31", "유효기간\n2026.12.31"] {
            let result = GifticonParser().parse(text: "교환처 동네카페\n상품권\n" + expiry, barcodeValues: ["123"])
            XCTAssertEqual(result?.brand, "동네카페")
            XCTAssertEqual(Calendar.current.component(.month, from: result!.expiryDate!), 12)
        }
    }
}
