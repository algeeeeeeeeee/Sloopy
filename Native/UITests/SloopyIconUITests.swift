import XCTest

final class SloopyIconUITests: XCTestCase {
    @MainActor
    func testAlternateIconChangeAndRestore() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--sloopy-icon-smoke-test"]
        app.launch()

        let support = app.staticTexts["icon-test-support"]
        XCTAssertTrue(support.waitForExistence(timeout: 15), "Icon smoke-test screen did not appear.")
        XCTAssertEqual(
            support.label,
            "supportsAlternateIcons=true",
            "The app reports that alternate icons are unavailable in this simulator."
        )

        let result = app.staticTexts["icon-test-result"]
        XCTAssertTrue(result.waitForExistence(timeout: 10))

        app.buttons["icon-test-change"].tap()
        handleSystemIconAlertIfPresent()
        waitForRequestCompletion(result, timeout: 30)

        let changeResult = result.label
        print("ALTERNATE_ICON_CHANGE_RESULT: \(changeResult)")
        XCTAssertTrue(
            changeResult.hasPrefix("SUCCESS: CrystalIcon"),
            "Alternate icon change did not succeed. Callback result: \(changeResult)"
        )

        app.buttons["icon-test-reset"].tap()
        handleSystemIconAlertIfPresent()
        waitForRequestCompletion(result, timeout: 30)

        let restoreResult = result.label
        print("ALTERNATE_ICON_RESTORE_RESULT: \(restoreResult)")
        XCTAssertTrue(
            restoreResult.hasPrefix("SUCCESS: Primary"),
            "Restoring the primary icon did not succeed. Callback result: \(restoreResult)"
        )
    }

    @MainActor
    private func waitForRequestCompletion(
        _ result: XCUIElement,
        timeout: TimeInterval
    ) {
        let completed = NSPredicate(
            format: "label BEGINSWITH 'SUCCESS:' OR label BEGINSWITH 'ERROR:' OR label BEGINSWITH 'MISMATCH:'"
        )
        expectation(for: completed, evaluatedWith: result)
        waitForExpectations(timeout: timeout)
    }

    @MainActor
    private func handleSystemIconAlertIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: 8) else { return }

        let changeButton = alert.buttons["Change"]
        if changeButton.exists {
            changeButton.tap()
            return
        }

        let okButton = alert.buttons["OK"]
        if okButton.exists {
            okButton.tap()
        }
    }
}
