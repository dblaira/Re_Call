import SwiftUI
import UIKit

/// App scaffold: a tan tab bar (Reminders ↔ Calendar) with a centered, raised crimson FAB. The FAB
/// is a lightning bolt; press it to "charge" (haptic) and the three entry types fan out — Reminder
/// (left), Action (up), Event (right). Drag onto one and release to pick, or tap one.
struct MainTabView: View {
    @EnvironmentObject var store: ReminderStore
    @State private var tab: Tab = .reminders
    @State private var showingForm = false
    @State private var editing: Reminder?
    @State private var fabMenuOpen = false
    @State private var pendingKind: ReminderKind = .reminder
    @State private var pendingSeed: Reminder?
    @State private var highlighted: ReminderKind?
    @State private var draggingFab = false
    @State private var menuWasOpenAtStart = false

    private let impactGen = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGen = UISelectionFeedbackGenerator()

    enum Tab: CaseIterable { case reminders, calendar }

    var body: some View {
        ZStack(alignment: .bottom) {
            Brand.page.ignoresSafeArea()
            content
            if fabMenuOpen {
                Color.black.opacity(0.45).ignoresSafeArea()
                    .onTapGesture { closeFabMenu() }
                    .transition(.opacity)
            }
            tabBar
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingForm, onDismiss: { editing = nil; pendingSeed = nil }) {
            ReminderFormView(
                initialKind: editing?.kind ?? pendingSeed?.kind ?? pendingKind,
                existing: editing ?? pendingSeed,
                existingTags: knownTags
            ) { store.save($0) }
        }
    }

    @ViewBuilder private var content: some View {
        switch tab {
        case .reminders:
            RemindersHomeView(onPick: { pickShape($0) }, onOpen: { open($0) })
        case .calendar:
            CalendarView(onOpen: { open($0) })
        }
    }

    // MARK: - Tab bar + centered FAB

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.reminders, icon: "clock", label: "Reminders").frame(maxWidth: .infinity)
            Color.clear.frame(width: 76, height: 1)         // gap for the centered FAB
            tabButton(.calendar, icon: "calendar", label: "Calendar").frame(maxWidth: .infinity)
        }
        .padding(.top, 10)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        // Hairline to crisp the edge where the white bar meets the navy feed above it.
        .overlay(alignment: .top) { Rectangle().fill(Color.black.opacity(0.08)).frame(height: 0.5) }
        .overlay(alignment: .top) {
            ZStack {
                if fabMenuOpen {
                    fabOption(.reminder, icon: "clock").offset(x: -76, y: -40)
                    fabOption(.action, icon: "bolt.fill").offset(x: 0, y: -116)
                    fabOption(.event, icon: "calendar").offset(x: 76, y: -40)
                }
                fab.offset(y: -22)
            }
        }
    }

    private func tabButton(_ t: Tab, icon: String, label: String) -> some View {
        let active = tab == t
        return Button { tab = t } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 22, weight: .bold))
                Text(label).font(.system(size: 13, weight: .heavy))
            }
            .foregroundStyle(active ? Brand.nearBlack : Brand.nearBlack.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var fab: some View {
        borderedSymbol(fabMenuOpen ? "xmark" : "bolt.fill")
            .frame(width: 64, height: 64)
            .background(Brand.crimson)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !draggingFab {
                            draggingFab = true
                            menuWasOpenAtStart = fabMenuOpen
                            impactGen.prepare(); selectionGen.prepare()
                            if !fabMenuOpen {
                                impactGen.impactOccurred()
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) { fabMenuOpen = true }
                            }
                        }
                        let target = targetKind(for: value.translation)
                        if target != highlighted {
                            highlighted = target
                            if target != nil { selectionGen.selectionChanged() }
                        }
                    }
                    .onEnded { _ in
                        if let k = highlighted {
                            impactGen.impactOccurred()
                            startEntry(k)
                        } else if menuWasOpenAtStart {
                            closeFabMenu()
                        }
                        draggingFab = false
                        highlighted = nil
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(fabMenuOpen ? "Close menu" : "New entry")
            .accessibilityIdentifier("chargeFab")
            .accessibilityAddTraits(.isButton)
    }

    /// White SF Symbol with a thin black outline (black copy slightly larger, behind the white).
    private func borderedSymbol(_ name: String) -> some View {
        ZStack {
            Image(systemName: name).font(.system(size: 30, weight: .bold)).foregroundStyle(.black)
            Image(systemName: name).font(.system(size: 25, weight: .bold)).foregroundStyle(.white)
        }
    }

    private func fabOption(_ kind: ReminderKind, icon: String) -> some View {
        let active = highlighted == kind
        return Button { startEntry(kind) } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(active ? Brand.crimson : Brand.nearBlack, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(active ? 0.9 : 0.15), lineWidth: 1.5))
                    .scaleEffect(active ? 1.15 : 1)
                Text(kind.label).font(.system(size: 12, weight: .heavy)).foregroundStyle(Brand.crimson)
            }
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    /// Maps a drag offset from the FAB to a fanned option: left = reminder, up = action, right = event.
    private func targetKind(for t: CGSize) -> ReminderKind? {
        guard hypot(t.width, t.height) > 30 else { return nil }
        let a = atan2(-t.height, t.width) * 180 / .pi      // up = +90, right = 0, left = ±180
        if a >= 45 && a < 135 { return .action }
        if a >= -45 && a < 45 { return .event }
        if a >= 135 || a < -135 { return .reminder }
        return nil
    }

    // MARK: - Actions

    /// Tags the user has used before, most-used first — offered as quick picks in the entry form.
    private var knownTags: [String] {
        let counts = Dictionary(store.reminders.flatMap { $0.tags }.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.map(\.key)
    }

    private func closeFabMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { fabMenuOpen = false }
    }
    private func startEntry(_ kind: ReminderKind) {
        pendingKind = kind
        pendingSeed = nil
        editing = nil
        closeFabMenu()
        showingForm = true
    }
    private func pickShape(_ title: String) {
        var draft = Reminder()
        draft.kind = .reminder
        draft.title = title
        pendingKind = .reminder
        pendingSeed = draft
        editing = nil
        showingForm = true
    }
    private func open(_ r: Reminder) { editing = r; pendingSeed = nil; showingForm = true }
}
