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

/// A factual Re_Call lifecycle event. This is descriptive input for Harness, not a decision about
/// whether the reminder should become a candidate.
enum HarnessCaptureKind: String, Codable, CaseIterable {
    case created = "reminder.created"
    case updated = "reminder.updated"
    case completed = "reminder.completed"
    case deleted = "reminder.deleted"
}

enum HarnessCaptureExportError: Error, LocalizedError, Equatable {
    case invalidCaptureID(String)
    case captureIDConflict(String)

    var errorDescription: String? {
        switch self {
        case .invalidCaptureID(let id):
            return "Invalid Re_Call capture id: \(id)"
        case .captureIDConflict(let id):
            return "Re_Call capture id already exists with different event data: \(id)"
        }
    }
}

/// Copies faithful reminder events into Re_Call's iCloud handoff folder. Re_Call records what
/// happened; Harness owns every later interpretation and candidate decision.
enum HarnessCaptureExporter {
    static let rootFolderName = "Harness Captures"
    static let pendingFolderName = "Pending"
    static let schemaVersion = "suite_capture.v1"
    static let sourceApp = "Re_Call"

    private static let worker = DispatchQueue(label: "app.understood.recall.harness-capture-export")

    /// Encode the exact reminder value before leaving the caller's actor, then perform only the
    /// iCloud file write on the serial worker.
    static func record(
        _ kind: HarnessCaptureKind,
        reminder: Reminder,
        at date: Date = Date()
    ) {
        let captureID = makeCaptureID()
        do {
            let data = try encodedCapture(
                kind,
                reminder: reminder,
                at: date,
                captureID: captureID
            )
            worker.async {
                do {
                    _ = try writeCapture(data, captureID: captureID, root: handoffRoot())
                } catch {
                    NSLog("Re_Call Harness capture export failed: %@", error.localizedDescription)
                }
            }
        } catch {
            NSLog("Re_Call Harness capture encoding failed: %@", error.localizedDescription)
        }
    }

    @discardableResult
    static func recordSynchronously(
        _ kind: HarnessCaptureKind,
        reminder: Reminder,
        at date: Date,
        captureID: String = makeCaptureID(),
        rootOverride: URL? = nil
    ) throws -> URL? {
        let data = try encodedCapture(
            kind,
            reminder: reminder,
            at: date,
            captureID: captureID
        )
        return try writeCapture(
            data,
            captureID: captureID,
            root: rootOverride ?? handoffRoot()
        )
    }

    private static func encodedCapture(
        _ kind: HarnessCaptureKind,
        reminder: Reminder,
        at date: Date,
        captureID: String
    ) throws -> Data {
        let envelope = CaptureEnvelope(
            schemaVersion: schemaVersion,
            captureID: captureID,
            capturedAt: date,
            captureKind: kind.rawValue,
            sourceApp: sourceApp,
            sourceRecordID: reminder.id.uuidString.lowercased(),
            payload: reminder,
            artifactRefs: artifactReferences(for: reminder)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(envelope)
    }

    private static func writeCapture(
        _ data: Data,
        captureID: String,
        root: URL?
    ) throws -> URL? {
        guard let root else { return nil }
        guard isSafeCaptureID(captureID) else {
            throw HarnessCaptureExportError.invalidCaptureID(captureID)
        }
        let pendingDirectory = root.appendingPathComponent(pendingFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: pendingDirectory, withIntermediateDirectories: true)
        let captureURL = pendingDirectory.appendingPathComponent("\(captureID).json")
        if FileManager.default.fileExists(atPath: captureURL.path) {
            guard try Data(contentsOf: captureURL) == data else {
                throw HarnessCaptureExportError.captureIDConflict(captureID)
            }
            return captureURL
        }
        try data.write(to: captureURL, options: .atomic)
        return captureURL
    }

    private static func artifactReferences(for reminder: Reminder) -> [String] {
        var references: [String] = []
        for value in [reminder.url, reminder.imageLocalPath ?? ""] {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !references.contains(trimmed) else { continue }
            references.append(trimmed)
        }
        return references
    }

    private static func makeCaptureID() -> String {
        "capture-recall-\(UUID().uuidString.lowercased())"
    }

    private static func isSafeCaptureID(_ id: String) -> Bool {
        guard id.hasPrefix("capture-recall-"), (16...160).contains(id.utf8.count) else {
            return false
        }
        return id.utf8.allSatisfy { byte in
            (97...122).contains(byte)
                || (48...57).contains(byte)
                || byte == 45
        }
    }

    private static func handoffRoot() -> URL? {
        if let override = ProcessInfo.processInfo.environment["RECALL_HARNESS_CAPTURE_ROOT"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        guard let container = FileManager.default.url(
            forUbiquityContainerIdentifier: ICloudReminderCache.containerID
        ) else {
            return nil
        }
        return container
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent(rootFolderName, isDirectory: true)
    }

    private struct CaptureEnvelope: Codable {
        let schemaVersion: String
        let captureID: String
        let capturedAt: Date
        let captureKind: String
        let sourceApp: String
        let sourceRecordID: String
        let payload: Reminder
        let artifactRefs: [String]

        enum CodingKeys: String, CodingKey {
            case schemaVersion = "schema_version"
            case captureID = "capture_id"
            case capturedAt = "captured_at"
            case captureKind = "capture_kind"
            case sourceApp = "source_app"
            case sourceRecordID = "source_record_id"
            case payload
            case artifactRefs = "artifact_refs"
        }
    }
}
