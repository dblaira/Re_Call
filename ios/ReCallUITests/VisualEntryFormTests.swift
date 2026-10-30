import XCTest

/// Exercises the shared entry form against a per-test local store; iCloud and Harness stay isolated.
@MainActor
final class VisualEntryFormTests: XCTestCase {
    private var app: XCUIApplication!
    private let matrixQuestion = "What relationship should this matrix make clear?"
    private let summarizeQuestion = "Why does this need to be summarized?"

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED"]
        app.launchEnvironment["RECALL_UI_TEST_SESSION"] = UUID().uuidString
        app.launch()
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow"]
        if allow.waitForExistence(timeout: 3) { allow.tap() }
    }

    func testOpenedThemeAndVisualChoicesMatchThePhoneReference() {
        openForm()
        attach("entry forms")
        element("Theme").tap()
        XCTAssertTrue(app.buttons["Habit"].waitForExistence(timeout: 5))
        attach("Theme")
        app.buttons["Habit"].tap()
        let visual = element("VisualFormat")
        reveal(visual)
        visual.tap()
        for name in ["Summarize", "Tables", "Matrices", "Node Trees", "Graphic Imagery", "Slides",
                     "Charts", "Images", "Video", "Audio", "Music", "Example"] {
            XCTAssertTrue(app.buttons[name].exists, "Missing Visual choice: \(name)")
        }
        attach("Visual")
        app.buttons["Summarize"].tap()
        reveal(element("VisualQuestion0"))
        XCTAssertEqual(element("VisualQuestion0").label, summarizeQuestion)
        attach("consistent styling")
        cancelForm()
        assertEmptyHome()
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testReminderActionAndEventUseTheSameThemeAndVisualRows() {
        openForm()
        var visualWidth: CGFloat?
        for destination in ["Reminder", "Action", "Event"] {
            let segment = app.segmentedControls.buttons[destination].firstMatch
            reveal(segment, towardTopWhenMissing: true)
            segment.tap()
            XCTAssertTrue(segment.isSelected)
            XCTAssertTrue(element("Theme").exists, "Theme must remain part of every entry kind")
            XCTAssertTrue(element("themeAnswer0").exists, "Decide must remain part of every entry kind")

            let visual = element("VisualFormat")
            reveal(visual)
            XCTAssertEqual(visual.value as? String, "Matrices")
            if let visualWidth {
                XCTAssertEqual(visual.frame.width, visualWidth, accuracy: 1)
            } else {
                visualWidth = visual.frame.width
            }
            let question = element("VisualQuestion0")
            let answer = element("VisualAnswer0")
            reveal(question)
            XCTAssertEqual(question.label, matrixQuestion)
            XCTAssertTrue(answer.exists)
            XCTAssertGreaterThanOrEqual(answer.frame.minY, question.frame.maxY - 1,
                                        "The answer belongs immediately under its question")
            XCTAssertLessThanOrEqual(answer.frame.minY - question.frame.maxY, 2,
                                     "There must be no extra gap before the answer")
        }
        cancelForm()
        assertEmptyHome()
    }

    func testFormatSwitchingKeepsSeparateWritingAndQuestionTapFocusesAnswer() {
        openForm()
        let question = element("VisualQuestion0")
        let answer = element("VisualAnswer0")
        reveal(question)
        question.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        app.typeText("Matrix answer.")
        XCTAssertEqual(answer.value as? String, "Matrix answer.")
        XCTAssertEqual(question.label, matrixQuestion, "Typing must not alter the question")
        dismissKeyboard()

        selectFormat("Summarize")
        reveal(question)
        XCTAssertEqual(question.label, summarizeQuestion)
        XCTAssertEqual(answer.value as? String, "")
        question.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        app.typeText("Summary answer.")
        XCTAssertEqual(answer.value as? String, "Summary answer.")
        XCTAssertEqual(question.label, summarizeQuestion)
        dismissKeyboard()

        selectFormat("Matrices")
        reveal(answer)
        XCTAssertEqual(answer.value as? String, "Matrix answer.")
        selectFormat("Summarize")
        reveal(answer)
        XCTAssertEqual(answer.value as? String, "Summary answer.")
        cancelForm()
        assertEmptyHome()
    }

    func testLongVisualWritingSurvivesSaveReopenRelaunchAndFirstLineEdit() {
        let title = "Visual entry " + UUID().uuidString
        let firstLine = "First line."
        let remainder = (1...8).map { "Line \($0) stays fully visible." }.joined(separator: "\n")
        let writing = firstLine + "\n" + remainder
        openForm()
        let answer = element("VisualAnswer0")
        reveal(answer)
        let emptyHeight = answer.frame.height
        answer.tap()
        answer.typeText(writing)
        XCTAssertEqual(answer.value as? String, writing)
        XCTAssertGreaterThan(answer.frame.height, emptyHeight * 3,
                             "Long writing must expand the row rather than stay in a clipped box")
        dismissKeyboard()
        let titleField = element("Title")
        reveal(titleField)
        titleField.tap()
        titleField.typeText(title)
        dismissKeyboard()
        saveForm()

        openSavedEntry(title)
        reveal(answer)
        XCTAssertEqual(answer.value as? String, writing)
        cancelForm()
        app.terminate()
        app.launch()
        openSavedEntry(title)
        reveal(answer)
        XCTAssertEqual(answer.value as? String, writing, "All lines must survive a normal relaunch")

        // The first line is deliberately short. A tap in the blank space to its right
        // positions the insertion point at that line's end, not at the end of the field.
        answer.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0))
            .withOffset(CGVector(dx: 0, dy: 10)).tap()
        app.typeText(" Updated.")
        let edited = firstLine + " Updated.\n" + remainder
        XCTAssertEqual(answer.value as? String, edited,
                       "Editing the first line must retain every following line")
        dismissKeyboard()
        saveForm()
        app.terminate()
        app.launch()
        openSavedEntry(title)
        reveal(answer)
        XCTAssertEqual(answer.value as? String, edited)
        XCTAssertEqual(element("VisualQuestion0").label, matrixQuestion)
        cancelForm()
    }

    func testUntouchedFormatChangesAndCancellationDoNotCreateAnEntry() {
        openForm()
        selectFormat("Summarize")
        let bar = app.navigationBars.firstMatch
        let start = bar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        start.press(forDuration: 0.05, thenDragTo:
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
        XCTAssertTrue(element("chargeFab").waitForExistence(timeout: 10))
        assertEmptyHome()
        app.terminate()
        app.launch()
        assertEmptyHome()

        openForm()
        selectFormat("Tables")
        cancelForm()
        assertEmptyHome()
    }

    private func openForm() {
        let fab = element("chargeFab")
        XCTAssertTrue(fab.waitForExistence(timeout: 20))
        let center = fab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.2, thenDragTo: center.withOffset(CGVector(dx: -120, dy: 0)))
        XCTAssertTrue(element("Theme").waitForExistence(timeout: 10))
    }

    private func selectFormat(_ name: String) {
        let picker = element("VisualFormat")
        reveal(picker)
        picker.tap()
        let choice = app.buttons[name].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        choice.tap()
        XCTAssertEqual(picker.value as? String, name)
    }

    private func openSavedEntry(_ title: String) {
        let saved = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label == %@", "cardTitleText-", title
        )).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 15))
        saved.tap()
        XCTAssertTrue(element("Theme").waitForExistence(timeout: 10))
    }

    private func saveForm() {
        app.buttons["Save"].tap()
        XCTAssertTrue(element("chargeFab").waitForExistence(timeout: 10))
    }

    private func cancelForm() {
        app.buttons["Cancel"].tap()
        XCTAssertTrue(element("chargeFab").waitForExistence(timeout: 10))
    }

    private func assertEmptyHome() {
        XCTAssertTrue(app.staticTexts["Nothing yet — tap + to add your first."].waitForExistence(timeout: 10),
                      "A blank template must not create a phantom entry")
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func reveal(_ target: XCUIElement, towardTopWhenMissing: Bool = false) {
        for _ in 0..<20 {
            let top = max(110, app.navigationBars.firstMatch.frame.maxY + 8)
            let keyboard = app.keyboards.firstMatch
            let share = element("shareForm")
            let bottom = share.exists && share.isHittable
                ? share.frame.minY - 12
                : (keyboard.exists ? keyboard.frame.minY - 20 : app.frame.height - 100)
            if target.exists && target.isHittable && target.frame.minY >= top && target.frame.maxY <= bottom {
                return
            }
            let exists = target.exists
            let frame = exists ? target.frame : .zero
            let down = exists ? frame.minY < top : towardTopWhenMissing
            let overflow = down ? top - frame.minY + 12 : frame.maxY - bottom + 12
            let distance = exists ? min(160, max(35, overflow)) : 160
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.4))
            start.press(forDuration: 0.05, thenDragTo:
                start.withOffset(CGVector(dx: 0, dy: down ? distance : -distance)))
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Entry form hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Entry field was not fully reachable")
    }

    private func dismissKeyboard() {
        let done = element("KeyboardRowDone")
        if done.exists && done.isHittable { done.tap() }
        else { app.navigationBars.firstMatch.tap() }
    }
}
