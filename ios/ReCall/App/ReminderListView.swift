import SwiftUI

/// The primary native surface: a black page listing active reminders, a crimson FAB that opens
/// the full-page form, and a completed section (retained).
struct ReminderListView: View {
    @EnvironmentObject var store: ReminderStore
    @State private var showingForm = false
    @State private var editing: Reminder?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Brand.page.ignoresSafeArea()
                content
                fab
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Notorious").font(Brand.serif(26)).foregroundStyle(.white)
                }
            }
            .toolbarBackground(Brand.page, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // UI-test / screenshot affordance only; never fires in normal use.
                if ProcessInfo.processInfo.arguments.contains("-recallOpenForm") { showingForm = true }
            }
        }
        .sheet(isPresented: $showingForm, onDismiss: { editing = nil }) {
            ReminderFormView(existing: editing) { store.save($0) }
        }
    }

    @ViewBuilder private var content: some View {
        if store.active.isEmpty && store.completed.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(store.active) { r in
                        ReminderRowView(reminder: r,
                                        onToggle: { store.complete(r) },
                                        onTap: { editing = r; showingForm = true })
                    }
                    if !store.completed.isEmpty {
                        HStack {
                            Text("Completed").font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(.white.opacity(0.4)).textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.top, 18).padding(.horizontal, 4)
                        ForEach(store.completed) { r in
                            ReminderRowView(reminder: r, completed: true,
                                            onToggle: { store.uncomplete(r) },
                                            onTap: { editing = r; showingForm = true })
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 100)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("Re_Call").font(Brand.serif(34)).foregroundStyle(.white)
            Text("Tap + to capture your first reminder.")
                .font(.system(size: 17)).foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fab: some View {
        Button {
            editing = nil
            showingForm = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Brand.crimson)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 28)
        .accessibilityLabel("New reminder")
    }
}

/// A row in the reminders list — title, a one-line subtitle, and crimson flag/priority/when meta.
struct ReminderRowView: View {
    let reminder: Reminder
    var completed: Bool = false
    var onToggle: () -> Void
    var onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(completed ? Brand.crimson : Color.white.opacity(0.5))
            }
            .buttonStyle(.plain)

            if let img = LocalImageStore.load(reminder.imageLocalPath) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 38, height: 38).clipShape(RoundedRectangle(cornerRadius: 9))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title.isEmpty ? "Untitled" : reminder.title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(completed ? .white.opacity(0.5) : .white)
                    .strikethrough(completed)
                    .lineLimit(2)
                if let sub = subtitle {
                    Text(sub).font(.system(size: 16)).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 5) {
                    if reminder.flag {
                        Image(systemName: "flag.fill").font(.system(size: 13)).foregroundStyle(Brand.crimson)
                    }
                    if reminder.priority != .none {
                        Text(reminder.priority.marks).font(.system(size: 14, weight: .heavy)).foregroundStyle(Brand.crimson)
                    }
                }
                if let when = reminder.whenLabel {
                    Text(when).font(.system(size: 14, weight: .bold)).foregroundStyle(Brand.crimson)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08)))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
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
