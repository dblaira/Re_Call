import XCTest

/// Home scroll must keep working after Up Next reorder gestures.
final class UpNextScrollTests: XCTestCase {

    private func dismissNotificationPrompt() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 5) { allow.tap() }
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
