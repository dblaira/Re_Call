import Foundation

@main
struct CardTitleRuntimeTests {
    @MainActor static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("UnderstoodTitles-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let local = root.appendingPathComponent("local/card-titles.json")
        let cloud = root.appendingPathComponent("cloud/card-titles.json")
        var online = false
        let store = CardTitleStore(localURL: local, cloudURL: { online ? cloud : nil })
        var original = Reminder()
        original.title = "Original writing"
        original.notes = "Keep these notes exactly."
        original.postAnswers = ["Original theme answer"]
        original.status = .completed
        let before = original
        let card = CardTitle.reminder(original)
        precondition(store.title(for: card) == original.title)
        precondition(!store.rename(card, to: " \n "))
        precondition(store.rename(card, to: "My exact\ncard title ✨"))
        precondition(original == before, "Renaming cannot rewrite a reminder or its answers")
        precondition(store.title(for: card) == "My exact\ncard title ✨")
        let relaunched = CardTitleStore(localURL: local, cloudURL: { nil })
        precondition(relaunched.title(for: card) == "My exact\ncard title ✨")
        online = true
        store.refresh()
        let remote = CardTitleStore(localURL: root.appendingPathComponent("other/card-titles.json"), cloudURL: { cloud })
        precondition(remote.title(for: card) == "My exact\ncard title ✨", "Offline edits must publish when reconnected")
        let tile = CardTitle(id: "shape:reminder-movement", original: "Add one movement")
        precondition(remote.rename(tile, to: "My movement"))
        precondition(remote.rename(card, to: "Later title"))
        store.refresh()
        precondition(store.title(for: tile) == "My movement", "Merge must retain independent card titles")
        precondition(store.title(for: card) == "Later title", "Newer title must win")
        precondition(store.restoreOriginal(card))
        remote.refresh()
        precondition(remote.title(for: card) == "Original writing", "Reset must survive cloud merging")
        precondition(remote.title(for: .reminder(original, title: "Original theme answer")) == "Original theme answer")
        precondition(remote.title(for: tile) == "My movement")
        precondition(ICloudReminderCache.iCloudDocumentsURL(fileName: "card-titles.json") == nil)
        precondition(ICloudReminderCache.localURL(fileName: "card-titles.json").path.contains("recall-ui-tests-"))
        print("PASS: exact title, blank rejection, original contents, relaunch, offline retry, per-card merge, reset, isolation")
    }
}
