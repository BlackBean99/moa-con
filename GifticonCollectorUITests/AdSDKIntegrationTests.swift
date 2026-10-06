import XCTest

/// Run separately from deterministic regression. Uses Google's sample inventory; never taps the ad.
final class AdSDKIntegrationTests: XCTestCase {
    @MainActor func testOfficialGoogleTestBannerLoads() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ads-sdk-testing", "-AppleLanguages", "(ko)"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ads.label"].waitForExistence(timeout: 45), "SDK must receive an ad; a UI preview is insufficient")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "17-google-official-test-banner"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertFalse(app.staticTexts["ads.test-preview"].exists)
        app.buttons["wallet.add"].tap()
        XCTAssertTrue(app.buttons["사진 한 장 선택"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["ads.label"].exists)
    }
}
