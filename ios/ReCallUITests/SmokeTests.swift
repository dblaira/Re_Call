import XCTest

/// QC Layer 3 — native device smoke. Boots the real app on a simulator and exercises the native
/// entry flow: the centered charge FAB → entry form → created reminder shows in Up Next.
///
/// Rewritten 2026-06-17 for the native charge-FAB UI. The previous version tested a retired web/old
/// flow (a "New reminder" button, a "Core" group, an "Add" toolbar) that no longer exists — see
/// qc.sh header and HANDOFF.md "Native-only rule".
final class SmokeTests: XCTestCase {

    /// The notification permission prompt belongs to SpringBoard and would block taps; dismiss it.
    private func dismissNotificationPrompt() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 5) { allow.tap() }
    }

    /// Opens the entry form the real way: press the charge FAB and drag toward the Reminder option
    /// (left of center), then release. This drives the actual fan-menu gesture rather than a tap.
    private func openReminderForm(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let fab = app.buttons["chargeFab"].firstMatch
        XCTAssertTrue(fab.waitForExistence(timeout: 20), "Charge FAB missing", file: file, line: line)
        let center = fab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let reminderZone = center.withOffset(CGVector(dx: -120, dy: 0))   // left = Reminder
        center.press(forDuration: 0.2, thenDragTo: reminderZone)
    }

    func testAppLaunchesToNativeReminders() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()
        XCTAssertTrue(app.staticTexts["Notorious"].waitForExistence(timeout: 20),
                      "Native Reminders did not render (brand title missing)")
        XCTAssertTrue(app.buttons["chargeFab"].waitForExistence(timeout: 10), "Charge FAB missing")
    }

    func testProTabOpensProfessionalTemplates() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()

        let proTab = app.buttons["PRO"]
        XCTAssertTrue(proTab.waitForExistence(timeout: 10), "PRO tab missing")
        proTab.tap()

        XCTAssertTrue(app.staticTexts["Professional Templates"].waitForExistence(timeout: 10),
                      "Professional Templates page title missing")
        XCTAssertTrue(app.otherElements["professionalTemplateGrid"].waitForExistence(timeout: 10),
                      "Professional template grid missing")
        XCTAssertTrue(app.staticTexts["Reply with leverage"].waitForExistence(timeout: 10),
                      "Expected professional template card missing")
    }

    func testFABOpensEntryForm() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()
        openReminderForm(app)
        XCTAssertTrue(app.textFields["Title"].waitForExistence(timeout: 10),
                      "Entry form did not open from the charge FAB")
    }

    func testCreatingAReminderShowsItInTheList() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()
        openReminderForm(app)
        let title = app.textFields["Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        title.tap()
        title.typeText("Smoke test reminder")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Smoke test reminder"].waitForExistence(timeout: 10),
                      "Created reminder did not appear in Up Next")
    }
}
