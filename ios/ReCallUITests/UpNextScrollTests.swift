import XCTest

/// Home scroll must keep working after Up Next reorder gestures (device-critical; simulator often misses the freeze).
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
        let theme = app.descendants(matching: .any).matching(identifier: "Theme").firstMatch
        XCTAssertTrue(theme.waitForExistence(timeout: 10), "Entry form did not open")
        let field = app.descendants(matching: .any).matching(identifier: "Title").firstMatch
        revealEntryField(app, field)
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Entry form did not open")
        field.tap()
        field.typeText(title)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10), "Created \(title) not in feed")
    }

    private func revealEntryField(_ app: XCUIApplication, _ element: XCUIElement) {
        for _ in 0..<20 {
            let top = max(110, app.navigationBars.firstMatch.frame.maxY + 8)
            let share = app.descendants(matching: .any).matching(identifier: "shareForm").firstMatch
            let bottom = share.exists && share.isHittable ? share.frame.minY - 12 : app.frame.height - 100
            let exists = element.exists
            let frame = exists ? element.frame : .zero
            if exists && element.isHittable && frame.minY >= top && frame.maxY <= bottom {
                return
            }
            let down = exists && frame.minY < top
            let overflow = down ? top - frame.minY + 12 : frame.maxY - bottom + 12
            let distance = exists ? min(140, max(35, overflow)) : 140
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.4))
            start.press(forDuration: 0.05, thenDragTo:
                start.withOffset(CGVector(dx: 0, dy: down ? distance : -distance)))
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Unreachable reminder entry field hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Reminder entry field was not fully reachable")
    }

    private func scrollUntilHittable(_ app: XCUIApplication, _ el: XCUIElement, maxSwipes: Int = 8) {
        let scroll = app.scrollViews["homeScroll"]
        for _ in 0..<maxSwipes {
            if el.exists && el.isHittable { return }
            scroll.swipeUp()
        }
    }

    private func scrollHomeUntilCompletedVisible(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let completed = app.buttons["completedRemindersToggle"]
        let scroll = app.scrollViews["homeScroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10), "Home scroll view missing", file: file, line: line)

        func visibleBounds() -> (top: CGFloat, bottom: CGFloat) {
            let keyboard = app.keyboards.firstMatch
            let fab = app.buttons["chargeFab"].firstMatch
            let top = max(scroll.frame.minY, app.frame.minY + 100)
            var bottom = min(scroll.frame.maxY, app.frame.maxY)
            if fab.exists { bottom = min(bottom, fab.frame.minY) }
            if keyboard.exists { bottom = min(bottom, keyboard.frame.minY) }
            return (top, bottom - 24)
        }

        for _ in 0..<16 {
            let (top, bottom) = visibleBounds()
            // XCTest can report this control as hittable beneath the bottom bar.
            // Bring the whole control above the floating button before tapping.
            if completed.exists && completed.isHittable
                && completed.frame.minY >= top && completed.frame.maxY <= bottom { return }
            // A full-screen swipe can jump past the control on smaller phones,
            // especially with the keyboard open. Drag within the visible page
            // and reverse if the control has already passed above the viewport.
            let low = top + (bottom - top) * 0.7
            let high = top + (bottom - top) * 0.3
            let towardTop = !completed.exists || completed.frame.minY >= top
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: app.frame.width / 2, dy: towardTop ? low : high))
            let end = origin.withOffset(CGVector(dx: app.frame.width / 2, dy: towardTop ? high : low))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(completed.waitForExistence(timeout: 2), "Completed reminders never scrolled into view", file: file, line: line)
        XCTAssertTrue(completed.isHittable, "Completed control is not reachable — scroll stuck", file: file, line: line)
        let (top, bottom) = visibleBounds()
        XCTAssertGreaterThanOrEqual(completed.frame.minY, top, "Completed is behind the header", file: file, line: line)
        XCTAssertLessThanOrEqual(completed.frame.maxY, bottom, "Completed is behind the bottom controls", file: file, line: line)
    }

    /// Long-press to arm, tap up chevron: Beta must move above Alpha.
    func testReorderMovesCardWithinUpNext() {
        let app = XCUIApplication()
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED"]
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

        betaText.press(forDuration: 0.6)
        let up = app.buttons["reorderUp"].firstMatch
        XCTAssertTrue(up.waitForExistence(timeout: 5), "armed reorder chevrons did not appear")
        up.tap()
        app.staticTexts["Understood"].tap()
        XCTAssertFalse(app.textFields["cardTitleField"].exists)

        XCTAssertLessThan(betaText.frame.minY, alphaText.frame.minY,
                          "tap-up did not move Beta above Alpha — reorder never fired")
    }

    func testHomeScrollsToCompletedOnLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED", "RECALL_UI_TEST_CARD_TITLES", "RECALL_UI_TEST_LONG_FEED"]
        app.launchEnvironment["RECALL_UI_TEST_SESSION"] = UUID().uuidString
        app.launch()
        dismissNotificationPrompt()
        XCTAssertTrue(app.staticTexts["Understood"].waitForExistence(timeout: 20))
        let completed = app.buttons["completedRemindersToggle"]
        XCTAssertFalse(completed.isHittable, "The fixture must require scrolling to reach Completed")
        scrollHomeUntilCompletedVisible(app)
        completed.tap()
        XCTAssertTrue(app.staticTexts["Original completed writing"].waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Completed opens after scrolling the long reminder list"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testHomeScrollWorksAfterUpNextLongPress() {
        let app = XCUIApplication()
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED", "RECALL_UI_TEST_CARD_TITLES", "RECALL_UI_TEST_LONG_FEED"]
        app.launchEnvironment["RECALL_UI_TEST_SESSION"] = UUID().uuidString
        app.launch()
        dismissNotificationPrompt()
        XCTAssertTrue(app.staticTexts["Understood"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["completedRemindersToggle"].isHittable,
                       "The fixture must require scrolling to reach Completed")

        let card = app.otherElements["upNextCard0"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.press(forDuration: 0.6)
        XCTAssertTrue(app.textFields["cardTitleField"].waitForExistence(timeout: 5))
        scrollHomeUntilCompletedVisible(app)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.006, dy: 0.20)).tap()
        XCTAssertTrue(app.textFields["cardTitleField"].waitForNonExistence(timeout: 5))
    }
}
