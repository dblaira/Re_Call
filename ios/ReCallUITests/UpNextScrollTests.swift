import XCTest

/// Home scroll must keep working after Up Next reorder gestures.
final class UpNextScrollTests: XCTestCase {

    private func dismissNotificationPrompt() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 5) { allow.tap() }
    }

    /// Creates a reminder via the real charge-FAB → form flow (drag FAB left = Reminder).
    private func createReminder(_ app: XCUIApplication, title: String) {
        let fab = app.buttons["chargeFab"].firstMatch
        XCTAssertTrue(fab.waitForExistence(timeout: 20), "Charge FAB missing")
        let center = fab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.2, thenDragTo: center.withOffset(CGVector(dx: -120, dy: 0)))
        let field = app.textFields["Title"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Entry form did not open")
        field.tap()
        field.typeText(title)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10), "Created \(title) not in feed")
    }

    private func scrollUntilHittable(_ app: XCUIApplication, _ el: XCUIElement, maxSwipes: Int = 8) {
        let scroll = app.scrollViews["homeScroll"]
        for _ in 0..<maxSwipes {
            if el.exists && el.isHittable { return }
            scroll.swipeUp()
        }
    }

    /// The actual feature: long-press a card to ARM it (crimson ring + chevrons), then TAP the up
    /// chevron to move it one slot. Two fresh reminders are adjacent (Alpha above Beta); arming Beta
    /// and tapping up must put Beta above Alpha. Tap-driven reorder — no drag — so scroll is safe.
    func testReorderMovesCardWithinUpNext() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()

        let alpha = "Reorder Alpha \(Int(Date().timeIntervalSince1970) % 100000)"
        let beta = "Reorder Beta \(Int(Date().timeIntervalSince1970) % 100000)"
        createReminder(app, title: alpha)
        createReminder(app, title: beta)

        let alphaText = app.staticTexts[alpha].firstMatch
        let betaText = app.staticTexts[beta].firstMatch
        scrollUntilHittable(app, betaText)
        XCTAssertTrue(betaText.isHittable, "Beta card not on screen")
        XCTAssertLessThan(alphaText.frame.minY, betaText.frame.minY,
                          "precondition: Alpha should start above Beta")

        // Long-press Beta (no drag) to arm; the up/down chevrons appear.
        betaText.press(forDuration: 0.6)
        let up = app.buttons["reorderUp"].firstMatch
        XCTAssertTrue(up.waitForExistence(timeout: 5), "armed reorder chevrons did not appear")
        up.tap()

        // After tap-up, Beta must now sit above Alpha.
        XCTAssertLessThan(betaText.frame.minY, alphaText.frame.minY,
                          "tap-up did not move Beta above Alpha — the move never fired")
    }

    private func scrollHomeUntilShapesVisible(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let shapes = app.staticTexts["Reminder shapes"]
        let scroll = app.scrollViews["homeScroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10), "Home scroll view missing", file: file, line: line)

        for _ in 0..<8 {
            if shapes.exists && shapes.isHittable { return }
            scroll.swipeUp()
        }
        XCTAssertTrue(shapes.waitForExistence(timeout: 2), "Reminder shapes never scrolled into view", file: file, line: line)
        XCTAssertTrue(shapes.isHittable, "Reminder shapes visible but not hittable — scroll stuck", file: file, line: line)
    }

    func testHomeScrollsToShapesOnLaunch() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()
        XCTAssertTrue(app.staticTexts["Notorious"].waitForExistence(timeout: 20))
        scrollHomeUntilShapesVisible(app)
    }

    func testHomeScrollWorksAfterUpNextLongPress() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()
        XCTAssertTrue(app.staticTexts["Notorious"].waitForExistence(timeout: 20))

        let card = app.otherElements["upNextCard0"]
        if card.waitForExistence(timeout: 5) {
            card.press(forDuration: 0.45)
            // Release without moving — must not brick scroll.
        }

        scrollHomeUntilShapesVisible(app)
    }

    func testHomeScrollWorksAfterUpNextReorderDrag() {
        let app = XCUIApplication()
        app.launch()
        dismissNotificationPrompt()
        XCTAssertTrue(app.staticTexts["Notorious"].waitForExistence(timeout: 20))

        let card = app.otherElements["upNextCard0"]
        guard card.waitForExistence(timeout: 5) else {
            scrollHomeUntilShapesVisible(app)
            return
        }

        let start = card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let hold = start.withOffset(CGVector(dx: 0, dy: 0))
        let up = start.withOffset(CGVector(dx: 0, dy: -80))
        hold.press(forDuration: 0.45, thenDragTo: up)

        scrollHomeUntilShapesVisible(app)
    }
}
