import Foundation
import Combine

/// A display title belongs to the saved card, independently of its original writing.
struct CardTitle: Equatable {
    let id: String
    let original: String
    var fallback: String { original.isEmpty ? "Untitled" : original }

    static func reminder(_ reminder: Reminder, title: String? = nil) -> Self {
        Self(id: "reminder:\(reminder.id.uuidString)", original: title ?? reminder.title)
    }
}

struct CardTitleOverride: Codable, Equatable {
    let title: String
    let modifiedAt: Date
}

/// A separate document preserves the original entry and template. Older builds
/// never write this file. Each title merges independently through iCloud Documents.
@MainActor
final class CardTitleStore: ObservableObject {
    static let shared = CardTitleStore()
    @Published private(set) var titles: [String: CardTitleOverride] = [:]
    private let localURL: URL
    private let cloudURL: () -> URL?

    init(localURL: URL? = nil, cloudURL: (() -> URL?)? = nil) {
        self.localURL = localURL ?? ICloudReminderCache.localURL(fileName: "card-titles.json")
        self.cloudURL = cloudURL ?? { ICloudReminderCache.iCloudDocumentsURL(fileName: "card-titles.json") }
        refresh()
    }

    func title(for card: CardTitle, fallback: String? = nil) -> String {
        guard let title = titles[card.id]?.title, !title.isEmpty else { return fallback ?? card.fallback }
        return title
    }

    @discardableResult
    func rename(_ card: CardTitle, to title: String) -> Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard self.title(for: card) != title else { return true }
        return save(title, for: card)
    }

    @discardableResult
    func restoreOriginal(_ card: CardTitle) -> Bool {
        // An empty value carries an intentional reset to the other device.
        save("", for: card)
    }

    func refresh() {
        let local = read(localURL)
        let cloud = cloudURL()
        if let cloud { try? FileManager.default.startDownloadingUbiquitousItem(at: cloud) }
        let cloudTitles = cloud.map(read) ?? [:]
        let merged = Self.merge(local, cloudTitles)
        if merged != local, !persist(merged, to: localURL) { return }
        if merged != titles { titles = merged }
        // Retry edits made offline when iCloud becomes available again.
        if let cloud, merged != cloudTitles { _ = persist(merged, to: cloud) }
    }

    private func save(_ title: String, for card: CardTitle) -> Bool {
        let cloud = cloudURL()
        var updated = Self.merge(titles, cloud.map(read) ?? [:])
        let timestamp = max(Date(), (updated[card.id]?.modifiedAt ?? .distantPast).addingTimeInterval(0.001))
        updated[card.id] = CardTitleOverride(title: title, modifiedAt: timestamp)
        guard persist(updated, to: localURL) else { return false }
        titles = updated
        if let cloud { _ = persist(updated, to: cloud) }
        return true
    }

    static func merge(_ local: [String: CardTitleOverride], _ cloud: [String: CardTitleOverride]) -> [String: CardTitleOverride] {
        local.merging(cloud) { $0.modifiedAt >= $1.modifiedAt ? $0 : $1 }
    }

    private func read(_ url: URL) -> [String: CardTitleOverride] {
        guard let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([String: CardTitleOverride].self, from: data) else { return [:] }
        return records
    }

    private func persist(_ records: [String: CardTitleOverride], to url: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(records).write(to: url, options: .atomic)
            return true
        } catch {
            NSLog("Understood card title save failed: %@", error.localizedDescription)
            return false
        }
    }
}
