import XCTest

final class WalletFlowTests: XCTestCase {
    @MainActor
    func testReviewApprovalAndRedemption() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        XCTAssertTrue(app.navigationBars["모아콘"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["아메리카노 Tall"].exists)
        XCTAssertFalse(app.staticTexts["멤버십 카드"].exists)
        capture("01-wallet")
        app.buttons["확인 필요"].tap()
        app.staticTexts["멤버십 카드"].tap()
        XCTAssertTrue(app.buttons["사용 완료"].exists)
        XCTAssertFalse(app.buttons["사용 완료"].isEnabled)
        app.buttons["정보 확인"].tap()
        app.buttons["쿠폰으로 보관"].tap()
        XCTAssertTrue(app.buttons["사용 완료"].isEnabled)
        XCTAssertTrue(app.navigationBars["정보 수정"].waitForNonExistence(timeout: 3))
        capture("02-approved-detail")
        app.buttons["사용 완료"].tap()
        XCTAssertTrue(app.buttons["사용 취소"].exists)
    }

    @MainActor
    func testSearchEditAndOriginalImage() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        XCTAssertTrue(app.navigationBars["모아콘"].waitForExistence(timeout: 10))
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("스타벅스")
        XCTAssertTrue(app.staticTexts["아메리카노 Tall"].exists)
        app.staticTexts["아메리카노 Tall"].tap()
        app.buttons["원본 크게 보기"].tap()
        XCTAssertTrue(app.navigationBars["원본"].waitForExistence(timeout: 3))
        capture("03-original")
        app.buttons["닫기"].tap()
        app.buttons["수정"].tap()
        let title = app.textFields["상품명"]
        title.tap()
        // Append text to verify editing and save propagation without relying on localized keyboard menus.
        title.typeText(" 수정")
        app.buttons["저장"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "수정")).firstMatch.waitForExistence(timeout: 3))
    }

    @MainActor
    func testDeleteCancellationAndManualImportAccess() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        XCTAssertTrue(app.navigationBars["모아콘"].waitForExistence(timeout: 10))
        app.buttons["사진 추가"].tap()
        XCTAssertTrue(app.buttons["사진 한 장 선택"].waitForExistence(timeout: 3))
        app.buttons["닫기"].tap()
        app.staticTexts["아메리카노 Tall"].tap()
        app.collectionViews.firstMatch.swipeUp()
        app.buttons["보관함에서 삭제"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        app.alerts.buttons["취소"].tap()
        XCTAssertTrue(app.buttons["보관함에서 삭제"].exists)
        app.buttons["보관함에서 삭제"].tap()
        app.buttons["삭제"].tap()
        XCTAssertTrue(app.navigationBars["모아콘"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["아메리카노 Tall"].exists)
    }

    @MainActor
    func testOnboardingCompletesOnceWithoutPermissionPrompt() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--onboarding-testing", "--reset-onboarding", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.start"].waitForExistence(timeout: 10))
        XCTAssertEqual(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.count, 0)
        capture("04-onboarding")
        app.buttons["onboarding.start"].tap()
        XCTAssertTrue(app.navigationBars["모아콘"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["쿠폰 없음"].exists)
        XCTAssertEqual(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.count, 0)
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-onboarding" }
        app.launch()
        XCTAssertTrue(app.navigationBars["모아콘"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["onboarding.start"].exists)
    }

    @MainActor
    func testLargeTextAndDarkAppearanceKeepCoreActionsAccessible() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "--dark-appearance"]
        app.launch()
        XCTAssertTrue(app.buttons["wallet.add"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["아메리카노 Tall"].exists)
        app.collectionViews.firstMatch.swipeUp()
        capture("05-wallet-large-dark")
        app.buttons["wallet.add"].tap()
        XCTAssertTrue(app.buttons["사진 한 장 선택"].waitForExistence(timeout: 5))
        capture("06-import-large-dark")
        app.buttons["닫기"].tap()
        app.staticTexts["아메리카노 Tall"].tap()
        XCTAssertTrue(app.buttons["원본 크게 보기"].waitForExistence(timeout: 5))
        capture("07-detail-large-dark")
    }

    @MainActor
    func testOnboardingAtLargestTextSize() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--onboarding-testing", "--reset-onboarding", "--dark-appearance",
                               "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.start"].waitForExistence(timeout: 10))
        if !app.buttons["onboarding.start"].isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(app.buttons["onboarding.start"].isHittable)
        capture("08-onboarding-large-dark")
        app.buttons["onboarding.start"].tap()
        XCTAssertTrue(app.buttons["wallet.add"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPrivacyPolicyIsAccessibleFromWallet() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        XCTAssertTrue(app.navigationBars["모아콘"].waitForExistence(timeout: 10))
        app.buttons["더 보기"].tap()
        app.buttons["개인정보 처리"].tap()
        XCTAssertTrue(app.navigationBars["개인정보 처리"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["사진과 바코드는 기기에서 분석합니다. 앱이 사진이나 인식 결과를 외부 서버로 보내지 않습니다."].exists)
        capture("09-privacy-policy")
        app.buttons["닫기"].tap()
        XCTAssertTrue(app.navigationBars["모아콘"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
