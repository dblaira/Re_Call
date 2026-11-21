import XCTest
@testable import ReCall

final class EntryShareContentTests: XCTestCase {
    private var entry: Reminder {
        var entry = Reminder()
        entry.kind = .action
        entry.title = "My exact words — including “quotes”.\nAnother line.  "
        entry.whenIAm = "Context stays intact."
        entry.outcome = "Done looks exactly like this."
        entry.postThemeID = "habit"
        entry.postThemeName = "Habit"
        entry.postAnswersContainQuestions = true
        entry.postAnswers = ["My edited question\nMy full answer 🧠\n  Indented writing."]
        entry.subtasks = [Subtask(title: "First step"), Subtask(title: "Finished step", done: true)]
        entry.context = .clearSign
        entry.listName = "Inspiration"
        entry.tags = ["Connection", "AI"]
        entry.priority = .medium
        entry.energy = .high
        entry.notes = "Exact metadata note.\nSecond line."
        entry.url = "https://example.com/context"
        entry.locationName = "At home"
        entry.waitingOn = "A collaborator"
        entry.imageLocalPath = "NEVER_SHARE_IMAGE.png"
        return entry
    }

    private func content(_ entry: Reminder) -> EntryShareContent {
        EntryShareContent(entry: entry, sourceApp: "Test App", entryLabel: "Action",
                          whenIAm: "Context stays intact.")
    }

    func testEntireFormPreservesWritingStepsAndMetadataWithoutImages() {
        let value = content(entry).entireForm
        XCTAssertTrue(value.contains(entry.title))
        XCTAssertTrue(value.contains("My edited question\nMy full answer 🧠\n  Indented writing."))
        XCTAssertTrue(value.contains("[ ] First step\n[x] Finished step"))
        assertMetadata(value)
        XCTAssertFalse(value.contains("NEVER_SHARE_IMAGE"))
        XCTAssertFalse(value.contains(entry.id.uuidString))
    }

    func testEntireFormIncludesEveryDelegateField() {
        let value = content(entry).entireForm
        XCTAssertTrue(value.contains(entry.title))
        XCTAssertTrue(value.contains("Context stays intact."))
        XCTAssertTrue(value.contains(entry.outcome))
        assertMetadata(value)
        XCTAssertTrue(value.contains("My full answer"))
        XCTAssertTrue(value.contains("My edited question"))
        XCTAssertTrue(value.contains("First step"))
        XCTAssertFalse(value.contains("NEVER_SHARE_IMAGE"))
    }

    func testLegacyAnswersRetainTheirQuestionAndEveryCharacter() {
        var legacy = entry
        legacy.postAnswersContainQuestions = nil
        legacy.postAnswers = ["  Original answer.\nSecond line.  "]
        let value = content(legacy).entireForm
        XCTAssertTrue(value.contains("Make it Obvious\n\n  Original answer.\nSecond line.  "))
    }

    func testPendingTagsAreIncludedWithoutMutatingSavedTags() {
        let saved = ["Connection"]
        XCTAssertEqual(EntryShareContent.tags(saved, pending: " #AI "), ["Connection", "AI"])
        XCTAssertEqual(EntryShareContent.tags(saved, pending: "Connection"), ["Connection"])
        XCTAssertEqual(saved, ["Connection"])
    }

    func testScheduleMetadataIsPresentInEntireForm() {
        let snapshot = EntryShareContent(
            entry: entry, sourceApp: "Test App", entryLabel: "Action", whenIAm: "",
            scheduleMetadata: ["Starts: Oct 20, 2026 at 9:00 AM", "Alert: Hourly", "Time zone: America/Los_Angeles"]
        )
        let value = snapshot.entireForm
        XCTAssertTrue(value.contains("Starts: Oct 20, 2026 at 9:00 AM"))
        XCTAssertTrue(value.contains("Alert: Hourly"))
        XCTAssertTrue(value.contains("Time zone: America/Los_Angeles"))
    }

    private func assertMetadata(_ value: String, file: StaticString = #filePath, line: UInt = #line) {
        for expected in ["Theme: Habit", "Pattern: Clear Sign of Success", "Lift: Inspiration",
                         "Tags: Connection, AI", "Priority: Medium", "Energy: High",
                         "Notes: Exact metadata note.\nSecond line.", "Link: https://example.com/context",
                         "Location: At home", "Waiting on / delegate to: A collaborator"] {
            XCTAssertTrue(value.contains(expected), "Missing \(expected)", file: file, line: line)
        }
    }
}

final class PostThemeCatalogTests: XCTestCase {
    func testCorrelationCausationMatchesTheSAVYThemeExactly() throws {
        let theme = try XCTUnwrap(PostThemeCatalog.theme(id: "correlation-causation"))
        XCTAssertEqual(theme.name, "Correlation → Causation")
        XCTAssertEqual(theme.questions, [
            PostThemeQuestion(prompt: "What two things seem to be connected, and what have I observed?", symbol: "link"),
            PostThemeQuestion(prompt: "Which one might cause the other, and how could that happen?", symbol: "arrow.right"),
            PostThemeQuestion(prompt: "What else could explain the connection, or could the cause and effect be reversed?", symbol: "arrow.triangle.branch"),
            PostThemeQuestion(prompt: "What could I compare or test to distinguish these explanations, and what result would change my mind?", symbol: "magnifyingglass"),
        ])
    }

    func testCorrelationCausationIsAppendedWithoutChangingExistingThemeOrder() {
        XCTAssertEqual(PostThemeCatalog.themes.map(\.id), [
            "habit", "a-strong-yes", "pattern-recognition", "inductive-reasoning", "mental-model",
            "your-personal-take-lessons-learned", "five-ws", "problem-solution", "before-after",
            "lesson-learned", "how-to", "story-arc", "myth-fact", "the-decision",
            "frequently-asked-questions", "customer-success-story", "key-challenges-solutions",
            "myths-vs-facts", "the-ultimate-checklist", "quick-hack-or-shortcut",
            "recommended-tools-resources", "essential-terminology", "before-after-scenarios",
            "audience-poll-or-survey-results", "core-principles-explained",
            "debunking-popular-industry-beliefs", "history-of-the-topic", "alternative-approaches",
            "step-by-step-breakdown", "checklist-for-breakdown", "checklist-for-beginners",
            "advanced-strategies", "frequently-misunderstood-concepts", "correlation-causation",
        ])
    }
}


extension EntryShareContentTests {
    func testEveryEntryKindExportsCreationAndChangeAsAbsoluteInstants() throws {
        for kind in ReminderKind.allCases {
            var entry = Reminder()
            entry.kind = kind
            entry.createdAt = Date(timeIntervalSince1970: 1_700_000_000)
            entry.updatedAt = Date(timeIntervalSince1970: 1_700_086_400)
            entry.dueDate = Date(timeIntervalSince1970: 1_900_000_000)
            let before = try JSONEncoder.recall.encode(entry)
            let text = EntryShareContent(entry: entry, sourceApp: "Test", entryLabel: kind.label, whenIAm: "").entireForm
            XCTAssertTrue(text.contains("Created: 2023-11-14T22:13:20Z"), kind.rawValue)
            XCTAssertTrue(text.contains("Changed: 2023-11-15T22:13:20Z"), kind.rawValue)
            XCTAssertEqual(try JSONDecoder.recall.decode(Reminder.self, from: before), entry)
            XCTAssertEqual(entry.updatedAt, Date(timeIntervalSince1970: 1_700_086_400), "Reading or sharing must not change the timestamp")
            let draft = EntryShareContent(entry: entry, sourceApp: "Test", entryLabel: kind.label, whenIAm: "", isDraft: true).entireForm
            XCTAssertTrue(draft.contains("Unsaved draft"))
        }
    }
}
