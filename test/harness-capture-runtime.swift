import Foundation

@main
struct HarnessCaptureRuntimeTests {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReCall-HarnessCaptureRuntime-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let formatter = ISO8601DateFormatter()
        let capturedAt = try unwrap(
            formatter.date(from: "2026-07-10T12:00:00Z"),
            "fixed capture date is invalid"
        )
        let reminderID = try unwrap(
            UUID(uuidString: "4AF2D635-7958-40C0-98FE-62C211DC5344"),
            "fixed reminder id is invalid"
        )

        var reminder = Reminder()
        reminder.id = reminderID
        reminder.kind = .action
        reminder.title = "Call the contractor"
        reminder.notes = "Ask about the roof estimate and next action."
        reminder.url = "https://example.com/roof-estimate"
        reminder.imageLocalPath = "images/roof-estimate.jpg"
        reminder.dueDate = capturedAt
        reminder.dueTime = capturedAt
        reminder.endTime = capturedAt.addingTimeInterval(3_600)
        reminder.urgent = true
        reminder.repeatRule = .weekly
        reminder.listName = "House"
        reminder.flag = true
        reminder.priority = .high
        reminder.whenIAm = "When I review the renovation"
        reminder.outcome = "Know whether to approve the estimate"
        reminder.effort = .m15
        reminder.energy = .medium
        reminder.context = .chooseSuccess
        reminder.deferDate = capturedAt.addingTimeInterval(86_400)
        reminder.waitingOn = "Contractor"
        reminder.locationName = "Home"
        reminder.seededFromTemplateID = "FindLeveragePointReminder"
        reminder.pinned = true
        reminder.upNextOrder = 2
        reminder.tags = ["renovation", "decision"]
        reminder.subtasks = [Subtask(
            id: try unwrap(
                UUID(uuidString: "11ECA6A8-C29D-4A75-B630-51F66DF99600"),
                "fixed subtask id is invalid"
            ),
            title: "Open estimate",
            done: false
        )]
        reminder.status = .active
        reminder.createdAt = capturedAt.addingTimeInterval(-3_600)
        reminder.updatedAt = capturedAt
        reminder.needsSync = true

        let createdID = "capture-recall-created-0001"
        let createdURL = try unwrap(
            HarnessCaptureExporter.recordSynchronously(
                .created,
                reminder: reminder,
                at: capturedAt,
                captureID: createdID,
                rootOverride: root
            ),
            "created reminder event must write one capture"
        )

        let createdData = try Data(contentsOf: createdURL)
        let createdObject = try object(from: createdData)
        let expectedFields: Set<String> = [
            "schema_version", "capture_id", "captured_at", "capture_kind",
            "source_app", "source_record_id", "payload", "artifact_refs"
        ]
        try require(Set(createdObject.keys) == expectedFields, "suite_capture.v1 fields changed")
        try require(createdObject["schema_version"] as? String == "suite_capture.v1", "schema version changed")
        try require(createdObject["capture_id"] as? String == createdID, "capture id changed")
        try require(createdObject["captured_at"] as? String == "2026-07-10T12:00:00Z", "captured_at changed")
        try require(createdObject["capture_kind"] as? String == "reminder.created", "capture kind changed")
        try require(createdObject["source_app"] as? String == "Re_Call", "source app changed")
        try require(
            createdObject["source_record_id"] as? String == reminderID.uuidString.lowercased(),
            "source record id changed"
        )
        try require(
            createdObject["artifact_refs"] as? [String] == [
                "https://example.com/roof-estimate",
                "images/roof-estimate.jpg"
            ],
            "artifact references did not preserve the reminder links"
        )

        let payloadObject = try unwrap(
            createdObject["payload"] as? [String: Any],
            "capture payload must be one reminder object"
        )
        let payloadData = try JSONSerialization.data(withJSONObject: payloadObject, options: [.sortedKeys])
        let decodedReminder = try JSONDecoder.recall.decode(Reminder.self, from: payloadData)
        try require(decodedReminder == reminder, "capture payload did not retain the complete reminder snapshot")

        let forbiddenCandidateFields: Set<String> = [
            "plain", "evidence", "domain_a", "domain_b", "strength",
            "connection_type", "threshold"
        ]
        try require(
            Set(createdObject.keys).isDisjoint(with: forbiddenCandidateFields),
            "Re_Call capture included candidate-only fields"
        )
        let serialized = try unwrap(String(data: createdData, encoding: .utf8), "capture must be UTF-8")
        try require(!serialized.contains("AGENT PROPOSAL:"), "Re_Call must not write a candidate proposal")

        let repeatedURL = try unwrap(
            HarnessCaptureExporter.recordSynchronously(
                .created,
                reminder: reminder,
                at: capturedAt,
                captureID: createdID,
                rootOverride: root
            ),
            "an exact retry must resolve to the durable capture"
        )
        try require(repeatedURL == createdURL, "an exact retry wrote a different capture")

        var conflictingReminder = reminder
        conflictingReminder.title = "Different event data"
        do {
            _ = try HarnessCaptureExporter.recordSynchronously(
                .created,
                reminder: conflictingReminder,
                at: capturedAt,
                captureID: createdID,
                rootOverride: root
            )
            throw Failure("a reused capture id must not overwrite different event data")
        } catch HarnessCaptureExportError.captureIDConflict(let id) {
            try require(id == createdID, "capture conflict reported the wrong id")
        }

        var updated = reminder
        updated.title = "Call the contractor with the revised question"
        updated.updatedAt = capturedAt.addingTimeInterval(60)
        _ = try HarnessCaptureExporter.recordSynchronously(
            .updated,
            reminder: updated,
            at: updated.updatedAt,
            captureID: "capture-recall-updated-0002",
            rootOverride: root
        )

        var completed = updated
        completed.status = .completed
        completed.completedAt = capturedAt.addingTimeInterval(120)
        completed.updatedAt = completed.completedAt ?? capturedAt
        _ = try HarnessCaptureExporter.recordSynchronously(
            .completed,
            reminder: completed,
            at: completed.updatedAt,
            captureID: "capture-recall-completed-0003",
            rootOverride: root
        )

        var deleted = completed
        deleted.status = .deleted
        deleted.updatedAt = capturedAt.addingTimeInterval(180)
        _ = try HarnessCaptureExporter.recordSynchronously(
            .deleted,
            reminder: deleted,
            at: deleted.updatedAt,
            captureID: "capture-recall-deleted-0004",
            rootOverride: root
        )

        var untemplated = Reminder()
        untemplated.id = try unwrap(
            UUID(uuidString: "51BFD04B-0490-4D3A-9696-177E65E27B16"),
            "fixed untemplated reminder id is invalid"
        )
        untemplated.title = "Captured without a template"
        untemplated.createdAt = capturedAt
        untemplated.updatedAt = capturedAt
        _ = try HarnessCaptureExporter.recordSynchronously(
            .created,
            reminder: untemplated,
            at: capturedAt,
            captureID: "capture-recall-untemplated-0005",
            rootOverride: root
        )

        let pendingDirectory = root.appendingPathComponent("Pending", isDirectory: true)
        let captureFiles = try FileManager.default.contentsOfDirectory(
            at: pendingDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        try require(captureFiles.count == 5, "every lifecycle event must remain a separate capture")

        var observedKinds: Set<String> = []
        for file in captureFiles {
            let capture = try object(from: Data(contentsOf: file))
            if let kind = capture["capture_kind"] as? String {
                observedKinds.insert(kind)
            }
        }
        try require(
            observedKinds == Set(HarnessCaptureKind.allCases.map(\.rawValue)),
            "created, updated, completed, and deleted capture kinds must all be present"
        )
        try require(
            !FileManager.default.fileExists(atPath: root.appendingPathComponent("Aggregates").path),
            "Re_Call must not aggregate or interpret captures"
        )
        try require(
            !FileManager.default.fileExists(atPath: root.appendingPathComponent("Accepted").path),
            "Re_Call must never create an accepted-authority path"
        )
        try require(
            !FileManager.default.fileExists(atPath: root.appendingPathComponent("Candidates").path),
            "Re_Call must never create a candidate path"
        )
    }

    private static func object(from data: Data) throws -> [String: Any] {
        try unwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "capture JSON must decode to one object"
        )
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw Failure(message) }
    }

    private static func unwrap<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else { throw Failure(message) }
        return value
    }

    private struct Failure: Error, CustomStringConvertible {
        let description: String
        init(_ description: String) { self.description = description }
    }
}
