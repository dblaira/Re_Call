import XCTest

final class ProImageTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED", "RECALL_UI_TEST_PRO_IMAGES"]
        app.launchEnvironment["RECALL_UI_TEST_SESSION"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["PRO"].waitForExistence(timeout: 20))
        app.buttons["PRO"].tap()
        XCTAssertTrue(title("Poster 1").waitForExistence(timeout: 20))
    }

    private func title(_ text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label == %@", "cardTitleText-pro-image:", text)).firstMatch
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    private func zoom(_ value: String) {
        let control = app.buttons["proZoomLevel"]
        let condition = NSPredicate(format: "value == %@", value)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: control)], timeout: 5), .completed)
    }

    private func replace(_ field: XCUIElement, with text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        // Place the insertion point after the existing text before replacing it.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.9)).tap()
        let old = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count) + text)
        XCTAssertEqual(field.value as? String, text)
    }

    private func editFromMenu() {
        app.buttons["proImageOptions"].tap()
        app.buttons["Edit details"].tap()
        XCTAssertTrue(app.textFields["proImageTitle"].waitForExistence(timeout: 5))
    }

    func testOnscreenKeyboardEditsAndFinishesBothTitleEditors() {
        let field = app.descendants(matching: .any).matching(identifier: "cardTitleField").firstMatch
        let secondID = title("Poster 2").identifier.replacingOccurrences(of: "cardTitleText-pro-image:", with: "")
        app.buttons["proEditTitle-\(secondID)"].tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        XCTAssertLessThan(field.frame.maxY, keyboard.frame.minY)
        keyboard.keys["s"].tap()
        XCTAssertEqual(field.value as? String, "Poster 2s")
        attach("Onscreen keys visible while editing the second title")
        keyboard.buttons["Done"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5), "Keyboard Done must finish editing instead of adding a newline")
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 5))
        XCTAssertTrue(title("Poster 2s").waitForExistence(timeout: 5))

        title("Poster 2s").tap()
        editFromMenu()
        let detailsTitle = app.textFields["proImageTitle"]
        detailsTitle.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        keyboard.keys["s"].tap()
        XCTAssertEqual(detailsTitle.value as? String, "Poster 2ss")
        attach("Details title accepts the onscreen keyboard")
        app.buttons["proSaveImage"].tap()
        app.buttons["proClosePoster"].tap()
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        XCTAssertTrue(title("Poster 2ss").waitForExistence(timeout: 10))
        XCTAssertTrue(title("Poster 1").exists)
    }

    func testSecondCardTitleWorksFromCardAndDetails() {
        let field = app.textFields["cardTitleField"]
        let secondID = title("Poster 2").identifier.replacingOccurrences(of: "cardTitleText-pro-image:", with: "")
        app.buttons["proEditTitle-\(secondID)"].tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        replace(field, with: "Cancelled title")
        app.buttons["cancelCardTitle"].tap()
        XCTAssertTrue(title("Poster 2").waitForExistence(timeout: 5))

        title("Poster 2").press(forDuration: 0.6)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        XCTAssertLessThan(field.frame.maxY, app.keyboards.firstMatch.frame.minY)
        replace(field, with: "Second image renamed")
        attach("Second image title accepts typing inline")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.2)).tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5))
        XCTAssertTrue(title("Second image renamed").waitForExistence(timeout: 5))

        title("Second image renamed").tap()
        editFromMenu()
        XCTAssertEqual(app.textFields["proImageTitle"].value as? String, "Second image renamed",
                       "Edit details must start with the title currently shown on the card")
        replace(app.textFields["proImageTitle"], with: "Second image from details")
        app.buttons["proSaveImage"].tap()
        XCTAssertTrue(app.navigationBars.staticTexts["Second image from details"].waitForExistence(timeout: 5))
        app.buttons["proClosePoster"].tap()
        XCTAssertTrue(title("Second image from details").waitForExistence(timeout: 5))
        XCTAssertTrue(title("Poster 1").exists, "Renaming the second card must preserve its neighbor")
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        XCTAssertTrue(title("Second image from details").waitForExistence(timeout: 10))
        attach("Second image title persists after both editing paths and relaunch")
        title("Second image from details").press(forDuration: 0.6)
        replace(field, with: "Temporary title")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.2)).tap()
        title("Temporary title").press(forDuration: 0.6)
        app.buttons["restoreCardTitle"].tap()
        XCTAssertTrue(title("Second image from details").waitForExistence(timeout: 5))
    }

    func testDetailsCancelValidationAndCopyFeedback() {
        title("Poster 2").tap()
        app.buttons["proShowDetails"].tap()
        XCTAssertTrue(app.buttons["proEditDetails"].waitForExistence(timeout: 5))
        app.buttons["proCopySource"].tap()
        XCTAssertEqual(app.buttons["proCopySource"].label, "Source copied")
        app.buttons["proShowDetails"].tap()
        XCTAssertFalse(app.buttons["proEditDetails"].exists)
        editFromMenu()
        replace(app.textFields["proImageTitle"], with: "Discard this edit")
        app.buttons["Cancel"].tap()
        editFromMenu()
        XCTAssertEqual(app.textFields["proImageTitle"].value as? String, "Poster 2")
        replace(app.textFields["proImageSource"], with: "javascript:invalid")
        app.buttons["proSaveImage"].tap()
        XCTAssertTrue(app.staticTexts["Enter a website address for the source, or leave it empty."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["proImageTitle"].exists, "A rejected source must keep the editor open")
        replace(app.textFields["proImageSource"], with: "https://example.org/tools")
        app.buttons["proSaveImage"].tap()
        app.buttons["proShowDetails"].tap()
        XCTAssertTrue(app.links["proSourceLink"].exists || app.buttons["proSourceLink"].exists)
        XCTAssertEqual(app.buttons["proCopySource"].label, "Copy source")
        attach("Edited source and copy feedback")
        app.buttons["proEditDetails"].tap()
        XCTAssertEqual(app.textFields["proImageSource"].value as? String, "https://example.org/tools")
        app.buttons["Cancel"].tap()
        app.buttons["proClosePoster"].tap()
        XCTAssertTrue(title("Poster 2").waitForExistence(timeout: 5))
    }

    func testRemovalRequiresConfirmationAndRemovesOnlySelectedImage() {
        title("Poster 2").tap()
        app.buttons["proImageOptions"].tap()
        app.buttons["Remove image"].tap()
        XCTAssertTrue(app.staticTexts["Remove this image from Pro?"].waitForExistence(timeout: 5))
        // Native popover confirmations dismiss on an outside tap; compact sheets show Cancel.
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.3)).tap()
        }
        XCTAssertTrue(app.staticTexts["Remove this image from Pro?"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["proClosePoster"].exists)
        app.buttons["proImageOptions"].tap()
        app.buttons["Remove image"].tap()
        XCTAssertTrue(app.staticTexts["Remove this image from Pro?"].waitForExistence(timeout: 5))
        app.buttons["Remove image"].tap()
        XCTAssertTrue(title("Poster 1").waitForExistence(timeout: 5))
        XCTAssertFalse(title("Poster 2").exists)
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        XCTAssertTrue(title("Poster 1").waitForExistence(timeout: 10))
        XCTAssertFalse(title("Poster 2").exists)
        XCTAssertTrue(title("Poster 3").exists)
        attach("Confirmed removal preserves neighboring cards after relaunch")
    }

    func testPosterZoomDetailsAndRelaunch() {
        attach("Pro saved images preserve different proportions")
        title("Poster 1").tap()
        XCTAssertTrue(app.buttons["proZoomIn"].waitForExistence(timeout: 10))
        let enabled = NSPredicate(format: "enabled == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabled, object: app.buttons["proZoomIn"])], timeout: 15), .completed)
        app.buttons["proZoomIn"].tap(); zoom("200 percent")
        attach("Poster enlarged with native zoom")
        app.buttons["proZoomOut"].tap(); zoom("100 percent")
        app.buttons["proZoomIn"].tap(); zoom("200 percent")
        app.buttons["proZoomLevel"].tap(); zoom("100 percent")
        let canvas = app.descendants(matching: .any).matching(identifier: "proPosterCanvas").firstMatch
        canvas.doubleTap(); zoom("300 percent")
        canvas.swipeUp()
        attach("Poster panned while enlarged")
        app.buttons["proZoomLevel"].tap(); zoom("100 percent")
        canvas.pinch(withScale: 2, velocity: 1)
        XCTAssertNotEqual(app.buttons["proZoomLevel"].value as? String, "100 percent", "Native pinch must enlarge the poster")
        app.buttons["proShowDetails"].tap()
        XCTAssertTrue(app.staticTexts["Original poster notes 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.links["proSourceLink"].exists || app.buttons["proSourceLink"].exists)
        app.buttons["proEditDetails"].tap()
        let noteField = app.descendants(matching: .any).matching(identifier: "proImageNotes").firstMatch
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        // Tap after the first line's text, rather than the empty center of a multiline field.
        noteField.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: noteField.frame.width - 8, dy: 10)).tap()
        noteField.typeText(" — explored")
        XCTAssertEqual(noteField.value as? String, "Original poster notes 1 — explored")
        app.buttons["proSaveImage"].tap()
        XCTAssertTrue(app.staticTexts["Original poster notes 1 — explored"].waitForExistence(timeout: 5))
        app.buttons["proClosePoster"].tap()
        XCTAssertTrue(title("Poster 1").waitForExistence(timeout: 5))
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        XCTAssertTrue(title("Poster 1").waitForExistence(timeout: 10))
        title("Poster 1").tap(); app.buttons["proShowDetails"].tap()
        XCTAssertTrue(app.staticTexts["Original poster notes 1 — explored"].waitForExistence(timeout: 10))
        attach("Saved source and edited notes survive relaunch")
    }

    func testClosingPosterPreservesScrolledCardPosition() {
        let scroll = app.scrollViews["proSavedImages"]
        let selected = title("Poster 7")
        for _ in 0..<8 {
            if selected.exists, selected.isHittable, selected.frame.midY < app.frame.height - 160 { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(selected.isHittable)
        let before = selected.frame
        selected.tap()
        XCTAssertTrue(app.buttons["proClosePoster"].waitForExistence(timeout: 5))
        app.buttons["proClosePoster"].tap()
        XCTAssertTrue(selected.waitForExistence(timeout: 5))
        XCTAssertEqual(selected.frame.minY, before.minY, accuracy: 2, "Closing must retain the card's scroll position")
        attach("Returned to the same saved card position")
    }
}
