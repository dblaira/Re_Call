import Foundation

@MainActor enum NotificationScheduler {
    static func schedule(_ reminder: Reminder) {}
    static func cancel(_ reminder: Reminder) {}
}

@main @MainActor struct EntryTimestampChecks {
    static func main() throws {
        precondition(ProcessInfo.processInfo.arguments.contains("RECALL_UI_TEST_ISOLATED"))
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let changed = created.addingTimeInterval(60)
        var records = ReminderKind.allCases.map { kind in
            var r = Reminder(); r.kind = kind; r.title = "Timestamp fixture"
            r.createdAt = created; r.updatedAt = changed
            return r
        }
        ICloudReminderCache.save(records)
        let store = ReminderStore()
        precondition(store.reminders == records, "A read is not a change")
        for original in records {
            var edited = original; edited.createdAt = Date(); edited.title = "Updated fixture"
            store.save(edited)
            guard let saved = store.reminders.first(where: { $0.id == original.id }) else { fatalError("Missing saved entry") }
            precondition(saved.createdAt == created && saved.updatedAt > changed)
            let text = EntryShareContent(entry: saved, sourceApp: "Understood", entryLabel: saved.kind.label, whenIAm: "").entireForm
            precondition(text.contains("Created: 2023-11-14T22:13:20Z") && text.contains("Changed: "))
            store.complete(saved)
            guard let completed = store.reminders.first(where: { $0.id == original.id }) else { fatalError("Missing completed entry") }
            precondition(completed.createdAt == created && completed.updatedAt >= saved.updatedAt)
            store.uncomplete(completed)
            let card = CardTitle.reminder(saved)
            precondition(CardTitleStore.shared.rename(card, to: "Display fixture"))
            guard let titleDate = CardTitleStore.shared.titles[card.id]?.modifiedAt,
                  let afterTitle = store.reminders.first(where: { $0.id == original.id }) else { fatalError("Missing rename") }
            precondition(afterTitle.updatedAt == titleDate && afterTitle.createdAt == created)
        }
        records = ICloudReminderCache.load()
        precondition(records.count == ReminderKind.allCases.count)
        precondition(records.allSatisfy { $0.createdAt == created && $0.updatedAt > changed })
        let before = records
        _ = ICloudReminderCache.load()
        precondition(ICloudReminderCache.load() == before, "Repeated reads must preserve timestamps")
        print("PASS: every Understood entry kind preserves creation, stamps saves/completion/reopening/title edits, reloads and exports UTC timestamps")
    }
}
