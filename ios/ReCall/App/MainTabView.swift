import SwiftUI

/// App scaffold matching the Figma frames: a custom tan tab bar (Reminders / Tasks / Calendar)
/// and a crimson FAB that floats above it. Reminders is the editorial home; Tasks is the real
/// reminder list; Calendar is a placeholder for now.
struct MainTabView: View {
    @EnvironmentObject var store: ReminderStore
    @State private var tab: Tab = .reminders
    @State private var showingForm = false
    @State private var editing: Reminder?

    enum Tab: CaseIterable { case reminders, tasks, calendar }

    var body: some View {
        ZStack(alignment: .bottom) {
            Brand.page.ignoresSafeArea()
            content
            tabBar
        }
        .overlay(alignment: .bottomTrailing) { fab }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingForm, onDismiss: { editing = nil }) {
            ReminderFormView(existing: editing) { store.save($0) }
        }
    }

    @ViewBuilder private var content: some View {
        switch tab {
        case .reminders:
            RemindersHomeView { _ in editing = nil; showingForm = true }
        case .tasks:
            tasksList
        case .calendar:
            CalendarView { editing = $0; showingForm = true }
        }
    }

    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(store.active) { r in
                    ReminderRowView(reminder: r,
                                    onToggle: { store.complete(r) },
                                    onTap: { editing = r; showingForm = true })
                }
                if !store.completed.isEmpty {
                    HStack {
                        Text("Completed").font(.system(size: 13, weight: .heavy))
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
            .padding(.top, 60)
            .padding(.bottom, 150)
        }
        .background(Brand.page)
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.reminders, icon: "clock", label: "Reminders")
            tabButton(.tasks, icon: "list.bullet", label: "Tasks")
            tabButton(.calendar, icon: "square.grid.2x2", label: "Calendar")
        }
        .padding(.top, 10)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Brand.tan)
        .background(Brand.tan.ignoresSafeArea(edges: .bottom))
    }

    private func tabButton(_ t: Tab, icon: String, label: String) -> some View {
        let active = tab == t
        return Button { tab = t } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 22, weight: .bold))
                Text(label).font(.system(size: 13, weight: .heavy))
            }
            .foregroundStyle(active ? Brand.tabActive : Brand.tabInactive)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var fab: some View {
        Button {
            editing = nil
            showingForm = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Brand.crimson)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.28), radius: 15, y: 14)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 96)
        .accessibilityLabel("New reminder")
    }
}
