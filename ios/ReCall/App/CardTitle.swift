import SwiftUI
import UIKit

/// Gives inline writing the space normally reserved for iPhone navigation.
@MainActor
final class CardTitleEditingState: ObservableObject {
    static let shared = CardTitleEditingState()
    @Published var isEditing = false
}

@MainActor
final class CardTitleSession: ObservableObject {
    private static weak var active: CardTitleSession?
    fileprivate let cardRegions = NSHashTable<UIView>.weakObjects()
    @Published private(set) var card: CardTitle?
    @Published var draft = ""
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onDelete: (() -> Void)?
    var isEditing: Bool { card != nil }

    func begin(_ card: CardTitle) {
        guard !isEditing else { return }
        if let previous = Self.active, previous !== self {
            previous.finish()
            guard !previous.isEditing else { return }
        }
        draft = CardTitleStore.shared.title(for: card)
        self.card = card
        Self.active = self
        CardTitleEditingState.shared.isEditing = true
    }

    func save() {
        guard let card, CardTitleStore.shared.rename(card, to: draft) else { return }
        cancel()
    }

    func finish() {
        guard isEditing else { return }
        if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { cancel() }
        else { save() }
    }

    func cancel() {
        card = nil
        if Self.active === self {
            Self.active = nil
            CardTitleEditingState.shared.isEditing = false
        }
    }
    func restoreOriginal() {
        guard let card, CardTitleStore.shared.restoreOriginal(card) else { return }
        cancel()
    }
}

private struct CardTitleSessionKey: EnvironmentKey {
    static let defaultValue: CardTitleSession? = nil
}
private struct CardTitleEditingKey: EnvironmentKey {
    static let defaultValue = false
}
extension EnvironmentValues {
    var recallCardTitleSession: CardTitleSession? {
        get { self[CardTitleSessionKey.self] }
        set { self[CardTitleSessionKey.self] = newValue }
    }
    var isEditingRecallCardTitle: Bool {
        get { self[CardTitleEditingKey.self] }
        set { self[CardTitleEditingKey.self] = newValue }
    }
}

/// Replaces only the title, inside its existing card. The surrounding font,
/// foreground, background and underline remain the card's own presentation.
struct CardTitleText: View {
    let card: CardTitle
    var fallback: String? = nil
    var accessibilityIdentifier: String? = nil
    @ObservedObject private var titles = CardTitleStore.shared
    @Environment(\.recallCardTitleSession) private var session
    @Environment(\.isEditingRecallCardTitle) private var isEditing

    var body: some View {
        if isEditing, let session {
            InlineCardTitle(session: session)
        } else {
            Text(titles.title(for: card, fallback: fallback))
                .accessibilityIdentifier(accessibilityIdentifier ?? "cardTitleText-\(card.id)")
        }
    }
}

private struct InlineCardTitle: View {
    @ObservedObject var session: CardTitleSession
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if #available(iOS 18.0, *) {
                    SelectedCardTitleField(text: $session.draft, onSubmit: session.finish)
                } else {
                    TextField("", text: $session.draft, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...8)
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit { session.finish() }
                        .onAppear { focused = true }
                }
            }
            .accessibilityLabel("Card title")
            .accessibilityIdentifier("cardTitleField")
            HStack(spacing: 16) {
                if let remove = session.onDelete {
                    control("Delete", icon: "trash", id: "deleteCard", action: {
                        session.cancel()
                        remove()
                    })
                }
                if let move = session.onMoveUp {
                    control("Move up", icon: "chevron.up", id: "reorderUp", action: move)
                }
                if let move = session.onMoveDown {
                    control("Move down", icon: "chevron.down", id: "reorderDown", action: move)
                }
                Spacer(minLength: 0)
                control("Cancel", icon: "xmark", id: "cancelCardTitle", action: session.cancel)
                if let card = session.card, let title = CardTitleStore.shared.titles[card.id]?.title, !title.isEmpty {
                    control("Use Original Title", icon: "arrow.uturn.backward", id: "restoreCardTitle", action: session.restoreOriginal)
                }
            }
            .font(.system(size: 14, weight: .semibold))
        }
        .id("activeCardTitleEditor")
    }

    private func control(_ title: String, icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).frame(width: 32, height: 32).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(id)
    }
}

private struct CardTitleContext: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var session: CardTitleSession
    func body(content: Content) -> some View {
        content
            .environment(\.recallCardTitleSession, session)
            .environment(\.isEditingRecallCardTitle, session.isEditing)
            .background {
                if session.isEditing {
                    CardTitleOutsideTapRegion(session: session)
                }
            }
            .onDisappear { session.finish() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { session.finish() }
            }
    }
}

/// Observes taps in the card's own window without covering the page or taking
/// touches away from its controls. Keyboard touches belong to another window.
private struct CardTitleOutsideTapRegion: UIViewRepresentable {
    let session: CardTitleSession

    func makeUIView(context: Context) -> CardTitleOutsideTapView {
        CardTitleOutsideTapView(session: session)
    }

    func updateUIView(_ uiView: CardTitleOutsideTapView, context: Context) {}

    static func dismantleUIView(_ uiView: CardTitleOutsideTapView, coordinator: ()) {
        uiView.stopObserving()
    }
}

private final class CardTitleOutsideTapView: UIView, UIGestureRecognizerDelegate {
    private weak var session: CardTitleSession?
    private weak var observedWindow: UIWindow?
    private lazy var outsideTap = UITapGestureRecognizer(target: self, action: #selector(finishEditing))

    init(session: CardTitleSession) {
        self.session = session
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        outsideTap.cancelsTouchesInView = false
        outsideTap.delegate = self
        session.cardRegions.add(self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        observedWindow?.removeGestureRecognizer(outsideTap)
        observedWindow = window
        window?.addGestureRecognizer(outsideTap)
    }

    func stopObserving() {
        observedWindow?.removeGestureRecognizer(outsideTap)
        observedWindow = nil
        session?.cardRegions.remove(self)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let session, session.isEditing, let window, touch.window === window else { return false }
        let point = touch.location(in: window)
        // Completed cards share one session with their title button. Treat all
        // of that card's regions as inside, including padding and other controls.
        return !session.cardRegions.allObjects.contains { region in
            region.window === window && region.convert(region.bounds, to: window).contains(point)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    @objc private func finishEditing() {
        guard outsideTap.state == .ended else { return }
        session?.finish()
    }
}

private struct CardTitleHold: ViewModifier {
    let card: CardTitle
    @ObservedObject var session: CardTitleSession
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .highPriorityGesture(LongPressGesture(minimumDuration: 0.35).onEnded { _ in session.begin(card) })
            .accessibilityAction(named: "Change Title") { session.begin(card) }
    }
}

struct EditableCardButton<Label: View>: View {
    let cardTitle: CardTitle
    var action: () -> Void
    @ViewBuilder var label: Label
    @StateObject private var session: CardTitleSession

    init(cardTitle: CardTitle, session: CardTitleSession? = nil,
         action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.cardTitle = cardTitle
        self.action = action
        self.label = label()
        _session = StateObject(wrappedValue: session ?? CardTitleSession())
    }

    var body: some View {
        ZStack {
            label.allowsHitTesting(session.isEditing)
            CardTitleTapHost(onTap: action, onHold: { session.begin(cardTitle) })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .allowsHitTesting(!session.isEditing)
                .accessibilityHidden(session.isEditing)
                .accessibilityIdentifier("cardHold-\(cardTitle.id)")
        }
        .fixedSize(horizontal: false, vertical: true)
        .recallCardTitleContext(session)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Change Title") { session.begin(cardTitle) }
        .accessibilityAction(named: "Open", action)
    }
}

/// Keeps a card's tap and hold in one stable native view. Vertical pans are left
/// to the ScrollView, and releasing a hold cannot also open the full entry form.
private struct CardTitleTapHost: UIViewRepresentable {
    let onTap: () -> Void
    let onHold: () -> Void

    func makeUIView(context: Context) -> CardTitleTapView { CardTitleTapView() }
    func updateUIView(_ view: CardTitleTapView, context: Context) {
        view.onTap = onTap
        view.onHold = onHold
    }
}

private final class CardTitleTapView: UIView, UIGestureRecognizerDelegate {
    var onTap: (() -> Void)?
    var onHold: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(held(_:)))
        hold.minimumPressDuration = 0.35
        hold.cancelsTouchesInView = false
        hold.delegate = self
        addGestureRecognizer(hold)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        tap.require(toFail: hold)
        addGestureRecognizer(tap)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    @objc private func tapped() { onTap?() }
    @objc private func held(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { onHold?() }
    }
}

extension View {
    func recallCardTitleContext(_ session: CardTitleSession) -> some View {
        modifier(CardTitleContext(session: session))
    }
    func recallCardTitleHold(_ card: CardTitle, session: CardTitleSession) -> some View {
        modifier(CardTitleHold(card: card, session: session))
    }
}

@available(iOS 18.0, *)
private struct SelectedCardTitleField: View {
    @Binding var text: String
    var onSubmit: () -> Void
    @State private var selection: TextSelection?
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $text, selection: $selection, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...8)
            .focused($focused)
            .submitLabel(.done)
            .onSubmit(onSubmit)
            .onAppear {
                selection = TextSelection(insertionPoint: text.endIndex)
                focused = true
            }
    }
}
