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
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED"]
        app.launch()
        dismissNotificationPrompt()
        XCTAssertTrue(app.staticTexts["Understood"].waitForExistence(timeout: 20),
                      "Native Reminders did not render (brand title missing)")
        XCTAssertTrue(app.buttons["chargeFab"].waitForExistence(timeout: 10), "Charge FAB missing")
    }

    func testProTabOpensProfessionalTemplates() {
        let app = XCUIApplication()
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED"]
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
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED"]
        app.launch()
        dismissNotificationPrompt()
        openReminderForm(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "Title").firstMatch.waitForExistence(timeout: 10),
                      "Entry form did not open from the charge FAB")
    }

    func testCreatingAReminderShowsItInTheList() {
        let app = XCUIApplication()
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED"]
        app.launch()
        dismissNotificationPrompt()
        openReminderForm(app)
        let title = app.descendants(matching: .any).matching(identifier: "Title").firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        title.tap()
        title.typeText("Smoke test reminder")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Smoke test reminder"].waitForExistence(timeout: 10),
                      "Created reminder did not appear in Up Next")
    }
    func testAddingMultipleStepsKeepsEachStepVisible() {
        let app = XCUIApplication()
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED"]
        app.launch()
        dismissNotificationPrompt()
        openReminderForm(app)

        let addStep = app.buttons["Add Step"]
        for _ in 0..<12 {
            if addStep.exists && addStep.isHittable && addStep.frame.midY > 200 && addStep.frame.midY < 550 { break }
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -130)))
        }
        XCTAssertTrue(addStep.isHittable)
        addStep.tap()

        let firstStep = app.descendants(matching: .any).matching(identifier: "Step").firstMatch
        XCTAssertTrue(firstStep.waitForExistence(timeout: 5))
        firstStep.tap()
        firstStep.typeText("First step")

        for _ in 0..<12 {
            if addStep.exists && addStep.isHittable && addStep.frame.midY > 200 && addStep.frame.midY < 550 { break }
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -130)))
        }
        XCTAssertTrue(addStep.isHittable)
        addStep.tap()
        let steps = app.descendants(matching: .any).matching(identifier: "Step")
        XCTAssertEqual(steps.count, 2)
        XCTAssertEqual(firstStep.value as? String, "First step")

        let removeSteps = app.buttons.matching(identifier: "removeStep")
        XCTAssertEqual(removeSteps.count, 2)
        removeSteps.element(boundBy: 0).tap()
        XCTAssertEqual(steps.count, 1)

        let title = app.descendants(matching: .any).matching(identifier: "Title").firstMatch
        title.tap()
        title.typeText("Step regression")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Step regression"].waitForExistence(timeout: 10))
    }

    func testThemeAndPersistentDelegateWithLongAnswers() {
        let app = XCUIApplication()
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED"]
        app.launch()
        dismissNotificationPrompt()
        openReminderForm(app)
        let theme = app.buttons["Theme"]
        XCTAssertTrue(theme.waitForExistence(timeout: 10))
        for destination in ["Action", "Event", "Reminder"] {
            app.segmentedControls.buttons[destination].tap()
            XCTAssertTrue(theme.exists, "Theme must remain available for every entry type")
        }
        app.segmentedControls.buttons["Action"].tap()
        theme.tap()
        let choice = app.buttons["Problem → Solution"]
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        choice.tap()
        let themeAnswer = app.descendants(matching: .any).matching(identifier: "themeAnswer0").firstMatch
        XCTAssertTrue(themeAnswer.waitForExistence(timeout: 5))
        themeAnswer.tap()
        themeAnswer.typeText("My exact theme answer")
        let themeShot = XCTAttachment(screenshot: app.screenshot())
        themeShot.name = "Action with SAVY theme"
        themeShot.lifetime = .keepAlways
        add(themeShot)

        let title = app.descendants(matching: .any).matching(identifier: "Title").firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        let initialHeight = title.frame.height
        let longAnswer = "Full answer test " + UUID().uuidString + "\n"
            + (1...8).map { "Line \($0): I can see all the words I enter." }.joined(separator: "\n")
        title.typeText(longAnswer)
        XCTAssertEqual(title.value as? String, longAnswer)
        XCTAssertGreaterThan(title.frame.height, initialHeight * 3,
                             "The field must expand rather than clip or scroll within three lines")
        XCTAssertTrue(app.staticTexts["What do I want?"].exists,
                      "The question must remain after typing an answer")
        let when = app.descendants(matching: .any).matching(identifier: "WhenIAm").firstMatch
        when.tap()
        when.typeText("Learning something unfamiliar")
        XCTAssertTrue(app.staticTexts["When I am...I like to"].exists)
        let outcome = app.descendants(matching: .any).matching(identifier: "Outcome").firstMatch
        outcome.tap()
        outcome.typeText("The full question and answer stay visible")
        XCTAssertTrue(app.staticTexts["Done looks like..."].exists)
        let delegateShot = XCTAttachment(screenshot: app.screenshot())
        delegateShot.name = "Persistent Delegate questions and full answers"
        delegateShot.lifetime = .keepAlways
        add(delegateShot)
        app.buttons["Save"].tap()
        let saved = app.staticTexts.matching(NSPredicate(format: "label == %@", longAnswer)).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 10))
        saved.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "Title").firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "Title").firstMatch.value as? String, longAnswer)
        XCTAssertTrue((app.descendants(matching: .any).matching(identifier: "themeAnswer0").firstMatch.value as? String ?? "").contains("My exact theme answer"))
        app.buttons["Cancel"].tap()
    }

}
