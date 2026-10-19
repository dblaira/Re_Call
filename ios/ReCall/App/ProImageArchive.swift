import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ProImageCard: Codable, Identifiable, Equatable {
    let id: UUID
    let imageName: String
    let pixelWidth: Int
    let pixelHeight: Int
    let createdAt: Date
    var title: String
    var source: String
    var notes: String

    var aspectRatio: CGFloat { CGFloat(pixelWidth) / CGFloat(max(1, pixelHeight)) }
    var sourceURL: URL? { source.isEmpty ? nil : URL(string: source) }
}

enum ProImageError: LocalizedError {
    case unreadableImage, imageTooLarge, invalidSource, missingCard, titleSaveFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage: return "This image couldn’t be opened. Choose another image."
        case .imageTooLarge: return "This image is too large. Choose an image under 80 MB and 120 megapixels."
        case .invalidSource: return "Enter a website address for the source, or leave it empty."
        case .missingCard: return "This saved image is no longer in Pro."
        case .titleSaveFailed: return "The title couldn’t be saved. Try Save again."
        }
    }
}

/// Original image bytes and their metadata live together, independently of reminders.
/// Serial writes and an atomic index keep a failed import from creating a broken card.
actor ProImageArchive {
    let directory: URL
    private var indexURL: URL { directory.appendingPathComponent("cards.json") }

    init(directory: URL) { self.directory = directory }

    func load() throws -> [ProImageCard] {
        guard FileManager.default.fileExists(atPath: indexURL.path) else { return [] }
        return try JSONDecoder().decode([ProImageCard].self, from: Data(contentsOf: indexURL))
    }

    func save(data: Data, title: String, source: String, notes: String) throws -> [ProImageCard] {
        let dimensions = try Self.dimensions(data)
        let source = try Self.normalizedSource(source)
        var cards = try load()
        let id = UUID()
        let imageSource = CGImageSourceCreateWithData(data as CFData, nil)
        let typeID = imageSource.flatMap { CGImageSourceGetType($0) } as String?
        let suffix = typeID.flatMap { UTType($0)?.preferredFilenameExtension } ?? "image"
        let name = id.uuidString + "." + suffix
        let card = ProImageCard(id: id, imageName: name, pixelWidth: dimensions.width,
                                pixelHeight: dimensions.height, createdAt: Date(),
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                source: source, notes: notes)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let imageURL = directory.appendingPathComponent(name)
        try data.write(to: imageURL, options: .atomic)
        cards.insert(card, at: 0)
        do { try persist(cards) }
        catch {
            try? FileManager.default.removeItem(at: imageURL)
            throw error
        }
        return cards
    }

    func update(_ card: ProImageCard, title: String, source: String, notes: String) throws -> [ProImageCard] {
        var cards = try load()
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { throw ProImageError.missingCard }
        cards[index].title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        cards[index].source = try Self.normalizedSource(source)
        cards[index].notes = notes
        try persist(cards)
        return cards
    }

    func remove(_ card: ProImageCard) throws -> [ProImageCard] {
        let cards = try load().filter { $0.id != card.id }
        try persist(cards)
        // A leftover image is recoverable; an index pointing at a deleted image is not.
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(card.imageName))
        return cards
    }

    private func persist(_ cards: [ProImageCard]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(cards).write(to: indexURL, options: .atomic)
    }

    static func dimensions(_ data: Data) throws -> (width: Int, height: Int) {
        guard data.count <= 80 * 1_024 * 1_024 else { throw ProImageError.imageTooLarge }
        guard let image = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else { throw ProImageError.unreadableImage }
        guard Double(width) * Double(height) <= 120_000_000 else { throw ProImageError.imageTooLarge }
        // Verify the bytes decode, without allocating the full poster during import.
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                       kCGImageSourceThumbnailMaxPixelSize: 64,
                                       kCGImageSourceCreateThumbnailWithTransform: true]
        guard CGImageSourceCreateThumbnailAtIndex(image, 0, options as CFDictionary) != nil else {
            throw ProImageError.unreadableImage
        }
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        return (5...8).contains(orientation) ? (height, width) : (width, height)
    }

    static func normalizedSource(_ value: String) throws -> String {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "" }
        let address = text.contains(":") ? text : "https://" + text
        guard let url = URL(string: address), ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty, !text.contains(where: { $0.isWhitespace }) else {
            throw ProImageError.invalidSource
        }
        return url.absoluteString
    }
}
