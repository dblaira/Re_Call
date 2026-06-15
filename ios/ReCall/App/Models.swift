import Foundation

enum Priority: String, Codable, CaseIterable, Identifiable {
    case none, low, medium, high
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    var marks: String {
        switch self {
        case .none: return ""
        case .low: return "!"
        case .medium: return "!!"
        case .high: return "!!!"
        }
    }
}

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case none, daily, weekdays, weekly, monthly, yearly
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "Never"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

enum EarlyReminder: String, Codable, CaseIterable, Identifiable {
    case none
    case m5 = "5m"
    case m10 = "10m"
    case m30 = "30m"
    case h1 = "1h"
    case d1 = "1d"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "None"
        case .m5: return "5 minutes before"
        case .m10: return "10 minutes before"
        case .m30: return "30 minutes before"
        case .h1: return "1 hour before"
        case .d1: return "1 day before"
        }
    }
    /// Seconds to subtract from the fire date.
    var lead: TimeInterval {
        switch self {
        case .none: return 0
        case .m5: return 300
        case .m10: return 600
        case .m30: return 1800
        case .h1: return 3600
        case .d1: return 86400
        }
    }
}

enum ReminderStatus: String, Codable { case active, completed, deleted }

/// What an item *is*: a timed nudge, a thing you do, or a time block. One model, three faces.
enum ReminderKind: String, Codable, CaseIterable, Identifiable {
    case reminder, action, event
    var id: String { rawValue }
    var label: String {
        switch self {
        case .reminder: return "Reminder"
        case .action: return "Action"
        case .event: return "Event"
        }
    }
}

struct Subtask: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String = ""
    var done: Bool = false
}

/// The domain model. Codable for the on-device cache; mapped to/from DB rows in the repository.
/// Every "part" from the entry form is a field here so nothing the user enters is dropped.
struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var kind: ReminderKind = .reminder         // reminder / action / event (local-first for now)
    // Core
    var title: String = ""
    var notes: String = ""
    var url: String = ""
    var imageLocalPath: String? = nil          // local filename; cloud upload is 1.0.1
    // Date & Time
    var dueDate: Date? = nil                    // calendar date (date-only meaning)
    var dueTime: Date? = nil                    // clock time (time-only meaning)
    var endTime: Date? = nil                    // event end (time-only meaning); local-first for now
    var urgent: Bool = false
    var repeatRule: RepeatRule = .none
    var earlyReminder: EarlyReminder = .none
    // Organization
    var listName: String = "Reminders"
    var flag: Bool = false
    var priority: Priority = .none
    // Places & People
    var locationName: String = ""
    var whenMessagingPerson: String = ""
    // Graph + lifecycle
    var seededFromTemplateID: String? = nil
    var tags: [String] = []
    var subtasks: [Subtask] = []
    var status: ReminderStatus = .active
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date? = nil
    var needsSync: Bool = false
}

extension Reminder {
    /// The concrete moment a notification should fire, if this reminder carries a date and/or time.
    var fireDate: Date? {
        if dueDate == nil && dueTime == nil { return nil }
        let cal = Calendar.current
        let base = dueDate ?? Date()
        var comps = cal.dateComponents([.year, .month, .day], from: base)
        if let t = dueTime {
            let tc = cal.dateComponents([.hour, .minute], from: t)
            comps.hour = tc.hour
            comps.minute = tc.minute
        } else {
            comps.hour = 9
            comps.minute = 0
        }
        return cal.date(from: comps)
    }

    /// Compact "Jun 20 9:30 AM" style label for the row.
    var whenLabel: String? {
        let dayFmt = DateFormatter(); dayFmt.dateFormat = "MMM d"
        let timeFmt = DateFormatter(); timeFmt.dateFormat = "h:mm a"
        if let date = dueDate, let time = dueTime {
            return dayFmt.string(from: date) + " " + timeFmt.string(from: time)
        } else if let date = dueDate {
            return dayFmt.string(from: date)
        } else if let time = dueTime {
            return timeFmt.string(from: time)
        }
        return nil
    }
}

extension JSONEncoder {
    static let recall: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }()
}
extension JSONDecoder {
    static let recall: JSONDecoder = {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }()
}
