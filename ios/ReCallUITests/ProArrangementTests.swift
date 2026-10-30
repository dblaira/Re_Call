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
        let firstID = title("Poster 3", in: row).identifier
            .replacingOccurrences(of: "cardTitleText-pro-image:", with: "proImageCard-")
        menu("Poster 4")
        app.buttons["Move to Row 1"].tap()
        XCTAssertTrue(title("Poster 4", in: row).waitForExistence(timeout: 5))
        let secondID = title("Poster 4", in: row).identifier
            .replacingOccurrences(of: "cardTitleText-pro-image:", with: "proImageCard-")
        for number in 5...7 {
            menu("Poster \(number)")
            app.buttons["Move to Row 1"].tap()
        }
        reveal(row, up: false)
        row.swipeRight(velocity: .slow)
        app.buttons["proArrange"].tap()
        XCTAssertFalse(app.staticTexts["Carousel"].exists)
        XCTAssertFalse(app.staticTexts["Row 1"].exists, "The horizontal row must have no visible heading while browsing")
        let firstCard = row.descendants(matching: .any).matching(identifier: firstID).firstMatch
        let secondCard = row.descendants(matching: .any).matching(identifier: secondID).firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        XCTAssertTrue(secondCard.waitForExistence(timeout: 5))
        let originalSize = firstCard.frame.size
        XCTAssertEqual(firstCard.frame.width, 90, accuracy: 1)
        XCTAssertEqual(firstCard.frame.height, 135, accuracy: 1)
        XCTAssertEqual(secondCard.frame.size, originalSize,
                       "Pinterest carousel thumbnails must have identical 2:3 frames for different source proportions")
        XCTAssertLessThan(firstCard.frame.minX, secondCard.frame.minX)
        attach("Matching Pinterest thumbnails without caption panels")
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        reveal(firstCard)
        XCTAssertTrue(secondCard.exists)
        XCTAssertLessThan(firstCard.frame.minX, secondCard.frame.minX)
        XCTAssertEqual(firstCard.frame.width, originalSize.width, accuracy: 1,
                       "Pinterest sizing must stay stable across relaunch")
        XCTAssertEqual(firstCard.frame.height, originalSize.height, accuracy: 1)
        let addImage = row.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "proRowAddImage-")).firstMatch
        XCTAssertTrue(!addImage.exists || addImage.frame.minX >= app.frame.maxX,
                      "Add image must start beyond the screen so the next swipe proves real horizontal scrolling")
        row.swipeLeft(velocity: .slow)
        XCTAssertTrue(addImage.isHittable)
        XCTAssertLessThanOrEqual(addImage.frame.maxX, app.frame.maxX,
                                 "A horizontal swipe must fully reveal the row's Add image card")
        attach("Native horizontal swipe reveals Add image")
        row.swipeRight(velocity: .slow)
        firstCard.tap()
        XCTAssertTrue(app.buttons["proClosePoster"].waitForExistence(timeout: 5))
        app.buttons["proClosePoster"].tap()
        XCTAssertTrue(firstCard.isHittable, "Closing the image must return to the same row")
        firstCard.press(forDuration: 0.6)
        let field = app.descendants(matching: .any).matching(identifier: "cardTitleField").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Holding a thumbnail must still allow inline title editing")
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        keyboard.keys["s"].tap()
        XCTAssertEqual(field.value as? String, "Poster 3s")
        keyboard.buttons["Done"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5))
        XCTAssertEqual(firstCard.frame.height, 135, accuracy: 1)
        attach("Chosen row and order survive relaunch and image viewing")
    }

    func testLargeSquareAcceptsOneChosenImageAndPersists() {
        app.buttons["proArrange"].tap()
        let addSquare = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "proAddSquare-")).firstMatch
        reveal(addSquare)
        addSquare.tap()
        let square = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "proSquare-")).firstMatch
        let addImage = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "proSquareAddImage-")).firstMatch
        reveal(addImage)
        let addImageID = addImage.identifier
        app.buttons["proArrange"].tap()
        XCTAssertEqual(addImage.frame.width, app.frame.width - 8, accuracy: 1)
        XCTAssertEqual(addImage.frame.height, addImage.frame.width, accuracy: 1)
        func openAddImageMenu() {
            let menu = app.descendants(matching: .any).matching(identifier: addImageID).firstMatch
            XCTAssertTrue(menu.waitForExistence(timeout: 10))
            reveal(menu)
            menu.tap()
            for choice in ["Photo Library", "Choose File", "Choose saved image"] {
                XCTAssertTrue(app.buttons[choice].waitForExistence(timeout: 5),
                              "The square's Add image menu must offer \(choice)")
            }
        }
        func cancelPicker() {
            let cancel = app.buttons["Cancel"].firstMatch
            XCTAssertTrue(cancel.waitForExistence(timeout: 10))
            cancel.tap()
            XCTAssertTrue(cancel.waitForNonExistence(timeout: 10),
                          "The picker must finish dismissing before reopening Add image")
        }
        openAddImageMenu()
        app.buttons["Photo Library"].tap()
        cancelPicker()
        openAddImageMenu()
        app.buttons["Choose File"].tap()
        cancelPicker()
        openAddImageMenu()
        app.buttons["Choose saved image"].tap()
        let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label == %@",
                                                     "proChooseSquareImage-", "Poster 2")).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        let cardID = choice.identifier.replacingOccurrences(of: "proChooseSquareImage-", with: "cardHold-pro-image:")
        choice.tap()
        let image = square.descendants(matching: .any).matching(identifier: cardID).firstMatch
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        reveal(image)
        XCTAssertEqual(image.frame.width, app.frame.width - 8, accuracy: 1)
        XCTAssertEqual(image.frame.height, image.frame.width, accuracy: 1)
        XCTAssertFalse(addImage.exists, "An occupied square holds one image")
        attach("One large square breaks up the collection")
        image.tap()
        XCTAssertTrue(app.buttons["proClosePoster"].waitForExistence(timeout: 5))
        app.buttons["proClosePoster"].tap()
        XCTAssertTrue(image.isHittable)
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        reveal(image)
        XCTAssertEqual(image.frame.height, image.frame.width, accuracy: 1)
        attach("Chosen square image and placement survive relaunch")
        reveal(title("Poster 1"), up: false)
        XCTAssertTrue(title("Poster 1").isHittable)
    }

    func testCarouselsMoveAroundSquareAndKeepMembershipAfterRelaunch() {
        app.buttons["proArrange"].tap()
        menu("Poster 1")
        app.buttons["proStartRow"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let firstID = row.identifier
        let first = app.scrollViews[firstID]
        menu("Poster 2")
        app.buttons["proStartRow"].tap()
        let rows = app.scrollViews.matching(NSPredicate(format: "identifier BEGINSWITH %@", "proRow-"))
        XCTAssertEqual(rows.count, 2)
        let secondID = rows.element(boundBy: 1).identifier
        let second = app.scrollViews[secondID]
        menu("Poster 3")
        app.buttons["Move to Row 2"].tap()
        let addSquare = app.buttons[firstID.replacingOccurrences(of: "proRow-", with: "proAddSquare-")]
        reveal(addSquare, up: false)
        addSquare.tap()
        let square = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "proSquare-")).firstMatch
        XCTAssertTrue(square.waitForExistence(timeout: 5))
        let later = app.buttons[firstID.replacingOccurrences(of: "proRow-", with: "proRowLater-")]
        reveal(later, up: false)
        later.tap()
        XCTAssertLessThan(square.frame.minY, first.frame.minY,
                          "The whole carousel must move below the square")
        reveal(first)
        attach("Carousel moved below the large square")
        let earlier = app.buttons[firstID.replacingOccurrences(of: "proRow-", with: "proRowEarlier-")]
        reveal(earlier, up: false)
        earlier.tap()
        XCTAssertLessThan(first.frame.minY, square.frame.minY)
        let secondEarlier = app.buttons[secondID.replacingOccurrences(of: "proRow-", with: "proRowEarlier-")]
        reveal(secondEarlier)
        // Pass the two empty card areas, the square, and the first carousel.
        for _ in 0..<4 {
            reveal(secondEarlier, up: false)
            secondEarlier.tap()
        }
        XCTAssertLessThan(second.frame.minY, first.frame.minY,
                          "A carousel must be able to pass another carousel")
        XCTAssertLessThan(first.frame.minY, square.frame.minY)
        XCTAssertTrue(title("Poster 1", in: first).exists)
        XCTAssertTrue(title("Poster 2", in: second).exists)
        XCTAssertTrue(title("Poster 3", in: second).exists)
        XCTAssertLessThan(title("Poster 2", in: second).frame.minX, title("Poster 3", in: second).frame.minX)
        app.buttons["proArrange"].tap()
        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        app.buttons["proArrange"].tap()
        XCTAssertTrue(second.waitForExistence(timeout: 5))
        XCTAssertLessThan(second.frame.minY, first.frame.minY)
        XCTAssertLessThan(first.frame.minY, square.frame.minY)
        XCTAssertTrue(title("Poster 1", in: first).exists)
        XCTAssertTrue(title("Poster 2", in: second).exists)
        XCTAssertTrue(title("Poster 3", in: second).exists)
        XCTAssertLessThan(title("Poster 2", in: second).frame.minX, title("Poster 3", in: second).frame.minX)
        attach("Carousel placement and image order survive relaunch")
        reveal(title("Poster 7"))
        XCTAssertTrue(title("Poster 7").isHittable)
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

    func testArrangeRemovalConfirmsAcrossCardsCarouselAndSquare() {
        app.buttons["proArrange"].tap()
        let confirmation = app.staticTexts["Remove this image from Pro?"]
        func requestRemoval(_ name: String) {
            menu(name)
            app.buttons["Remove image"].tap()
            XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["proClosePoster"].exists,
                           "Removing in Arrange must not open the image viewer")
        }
        func confirmRemoval(_ name: String) {
            requestRemoval(name)
            app.buttons["Remove image"].tap()
            XCTAssertTrue(title(name).waitForNonExistence(timeout: 5))
            XCTAssertEqual(app.buttons["proArrange"].label, "Done",
                           "Removing an image must keep Arrange active")
        }

        requestRemoval("Poster 1")
        attach("Remove image is available directly in Arrange with confirmation")
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.3)).tap()
        }
        XCTAssertTrue(confirmation.waitForNonExistence(timeout: 5))
        XCTAssertTrue(title("Poster 1").exists, "Cancel must preserve the selected image")
        confirmRemoval("Poster 1")
        XCTAssertTrue(title("Poster 2").exists, "Removal must preserve the neighboring image")

        menu("Poster 2")
        app.buttons["proStartRow"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let rowID = row.identifier
        confirmRemoval("Poster 2")
        let rowAdd = app.buttons[rowID.replacingOccurrences(of: "proRow-", with: "proRowAddImage-")]
        XCTAssertTrue(rowAdd.exists, "Removing the final carousel image must leave Add image available")

        let addSquare = app.buttons[rowID.replacingOccurrences(of: "proRow-", with: "proAddSquare-")]
        reveal(addSquare)
        addSquare.tap()
        let squareAdd = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "proSquareAddImage-")).firstMatch
        reveal(squareAdd)
        squareAdd.tap()
        app.buttons["Choose saved image"].tap()
        let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label == %@",
                                                     "proChooseSquareImage-", "Poster 3")).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        choice.tap()
        confirmRemoval("Poster 3")
        XCTAssertTrue(squareAdd.waitForExistence(timeout: 5),
                      "Removing the square's image must leave its container ready for another image")
        attach("Removing an image preserves the square and Arrange controls")

        app.terminate(); app.launch(); app.buttons["PRO"].tap()
        app.buttons["proArrange"].tap()
        XCTAssertTrue(rowAdd.waitForExistence(timeout: 5))
        reveal(squareAdd)
        XCTAssertTrue(squareAdd.exists)
        for number in 4...7 {
            reveal(title("Poster \(number)"))
            XCTAssertTrue(title("Poster \(number)").exists,
                          "Every unselected image must survive removal and relaunch")
        }
        for number in 1...3 {
            XCTAssertFalse(title("Poster \(number)").exists)
        }
        attach("Arrange removals persist and preserve all unselected images")
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
