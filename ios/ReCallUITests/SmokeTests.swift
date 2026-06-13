import XCTest

/// QC Layer 3 — device smoke. Deliberately thin: deep behavior is covered by
/// the Playwright suite (tests/web). This only proves the native shell boots
/// and actually renders the bundled web prototype.
final class SmokeTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesAndRendersWebUI() {
        let app = XCUIApplication()
        app.launch()

        // The WKWebView must come up.
        let web = app.webViews.firstMatch
        XCTAssertTrue(web.waitForExistence(timeout: 20), "WKWebView never appeared")

        // The web content must expose the brand header — proves index.html
        // loaded from the bundle, not a blank or error page.
        let brand = web.staticTexts["Notorious"]
        XCTAssertTrue(brand.waitForExistence(timeout: 20), "Web UI did not render (brand title missing)")
    }

    /// Real touch, real device-class input: tap the Tasks tab with the iOS
    /// touch pipeline (not a desktop click) and assert the screen actually
    /// switches. This is the layer Playwright cannot see.
    func testButtonsRespondToRealTouch() {
        let app = XCUIApplication()
        app.launch()

        let web = app.webViews.firstMatch
        XCTAssertTrue(web.waitForExistence(timeout: 20), "WKWebView never appeared")

        let tasksTab = web.descendants(matching: .any)["Tasks"].firstMatch
        XCTAssertTrue(tasksTab.waitForExistence(timeout: 20), "Tasks tab not found")
        tasksTab.tap()

        // "Upcoming" exists only on the Tasks screen (segment + section head)
        let upcoming = web.descendants(matching: .any)["Upcoming"].firstMatch
        XCTAssertTrue(upcoming.waitForExistence(timeout: 10), "Tap did not switch screens — touch input is broken")
    }

    func testMacBookCaptureFlowSurvivesRealSimulatorInput() {
        let app = XCUIApplication()
        app.launch()

        let web = app.webViews.firstMatch
        XCTAssertTrue(web.waitForExistence(timeout: 20), "WKWebView never appeared")

        let tile = web.descendants(matching: .any)["Capture the MacBook unlocks"].firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 20), "MacBook capture tile not found")
        tile.tap()

        let title = app.staticTexts["MacBook capture"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10), "Native MacBook capture sheet did not appear")

        let cadence = app.staticTexts["4x/day for 4 days"].firstMatch
        XCTAssertTrue(cadence.waitForExistence(timeout: 10), "Native cadence control missing")

        let record = app.buttons["Record voice memo"].firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 10), "Voice record control missing")
        record.tap()

        allowSystemAlertIfPresent(app)

        let stop = app.buttons["Stop recording"].firstMatch
        XCTAssertTrue(stop.waitForExistence(timeout: 10), "Voice capture never entered recording state")
        stop.tap()

        let voiceState = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Voice memo captured'")).firstMatch
        XCTAssertTrue(voiceState.waitForExistence(timeout: 10), "Recorded voice state never surfaced")

        let titleField = app.textFields["nativeCaptureTitleField"].firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 10), "Title field missing")
        titleField.tap()
        clearText(titleField)
        titleField.typeText("Two real unlocks from the new machine")
        dismissKeyboardIfPresent(app)

        let saveCapture = app.buttons["Save capture"].firstMatch
        XCTAssertTrue(saveCapture.waitForExistence(timeout: 10), "Capture save button missing")
        saveCapture.tap()

        XCTAssertFalse(title.waitForExistence(timeout: 5), "Native capture sheet never dismissed")

        let latest = web.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Two real unlocks from the new machine'")).firstMatch
        XCTAssertTrue(latest.waitForExistence(timeout: 10), "Saved native capture reminder missing from latest list")

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "MacBook capture flow"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func allowSystemAlertIfPresent(_ app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"].firstMatch
        if allow.waitForExistence(timeout: 3) {
            allow.tap()
            return
        }

        let ok = springboard.buttons["OK"].firstMatch
        if ok.waitForExistence(timeout: 1) {
            ok.tap()
        }
    }

    private func dismissKeyboardIfPresent(_ app: XCUIApplication) {
        let returnKey = app.keyboards.buttons["return"].firstMatch
        if returnKey.waitForExistence(timeout: 1) {
            returnKey.tap()
            return
        }

        let capitalReturnKey = app.keyboards.buttons["Return"].firstMatch
        if capitalReturnKey.waitForExistence(timeout: 1) {
            capitalReturnKey.tap()
        }
    }

    private func clearText(_ element: XCUIElement) {
        guard let value = element.value as? String, !value.isEmpty else { return }
        let deleteSequence = String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)
        element.typeText(deleteSequence)
    }
}
