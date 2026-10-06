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
        XCTAssertTrue(app.buttons["사용 완료 처리"].exists)
        XCTAssertFalse(app.buttons["사용 완료 처리"].isEnabled)
        app.buttons["정보 확인하고 보관하기"].tap()
        app.buttons["기프티콘으로 확인하고 저장"].tap()
        XCTAssertTrue(app.buttons["사용 완료 처리"].isEnabled)
        capture("02-approved-detail")
        app.buttons["사용 완료 처리"].tap()
        XCTAssertTrue(app.buttons["사용 처리 취소"].exists)
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
        XCTAssertTrue(app.navigationBars["매장에 보여주세요"].waitForExistence(timeout: 3))
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
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
