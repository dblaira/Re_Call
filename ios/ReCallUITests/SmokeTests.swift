import XCTest

/// QC Layer 3 — device smoke. Deliberately thin: it proves the native app boots, the full-page
/// entry form opens with its part groups, and a created reminder shows up in the list.
final class SmokeTests: XCTestCase {

    /// The notification permission prompt belongs to SpringBoard and would block taps; dismiss it.
    private func dismissNotificationPrompt() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 5) { allow.tap() }
    }

    func testAppLaunchesToNativeReminders() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()
        XCTAssertTrue(app.staticTexts["Notorious"].waitForExistence(timeout: 20),
                      "Native Reminders did not render (brand title missing)")
        XCTAssertTrue(app.buttons["New reminder"].waitForExistence(timeout: 10),
                      "FAB missing")
    }

    func testFABOpensFullPageForm() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()
        let fab = app.buttons["New reminder"]
        XCTAssertTrue(fab.waitForExistence(timeout: 20))
        fab.tap()
        XCTAssertTrue(app.navigationBars["New Reminder"].waitForExistence(timeout: 10),
                      "Entry form did not open")
        XCTAssertTrue(app.staticTexts["Core"].waitForExistence(timeout: 5), "Core group missing")
        XCTAssertTrue(app.textFields["Title"].exists, "Title field missing")
    }

    func testCreatingAReminderShowsItInTheList() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()
        app.buttons["New reminder"].tap()
        let title = app.textFields["Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        title.tap()
        title.typeText("Smoke test reminder")
        app.navigationBars.buttons["Add"].tap()
        XCTAssertTrue(app.staticTexts["Smoke test reminder"].waitForExistence(timeout: 10),
                      "Created reminder did not appear in the list")
    }
}
