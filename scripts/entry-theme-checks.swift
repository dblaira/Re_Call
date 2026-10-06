import Foundation

@main
struct EntryThemeChecks {
    static func main() throws {
        precondition(PostThemeCatalog.themes.count == 31)
        precondition(Set(PostThemeCatalog.themes.map(\.id)).count == 31)
        guard let theme = PostThemeCatalog.theme(id: "inductive-reasoning") else { preconditionFailure("Missing Inductive Reasoning") }
        precondition(theme.questions.map(\.prompt) == [
            "Why does this feel special?", "What difference does it make?",
            "What can I do now?", "How much value can I keep from what I build?"
        ])
        for kind in ReminderKind.allCases {
            var entry = Reminder()
            entry.kind = kind
            entry.title = "My complete answer\n" + String(repeating: "Every word matters. ", count: 80)
            entry.whenIAm = "When I am learning"
            entry.outcome = "All my words stay visible"
            var draft = PostEntryDraft(entry: entry)
            precondition(!draft.hasUserContent)
            draft.selectTheme("inductive-reasoning")
            let answer = draft.answers[0] + "I can see a connection.\n" + String(repeating: "Keep this exact text. ", count: 80)
            draft.setAnswer(answer, at: 0)
            draft.selectTheme("pattern-recognition")
            draft.setAnswer(draft.answers[0] + "A new pattern", at: 0)
            draft.selectTheme("inductive-reasoning")
            precondition(draft.answers[0] == answer)
            precondition(draft.hasUserContent)
            draft.apply(to: &entry)
            let data = try JSONEncoder.recall.encode(entry)
            let reopened = try JSONDecoder.recall.decode(Reminder.self, from: data)
            precondition(reopened.title == entry.title && reopened.whenIAm == entry.whenIAm
                         && reopened.outcome == entry.outcome && reopened.postAnswers == entry.postAnswers
                         && reopened.kind == kind)
            precondition(PostEntryDraft(entry: reopened).answers[0] == answer)
            // An older cache has no theme fields. It must still decode without dropping the entry.
            guard var legacy = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { preconditionFailure("Invalid fixture") }
            for key in ["postThemeID", "postThemeName", "postAnswers", "postAnswersContainQuestions"] {
                legacy.removeValue(forKey: key)
            }
            let old = try JSONDecoder.recall.decode(Reminder.self, from: JSONSerialization.data(withJSONObject: legacy))
            precondition(old.title == entry.title && old.whenIAm == entry.whenIAm && old.postThemeID == nil)
            print("PASS \(kind.label): full text, theme switching, reopen, and old-cache compatibility")
        }
        print("PASS exact 31-theme SAVY catalog")
    }
}
