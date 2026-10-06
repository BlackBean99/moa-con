import XCTest
@testable import GifticonCollector

final class AdvertisingTests: XCTestCase {
    func testReleaseCannotEnableTestIDsOrDebugArguments() {
        XCTAssertEqual(AdsConfiguration(info: [:], arguments: ["--ads-sdk-testing"]).mode, .disabled)
        var info = liveInfo
        info["GADApplicationIdentifier"] = AdsConfiguration.testAppID
        XCTAssertEqual(AdsConfiguration(info: info).mode, .disabled)
        info = liveInfo; info["MoaconAdsPrivacyReviewed"] = false
        XCTAssertEqual(AdsConfiguration(info: info).mode, .disabled)
        info = liveInfo; info["MoaconPrivacyPolicyURL"] = "http://example.com/privacy"
        XCTAssertEqual(AdsConfiguration(info: info).mode, .disabled)
        info = liveInfo; info["MoaconBannerAdUnitID"] = "ca-app-pub-9999999999999999/1234567890"
        XCTAssertEqual(AdsConfiguration(info: info).mode, .disabled)
        XCTAssertEqual(AdsConfiguration(info: liveInfo).mode, .live)
    }

    func testDebugAlwaysUsesOfficialTestUnit() {
        let config = AdsConfiguration(info: liveInfo, arguments: ["--ads-sdk-testing"], permitsDebugTools: true)
        XCTAssertEqual(config.mode, .test)
        XCTAssertEqual(config.bannerID, AdsConfiguration.testBannerID)
        XCTAssertEqual(AdsConfiguration(info: liveInfo, arguments: ["--ui-testing"], permitsDebugTools: true).mode, .disabled)
    }

    func testPlacementHasNoAdDuringCouponTasksOrWithoutContent() {
        XCTAssertTrue(AdPlacement.isEligible(hasCoupons: true, isSearchPresented: false, isBusy: false, isDetail: false))
        XCTAssertFalse(AdPlacement.isEligible(hasCoupons: false, isSearchPresented: false, isBusy: false, isDetail: false))
        XCTAssertFalse(AdPlacement.isEligible(hasCoupons: true, isSearchPresented: true, isBusy: false, isDetail: false))
        XCTAssertFalse(AdPlacement.isEligible(hasCoupons: true, isSearchPresented: false, isBusy: true, isDetail: false))
        XCTAssertFalse(AdPlacement.isEligible(hasCoupons: true, isSearchPresented: false, isBusy: false, isDetail: true))
    }

    @MainActor func testConsentDenialAndFailureNeverStartSDK() async {
        let driver = ConsentStub()
        var starts = 0
        let service = AdvertisingService(configuration: AdsConfiguration(info: liveInfo), consent: driver) { starts += 1 }
        await service.prepare()
        XCTAssertFalse(service.canShowAds); XCTAssertEqual(starts, 0)
        driver.snapshot = ConsentSnapshot(canRequestAds: true, privacyOptionsRequired: true)
        driver.fail = true
        await service.retryConsent()
        XCTAssertFalse(service.canShowAds); XCTAssertEqual(starts, 0)
        XCTAssertNotNil(service.privacyError)
    }

    @MainActor func testConsentAndPrivacyChangeInitializeOnlyOnceAndRemoveOldBanner() async {
        let driver = ConsentStub()
        driver.snapshot = ConsentSnapshot(canRequestAds: true, privacyOptionsRequired: true)
        var starts = 0
        let service = AdvertisingService(configuration: AdsConfiguration(info: liveInfo), consent: driver) { starts += 1 }
        await service.prepare(); await service.prepare()
        XCTAssertEqual(driver.gathers, 1); XCTAssertEqual(starts, 1)
        XCTAssertTrue(service.canShowAds); XCTAssertTrue(service.privacyOptionsRequired)
        let revision = service.revision
        driver.snapshot = ConsentSnapshot(canRequestAds: false, privacyOptionsRequired: true)
        await service.changePrivacyOptions()
        XCTAssertFalse(service.canShowAds); XCTAssertGreaterThan(service.revision, revision)
        driver.snapshot = ConsentSnapshot(canRequestAds: true, privacyOptionsRequired: true)
        await service.changePrivacyOptions()
        XCTAssertTrue(service.canShowAds); XCTAssertEqual(starts, 1)
    }

    @MainActor func testDisabledConfigurationDoesNotGatherOrStart() async {
        let driver = ConsentStub()
        var starts = 0
        let service = AdvertisingService(configuration: AdsConfiguration(info: [:]), consent: driver) { starts += 1 }
        await service.prepare(); await service.retryConsent(); await service.changePrivacyOptions()
        XCTAssertEqual(driver.gathers, 0); XCTAssertEqual(starts, 0)
    }

    @MainActor func testOldConsentCompletionCannotOverridePrivacyChange() async {
        let driver = ConsentStub()
        driver.suspendGather = true
        var starts = 0
        let service = AdvertisingService(configuration: AdsConfiguration(info: liveInfo), consent: driver) { starts += 1 }
        let pending = Task { await service.prepare() }
        while driver.continuation == nil { await Task.yield() }
        driver.snapshot = ConsentSnapshot(canRequestAds: false, privacyOptionsRequired: true)
        await service.changePrivacyOptions()
        driver.continuation?.resume(returning: ConsentSnapshot(canRequestAds: true, privacyOptionsRequired: false))
        await pending.value
        XCTAssertFalse(service.canShowAds); XCTAssertEqual(starts, 0)
    }

    private var liveInfo: [String: Any] {
        ["MoaconAdsEnabled": true, "GADApplicationIdentifier": "ca-app-pub-1234567890123456~1234567890",
         "MoaconBannerAdUnitID": "ca-app-pub-1234567890123456/1234567890",
         "MoaconAdsConsentConfigured": true, "MoaconAdsPrivacyReviewed": true,
         "MoaconAdsAppAdsTxtVerified": true, "MoaconAdsReadinessApproved": true,
         "MoaconPrivacyPolicyURL": "https://example.com/privacy"]
    }
}

@MainActor private final class ConsentStub: AdvertisingConsent {
    var snapshot = ConsentSnapshot(canRequestAds: false, privacyOptionsRequired: false)
    var fail = false
    var gathers = 0
    var suspendGather = false
    var continuation: CheckedContinuation<ConsentSnapshot, Never>?
    func gather() async throws -> ConsentSnapshot {
        gathers += 1
        if suspendGather { return await withCheckedContinuation { continuation = $0 } }
        if fail { throw NSError(domain: "TestConsent", code: 1) }
        return snapshot
    }
    func presentPrivacyOptions() async throws -> ConsentSnapshot {
        if fail { throw NSError(domain: "TestConsent", code: 1) }
        return snapshot
    }
}
