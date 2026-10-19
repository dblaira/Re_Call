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
        let cards = try await archive.save(data: bytes, title: "Tool poster", source: "example.com/tools", notes: "Try this brush.")
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
        print("PASS: original bytes, dimensions, source, notes, relaunch, edit identity, invalid imports, removal, corrupt-index preservation")
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
}
