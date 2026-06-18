import SwiftUI
import UIKit

/// Up Next feed row: UIKit pan/long-press so vertical scroll isn't stolen from the parent ScrollView.
struct UpNextCardRow<Content: View>: View {
    let reminderId: UUID
    @Binding var armedId: UUID?
    let actions: [SwipeAction]
    var onTap: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    @ViewBuilder var content: Content

    @State private var swipeOffset: CGFloat = 0
    private var actionsWidth: CGFloat { CGFloat(actions.count) * 64 }
    private var isArmed: Bool { armedId == reminderId }

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                ForEach(actions) { a in
                    Button {
                        withAnimation(.snappy) { swipeOffset = 0 }
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

            ZStack(alignment: .topTrailing) {
                content
                    .allowsHitTesting(false)
                UpNextGestureHost(
                    armedId: $armedId,
                    reminderId: reminderId,
                    actionsWidth: actionsWidth,
                    swipeOffset: $swipeOffset,
                    onTap: onTap,
                    onMoveUp: onMoveUp,
                    onMoveDown: onMoveDown
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                if isArmed {
                    reorderControls
                        .padding(8)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .overlay {
                if isArmed {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(Brand.crimson.opacity(0.45), lineWidth: 8)
                            .padding(-4)
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Brand.crimson, lineWidth: 4)
                    }
                }
            }
            .offset(x: swipeOffset)
            .scaleEffect(isArmed ? 1.04 : 1)
            .shadow(color: isArmed ? Brand.crimson.opacity(0.55) : .clear, radius: 22, y: 0)
            .shadow(color: isArmed ? Brand.crimson.opacity(0.3) : .clear, radius: 6, y: 2)
            .animation(.snappy, value: isArmed)
        }
        .onDisappear {
            if isArmed { armedId = nil }
        }
    }

    /// Up/down chevrons while armed — SwiftUI buttons, not gestures, so scroll stays safe.
    private var reorderControls: some View {
        VStack(spacing: 2) {
            reorderButton("chevron.up", action: onMoveUp)
            reorderButton("chevron.down", action: onMoveDown)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.crimson.opacity(0.55)))
    }

    private func reorderButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Brand.crimson)
                .frame(width: 40, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(icon == "chevron.up" ? "reorderUp" : "reorderDown")
    }
}

// MARK: - UIKit gesture surface (scroll-friendly)

private struct UpNextGestureHost: UIViewRepresentable {
    @Binding var armedId: UUID?
    let reminderId: UUID
    let actionsWidth: CGFloat
    @Binding var swipeOffset: CGFloat
    var onTap: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UpNextGestureView {
        let view = UpNextGestureView()
        view.coordinator = context.coordinator
        context.coordinator.view = view
        view.pan.delegate = context.coordinator
        view.longPress.delegate = context.coordinator
        view.tap.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UpNextGestureView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: UpNextGestureHost
        weak var view: UpNextGestureView?

        init(parent: UpNextGestureHost) { self.parent = parent }

        func isArmed() -> Bool { parent.armedId == parent.reminderId }

        func arm() {
            guard parent.armedId != parent.reminderId else { return }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) {
                    self.parent.armedId = self.parent.reminderId
                }
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        func disarm() {
            guard parent.armedId == parent.reminderId else { return }
            DispatchQueue.main.async {
                withAnimation(.snappy) { self.parent.armedId = nil }
            }
        }

        func setSwipeOffset(_ x: CGFloat) {
            DispatchQueue.main.async { self.parent.swipeOffset = x }
        }

        func settleSwipe(open: Bool) {
            DispatchQueue.main.async {
                withAnimation(.snappy) {
                    self.parent.swipeOffset = open ? self.parent.actionsWidth : 0
                }
            }
        }

        func moveUp() { DispatchQueue.main.async { self.parent.onMoveUp() } }
        func moveDown() { DispatchQueue.main.async { self.parent.onMoveDown() } }

        func tap() {
            DispatchQueue.main.async {
                if self.isArmed() {
                    self.disarm()
                } else if self.parent.swipeOffset != 0 {
                    withAnimation(.snappy) { self.parent.swipeOffset = 0 }
                } else {
                    self.parent.onTap()
                }
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let view else { return true }
            if gestureRecognizer === view.pan {
                // Never claim pans while reorder is armed — let the ScrollView keep vertical scroll.
                if view.reorderArmed || isArmed() { return false }
                let v = view.pan.velocity(in: view)
                return v.x > 0 && abs(v.x) > abs(v.y) * 1.15
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

private final class UpNextGestureView: UIView {
    weak var coordinator: UpNextGestureHost.Coordinator?

    fileprivate let pan = UIPanGestureRecognizer()
    fileprivate let longPress = UILongPressGestureRecognizer()
    fileprivate let tap = UITapGestureRecognizer()
    fileprivate var reorderArmed = false
    private var longPressStartY: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true

        pan.cancelsTouchesInView = false
        pan.addTarget(self, action: #selector(handlePan))
        addGestureRecognizer(pan)

        longPress.cancelsTouchesInView = false
        longPress.addTarget(self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.35
        addGestureRecognizer(longPress)

        tap.cancelsTouchesInView = false
        tap.addTarget(self, action: #selector(handleTap))
        tap.require(toFail: longPress)
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    @objc private func handleTap() {
        coordinator?.tap()
    }

    @objc private func handleLongPress() {
        switch longPress.state {
        case .began:
            reorderArmed = true
            longPressStartY = longPress.location(in: self).y
            coordinator?.arm()
        case .ended, .cancelled, .failed:
            let dy = longPress.location(in: self).y - longPressStartY
            if abs(dy) > 20 {
                if dy < 0 { coordinator?.moveUp() }
                else { coordinator?.moveDown() }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                coordinator?.disarm()
            }
            // Release without a drag keeps the card armed so chevron taps can move it.
            reorderArmed = false
        default:
            break
        }
    }

    @objc private func handlePan() {
        guard let coordinator else { return }
        guard !reorderArmed, !coordinator.isArmed() else { return }
        switch pan.state {
        case .changed:
            let t = pan.translation(in: self)
            guard abs(t.x) > abs(t.y) else { return }
            coordinator.setSwipeOffset(min(max(t.x, 0), coordinator.parent.actionsWidth))
        case .ended, .cancelled, .failed:
            pan.setTranslation(.zero, in: self)
            coordinator.settleSwipe(open: coordinator.parent.swipeOffset > coordinator.parent.actionsWidth / 2)
        default:
            break
        }
    }
}
