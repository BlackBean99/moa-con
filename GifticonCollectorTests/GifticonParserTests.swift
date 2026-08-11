import XCTest
@testable import GifticonCollector

final class GifticonParserTests: XCTestCase {
    func testParsesLikelyGifticonFields() {
        let parser = GifticonParser()
        let result = parser.parse(
            text: "스타벅스\n아메리카노 Tall\n5,000원\n유효기간 2026.08.31\n교환처 스타벅스",
            barcodeValues: ["8801234567890"]
        )

        XCTAssertEqual(result?.brand, "스타벅스")
        XCTAssertEqual(result?.barcodeNumber, "8801234567890")
        XCTAssertNotNil(result?.expiryDate)
        XCTAssertGreaterThan(result?.confidence ?? 0, 0.45)
    }

    func testRejectsUnrelatedImageText() {
        let parser = GifticonParser()
        XCTAssertNil(parser.parse(text: "오늘의 일기\n맑은 날씨", barcodeValues: []))
    }
}
