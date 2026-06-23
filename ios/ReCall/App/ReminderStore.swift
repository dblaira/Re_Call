import Foundation
import SwiftUI

/// Local-first source of truth for every item type (Reminder, Action, Event). Writes to the phone
/// immediately, then copies the same file to iCloud Documents — no Supabase, no login screen.
@MainActor
final class ReminderStore: ObservableObject {
    @Published private(set) var reminders: [Reminder] = []

    init() {
        reminders = ICloudReminderCache.load()
        reminders.forEach(NotificationScheduler.schedule)
    }

    var active: [Reminder] {
        reminders.filter { $0.status == .active }
            .sorted { compareUpNext($0, $1) }
    }

    /// Pinned block first; within each block, manual order then date fallback.
    private func compareUpNext(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        if lhs.pinned != rhs.pinned { return lhs.pinned }
        return compareWithinBlock(lhs, rhs)
    }

    private func compareWithinBlock(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        switch (lhs.upNextOrder, rhs.upNextOrder) {
        case let (l?, r?): return l < r
        case (nil, nil): return sortKey(lhs) < sortKey(rhs)
        case (_?, nil): return true
        case (nil, _?): return false
        }
    }
    var completed: [Reminder] {
        reminders.filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
    private func sortKey(_ r: Reminder) -> Date { r.fireDate ?? r.createdAt }

    /// Pull the latest copy from disk + iCloud (e.g. after another device edits or app returns active).
    func bootstrap() async { await refresh() }

    func refresh() async {
        let loaded = ICloudReminderCache.load()
        guard loaded != reminders else { return }
        reminders = loaded
        reminders.forEach(NotificationScheduler.schedule)
    }

    func save(_ reminder: Reminder) {
        var r = reminder
        r.updatedAt = Date()
        upsertLocal(r)
        NotificationScheduler.schedule(r)
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

    func togglePin(_ reminder: Reminder) {
        guard let idx = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        var r = reminders[idx]
        r.pinned.toggle()
        reminders[idx] = r

        if r.pinned {
            applyBlockOrder(active.filter { !$0.pinned })
            var pinned = active.filter { $0.pinned }
            pinned.removeAll { $0.id == r.id }
            pinned.insert(reminders[idx], at: 0)
            applyBlockOrder(pinned)
        } else {
            applyBlockOrder(active.filter { $0.pinned })
            var unpinned = active.filter { !$0.pinned }
            unpinned.removeAll { $0.id == r.id }
            unpinned.insert(reminders[idx], at: 0)
            applyBlockOrder(unpinned)
        }
    }

    enum UpNextMoveDirection { case up, down }

    /// Move one step within the reminder's pinned/unpinned block.
    func moveUpNext(_ reminder: Reminder, direction: UpNextMoveDirection) {
        let feed = active
        let blockPinned = reminder.pinned
        var block = feed.filter { $0.pinned == blockPinned }
        guard let blockIdx = block.firstIndex(where: { $0.id == reminder.id }) else { return }

        let target: Int
        switch direction {
        case .up: target = blockIdx - 1
        case .down: target = blockIdx + 1
        }
        guard block.indices.contains(target) else { return }

        block.swapAt(blockIdx, target)
        applyBlockOrder(block)
    }

    private func applyBlockOrder(_ ordered: [Reminder]) {
        var touched: [Reminder] = []
        for (i, item) in ordered.enumerated() {
            guard let idx = reminders.firstIndex(where: { $0.id == item.id }) else { continue }
            guard reminders[idx].upNextOrder != i else { continue }
            var r = reminders[idx]
            r.upNextOrder = i
            r.updatedAt = Date()
            reminders[idx] = r
            touched.append(r)
        }
        guard !touched.isEmpty else { return }
        saveCache()
        for r in touched {
            NotificationScheduler.schedule(r)
        }
    }

    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        NotificationScheduler.cancel(reminder)
        saveCache()
    }

    private func upsertLocal(_ r: Reminder) {
        if let idx = reminders.firstIndex(where: { $0.id == r.id }) { reminders[idx] = r }
        else { reminders.append(r) }
        saveCache()
    }

    private func saveCache() {
        ICloudReminderCache.save(reminders)
    }
}
