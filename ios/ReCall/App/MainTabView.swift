import SwiftUI

/// App scaffold: a custom tan tab bar (Reminders / Actions / Calendar) and a crimson FAB. Each tab
/// owns its type — Reminders lists reminders (under the story gallery), Actions lists actions,
/// Calendar is the time view. The FAB opens the entry form defaulted to the current tab's type.
struct MainTabView: View {
    @EnvironmentObject var store: ReminderStore
    @State private var tab: Tab = .reminders
    @State private var showingForm = false
    @State private var editing: Reminder?

    enum Tab: CaseIterable { case reminders, actions, calendar }

    var body: some View {
        ZStack(alignment: .bottom) {
            Brand.page.ignoresSafeArea()
            content
            tabBar
        }
        .overlay(alignment: .bottomTrailing) { fab }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingForm, onDismiss: { editing = nil }) {
            ReminderFormView(initialKind: editing?.kind ?? defaultKind, existing: editing) { store.save($0) }
        }
    }

    @ViewBuilder private var content: some View {
        switch tab {
        case .reminders:
            RemindersHomeView(onPick: { _ in newItem() }, onOpen: { open($0) })
        case .actions:
            actionsPage
        case .calendar:
            CalendarView(onOpen: { open($0) })
        }
    }

    private var actionsPage: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Actions")
                    .font(Brand.serif(40)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 60).padding(.bottom, 18).padding(.horizontal, 16)
                    .background(Brand.nearBlack)
                Rectangle().fill(Brand.crimson).frame(height: 2)
                ItemListView(kind: .action, onOpen: { open($0) })
                    .padding(16)
                    .padding(.bottom, 150)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.reminders, icon: "clock", label: "Reminders")
            tabButton(.actions, icon: "bolt", label: "Actions")
            tabButton(.calendar, icon: "calendar", label: "Calendar")
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
        Button { newItem() } label: {
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
        .accessibilityLabel("New item")
    }

    // MARK: - Actions

    private var defaultKind: ReminderKind {
        switch tab {
        case .reminders: return .reminder
        case .actions: return .action
        case .calendar: return .event
        }
    }

    private func newItem() { editing = nil; showingForm = true }
    private func open(_ r: Reminder) { editing = r; showingForm = true }
}
