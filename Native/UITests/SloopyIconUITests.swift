import XCTest

final class SloopyIconUITests: XCTestCase {
    @MainActor
    func testAlternateIconChangeAndRestore() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--sloopy-icon-smoke-test"]
        app.launch()

        let support = app.staticTexts["icon-test-support"]
        XCTAssertTrue(support.waitForExistence(timeout: 15), "Icon smoke-test screen did not appear.")
        XCTAssertEqual(support.label, "supportsAlternateIcons=true", "The app reports that alternate icons are unavailable in this simulator.")

        let result = app.staticTexts["icon-test-result"]

        app.buttons["icon-test-change"].tap()
        dismissSystemIconAlertIfPresent()
        XCTAssertTrue(result.waitForExistence(timeout: 30), "No result was returned for the alternate icon request.")
        let changeResult = result.label
        print("ALTERNATE_ICON_CHANGE_RESULT: \(changeResult)")
        XCTAssertEqual(changeResult, "SUCCESS: CrystalIcon", "Alternate icon change did not succeed.")

        app.buttons["icon-test-reset"].tap()
        dismissSystemIconAlertIfPresent()
        let resetPredicate = NSPredicate(format: "label == %@", "SUCCESS: Primary")
        expectation(for: resetPredicate, evaluatedWith: result)
        waitForExpectations(timeout: 30)
        print("ALTERNATE_ICON_RESTORE_RESULT: \(result.label)")
    }

    @MainActor
    private func dismissSystemIconAlertIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        if alert.waitForExistence(timeout: 2) {
            let buttons = alert.buttons
            if buttons.count > 0 {
                buttons.element(boundBy: 0).tap()
            }
        }
    }
}
