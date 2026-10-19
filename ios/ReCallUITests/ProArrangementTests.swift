import XCTest

final class ProArrangementTests: XCTestCase {
    private let app = XCUIApplication()
    private var scroll: XCUIElement { app.scrollViews["proSavedImages"] }
    private var row: XCUIElement {
        app.scrollViews.matching(NSPredicate(format: "identifier BEGINSWITH %@", "proRow-")).firstMatch
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED", "RECALL_UI_TEST_PRO_IMAGES"]
        app.launchEnvironment["RECALL_UI_TEST_SESSION"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["PRO"].waitForExistence(timeout: 20))
        app.buttons["PRO"].tap()
        XCTAssertTrue(title("Poster 1").waitForExistence(timeout: 20))
    }

    private func title(_ text: String, in parent: XCUIElement? = nil) -> XCUIElement {
        (parent ?? app).descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label == %@", "cardTitleText-pro-image:", text)).firstMatch
    }

    private func reveal(_ element: XCUIElement, up: Bool = true) {
        for _ in 0..<10 {
            if element.exists && element.isHittable && element.frame.maxY < app.frame.height - 130
                && element.frame.minY > 115 { return }
            if up { scroll.swipeUp(velocity: .slow) } else { scroll.swipeDown(velocity: .slow) }
        }
        XCTAssertTrue(element.isHittable, "The requested card must be reachable by scrolling")
    }

    private func menu(_ text: String) {
        let button = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label == %@",
                                                      "proMove-", "Move " + text)).firstMatch
        reveal(button)
        button.tap()
    }

    private func attach(_ name: String) {
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = name; image.lifetime = .keepAlways; add(image)
    }

    func testChosenRowMembershipAndOrderSurviveRelaunch() {
        XCTAssertFalse(row.exists, "An existing collection must not have cards automatically assigned to a row")
        app.buttons["proArrange"].tap()
        menu("Poster 3")
        app.buttons["proStartRow"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(title("Poster 3", in: row).exists)
        menu("Poster 4")
        app.buttons["Move to Row 1"].tap()
        XCTAssertTrue(title("Poster 4", in: row).waitForExistence(timeout: 5))
        let first = title("Poster 3", in: row)
        let second = title("Poster 4", in: row)
        XCTAssertLessThan(first.frame.minX, second.frame.minX)
        app.buttons["proArrange"].tap()
        XCTAssertFalse(app.staticTexts["Carousel"].exists)
        XCTAssertFalse(app.staticTexts["Row 1"].exists, "The horizontal row must have no visible heading while browsing")
        let firstCard = row.descendants(matching: .any).matching(identifier:
            first.identifier.replacingOccurrences(of: "cardTitleText-pro-image:", with: "proImageCard-")).firstMatch
        let secondCard = row.descendants(matching: .any).matching(identifier:
            second.identifier.replacingOccurrences(of: "cardTitleText-pro-image:", with: "proImageCard-")).firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        XCTAssertTrue(secondCard.waitForExistence(timeout: 5))
        let originalSize = firstCard.frame.size
        XCTAssertGreaterThan(abs(firstCard.frame.height - secondCard.frame.height), 20,
                             "Different image proportions must remain visibly different lengths in a carousel")
        attach("Only the chosen cards occupy the unlabelled smaller row")
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        reveal(first)
        XCTAssertTrue(second.exists)
        XCTAssertLessThan(first.frame.minX, second.frame.minX)
        XCTAssertEqual(firstCard.frame.width, originalSize.width, accuracy: 1,
                       "Varied sizes must stay stable across relaunch")
        XCTAssertEqual(firstCard.frame.height, originalSize.height, accuracy: 1)
        let addImage = row.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "proRowAddImage-")).firstMatch
        row.swipeLeft(velocity: .slow)
        XCTAssertTrue(addImage.isHittable)
        XCTAssertLessThanOrEqual(addImage.frame.maxX, app.frame.maxX,
                                 "A horizontal swipe must fully reveal the row's Add image card")
        attach("Native horizontal swipe reveals Add image")
        row.swipeRight(velocity: .slow)
        first.tap()
        XCTAssertTrue(app.buttons["proClosePoster"].waitForExistence(timeout: 5))
        app.buttons["proClosePoster"].tap()
        XCTAssertTrue(first.isHittable, "Closing the image must return to the same row")
        attach("Chosen row and order survive relaunch and image viewing")
    }

    func testNativeDragReordersCardsAndKeepsVerticalScroll() {
        app.buttons["proArrange"].tap()
        let firstID = title("Poster 1").identifier.replacingOccurrences(of: "cardTitleText-pro-image:", with: "")
        let secondID = title("Poster 2").identifier.replacingOccurrences(of: "cardTitleText-pro-image:", with: "")
        let first = app.descendants(matching: .any).matching(identifier: "proArrangeCard-" + firstID).firstMatch
        let second = app.descendants(matching: .any).matching(identifier: "proArrangeCard-" + secondID).firstMatch
        XCTAssertLessThan(first.frame.minX, second.frame.minX)
        second.press(forDuration: 1.1, thenDragTo: first)
        let moved = NSPredicate { _, _ in second.frame.minX < first.frame.minX }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: moved, object: second)], timeout: 8), .completed)
        attach("Native drag changes the first two card positions")
        reveal(title("Poster 7"))
        XCTAssertTrue(title("Poster 7").isHittable, "Arrange must still allow vertical page scrolling")
        app.buttons["proArrange"].tap()
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        XCTAssertLessThan(title("Poster 2").frame.minX, title("Poster 1").frame.minX)
        attach("Dragged order persists after relaunch")
    }

    func testEmptyRowOffersFreshPhotoAndFileImports() {
        app.terminate()
        app.launchArguments = ["RECALL_UI_TEST_ISOLATED"]
        app.launchEnvironment["RECALL_UI_TEST_SESSION"] = UUID().uuidString
        app.launch()
        app.buttons["PRO"].tap()
        XCTAssertTrue(app.buttons["proFirstImage"].waitForExistence(timeout: 10))
        app.buttons["proArrange"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "proAddRow-")).firstMatch.tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        app.buttons["proArrange"].tap()
        let add = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "proRowAddImage-")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5), "An empty row must allow a fresh image without an existing Pro card")
        add.tap()
        XCTAssertTrue(app.buttons["Choose File"].exists)
        app.buttons["Photo Library"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10), "The row must open the system photo picker")
        attach("Empty row opens Photo Library for a fresh image")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        app.buttons["Choose File"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10), "The row must open the system file picker")
        attach("Empty row opens Files for a fresh image")
        app.buttons["Cancel"].tap()
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        XCTAssertTrue(add.waitForExistence(timeout: 10), "The empty row must remain available after cancelling and relaunching")
        XCTAssertFalse(app.buttons["proFirstImage"].exists)
        attach("Empty row remains ready for fresh images after relaunch")
    }
}
