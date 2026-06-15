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
        if r.repeatRule == .weekdays {
            let time = cal.dateComponents([.hour, .minute], from: fire)
            for weekday in 2...6 {
                var comps = DateComponents()
                comps.weekday = weekday
                comps.hour = time.hour
                comps.minute = time.minute
                addRequest(identifier: id(r, suffix: "\(weekday)"), content: content, components: comps, repeats: true)
            }
            return
        }

        let comps: DateComponents
        switch r.repeatRule {
        case .none:
            comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        case .daily:
            comps = cal.dateComponents([.hour, .minute], from: fire)
        case .weekly:
            comps = cal.dateComponents([.weekday, .hour, .minute], from: fire)
        case .weekdays:
            return
        case .monthly:
            comps = cal.dateComponents([.day, .hour, .minute], from: fire)
        case .yearly:
            comps = cal.dateComponents([.month, .day, .hour, .minute], from: fire)
        }

        addRequest(identifier: id(r), content: content, components: comps, repeats: repeats)
    }

    static func cancel(_ r: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids(r))
    }

    private static func id(_ r: Reminder) -> String { "recall.reminder.\(r.id.uuidString)" }
    private static func id(_ r: Reminder, suffix: String) -> String { "\(id(r)).\(suffix)" }
    private static func ids(_ r: Reminder) -> [String] { [id(r)] + (2...6).map { id(r, suffix: "\($0)") } }
    private static func addRequest(identifier: String, content: UNNotificationContent, components: DateComponents, repeats: Bool) {
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
