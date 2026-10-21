import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

@main struct ProImageRuntimeTests {
    static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = ProImageArchive(directory: directory)
        let bytes = try fixture()
        let cards = try await archive.save(data: bytes, title: "Tool poster", source: "example.com/tools", notes: "Try this brush.").cards
        guard let card = cards.first else { fatalError("Saved card missing") }
        precondition(card.pixelWidth == 120 && card.pixelHeight == 240)
        precondition(card.source == "https://example.com/tools")
        let savedBytes = try Data(contentsOf: directory.appendingPathComponent(card.imageName))
        precondition(savedBytes == bytes, "Saving must preserve original image bytes")
        let reopened = try await ProImageArchive(directory: directory).load()
        precondition(reopened == cards, "Image identity, source and notes must survive relaunch")
        let edited = try await archive.update(card, title: "My title", source: card.source, notes: "Keep these details")
        precondition(edited.count == 1 && edited[0].id == card.id && edited[0].notes == "Keep these details")
        do {
            _ = try await archive.save(data: Data("not an image".utf8), title: "Bad", source: "", notes: "")
            fatalError("Invalid image was accepted")
        } catch ProImageError.unreadableImage { }
        do {
            _ = try await archive.save(data: bytes, title: "Bad URL", source: "javascript:alert(1)", notes: "")
            fatalError("Unsupported URL was accepted")
        } catch ProImageError.invalidSource { }
        let unchanged = try await archive.load()
        precondition(unchanged == edited, "Failed imports must leave saved cards unchanged")
        let remaining = try await archive.remove(card)
        precondition(remaining.isEmpty)
        precondition(!FileManager.default.fileExists(atPath: directory.appendingPathComponent(card.imageName).path))
        let corrupt = Data("broken index".utf8)
        try corrupt.write(to: directory.appendingPathComponent("cards.json"))
        do {
            _ = try await archive.save(data: bytes, title: "No overwrite", source: "", notes: "")
            fatalError("Corrupt index was silently replaced")
        } catch is DecodingError { }
        let preserved = try Data(contentsOf: directory.appendingPathComponent("cards.json"))
        precondition(preserved == corrupt)
        try await arrangementTests(bytes: bytes)
        try await freshRowImportTests(bytes: bytes)
        try await squareImportTests(bytes: bytes)
        print("PASS: original bytes, dimensions, source, notes, relaunch, edit identity, invalid imports, removal, corrupt-index preservation")
    }

    static func arrangementTests(bytes: Data) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = ProImageArchive(directory: directory)
        for number in 1...6 {
            _ = try await archive.save(data: bytes, title: "Image \(number)", source: "example.com", notes: "Keep \(number)")
        }
        let cards = try await archive.load()
        let ids = cards.map(\.id)
        let indexBytes = try Data(contentsOf: directory.appendingPathComponent("cards.json"))
        let initial = try await archive.loadArrangement()
        precondition(initial.areas.count == 1 && initial.areas[0].cardIDs == ids,
                     "A legacy collection must keep every image in its existing order, with no automatic rows")
        let firstAreaID = initial.areas[0].id
        let emptyRow = try await archive.arrange { $0.addRow(after: firstAreaID) }
        precondition(emptyRow.areas.count == 3 && emptyRow.areas[1].cardIDs.isEmpty,
                     "Add row must work on the first use, before an arrangement file exists")
        let emptyRowID = emptyRow.areas[1].id
        _ = try await archive.arrange { $0.removeRow(emptyRowID) }
        let shifted = try await archive.arrange { $0.shift(ids[1], by: -1) }
        precondition(shifted.areas[0].cardIDs == [ids[1], ids[0]] + Array(ids.dropFirst(2)))
        let split = try await archive.arrange { $0.startRow(at: ids[2]) }
        precondition(split.areas.count == 3)
        precondition(split.areas[0].cardIDs == [ids[1], ids[0]])
        precondition(split.areas[1].style == .row && split.areas[1].cardIDs == [ids[2]])
        precondition(split.areas[2].cardIDs == Array(ids.dropFirst(3)))
        let rowID = split.areas[1].id
        let moved = try await archive.arrange { $0.move(ids[5], to: rowID, before: ids[2]) }
        precondition(moved.areas[1].cardIDs == [ids[5], ids[2]])
        let secondRow = try await archive.arrange { $0.startRow(at: ids[4]) }
        precondition(secondRow.areas.filter { $0.style == .row }.count == 2)
        let reopened = try await ProImageArchive(directory: directory).loadArrangement()
        precondition(reopened == secondRow, "Area IDs, row membership and card order must survive relaunch")
        precondition(Set(reopened.areas.flatMap(\.cardIDs)) == Set(ids))
        precondition(reopened.areas.flatMap(\.cardIDs).count == ids.count, "Moving must never duplicate or lose cards")
        let unchangedIndex = try Data(contentsOf: directory.appendingPathComponent("cards.json"))
        precondition(unchangedIndex == indexBytes, "Arranging must not rewrite card metadata")
        for card in cards {
            let original = try Data(contentsOf: directory.appendingPathComponent(card.imageName))
            precondition(original == bytes, "Arranging must leave original image bytes intact")
        }
        let invalid = try await archive.arrange { $0.move(ids[0], to: UUID()) }
        precondition(invalid == reopened, "An invalid drop must leave the arrangement unchanged")
        let imported = try await archive.save(data: bytes, title: "New", source: "", notes: "").cards
        guard let newID = imported.first?.id else { fatalError("Missing import") }
        let withImport = try await archive.loadArrangement()
        precondition(withImport.areas[0].cardIDs.first == newID)
        precondition(withImport.areas[1].cardIDs == reopened.areas[1].cardIDs,
                     "New imports must not enter a user-selected row automatically")
        _ = try await archive.remove(cards[5])
        let afterRemoval = try await archive.loadArrangement()
        precondition(!afterRemoval.areas.flatMap(\.cardIDs).contains(ids[5]))
        let flattened = try await archive.arrange { $0.removeRow(rowID) }
        precondition(flattened.areas.flatMap(\.cardIDs) == afterRemoval.areas.flatMap(\.cardIDs),
                     "Changing a row to full-size cards must retain every position and image")
        precondition(flattened.areas.filter { $0.style == .row }.count == 1)
        let corruptLayout = Data("broken arrangement".utf8)
        try corruptLayout.write(to: directory.appendingPathComponent("arrangement.json"))
        do {
            _ = try await archive.arrange { $0.shift(ids[0], by: 1) }
            fatalError("A damaged arrangement was overwritten")
        } catch is DecodingError { }
        let retained = try Data(contentsOf: directory.appendingPathComponent("arrangement.json"))
        precondition(retained == corruptLayout)
        let readable = try await archive.load()
        precondition(readable.count == 6, "A damaged layout must not make the image collection unreadable")
        print("PASS: legacy order, manual rows, moves, separate metadata, multiple rows, relaunch, imports, removal, damaged-layout preservation")
    }

    static func freshRowImportTests(bytes: Data) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = ProImageArchive(directory: directory)
        let initial = try await archive.loadArrangement()
        let firstAreaID = initial.areas[0].id
        let empty = try await archive.arrange { $0.addRow(after: firstAreaID) }
        let rowID = empty.areas[1].id
        let first = try await archive.save(data: bytes, title: "Fresh photo", source: "example.com/new",
                                           notes: "Added directly", to: rowID)
        guard let firstCard = first.cards.first, let firstLayout = first.arrangement else {
            fatalError("Direct import must return the saved card and its destination")
        }
        precondition(firstLayout.areas[0].cardIDs.isEmpty, "Direct row imports must not land among the top cards")
        precondition(firstLayout.areas[1].cardIDs == [firstCard.id])
        precondition(firstCard.source == "https://example.com/new" && firstCard.notes == "Added directly")
        let original = try Data(contentsOf: directory.appendingPathComponent(firstCard.imageName))
        precondition(original == bytes)
        let second = try await archive.save(data: bytes, title: "Fresh file", source: "", notes: "", to: rowID)
        guard let secondID = second.cards.first?.id else { fatalError("Second import missing") }
        let reopened = try await ProImageArchive(directory: directory).loadArrangement()
        precondition(reopened.areas[1].cardIDs == [firstCard.id, secondID],
                     "Fresh imports must append to the chosen row and survive relaunch")
        let top = try await archive.save(data: bytes, title: "Header import", source: "", notes: "")
        let withTop = try await archive.loadArrangement()
        precondition(withTop.areas[0].cardIDs == [top.cards[0].id])
        precondition(withTop.areas[1].cardIDs == reopened.areas[1].cardIDs,
                     "The header's Add image must not inherit the previous row destination")
        let indexBefore = try Data(contentsOf: directory.appendingPathComponent("cards.json"))
        let filesBefore = try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
        do {
            _ = try await archive.save(data: bytes, title: "Invalid destination", source: "", notes: "", to: UUID())
            fatalError("A missing destination was silently redirected to the top")
        } catch ProImageError.missingRow { }
        let indexAfter = try Data(contentsOf: directory.appendingPathComponent("cards.json"))
        let filesAfter = try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
        precondition(indexAfter == indexBefore && filesAfter == filesBefore,
                     "A rejected destination must create no card or image file")
        _ = try await archive.arrange { $0.removeRow(rowID) }
        do {
            _ = try await archive.save(data: bytes, title: "Removed destination", source: "", notes: "", to: rowID)
            fatalError("An import was accepted after its row was removed")
        } catch ProImageError.missingRow { }
        print("PASS: fresh imports into empty and existing rows, exact bytes, append order, relaunch, independent header imports, missing destinations")
    }

    static func fixture() throws -> Data {
        guard let context = CGContext(data: nil, width: 120, height: 240, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let image = context.makeImage() else { throw ProImageError.unreadableImage }
        let bytes = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil) else {
            throw ProImageError.unreadableImage
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw ProImageError.unreadableImage }
        return bytes as Data
    }

    static func squareImportTests(bytes: Data) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = ProImageArchive(directory: directory)
        let first = try await archive.save(data: bytes, title: "Existing", source: "example.com", notes: "Keep")
        let originalID = first.cards[0].id
        let initial = try await archive.loadArrangement()
        let topID = initial.areas[0].id
        let empty = try await archive.arrange { $0.addSquare(after: topID) }
        guard let squareID = empty.areas.first(where: { $0.style == .square })?.id else {
            fatalError("Square missing")
        }
        let single = try await archive.arrange { $0.addSquare(after: topID) }
        precondition(single == empty, "Only one large square is added")
        let fresh = try await archive.save(data: bytes, title: "Fresh square", source: "", notes: "", to: squareID)
        let squareCard = fresh.cards[0]
        let reopened = try await ProImageArchive(directory: directory).loadArrangement()
        precondition(reopened.areas.first(where: { $0.id == squareID })?.cardIDs == [squareCard.id])
        precondition(reopened.areas[0].cardIDs == [originalID])
        let originalBytes = try Data(contentsOf: directory.appendingPathComponent(squareCard.imageName))
        precondition(originalBytes == bytes)
        let indexBefore = try Data(contentsOf: directory.appendingPathComponent("cards.json"))
        let filesBefore = try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
        do {
            _ = try await archive.save(data: bytes, title: "Must not replace", source: "", notes: "", to: squareID)
            fatalError("A second image was accepted into an occupied square")
        } catch ProImageError.squareOccupied { }
        let rejectedMove = try await archive.arrange { $0.move(originalID, to: squareID) }
        precondition(rejectedMove == reopened, "Moving into an occupied square must leave both images intact")
        let filesAfter = try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
        let indexAfter = try Data(contentsOf: directory.appendingPathComponent("cards.json"))
        precondition(filesBefore == filesAfter && indexBefore == indexAfter)
        _ = try await archive.arrange { $0.move(squareCard.id, to: topID) }
        let chosen = try await archive.arrange { $0.move(originalID, to: squareID) }
        precondition(chosen.areas.first(where: { $0.id == squareID })?.cardIDs == [originalID])
        let shifted = try await archive.arrange { $0.moveArea(squareID, by: 1) }
        precondition(shifted.areas.last?.id == squareID)
        let flattened = try await archive.arrange { $0.removeRow(squareID) }
        precondition(flattened.areas.flatMap(\.cardIDs) == shifted.areas.flatMap(\.cardIDs))
        precondition(flattened.areas.allSatisfy { $0.style == .grid })
        do {
            _ = try await archive.save(data: bytes, title: "Removed square", source: "", notes: "", to: squareID)
            fatalError("A removed square accepted an import")
        } catch ProImageError.missingRow { }
        print("PASS: single square, fresh and chosen images, occupied-slot protection, exact bytes, relaunch, placement and removal")
    }
}
