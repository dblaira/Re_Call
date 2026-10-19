import SwiftUI

/// Dedicated Actions tab. Same editorial language as Reminders, but narrowed to things Adam can do.
struct ActionsHomeView: View {
    var onOpen: (Reminder) -> Void = { _ in }

    @EnvironmentObject private var store: ReminderStore
    @State private var armedReorderId: UUID?

    private var actions: [Reminder] {
        store.active.filter { $0.kind == .action }
    }

    private var completedActions: [Reminder] {
        store.completed.filter { $0.kind == .action }
    }

    var body: some View {
        VStack(spacing: 0) {
            BrandPageHeader(title: "Actions") { EmptyView() }
            ScrollView {
                VStack(spacing: 0) {
                    priorityBand
                    completedBand
                }
            }
            .accessibilityIdentifier("actionsHome")
        }
        .background(Brand.tan)
    }

    private var priorityBand: some View {
        VStack(alignment: .leading, spacing: 10) {
            if actions.isEmpty {
                emptyState
            } else {
                ForEach(Array(actions.enumerated()), id: \.element.id) { idx, action in
                    UpNextCardRow(
                        reminderId: action.id,
                        cardTitle: .reminder(action),
                        armedId: $armedReorderId,
                        actions: cardActions(action),
                        onTap: { onOpen(action) },
                        onMoveUp: { store.moveUpNext(action, direction: .up) },
                        onMoveDown: { store.moveUpNext(action, direction: .down) }
                    ) {
                        BandCard(
                            reminder: action,
                            bg: cardColors(for: idx).bg,
                            fg: cardColors(for: idx).fg,
                            accent: cardColors(for: idx).accent,
                            detail: idx == 0 ? .full : (idx == 1 ? .medium : .minimal)
                        )
                        .scaleEffect(x: 1, y: cardScale(for: idx), anchor: .top)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(idx == 0 ? "topActionCard" : "actionCard")
                    }
                }
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.tan)
    }

    @ViewBuilder private var completedBand: some View {
        if completedActions.isEmpty {
            Brand.tan.frame(height: 150)
        } else {
            CompletedBand(
                items: completedActions,
                toggleIdentifier: "completedActionsToggle",
                onOpen: onOpen,
                onUncomplete: { store.uncomplete($0) },
                onDelete: { store.delete($0) },
                bottomPadding: 150
            )
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No actions yet.")
                .font(Brand.serif(26))
                .foregroundStyle(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.nearBlack)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func cardActions(_ action: Reminder) -> [SwipeAction] {
        [
            SwipeAction(title: "Done", icon: "checkmark", bg: Brand.tan, foreground: Brand.nearBlack) { store.complete(action) },
            SwipeAction(title: action.pinned ? "Unpin" : "Pin", icon: "pin", bg: Brand.nearBlack) { store.togglePin(action) },
            SwipeAction(title: "Delete", icon: "trash", bg: Color(hex: 0xB00124)) { store.delete(action) },
        ]
    }

    private func cardColors(for index: Int) -> (bg: Color, fg: Color, accent: Color) {
        switch index {
        case 0: return (.white, Brand.nearBlack, Brand.crimson)
        case 1: return (Brand.darkRed, .white, .white)
        default: return (Brand.tan, Brand.nearBlack, Brand.crimson)
        }
    }

    private func cardScale(for index: Int) -> CGFloat {
        switch index {
        case 0: return 1.08
        case 1: return 1.02
        default: return 1
        }
    }
}
