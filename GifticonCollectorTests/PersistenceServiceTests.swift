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
    func testSettingsNeverRestoreSpentBalance() throws {
        let container = try ModelContainer(for: Gifticon.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let service = PersistenceService(modelContext: container.mainContext)
        let gifticon = try service.save(parsed: ParsedGifticon(brand: "테스트", title: "상품권", barcodeNumber: "123", expiryDate: nil, amount: 10000, confidence: 0.9), assetLocalIdentifier: "test")
        try service.setPartialRedemption(true, for: gifticon)
        try service.deduct(2500, from: gifticon)
        try service.setPartialRedemption(false, for: gifticon)
        XCTAssertEqual(gifticon.remainingAmount, 7500)
        try service.toggleUsed(gifticon)
        try service.toggleUsed(gifticon)
        XCTAssertEqual(gifticon.remainingAmount, 7500)
        try service.setPartialRedemption(true, for: gifticon)
        try service.deduct(7500, from: gifticon)
        XCTAssertThrowsError(try service.toggleUsed(gifticon))
        XCTAssertThrowsError(try service.setInitialAmount(.infinity, for: gifticon))
    }

    func testReviewSurvivesSaveAndCannotBeRedeemed() throws {
        let container = try ModelContainer(for: Gifticon.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let service = PersistenceService(modelContext: container.mainContext)
        let item = try service.save(parsed: ParsedGifticon(brand: "미상", title: "확인", barcodeNumber: "review", expiryDate: nil, amount: nil, confidence: 0.3, needsReview: true), assetLocalIdentifier: "test")
        XCTAssertTrue(try container.mainContext.fetch(FetchDescriptor<Gifticon>()).first!.needsReview)
        XCTAssertThrowsError(try service.toggleUsed(item))
    }

    func testExpiryIncludesEntireLastDay() {
        let day = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 6))!
        let item = Gifticon(brand: "테스트", title: "쿠폰", expiryDate: day, assetLocalIdentifier: "test")
        XCTAssertFalse(item.isExpired(on: day.addingTimeInterval(23 * 3600)))
        XCTAssertTrue(item.isExpired(on: day.addingTimeInterval(24 * 3600)))
    }
}
