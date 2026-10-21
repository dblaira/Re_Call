import SwiftUI

/// The Reminders tab: brand header, active reminders, and completed reminders.
struct RemindersHomeView: View {
    /// Tapping one of your reminders opens it for editing.
    var onOpen: (Reminder) -> Void = { _ in }

    @EnvironmentObject private var store: ReminderStore

    @State private var armedReorderId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            BrandPageHeader(title: "Understood", centered: true) { EmptyView() }
            homeScroll
        }
    }

    @ViewBuilder private var homeScroll: some View {
        Group {
            if #available(iOS 18.0, *) {
                scrollBody.onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { oldY, newY in
                    guard armedReorderId == nil else { return }
                    // Only disarm when the user actually scrolls — not on layout churn from arming
                    // (scale/shadow on the card also fires geometry callbacks).
                    guard abs(newY - oldY) > 0.5 else { return }
                    armedReorderId = nil
                }
            } else {
                scrollBody
            }
        }
    }

    private var scrollBody: some View {
        ScrollView {
            VStack(spacing: 0) {
                band
                completedBand
            }
            .padding(.bottom, 150) // Keep the final reminders above the FAB and tab bar.
        }
        .accessibilityIdentifier("homeScroll")
        // Up Next cards use UIKit gestures (UpNextCardRow) so vertical pans reach this ScrollView
        // on device. SwiftUI DragGesture on every row froze scroll on launch — see HANDOFF §5b.
        .background(Brand.tan)
    }

    /// The "what matters now" feed — reminders, actions, and events together, pinned first then
    /// soonest. The top two render larger (and richer) as an importance signal.
    private var feed: [Reminder] { store.active }

    private func cardActions(_ r: Reminder) -> [SwipeAction] {
        [
            SwipeAction(title: "Done", icon: "checkmark", bg: Brand.tan, foreground: Brand.nearBlack) { store.complete(r) },
            SwipeAction(title: r.pinned ? "Unpin" : "Pin", icon: "pin", bg: Brand.nearBlack) { store.togglePin(r) },
            SwipeAction(title: "Delete", icon: "trash", bg: Color(hex: 0xB00124)) { store.delete(r) },
        ]
    }

    private var band: some View {
        VStack(alignment: .leading, spacing: 8) {
            if feed.isEmpty {
                Text("Nothing yet — tap + to add your first.")
                    .font(.system(size: 15)).foregroundStyle(Brand.nearBlack.opacity(0.65))
                    .padding(.vertical, 6)
            } else {
                ForEach(Array(feed.enumerated()), id: \.element.id) { idx, rem in
                    // Color tiers importance: #1 white, #2 red, everything else black.
                    let c: (bg: Color, fg: Color, accent: Color) =
                        idx == 0 ? (.white, Brand.nearBlack, Brand.crimson)
                        : idx == 1 ? (Brand.darkRed, .white, .white)
                        : (Brand.tan, Brand.nearBlack, Brand.crimson)   // light brown, dark text
                    let detail: CardDetail = idx == 0 ? .full : (idx == 1 ? .medium : .minimal)
                    UpNextCardRow(
                        reminderId: rem.id,
                        cardTitle: .reminder(rem, title: rem.firstThemeAnswer),
                        armedId: $armedReorderId,
                        actions: cardActions(rem),
                        onTap: { onOpen(rem) },
                        onMoveUp: { store.moveUpNext(rem, direction: .up) },
                        onMoveDown: { store.moveUpNext(rem, direction: .down) }
                    ) {
                        // Adam, 2026-10-15: the Theme entry reads first on the main page cards,
                        // never the delegation entry or the question itself.
                        BandCard(reminder: rem, bg: c.bg, fg: c.fg, accent: c.accent,
                                 title: rem.firstThemeAnswer, detail: detail, showsTextDetails: false)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(idx == 0 ? "upNextCard0" : "upNextCard")
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

    /// SAVY's collapsed completed indicator. Closed: `COMPLETED N >`. Open: the rows.
    private var completedBand: some View {
        CompletedBand(
            items: store.completed,
            toggleIdentifier: "completedRemindersToggle",
            onOpen: onOpen,
            onUncomplete: { store.uncomplete($0) },
            onDelete: { store.delete($0) }
        )
    }

}

// MARK: - Feed card

/// How much a card reveals — bigger / more important cards show more. Driven by feed position.
enum CardDetail { case minimal, medium, full }

struct BandCard: View {
    let reminder: Reminder
    let bg: Color
    let fg: Color
    let accent: Color
    var title: String? = nil
    var detail: CardDetail = .minimal
    /// Adam, 2026-10-15: main page cards match SAVY — label, answer, then pills.
    var showsTextDetails: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Type kicker — the marker that tells reminder from action from event.
            HStack(spacing: 6) {
                Image(systemName: kindIcon).font(.system(size: 11, weight: .bold))
                Text(reminder.kind.label.uppercased())
                    .font(.system(size: 11, weight: .heavy)).tracking(1.5)
            }
            .foregroundStyle(fg.opacity(0.7))

            CardTitleText(card: .reminder(reminder, title: title))
                .tint(fg)
                .font(Brand.serif(26, weight: .regular))
                .foregroundStyle(fg)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle().fill(accent).frame(width: 36, height: 2)

            // Pattern step and priority now read as the detail labels below; tags stay as text.
            if showsTextDetails, !tagText.isEmpty {
                Text(tagText)
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(fg.opacity(0.8))
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
            // Demoted but still present: date/time, Lift, location.
            if showsTextDetails, !secondaryText.isEmpty {
                Text(secondaryText).font(.system(size: 12, weight: .medium)).foregroundStyle(fg.opacity(0.5))
            }
            // Notes/outcome only on the larger cards.
            if showsTextDetails, detail != .minimal, let note = detailLine {
                Text(note)
                    .font(.system(size: 14))
                    .foregroundStyle(fg.opacity(0.78))
                    .lineLimit(detail == .full ? 3 : 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // Adam, 2026-10-15: "Add the meta data labels to the cards in the Understood app too."
            // The same Theme, Pattern, Priority and Energy labels as SAVY's main page cards.
            CardDetailPills(details: CardDetailPill.values(for: reminder), colors: pillColors)
                .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08)))
    }

    private var kindIcon: String {
        switch reminder.kind {
        case .reminder: return "clock"
        case .action:   return "bolt"
        case .event:    return "calendar"
        }
    }
    private var detailLine: String? {
        if !reminder.notes.isEmpty { return reminder.notes }
        if !reminder.outcome.isEmpty { return reminder.outcome }
        return nil
    }
    private var tagText: String {
        reminder.tags.map { "#\($0)" }.joined(separator: "   ·   ")
    }
    /// SAVY's muted pills: the card's own color, shaded.
    private var pillColors: CardDetailPills.Colors {
        if bg == Brand.darkRed {
            return .init(background: Color(hex: 0x98011F), text: Color(hex: 0xCEC7C9), icon: Color(hex: 0xCEC7C9))
        }
        if bg == Brand.tan {
            return .init(background: Color(hex: 0xBCA489), text: Color(hex: 0x595653), icon: Brand.crimson)
        }
        return .init(background: Color(hex: 0xEBEBEB), text: Color(hex: 0x737373), icon: Brand.crimson)
    }
    /// Quiet secondary line — Lift and location. Date/time intentionally omitted from cards
    /// (it lives in the entry form); the user doesn't scan for it here.
    private var secondaryText: String {
        var parts: [String] = []
        if !reminder.listName.isEmpty { parts.append(reminder.listName) }        // Lift
        if !reminder.locationName.isEmpty { parts.append(reminder.locationName) }
        return parts.joined(separator: "   ·   ")
    }
}

// MARK: - Detail labels

/// The saved Theme, Pattern, Priority and Energy, shown the way SAVY's main page cards show them.
struct CardDetailPill: Identifiable {
    enum Kind: String { case theme, pattern, priority, energy }

    let kind: Kind
    let text: String
    let systemImage: String
    let accessibilityLabel: String
    var id: Kind { kind }

    static func values(for reminder: Reminder) -> [CardDetailPill] {
        var values: [CardDetailPill] = []
        let savedName = reminder.postThemeName.flatMap { name in
            name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : name
        }
        let theme = PostThemeCatalog.theme(id: reminder.postThemeID)
            ?? PostThemeCatalog.themes.first { $0.name == savedName }
        if let name = theme?.name ?? savedName {
            values.append(CardDetailPill(kind: .theme, text: name,
                                         systemImage: theme?.questions.first?.symbol ?? "list.bullet",
                                         accessibilityLabel: "Theme: \(name)"))
        }
        if reminder.context != .none {
            values.append(CardDetailPill(kind: .pattern, text: reminder.context.label, systemImage: "list.number",
                                         accessibilityLabel: "Pattern: \(reminder.context.label)"))
        }
        if reminder.priority != .none {
            values.append(CardDetailPill(kind: .priority, text: "\(reminder.priority.label) priority",
                                         systemImage: "exclamationmark.3",
                                         accessibilityLabel: "Priority: \(reminder.priority.label)"))
        }
        if reminder.energy != .none {
            values.append(CardDetailPill(kind: .energy, text: "\(reminder.energy.label) energy", systemImage: "bolt",
                                         accessibilityLabel: "Energy: \(reminder.energy.label)"))
        }
        return values
    }
}

/// Theme and Pattern share the first row, Priority and Energy the next, wrapping when needed.
struct CardDetailPills: View {
    struct Colors {
        let background: Color
        let text: Color
        let icon: Color
    }

    let details: [CardDetailPill]
    let colors: Colors

    var body: some View {
        if !details.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                pillRow(details.filter { $0.kind == .theme || $0.kind == .pattern })
                pillRow(details.filter { $0.kind == .priority || $0.kind == .energy })
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.legibilityWeight, .regular)
        }
    }

    @ViewBuilder
    private func pillRow(_ row: [CardDetailPill]) -> some View {
        if !row.isEmpty {
            PillFlowLayout(spacing: 4) {
                ForEach(row) { detail in
                    HStack(spacing: 3) {
                        Image(systemName: detail.systemImage)
                            .font(.system(size: 13, weight: .regular))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(colors.icon)
                            .accessibilityHidden(true)
                        Text(detail.text)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(colors.text)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(colors.background, in: Capsule())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(detail.accessibilityLabel)
                    .accessibilityIdentifier("cardDetail-\(detail.kind.rawValue)")
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PillFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(width: proposal.width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangement(width: bounds.width, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangement(width: CGFloat?, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        guard !subviews.isEmpty else { return (.zero, []) }
        let availableWidth = width.flatMap { $0.isFinite ? max(0, $0) : nil } ?? .greatestFiniteMagnitude
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0
        for subview in subviews {
            let ideal = subview.sizeThatFits(.unspecified)
            let size = subview.sizeThatFits(ProposedViewSize(width: min(ideal.width, availableWidth), height: nil))
            if x > 0, x + size.width > availableWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            usedWidth = max(usedWidth, x + size.width)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: usedWidth, height: y + rowHeight), frames)
    }
}

// MARK: - Shape tile

struct ShapeTileSpec: Identifiable {
    let id: String
    let title: String
    let bg: Color
    let fg: Color
    let tags: [String]
    let height: CGFloat
    let dark: Bool
    let templateID: String?
    var cardTitle: CardTitle { CardTitle(id: "shape:\(id)", original: title) }

    init(
        id: String,
        title: String,
        bg: Color,
        fg: Color,
        tags: [String],
        height: CGFloat,
        dark: Bool,
        templateID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.bg = bg
        self.fg = fg
        self.tags = tags
        self.height = height
        self.dark = dark
        self.templateID = templateID
    }
}

struct ShapeTile: View {
    let spec: ShapeTileSpec
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            grip
            Spacer(minLength: 8)
            VStack(alignment: .leading, spacing: 11) {
                CardTitleText(card: spec.cardTitle)
                    .tint(spec.fg)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(spec.fg)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    ForEach(spec.tags, id: \.self) { tag in tagPill(tag) }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: spec.height, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(spec.bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(spec.dark ? Color.white.opacity(0.14) : Color.black.opacity(0.1)))
    }

    private var grip: some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 1).frame(width: 3, height: 15)
            RoundedRectangle(cornerRadius: 1).frame(width: 3, height: 15)
        }
        .foregroundStyle(spec.fg.opacity(0.5))
    }

    private func tagPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy)).tracking(0.3)
            .foregroundStyle(spec.fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((spec.dark ? Color.white : Color.black).opacity(spec.dark ? 0.16 : 0.06))
            .clipShape(Capsule())
    }
}
