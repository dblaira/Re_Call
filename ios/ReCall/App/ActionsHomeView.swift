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
        ScrollView {
            VStack(spacing: 0) {
                hero
                Rectangle().fill(Brand.crimson).frame(height: 2)
                priorityBand
                completedBand
            }
        }
        .background(Brand.page)
        .ignoresSafeArea(edges: .top)
        .accessibilityIdentifier("actionsHome")
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(Brand.serif(48))
                .foregroundStyle(Brand.nearBlack)
            Text("Choose the move that matters.")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Brand.crimson)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 60)
        .padding(.bottom, 18)
        .padding(.horizontal, 16)
        .background(Brand.tan)
    }

    private var priorityBand: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                Text("PRIORITY")
                    .font(.system(size: 15, weight: .heavy))
                    .tracking(2.5)
                    .foregroundStyle(Brand.tan)
                Spacer()
                Text("\(actions.count)")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.45))
            }

            if actions.isEmpty {
                emptyState
            } else {
                ForEach(Array(actions.enumerated()), id: \.element.id) { idx, action in
                    UpNextCardRow(
                        reminderId: action.id,
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
                        .accessibilityIdentifier(idx == 0 ? "topActionCard" : "actionCard")
                    }
                }
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.page)
    }

    @ViewBuilder private var completedBand: some View {
        if !completedActions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Completed")
                    .font(.system(size: 13, weight: .heavy))
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(.black.opacity(0.35))
                ForEach(completedActions.prefix(8)) { action in
                    ItemRow(
                        reminder: action,
                        completed: true,
                        onToggle: { store.uncomplete(action) },
                        onTap: { onOpen(action) },
                        onDelete: { store.delete(action) }
                    )
                }
            }
            .padding(.top, 18)
            .padding(.horizontal, 16)
            .padding(.bottom, 150)
            .background(Color.white)
        } else {
            Color.white.frame(height: 150)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No actions yet.")
                .font(Brand.serif(26))
                .foregroundStyle(.white)
            Text("Tap the charge button and choose Action.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.nearBlack)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func cardActions(_ action: Reminder) -> [SwipeAction] {
        [
            SwipeAction(title: "Done", icon: "checkmark", bg: Brand.crimson) { store.complete(action) },
            SwipeAction(title: action.pinned ? "Unpin" : "Pin", icon: "pin", bg: Brand.tileBlue) { store.togglePin(action) },
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
