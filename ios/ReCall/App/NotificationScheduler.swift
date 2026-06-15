import Foundation
import UserNotifications

/// Local notifications for the Date/Time/Early-Reminder/Repeat parts. One request per reminder,
/// keyed by its id, so rescheduling and cancellation are deterministic.
enum NotificationScheduler {
    static func requestAuth() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func schedule(_ r: Reminder) {
        cancel(r)
        guard r.status == .active, let base = r.fireDate else { return }
        let fire = base.addingTimeInterval(-r.earlyReminder.lead)

        let content = UNMutableNotificationContent()
        content.title = r.title.isEmpty ? "Reminder" : r.title
        if !r.notes.isEmpty { content.body = r.notes }
        content.sound = .default
        if r.urgent { content.interruptionLevel = .timeSensitive }

        let cal = Calendar.current
        let repeats = r.repeatRule != .none
        let comps: DateComponents
        switch r.repeatRule {
        case .none:
            comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        case .daily:
            comps = cal.dateComponents([.hour, .minute], from: fire)
        case .weekly, .weekdays:
            comps = cal.dateComponents([.weekday, .hour, .minute], from: fire)
        case .monthly:
            comps = cal.dateComponents([.day, .hour, .minute], from: fire)
        case .yearly:
            comps = cal.dateComponents([.month, .day, .hour, .minute], from: fire)
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeats)
        let request = UNNotificationRequest(identifier: id(r), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(_ r: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id(r)])
    }

    private static func id(_ r: Reminder) -> String { "recall.reminder.\(r.id.uuidString)" }
}
