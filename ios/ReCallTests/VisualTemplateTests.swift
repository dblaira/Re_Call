import XCTest
@testable import ReCall

final class VisualTemplateTests: XCTestCase {
    func testSAVYFormatsAndDefaultQuestionsArePreserved() {
        XCTAssertEqual(VisualTemplateCatalog.formats.map(\.name), [
            "Summarize", "Tables", "Matrices", "Node Trees", "Graphic Imagery",
            "Slides", "Charts", "Images", "Video", "Audio", "Music", "Example"
        ])
        XCTAssertTrue(VisualTemplateCatalog.formats.allSatisfy { $0.questions.count == 4 })
        XCTAssertTrue(VisualTemplateCatalog.formats.prefix(5).allSatisfy { $0.questions.allSatisfy { !$0.isEmpty } })
        XCTAssertTrue(VisualTemplateCatalog.formats.dropFirst(5).allSatisfy { $0.questions.allSatisfy(\.isEmpty) })
        let draft = VisualTemplateDraft()
        XCTAssertEqual(draft.selectedFormatID, "Matrices")
        XCTAssertEqual(draft.questions[0], "What relationship should this matrix make clear?")
        XCTAssertEqual(draft.answers, ["", "", "", ""])
        XCTAssertFalse(draft.hasUserContent, "Prompt labels are not user writing")
    }

    func testAllFormatsKeepExactLongWritingAcrossSwitchingAndCodable() throws {
        var draft = VisualTemplateDraft()
        for format in VisualTemplateCatalog.formats {
            draft.selectFormat(format.id)
            for index in 0..<4 { draft.setAnswer(answer(format.id, index), at: index) }
        }
        var restored = try JSONDecoder().decode(VisualTemplateDraft.self, from: JSONEncoder().encode(draft))
        XCTAssertEqual(restored, draft)
        for format in VisualTemplateCatalog.formats {
            restored.selectFormat(format.id)
            XCTAssertEqual(restored.questions, format.questions)
            XCTAssertEqual(restored.answers, (0..<4).map { answer(format.id, $0) })
        }
        restored.selectFormat("Matrices")
        for index in 0..<4 { restored.setAnswer("", at: index) }
        XCTAssertTrue(restored.hasUserContent, "Writing in an unselected format must survive")
    }

    func testEveryEntryKindRoundTripsWithoutChangingExistingWriting() throws {
        for kind in ReminderKind.allCases {
            var entry = Reminder()
            entry.kind = kind
            entry.createdAt = Date(timeIntervalSince1970: 1_790_000_000)
            entry.updatedAt = entry.createdAt
            entry.title = "  Original title.\n"
            entry.notes = "Original notes.\n  Exact spacing.  "
            entry.postThemeID = "habit"
            entry.postAnswers = ["Original Decide writing.\nAnother line."]
            entry.visualTemplates = populatedDraft()
            let archive = try JSONEncoder.recall.encode([entry])
            XCTAssertEqual(try JSONDecoder.recall.decode([Reminder].self, from: archive), [entry])
        }
    }

    func testOlderEntriesWithoutVisualDecodeUnchanged() throws {
        var original = Reminder()
        original.createdAt = Date(timeIntervalSince1970: 1_790_000_000)
        original.updatedAt = original.createdAt
        original.title = "Saved before Visual"
        original.postAnswers = ["  Original answer.\nSecond line.  "]
        let encoded = try JSONEncoder.recall.encode(original)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "visualTemplates")
        let oldArchive = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder.recall.decode(Reminder.self, from: oldArchive)
        XCTAssertEqual(restored, original)
        XCTAssertNil(restored.visualTemplates)
    }

    func testUnknownFormatAndExtraFieldsSurviveKnownFormatEditing() throws {
        let encoded = Data("""
        {"selectedFormatID":"Future Format","fieldsByFormat":{"Future Format":[
          {"question":"Saved question?","answer":"  Exact future writing.\\nSecond line.  "},
          {"question":"","answer":""},{"question":"","answer":""},{"question":"","answer":""},
          {"question":"Additional question?","answer":"Additional writing must survive."}
        ]}}
        """.utf8)
        var draft = try JSONDecoder().decode(VisualTemplateDraft.self, from: encoded)
        XCTAssertEqual(draft.format.name, "Future Format")
        draft.selectFormat("Matrices")
        draft.setAnswer("Known format writing", at: 0)
        var restored = try JSONDecoder().decode(VisualTemplateDraft.self, from: JSONEncoder().encode(draft))
        restored.selectFormat("Future Format")
        XCTAssertEqual(restored.answers[0], "  Exact future writing.\nSecond line.  ")
        XCTAssertTrue(restored.shareText.contains("Additional question?\nAdditional writing must survive."))
        XCTAssertTrue(restored.shareText.contains("Known format writing"))
    }

    func testSharingIncludesAllExploredWritingBetweenDecideAndDelegateWithoutMutation() throws {
        var entry = Reminder()
        entry.postThemeID = "habit"
        entry.postAnswers = ["Existing Decide writing"]
        entry.title = "Existing Delegate writing"
        entry.visualTemplates = populatedDraft()
        let before = entry
        let text = EntryShareContent(entry: entry, sourceApp: "Understood", entryLabel: "Action", whenIAm: "").entireForm
        let decide = try XCTUnwrap(text.range(of: "Decide\n\n"))
        let visual = try XCTUnwrap(text.range(of: "Visual templates\n\nFormat: Tables"))
        let delegate = try XCTUnwrap(text.range(of: "Delegate\n\n"))
        XCTAssertLessThan(decide.lowerBound, visual.lowerBound)
        XCTAssertLessThan(visual.lowerBound, delegate.lowerBound)
        XCTAssertTrue(text.contains("What relationship should this matrix make clear?\n" + answer("Matrices", 0)))
        XCTAssertTrue(text.contains("Why would a table help explain this?\n" + answer("Tables", 0)))
        XCTAssertEqual(entry, before)
        entry.visualTemplates = nil
        XCTAssertFalse(EntryShareContent(entry: entry, sourceApp: "Understood", entryLabel: "Action", whenIAm: "").entireForm.contains("Visual templates"))
    }

    private func populatedDraft() -> VisualTemplateDraft {
        var draft = VisualTemplateDraft()
        draft.setAnswer(answer("Matrices", 0), at: 0)
        draft.selectFormat("Tables")
        draft.setAnswer(answer("Tables", 0), at: 0)
        return draft
    }

    private func answer(_ format: String, _ index: Int) -> String {
        "  \(format) answer \(index) — “exact words” 🧠\n\n" + String(repeating: "Long writing stays intact.\n", count: 40) + "  Last line.  "
    }
}
