import XCTest

/// Real holds, typing and outside taps against an isolated local store, on phone and simulator.
final class CardTitleTests: XCTestCase {
    private let app = XCUIApplication()
    private var field: XCUIElement { app.textFields["cardTitleField"].firstMatch }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED", "RECALL_UI_TEST_CARD_TITLES"]
        app.launchEnvironment["RECALL_UI_TEST_SESSION"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.staticTexts["Understood"].waitForExistence(timeout: 20))
    }

    private func reveal(_ element: XCUIElement, in scroll: XCUIElement) {
        for _ in 0..<16 {
            if element.exists, element.isHittable,
               element.frame.midY > 110, element.frame.midY < app.frame.height - 140 { return }
            if element.exists && element.frame.midY < 110 { scroll.swipeDown() }
            else { scroll.swipeUp() }
        }
        let snapshot = XCTAttachment(string: app.debugDescription)
        snapshot.name = "Unreachable card hierarchy"
        snapshot.lifetime = .keepAlways
        add(snapshot)
        XCTAssertTrue(element.isHittable, "Card was not reachable: \(element)")
    }

    private func titleElement(_ title: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label == %@", "cardTitleText-", title
        )).firstMatch
    }

    private func revealEntryField(_ element: XCUIElement) {
        for _ in 0..<20 {
            let top = max(110, app.navigationBars.firstMatch.frame.maxY + 8)
            let share = app.descendants(matching: .any).matching(identifier: "shareForm").firstMatch
            let bottom = share.exists && share.isHittable ? share.frame.minY - 12 : app.frame.height - 100
            if element.exists && element.isHittable && element.frame.minY >= top && element.frame.maxY <= bottom {
                return
            }
            let exists = element.exists
            let frame = exists ? element.frame : .zero
            let down = exists && frame.minY < top
            let overflow = down ? top - frame.minY + 12 : frame.maxY - bottom + 12
            let distance = exists ? min(140, max(35, overflow)) : 140
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.4))
            start.press(forDuration: 0.05, thenDragTo:
                start.withOffset(CGVector(dx: 0, dy: down ? distance : -distance)))
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Unreachable entry field hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Entry field was not fully reachable")
    }

    private func begin(_ title: String, scroll: String = "homeScroll") {
        let text = titleElement(title)
        reveal(text, in: app.scrollViews[scroll])
        text.press(forDuration: 0.6)
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Hold must put a cursor inside \(title)")
        XCTAssertEqual(field.value as? String, title)
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertFalse(app.buttons["Save"].exists, "Renaming must not open the entry form")
        XCTAssertFalse(app.buttons["saveCardTitle"].exists)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        let visible = NSPredicate { _, _ in
            self.field.frame.minY >= 60 && self.field.frame.maxY + 8 < self.app.keyboards.firstMatch.frame.minY
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: visible, object: nil)], timeout: 5), .completed,
                       "The editable title must be visible above the keyboard")
    }

    private func replace(with title: String) {
        let old = field.value as? String ?? ""
        // Backspace must work immediately: the hold places the cursor at the end.
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count) + title)
        XCTAssertTrue(field.exists)
        XCTAssertEqual(field.value as? String ?? "", title)
        XCTAssertTrue(app.keyboards.firstMatch.exists, "Typing must keep the keyboard available")
    }

    private func outside() {
        // Page margin is outside every card, including when the Calendar hero is scrolled away.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.006, dy: 0.20)).tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5), "Outside tap must close the inline editor")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "Outside tap must dismiss the keyboard")
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertPillsFit(in cardID: String, lastTag: String) {
        let card = app.descendants(matching: .any).matching(identifier: "shapeCard-\(cardID)").firstMatch
        let pill = card.staticTexts[lastTag].firstMatch
        let fits = NSPredicate { _, _ in
            pill.exists && pill.frame.maxY + 10 <= card.frame.maxY
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: fits, object: nil)], timeout: 5)
        if result != .completed {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "Template title layout hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            attach("Template title layout failure")
        }
        XCTAssertEqual(result, .completed, "The title editor and pills must fit inside their card")
    }

    func testThemeCardOutsideTapSavesAcrossPagesAndRelaunch() {
        begin("Original theme answer")
        field.tap()
        XCTAssertTrue(field.exists, "Tapping inside the card must keep editing")
        let key = app.keyboards.keys["s"]
        XCTAssertTrue(key.waitForExistence(timeout: 5))
        key.tap()
        XCTAssertEqual(field.value as? String, "Original theme answers", "The cursor starts at the end and keyboard taps keep editing")
        attach("Inline theme title and keyboard on iPhone")
        outside()
        XCTAssertTrue(titleElement("Original theme answers").exists)
        app.buttons["Actions"].tap()
        XCTAssertTrue(titleElement("Original theme answers").waitForExistence(timeout: 5))
        titleElement("Original theme answers").tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "Theme").firstMatch.waitForExistence(timeout: 10))
        let original = app.descendants(matching: .any).matching(identifier: "Title").firstMatch
        revealEntryField(original)
        XCTAssertTrue(original.waitForExistence(timeout: 5))
        XCTAssertTrue(original.isHittable)
        XCTAssertEqual(original.value as? String, "Original action writing", "Original writing must remain untouched")
        app.buttons["Cancel"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(titleElement("Original theme answers").waitForExistence(timeout: 10))
        begin("Original theme answers")
        replace(with: "")
        outside()
        XCTAssertTrue(titleElement("Original theme answers").exists, "An empty draft preserves the saved title")
        begin("Original theme answers")
        app.buttons["restoreCardTitle"].tap()
        XCTAssertTrue(titleElement("Original theme answer").waitForExistence(timeout: 5))
    }

    func testRemindersActionsAndCompletedCardsEditInPlace() {
        begin("Original reminder writing")
        replace(with: "My reminder title")
        outside()
        XCTAssertTrue(titleElement("My reminder title").exists)
        app.buttons["Actions"].tap()
        begin("Original action writing", scroll: "actionsHome")
        replace(with: "My action title")
        outside()
        XCTAssertTrue(titleElement("My action title").exists)
        app.buttons["completedActionsToggle"].tap()
        begin("Original completed writing", scroll: "actionsHome")
        replace(with: "My completed title")
        attach("Completed title edits in its own card")
        outside()
        app.buttons["Reminders"].tap()
        let completed = app.buttons["completedRemindersToggle"]
        reveal(completed, in: app.scrollViews["homeScroll"])
        completed.tap()
        reveal(titleElement("My completed title"), in: app.scrollViews["homeScroll"])
        XCTAssertTrue(titleElement("My completed title").isHittable)
    }

    func testCalendarTimedAndAllDayTitles() {
        app.buttons["Calendar"].tap()
        // Calendar now opens at the month grid. Use its visible Today action to reach
        // the fixture at the current time before exercising the unchanged title editor.
        app.buttons["Today"].tap()
        begin("Original timed writing", scroll: "calendarScroll")
        replace(with: "My timed title")
        attach("Calendar timed title expands inline")
        outside()
        XCTAssertTrue(titleElement("My timed title").exists)
        let scroll = app.scrollViews["calendarScroll"]
        // The all-day band is above the hours; scroll back to it.
        for _ in 0..<20 {
            if titleElement("Original all-day writing").isHittable { break }
            scroll.swipeDown()
        }
        begin("Original all-day writing", scroll: "calendarScroll")
        replace(with: "My all-day title")
        attach("Calendar all-day title expands inline")
        outside()
        XCTAssertTrue(titleElement("My all-day title").exists)
        app.buttons["Reminders"].tap()
        XCTAssertTrue(titleElement("My timed title").exists)
        XCTAssertTrue(titleElement("My all-day title").exists)
    }

    func testEveryProfessionalTemplateSupportsInlineTitles() {
        app.buttons["PRO"].tap()
        app.buttons["proTemplatesToggle"].tap()
        for title in ["Reply with leverage", "Turn note into ask", "Before the meeting", "Research sprint", "Client follow-up", "Decision receipt", "Promise tracker", "Professional reset", "Send the clean version"] {
            begin(title, scroll: "professionalTemplatesHome")
            replace(with: title + " edited")
            if title == "Reply with leverage" {
                assertPillsFit(in: "pro-reply", lastTag: "URL")
                attach("Professional template title retains its own styling")
            }
            outside()
            XCTAssertTrue(titleElement(title + " edited").exists)
        }
        app.buttons["Reminders"].tap()
        app.buttons["PRO"].tap()
        app.buttons["proTemplatesToggle"].tap()
        XCTAssertTrue(titleElement("Reply with leverage edited").exists)
    }
}
