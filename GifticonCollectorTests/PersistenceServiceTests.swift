import SwiftData
import XCTest
@testable import GifticonCollector

@MainActor
final class PersistenceServiceTests: XCTestCase {
    func testBarcodeIsUniqueAndPartialRedemptionUpdatesBalance() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Gifticon.self, configurations: configuration)
        let service = PersistenceService(modelContext: container.mainContext)
        let parsed = ParsedGifticon(
            brand: "테스트 브랜드",
            title: "테스트 상품",
            barcodeNumber: "8801234567890",
            expiryDate: nil,
            amount: 10_000,
            confidence: 0.9
        )

        let first = try service.save(parsed: parsed, assetLocalIdentifier: "asset-1")
        let duplicate = try service.save(parsed: parsed, assetLocalIdentifier: "asset-2")
        XCTAssertEqual(first.id, duplicate.id)

        try service.setPartialRedemption(true, for: first)
        try service.deduct(2_500, from: first)
        XCTAssertEqual(first.remainingAmount, 7_500)
        XCTAssertFalse(first.isUsed)
    }

    func testPartialRedemptionIsOffByDefault() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Gifticon.self, configurations: configuration)
        let service = PersistenceService(modelContext: container.mainContext)
        let parsed = ParsedGifticon(
            brand: "테스트",
            title: "상품",
            barcodeNumber: "ABC123",
            expiryDate: nil,
            amount: 5_000,
            confidence: 0.8
        )

        let gifticon = try service.save(parsed: parsed, assetLocalIdentifier: "asset-1")
        XCTAssertFalse(gifticon.allowsPartialRedemption)
        XCTAssertThrowsError(try service.deduct(1_000, from: gifticon))
    }
}
