import Foundation
import SwiftUI

/// Local-first source of truth: every change writes to the on-device cache immediately (so a
/// reminder is never lost), then syncs to Supabase. Unsynced rows are retried on launch.
@MainActor
final class ReminderStore: ObservableObject {
    @Published private(set) var reminders: [Reminder] = []
    @Published var lastSyncFailed = false

    private let repo: ReminderRepository
    private let cacheURL: URL

    init(repo: ReminderRepository = SupabaseReminderRepository()) {
        self.repo = repo
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        cacheURL = dir.appendingPathComponent("reminders.json")
        loadCache()
    }

    var active: [Reminder] {
        reminders.filter { $0.status == .active }
            .sorted { sortKey($0) < sortKey($1) }
    }
    var completed: [Reminder] {
        reminders.filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
    private func sortKey(_ r: Reminder) -> Date { r.fireDate ?? r.createdAt }

    func bootstrap() async {
        guard await repo.ensureReady() else { return }
        await pushPending()
        await refresh()
    }

    func refresh() async {
        do {
            let remote = try await repo.fetchAll()
            var merged = remote
            // Keep local rows that haven't synced yet; they win over the remote copy.
            for u in reminders where u.needsSync {
                if let idx = merged.firstIndex(where: { $0.id == u.id }) { merged[idx] = u }
                else { merged.append(u) }
            }
            reminders = merged
            saveCache()
            reminders.forEach(NotificationScheduler.schedule)
        } catch {
            // Stay on the local cache; no intrusive error.
        }
    }

    func save(_ reminder: Reminder) {
        var r = reminder
        r.updatedAt = Date()
        r.needsSync = true
        upsertLocal(r)
        NotificationScheduler.schedule(r)
        Task { await sync(r) }
    }

    func complete(_ reminder: Reminder) {
        var r = reminder
        r.status = .completed
        r.completedAt = Date()
        NotificationScheduler.cancel(r)
        save(r)
    }

    func uncomplete(_ reminder: Reminder) {
        var r = reminder
        r.status = .active
        r.completedAt = nil
        save(r)
    }

    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        saveCache()
        NotificationScheduler.cancel(reminder)
        Task { try? await repo.delete(id: reminder.id) }
    }

    // MARK: - sync

    private func sync(_ r: Reminder) async {
        guard await repo.ensureReady() else { lastSyncFailed = true; return }
        do {
            try await repo.upsert(r)
            markSynced(r.id)
            lastSyncFailed = false
        } catch {
            lastSyncFailed = true
        }
    }

    private func pushPending() async {
        for r in reminders where r.needsSync { await sync(r) }
    }

    private func upsertLocal(_ r: Reminder) {
        if let idx = reminders.firstIndex(where: { $0.id == r.id }) { reminders[idx] = r }
        else { reminders.append(r) }
        saveCache()
    }

    private func markSynced(_ id: UUID) {
        if let idx = reminders.firstIndex(where: { $0.id == id }) {
            reminders[idx].needsSync = false
            saveCache()
        }
    }

    // MARK: - cache

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let decoded = try? JSONDecoder.recall.decode([Reminder].self, from: data) else { return }
        reminders = decoded
    }

    private func saveCache() {
        if let data = try? JSONEncoder.recall.encode(reminders) {
            try? data.write(to: cacheURL, options: .atomic)
        }
    }
}
