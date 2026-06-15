import Foundation

/// The seam the app codes against. Backed by Supabase over plain URLSession (no SDK), so swapping
/// to the Vercel API contract or a Neo4j-backed store later stays a one-file change.
protocol ReminderRepository {
    func ensureReady() async -> Bool
    func fetchAll() async throws -> [Reminder]
    func upsert(_ reminder: Reminder) async throws
    func delete(id: UUID) async throws
}

// MARK: - DB row shapes (snake_case columns in recall.*)

private struct ReminderRow: Decodable {
    var id: String
    var title: String
    var notes: String
    var url: String
    var image_path: String?
    var due_date: String?
    var due_time: String?
    var urgent: Bool
    var repeat_rule: String
    var early_reminder: String
    var list_name: String
    var flag: Bool
    var priority: String
    var location_name: String
    var when_messaging_person: String
    var seeded_from_template_id: String?
    var status: String
    var completed_at: String?
    var created_at: String?
    var updated_at: String?
}

/// Write payload — omits server-managed columns (user_id default auth.uid(), created_at,
/// updated_at) so an upsert never clobbers them.
private struct ReminderUpsert: Encodable {
    var id: String
    var title: String
    var notes: String
    var url: String
    var image_path: String?
    var due_date: String?
    var due_time: String?
    var urgent: Bool
    var repeat_rule: String
    var early_reminder: String
    var list_name: String
    var flag: Bool
    var priority: String
    var location_name: String
    var when_messaging_person: String
    var seeded_from_template_id: String?
    var status: String
    var completed_at: String?
}

private struct TagRow: Codable { var reminder_id: String; var tag: String }
private struct SubtaskRow: Codable {
    var id: String; var reminder_id: String; var title: String; var done: Bool; var position: Int
}

private enum PG {
    static let date: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    static let time: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "HH:mm:ss"; return f
    }()
    static func parseTimestamp(_ s: String) -> Date? {
        let withFrac = ISO8601DateFormatter(); withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFrac.date(from: s) { return d }
        let plain = ISO8601DateFormatter(); plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: s)
    }
}

// MARK: - Supabase implementation (URLSession / PostgREST)

final class SupabaseReminderRepository: ReminderRepository {
    private let service = SupabaseService.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func ensureReady() async -> Bool { await service.ensureSession() }

    func fetchAll() async throws -> [Reminder] {
        guard let rReq = await service.request("GET", "reminders", query: "status=neq.deleted&order=created_at.desc") else { return [] }
        let rows = try decoder.decode([ReminderRow].self, from: try await service.send(rReq))

        var tagMap: [String: [String]] = [:]
        if let tReq = await service.request("GET", "reminder_tags", query: "select=*") {
            let tags = (try? decoder.decode([TagRow].self, from: try await service.send(tReq))) ?? []
            for t in tags { tagMap[t.reminder_id, default: []].append(t.tag) }
        }
        var subMap: [String: [Subtask]] = [:]
        if let sReq = await service.request("GET", "reminder_subtasks", query: "select=*&order=position.asc") {
            let subs = (try? decoder.decode([SubtaskRow].self, from: try await service.send(sReq))) ?? []
            for s in subs {
                subMap[s.reminder_id, default: []].append(
                    Subtask(id: UUID(uuidString: s.id) ?? UUID(), title: s.title, done: s.done))
            }
        }
        return rows.map { reminder(from: $0, tags: tagMap[$0.id] ?? [], subtasks: subMap[$0.id] ?? []) }
    }

    func upsert(_ r: Reminder) async throws {
        let rid = r.id.uuidString.lowercased()
        let body = try encoder.encode([upsertRow(from: r)])
        guard let req = await service.request("POST", "reminders", query: "on_conflict=id", body: body,
                                              prefer: "resolution=merge-duplicates,return=minimal") else {
            throw NSError(domain: "Supabase", code: -1, userInfo: [NSLocalizedDescriptionKey: "not signed in"])
        }
        try await service.send(req)

        // Replace child rows so tags/subtasks always mirror the reminder.
        if let del = await service.request("DELETE", "reminder_tags", query: "reminder_id=eq.\(rid)") {
            try await service.send(del)
        }
        if !r.tags.isEmpty {
            let rows = r.tags.map { TagRow(reminder_id: rid, tag: $0) }
            if let ins = await service.request("POST", "reminder_tags", body: try encoder.encode(rows), prefer: "return=minimal") {
                try await service.send(ins)
            }
        }
        if let del = await service.request("DELETE", "reminder_subtasks", query: "reminder_id=eq.\(rid)") {
            try await service.send(del)
        }
        if !r.subtasks.isEmpty {
            let rows = r.subtasks.enumerated().map { idx, s in
                SubtaskRow(id: s.id.uuidString.lowercased(), reminder_id: rid, title: s.title, done: s.done, position: idx)
            }
            if let ins = await service.request("POST", "reminder_subtasks", body: try encoder.encode(rows), prefer: "return=minimal") {
                try await service.send(ins)
            }
        }
    }

    func delete(id: UUID) async throws {
        guard let req = await service.request("DELETE", "reminders", query: "id=eq.\(id.uuidString.lowercased())") else { return }
        try await service.send(req)
    }

    private func upsertRow(from r: Reminder) -> ReminderUpsert {
        ReminderUpsert(
            id: r.id.uuidString.lowercased(),
            title: r.title, notes: r.notes, url: r.url,
            image_path: nil,                                   // cloud image upload deferred to 1.0.1
            due_date: r.dueDate.map { PG.date.string(from: $0) },
            due_time: r.dueTime.map { PG.time.string(from: $0) },
            urgent: r.urgent,
            repeat_rule: r.repeatRule.rawValue,
            early_reminder: r.earlyReminder.rawValue,
            list_name: r.listName,
            flag: r.flag,
            priority: r.priority.rawValue,
            location_name: r.locationName,
            when_messaging_person: r.whenMessagingPerson,
            seeded_from_template_id: r.seededFromTemplateID,
            status: r.status.rawValue,
            completed_at: r.completedAt.map { ISO8601DateFormatter().string(from: $0) }
        )
    }

    private func reminder(from row: ReminderRow, tags: [String], subtasks: [Subtask]) -> Reminder {
        var r = Reminder()
        r.id = UUID(uuidString: row.id) ?? UUID()
        r.title = row.title
        r.notes = row.notes
        r.url = row.url
        r.imageLocalPath = nil
        r.dueDate = row.due_date.flatMap { PG.date.date(from: $0) }
        r.dueTime = row.due_time.flatMap { PG.time.date(from: $0) }
        r.urgent = row.urgent
        r.repeatRule = RepeatRule(rawValue: row.repeat_rule) ?? .none
        r.earlyReminder = EarlyReminder(rawValue: row.early_reminder) ?? .none
        r.listName = row.list_name
        r.flag = row.flag
        r.priority = Priority(rawValue: row.priority) ?? .none
        r.locationName = row.location_name
        r.whenMessagingPerson = row.when_messaging_person
        r.seededFromTemplateID = row.seeded_from_template_id
        r.status = ReminderStatus(rawValue: row.status) ?? .active
        r.tags = tags
        r.subtasks = subtasks
        r.completedAt = row.completed_at.flatMap { PG.parseTimestamp($0) }
        r.createdAt = row.created_at.flatMap { PG.parseTimestamp($0) } ?? Date()
        r.updatedAt = row.updated_at.flatMap { PG.parseTimestamp($0) } ?? Date()
        r.needsSync = false
        return r
    }
}
