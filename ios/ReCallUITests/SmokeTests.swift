import XCTest

/// QC Layer 3 — device smoke. Deliberately thin: deep behavior is covered by
/// the Playwright suite (tests/web). This only proves the native shell boots
/// and actually renders the bundled web prototype.
final class SmokeTests: XCTestCase {

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
}
