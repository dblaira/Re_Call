import Foundation

@main
struct EntryThemeChecks {
    static func main() throws {
        precondition(PostThemeCatalog.themes.count == 33)
        precondition(Set(PostThemeCatalog.themes.map(\.id)).count == 33)
        // Adam, 2026-10-15: Habit first, then A Strong Yes, Pattern Recognition, Inductive
        // Reasoning, Mental Model, and Personal Lessons; the rest keep their order.
        precondition(Array(PostThemeCatalog.themes.prefix(7).map(\.name)) == [
            "Habit", "A Strong Yes", "Pattern Recognition", "Inductive Reasoning",
            "Mental Model", "Personal Lessons", "The 5 Ws",
        ])
        precondition(PostThemeCatalog.theme(id: "habit")?.questions.map(\.prompt) == [
            "Make it Obvious", "Make it Easy", "Make it Attractive", "Make it Satisfying",
        ])
        precondition(PostThemeCatalog.theme(id: "habit")?.questions.first?.symbol == "target")
        precondition(PostEntryDraft(entry: Reminder()).theme.id == "habit")
        var unthemed = Reminder()
        unthemed.postAnswers = ["An older answer."]
        precondition(PostEntryDraft(entry: unthemed).theme.id == "five-ws")
        precondition(PostEntryDraft(entry: unthemed).answers[0] == "What happened?\n\nAn older answer.")
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
        // Adam, 2026-10-15: the Theme entry, not the delegation entry or the question, leads the card.
        var card = Reminder()
        card.title = "My delegation entry"
        var cardDraft = PostEntryDraft(entry: card)
        cardDraft.apply(to: &card)
        precondition(card.firstThemeAnswer == nil)
        cardDraft.setAnswer("Make it Easy\nLay out my shoes the night before.", at: 1)
        cardDraft.apply(to: &card)
        precondition(card.firstThemeAnswer == "Lay out my shoes the night before.")
        cardDraft.setAnswer("Make it Obvious\nPut the shoes by the door.", at: 0)
        cardDraft.apply(to: &card)
        precondition(card.firstThemeAnswer == "Put the shoes by the door.")
        print("PASS exact 33-theme SAVY catalog, Habit first, Theme answer leads the card")
    }
}
