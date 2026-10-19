import SwiftUI
import ImageIO

@MainActor
final class ProImageStore: ObservableObject {
    @Published private(set) var cards: [ProImageCard] = []
    let directory: URL
    private let archive: ProImageArchive

    init() {
        directory = ICloudReminderCache.localURL(fileName: "pro-library")
        archive = ProImageArchive(directory: directory)
    }

    func refresh() async throws { cards = try await archive.load() }

    func save(data: Data, title: String, source: String, notes: String) async throws {
        cards = try await archive.save(data: data, title: title, source: source, notes: notes)
    }

    func update(_ card: ProImageCard, title: String, source: String, notes: String) async throws {
        cards = try await archive.update(card, title: title, source: source, notes: notes)
        // Details edits become the image's base title. Retire any earlier inline
        // override so it cannot hide the title the user has just saved.
        if CardTitleStore.shared.titles[card.cardTitle.id] != nil,
           !CardTitleStore.shared.restoreOriginal(card.cardTitle) {
            throw ProImageError.titleSaveFailed
        }
    }

    func remove(_ card: ProImageCard) async throws { cards = try await archive.remove(card) }

    func url(for card: ProImageCard) -> URL { directory.appendingPathComponent(card.imageName) }
}

/// Decode off the UI thread and only at the resolution needed by the current surface.
enum ProImageLoader {
    static func load(url: URL, maxPixelSize: Int) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            return thumbnail(source: source, maxPixelSize: maxPixelSize)
        }.value
    }

    static func preview(data: Data) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            _ = try ProImageArchive.dimensions(data)
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = thumbnail(source: source, maxPixelSize: 1_200) else {
                throw ProImageError.unreadableImage
            }
            return image
        }.value
    }

    private static func thumbnail(source: CGImageSource, maxPixelSize: Int) -> UIImage? {
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                       kCGImageSourceCreateThumbnailWithTransform: true,
                                       kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                                       kCGImageSourceShouldCacheImmediately: true]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}
