import Foundation

/// Every item type (Reminder, Action, Event) lives in one JSON file on the phone, then the same
/// file is copied to iCloud Documents (uses the device's iCloud account — no login UI in the app).
enum ICloudReminderCache {
    static let fileName = "reminders.json"
    static let containerID = "iCloud.app.understood.recall"

    static func load() -> [Reminder] {
        let local = decode(readData(from: localURL()))
        guard let cloudURL = iCloudDocumentsURL() else { return local }
        try? FileManager.default.startDownloadingUbiquitousItem(at: cloudURL)
        let cloud = decode(readData(from: cloudURL))
        return merge(local, cloud)
    }

    static func save(_ reminders: [Reminder]) {
        guard let data = try? JSONEncoder.recall.encode(reminders) else { return }
        write(data, to: localURL())
        if let cloudURL = iCloudDocumentsURL() {
            write(data, to: cloudURL)
        }
    }

    // MARK: - paths

    private static func localURL() -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    private static func iCloudDocumentsURL() -> URL? {
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: containerID) else {
            return nil
        }
        let docs = container.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return docs.appendingPathComponent(fileName)
    }

    // MARK: - IO

    private static func readData(from url: URL) -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    private static func write(_ data: Data, to url: URL) {
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private static func decode(_ data: Data?) -> [Reminder] {
        guard let data, let decoded = try? JSONDecoder.recall.decode([Reminder].self, from: data) else {
            return []
        }
        return decoded
    }

    /// Per-id winner is whichever copy was updated most recently.
    private static func merge(_ a: [Reminder], _ b: [Reminder]) -> [Reminder] {
        var map: [UUID: Reminder] = [:]
        for r in a { map[r.id] = r }
        for r in b {
            if let existing = map[r.id] {
                map[r.id] = existing.updatedAt >= r.updatedAt ? existing : r
            } else {
                map[r.id] = r
            }
        }
        return Array(map.values)
    }
}
