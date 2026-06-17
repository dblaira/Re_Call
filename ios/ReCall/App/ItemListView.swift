import SwiftUI
import UIKit

/// A light-themed list of items of one kind: active rows on top, then completed greyed at the
/// bottom. Each row swipes right to reveal Done/Reopen + Delete. Used by the Reminders and
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
                ItemRow(reminder: r,
                        onToggle: { store.complete(r) },
                        onTap: { onOpen(r) },
                        onDelete: { store.delete(r) })
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

/// One item row on a white page. Tap to open; tap the circle to complete/reopen. Swipe right to
/// reveal Done/Reopen + Delete.
struct ItemRow: View {
    let reminder: Reminder
    var completed: Bool = false
    var onToggle: () -> Void
    var onTap: () -> Void
    var onDelete: (() -> Void)? = nil

    @State private var offset: CGFloat = 0
    private let actionsWidth: CGFloat = 132

    var body: some View {
        ZStack(alignment: .leading) {
            actions
            rowContent
                .background(completed ? Color.black.opacity(0.03) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08)))
                .offset(x: offset)
                .gesture(swipe)
                .onTapGesture {
                    if offset != 0 { withAnimation(.snappy) { offset = 0 } }
                    else { onTap() }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(completed ? 0.7 : 1)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { v in
                guard abs(v.translation.width) > abs(v.translation.height) else { return }
                offset = min(max(v.translation.width, 0), actionsWidth)
            }
            .onEnded { _ in
                withAnimation(.snappy) { offset = offset > actionsWidth / 2 ? actionsWidth : 0 }
            }
    }

    private var actions: some View {
        HStack(spacing: 0) {
            swipeButton(completed ? "Reopen" : "Done",
                        icon: completed ? "arrow.uturn.left" : "checkmark",
                        bg: Brand.crimson) {
                withAnimation(.snappy) { offset = 0 }
                onToggle()
            }
            swipeButton("Delete", icon: "trash", bg: Color(hex: 0xB00124)) {
                withAnimation(.snappy) { offset = 0 }
                onDelete?()
            }
        }
        .frame(width: actionsWidth)
        .frame(maxHeight: .infinity)
    }

    private func swipeButton(_ title: String, icon: String, bg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 16, weight: .bold))
                Text(title).font(.system(size: 11, weight: .heavy))
            }
            .foregroundStyle(.white)
            .frame(width: actionsWidth / 2)
            .frame(maxHeight: .infinity)
            .background(bg)
        }
        .buttonStyle(.plain)
    }

    private var rowContent: some View {
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
            if !completed { trailingMeta }
        }
        .padding(12)
        .contentShape(Rectangle())
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

// MARK: - Reusable swipe container

/// One revealed action behind a swiped row.
struct SwipeAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let bg: Color
    let run: () -> Void
}

/// Wraps any row content and reveals leading action buttons on a right-swipe. Tap (when closed)
/// fires `onTap`; tap (when open) closes. Works inside a ScrollView.
///
/// Optional reorder: long-press (~0.35s, finger still down), then drag vertically. Horizontal
/// swipe and reorder share one drag handler so they don't block each other.
struct SwipeRow<Content: View>: View {
    let actions: [SwipeAction]
    var onTap: () -> Void = {}
    var cornerRadius: CGFloat = 12
    var swipeEnabled: Bool = true
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    @ViewBuilder var content: Content

    @State private var offset: CGFloat = 0
    @State private var reordering = false
    private var actionsWidth: CGFloat { CGFloat(actions.count) * 64 }
    private var supportsReorder: Bool { onMoveUp != nil || onMoveDown != nil }

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                ForEach(actions) { a in
                    Button {
                        withAnimation(.snappy) { offset = 0 }
                        a.run()
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: a.icon).font(.system(size: 16, weight: .bold))
                            Text(a.title).font(.system(size: 10, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 64)
                        .frame(maxHeight: .infinity)
                        .background(a.bg)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: actionsWidth)
            .frame(maxHeight: .infinity)

            interactiveContent
        }
    }

    @ViewBuilder private var interactiveContent: some View {
        let row = ZStack(alignment: .topTrailing) {
            content
            if reordering {
                ReorderGrip()
                    .padding(12)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .overlay {
            if supportsReorder && reordering {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius + 3)
                        .strokeBorder(Brand.crimson.opacity(0.45), lineWidth: 8)
                        .padding(-4)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Brand.crimson, lineWidth: 4)
                }
            }
        }
        .offset(x: offset)
        .scaleEffect(reordering ? 1.04 : 1)
        .shadow(color: reordering ? Brand.crimson.opacity(0.55) : .clear, radius: 22, y: 0)
        .shadow(color: reordering ? Brand.crimson.opacity(0.3) : .clear, radius: 6, y: 2)
        .animation(.snappy, value: reordering)
        .onTapGesture {
            if offset != 0 { withAnimation(.snappy) { offset = 0 } }
            else { onTap() }
        }

        if supportsReorder {
            row
                .simultaneousGesture(swipeDragGesture)
                .simultaneousGesture(reorderDragGesture)
                .simultaneousGesture(reorderArmGesture)
                .onDisappear { disarmReorder() }
        } else {
            row.gesture(swipeDragGesture)
        }
    }

    private func disarmReorder() {
        guard reordering else { return }
        withAnimation(.snappy) { reordering = false }
    }

    private var reorderArmGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .onEnded { _ in armReorder() }
    }

    private func armReorder() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) {
            reordering = true
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Horizontal swipe — simultaneous so vertical pans reach the ScrollView.
    private var swipeDragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { v in
                guard !reordering else { return }
                guard swipeEnabled else { return }
                guard abs(v.translation.width) > abs(v.translation.height) else { return }
                offset = min(max(v.translation.width, 0), actionsWidth)
            }
            .onEnded { _ in
                guard !reordering else { return }
                guard swipeEnabled else { return }
                withAnimation(.snappy) { offset = offset > actionsWidth / 2 ? actionsWidth : 0 }
            }
    }

    /// Active only after long-press arms reorder; always disarms on finger up.
    private var reorderDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { v in
                guard reordering else { return }
                defer { disarmReorder() }
                let t = v.translation
                if abs(t.height) > abs(t.width), abs(t.height) > 20 {
                    if t.height < 0 { onMoveUp?() }
                    else { onMoveDown?() }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

/// Grip affordance — crimson so it reads on white, tan, and dark cards.
private struct ReorderGrip: View {
    var body: some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 1).frame(width: 3, height: 15)
            RoundedRectangle(cornerRadius: 1).frame(width: 3, height: 15)
        }
        .foregroundStyle(Brand.crimson)
    }
}
