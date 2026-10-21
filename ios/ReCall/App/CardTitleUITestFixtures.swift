#if DEBUG
import Foundation

/// Only the isolated UI-test store can receive these fixtures. Never exports or schedules them.
enum CardTitleUITestFixtures {
    static func seedIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("RECALL_UI_TEST_ISOLATED"),
              arguments.contains("RECALL_UI_TEST_CARD_TITLES"),
              ICloudReminderCache.load().isEmpty else { return }
        var action = Reminder()
        action.kind = .action
        action.title = "Original action writing"
        action.notes = "Original notes stay here"
        action.postAnswers = ["Original theme answer"]
        action.upNextOrder = 0
        var reminder = Reminder()
        reminder.title = "Original reminder writing"
        reminder.upNextOrder = 1
        var completed = Reminder()
        completed.title = "Original completed writing"
        completed.kind = .action
        completed.status = .completed
        completed.completedAt = Date()
        var allDay = Reminder()
        allDay.kind = .event
        allDay.title = "Original all-day writing"
        allDay.dueDate = Date()
        allDay.upNextOrder = 2
        var timed = Reminder()
        timed.kind = .event
        timed.title = "Original timed writing"
        timed.dueDate = Date()
        timed.dueTime = Date()
        timed.upNextOrder = 3
        var fixtures = [action, reminder, completed, allDay, timed]
        if arguments.contains("RECALL_UI_TEST_LONG_FEED") {
            for index in 0..<8 {
                var extra = Reminder()
                extra.title = "Scroll reminder \(index + 1)"
                extra.upNextOrder = index + 4
                fixtures.append(extra)
            }
        }
        ICloudReminderCache.save(fixtures)
    }
}
#endif
