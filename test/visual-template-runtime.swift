import Foundation

@main
struct VisualTemplateCacheRuntimeTests {
    static func main() throws {
        guard ProcessInfo.processInfo.arguments.contains("RECALL_UI_TEST_ISOLATED") else {
            throw Failure("Visual cache checks require the isolated store")
        }
        let file = ICloudReminderCache.localURL()
        guard !FileManager.default.fileExists(atPath: file.path) else {
            throw Failure("Refusing to overwrite a preexisting cache")
        }
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        guard ICloudReminderCache.iCloudDocumentsURL() == nil else {
            throw Failure("Visual cache checks must not reach iCloud")
        }

        var draft = VisualTemplateDraft()
        for format in VisualTemplateCatalog.formats {
            draft.selectFormat(format.id)
            for index in 0..<4 {
                draft.setAnswer("  \(format.name) answer \(index) — 🧠\n\nSecond line.  ", at: index)
            }
        }
        let entries = ReminderKind.allCases.map { kind in
            var entry = Reminder()
            entry.kind = kind
            entry.createdAt = Date(timeIntervalSince1970: 1_790_000_000)
            entry.updatedAt = entry.createdAt
            entry.title = "Original \(kind.label) writing.\n  Exact spacing.  "
            entry.visualTemplates = draft
            return entry
        }
        ICloudReminderCache.save(entries)
        let restored = ICloudReminderCache.load()
        guard restored == entries else { throw Failure("The real cache lost Visual or existing writing") }
        for entry in restored {
            let text = EntryShareContent(entry: entry, sourceApp: "Understood", entryLabel: entry.kind.label, whenIAm: "").entireForm
            for format in VisualTemplateCatalog.formats {
                for index in 0..<4 {
                    guard text.contains("  \(format.name) answer \(index) — 🧠\n\nSecond line.  ") else {
                        throw Failure("Share omitted \(format.name) answer \(index)")
                    }
                }
            }
        }
        print("Visual cache runtime checks passed: all three entry kinds, twelve formats, exact multiline writing and share snapshot.")
    }

    private struct Failure: Error, CustomStringConvertible {
        let description: String
        init(_ description: String) { self.description = description }
    }
}
