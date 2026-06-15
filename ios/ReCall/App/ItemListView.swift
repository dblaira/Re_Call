import SwiftUI

/// A light-themed list of items of one kind: active rows on top, then completed greyed at the
/// bottom — tap the check to reopen, the trash to permanently delete. Used by the Reminders and
/// Actions tabs, both of which sit on a white page.
struct ItemListView: View {
    @EnvironmentObject var store: ReminderStore
    let kind: ReminderKind
    var onOpen: (Reminder) -> Void

    var body: some View {
        let active = store.active.filter { $0.kind == kind }
        let done = store.completed.filter { $0.kind == kind }
        VStack(alignment: .leading, spacing: 10) {
            if active.isEmpty && done.isEmpty {
                Text("Nothing here yet — tap + to add one.")
                    .font(.system(size: 15)).foregroundStyle(.black.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            ForEach(active) { r in
                ItemRow(reminder: r, onToggle: { store.complete(r) }, onTap: { onOpen(r) })
            }
            if !done.isEmpty {
                Text("Completed")
                    .font(.system(size: 13, weight: .heavy)).textCase(.uppercase)
                    .foregroundStyle(.black.opacity(0.35))
                    .padding(.top, 10)
                ForEach(done) { r in
                    ItemRow(reminder: r, completed: true,
                            onToggle: { store.uncomplete(r) },
                            onTap: { onOpen(r) },
                            onDelete: { store.delete(r) })
                }
            }
        }
    }
}

/// One item row on a white page. Active: check to complete, meta on the right. Completed: greyed
/// and struck through, with reopen (the check) and a trash to permanently delete.
struct ItemRow: View {
    let reminder: Reminder
    var completed: Bool = false
    var onToggle: () -> Void
    var onTap: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(completed ? Brand.crimson : Color.black.opacity(0.3))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title.isEmpty ? "Untitled" : reminder.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(completed ? .black.opacity(0.4) : .black)
                    .strikethrough(completed)
                    .lineLimit(2)
                if let sub = subtitle {
                    Text(sub).font(.system(size: 14)).foregroundStyle(.black.opacity(0.45)).lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if completed {
                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash").font(.system(size: 16)).foregroundStyle(.black.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                trailingMeta
            }
        }
        .padding(12)
        .background(completed ? Color.black.opacity(0.03) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08)))
        .opacity(completed ? 0.7 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder private var trailingMeta: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 5) {
                if reminder.flag {
                    Image(systemName: "flag.fill").font(.system(size: 12)).foregroundStyle(Brand.crimson)
                }
                if reminder.priority != .none {
                    Text(reminder.priority.marks).font(.system(size: 13, weight: .heavy)).foregroundStyle(Brand.crimson)
                }
            }
            if let when = reminder.whenLabel {
                Text(when).font(.system(size: 13, weight: .bold)).foregroundStyle(Brand.crimson)
            }
        }
    }

    private var subtitle: String? {
        if !reminder.notes.isEmpty { return reminder.notes }
        let extras = [
            reminder.listName == "Reminders" ? "" : reminder.listName,
            reminder.locationName,
            reminder.tags.map { "#\($0)" }.joined(separator: " "),
        ].filter { !$0.isEmpty }
        return extras.isEmpty ? nil : extras.joined(separator: " · ")
    }
}
