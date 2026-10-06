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
    func testEditApprovalAndDuplicateProtection() throws {
        let container = try ModelContainer(for: Gifticon.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let service = PersistenceService(modelContext: container.mainContext)
        let item = try service.save(parsed: ParsedGifticon(brand: "미상", title: "확인", barcodeNumber: "edit1", expiryDate: nil, amount: nil, confidence: 0.3, needsReview: true), assetLocalIdentifier: "test")
        _ = try service.save(parsed: ParsedGifticon(brand: "다른 쿠폰", title: "상품", barcodeNumber: "edit2", expiryDate: nil, amount: nil, confidence: 0.9), assetLocalIdentifier: "test2")
        XCTAssertThrowsError(try service.update(item, brand: "수정", title: "쿠폰", barcode: "edit2", expiryDate: nil, needsReview: false))
        XCTAssertEqual(item.brand, "미상")
        try service.update(item, brand: "수정 브랜드", title: "수정 상품", barcode: "edit1", expiryDate: nil, needsReview: false)
        XCTAssertFalse(item.needsReview)
        XCTAssertEqual(item.title, "수정 상품")
        try service.toggleUsed(item)
        XCTAssertTrue(item.isUsed)
    }

    func testArchivedOriginalIsReadableAndNotPendingAgain() throws {
        let filename = try SharedImageInbox.enqueue(imageData: Data([1, 2, 3]))
        let pending = try XCTUnwrap(SharedImageInbox.url(for: filename))
        try SharedImageInbox.archive(pending)
        let saved = try XCTUnwrap(SharedImageInbox.url(for: filename))
        defer { try? SharedImageInbox.remove(saved) }
        XCTAssertEqual(try Data(contentsOf: saved), Data([1, 2, 3]))
        XCTAssertFalse(try SharedImageInbox.pendingFiles().contains { $0.lastPathComponent == filename })
        XCTAssertNil(SharedImageInbox.url(for: "../private.jpg"))
    }

    func testDeletePreservesSharedOriginalUntilLastReferenceAndPreventsRescan() throws {
        let previous = UserDefaults.standard.stringArray(forKey: "scan.ignoredBarcodes")
        defer { UserDefaults.standard.set(previous, forKey: "scan.ignoredBarcodes") }
        let filename = try SharedImageInbox.enqueue(imageData: Data([4, 5, 6]))
        try SharedImageInbox.archive(XCTUnwrap(SharedImageInbox.url(for: filename)))
        let url = try XCTUnwrap(SharedImageInbox.url(for: filename))
        let container = try ModelContainer(for: Gifticon.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let service = PersistenceService(modelContext: container.mainContext)
        let first = try service.save(parsed: ParsedGifticon(brand: "테스트", title: "쿠폰1", barcodeNumber: "DELETE-TEST-1", expiryDate: nil, amount: nil, confidence: 0.9), assetLocalIdentifier: "shared:\(filename)")
        let second = try service.save(parsed: ParsedGifticon(brand: "테스트", title: "쿠폰2", barcodeNumber: "DELETE-TEST-2", expiryDate: nil, amount: nil, confidence: 0.9), assetLocalIdentifier: "shared:\(filename)")
        try service.delete(first)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(service.isIgnoredByAutomaticScan("DELETE-TEST-1"))
        try service.delete(second)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        let reimport = try service.save(parsed: ParsedGifticon(brand: "테스트", title: "직접 추가", barcodeNumber: "DELETE-TEST-1", expiryDate: nil, amount: nil, confidence: 0.9), assetLocalIdentifier: "test")
        XCTAssertEqual(reimport.title, "직접 추가")
    }

    func testLegacyStoreMigratesWithoutLosingCoupon() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy.store")
        try writeLegacyStore(at: url)
        let container = try ModelContainer(for: Gifticon.self, configurations: ModelConfiguration(url: url))
        let item = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Gifticon>()).first)
        XCTAssertEqual(item.brand, "기존 쿠폰")
        XCTAssertEqual(item.remainingAmount, 7500)
        XCTAssertEqual(item.barcodeNumber, "LEGACY-123")
        XCTAssertTrue(item.needsReview, "이전 오분류 가능 항목은 데이터를 보존하며 확인 필요로 이동")
    }

    private func writeLegacyStore(at url: URL) throws {
        let container = try ModelContainer(for: LegacySchema.Gifticon.self, configurations: ModelConfiguration(url: url))
        container.mainContext.insert(LegacySchema.Gifticon())
        try container.mainContext.save()
    }
}

private enum LegacySchema {
    @Model final class Gifticon {
        @Attribute(.unique) var barcodeNumber: String?
        var id: UUID
        var brand: String
        var title: String
        var expiryDate: Date?
        var assetLocalIdentifier: String
        var isUsed: Bool
        var originalAmount: Double?
        var remainingAmount: Double?
        var allowsPartialRedemption: Bool
        var createdAt: Date
        init() {
            barcodeNumber = "LEGACY-123"
            id = UUID()
            brand = "기존 쿠폰"
            title = "원래 상품"
            expiryDate = nil
            assetLocalIdentifier = "old-photo"
            isUsed = false
            originalAmount = 10000
            remainingAmount = 7500
            allowsPartialRedemption = true
            createdAt = .now
        }
    }
}
