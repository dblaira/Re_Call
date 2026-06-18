import SwiftUI

/// The Reminders tab: editorial home — brand hero, Up Next feed, and reminder-shape tiles.
struct RemindersHomeView: View {
    /// Tapping a shape tile starts a new reminder seeded with a title.
    var onPick: (String) -> Void = { _ in }
    /// Tapping one of your reminders opens it for editing.
    var onOpen: (Reminder) -> Void = { _ in }

    @EnvironmentObject private var store: ReminderStore

    private let leftTiles: [ShapeTileSpec] = [
        .init(title: "Add one movement",        bg: Brand.primaryBlue,   fg: .white, tags: ["PHOTO", "TIME", "URL"], height: 190, dark: true),
        .init(title: "Pay before due",          bg: Brand.primaryYellow, fg: .black, tags: ["DATE"],                 height: 135, dark: false),
        .init(title: "Bring this when I leave", bg: Brand.primaryGreen,  fg: .white, tags: ["PLACE", "PHOTO"],       height: 150, dark: true),
    ]
    private let rightTiles: [ShapeTileSpec] = [
        .init(title: "Text them back",        bg: Brand.crimson,   fg: .white, tags: ["PERSON"],       height: 190, dark: true),
        .init(title: "Do this after workout", bg: Brand.nearBlack, fg: .white, tags: ["TIME", "CUE"], height: 190, dark: true),
    ]

    @State private var armedReorderId: UUID?

    var body: some View {
        homeScroll
    }

    @ViewBuilder private var homeScroll: some View {
        Group {
            if #available(iOS 18.0, *) {
                scrollBody.onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { oldY, newY in
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
                hero
                Rectangle().fill(Brand.crimson).frame(height: 2)
                band
                shapes
            }
        }
        .accessibilityIdentifier("homeScroll")
        // Up Next cards use UIKit gestures (UpNextCardRow) so vertical pans reach this ScrollView
        // on device. SwiftUI DragGesture on every row froze scroll on launch — see HANDOFF §5b.
        .background(Brand.page)
        .ignoresSafeArea(edges: .top)
    }

    private var hero: some View {
        Text("Notorious")
            .font(Brand.serif(48))
            .foregroundStyle(Brand.nearBlack)
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
            .padding(.bottom, 18)
            .padding(.horizontal, 16)
            .background(Brand.tan)
    }

    /// The "what matters now" feed — reminders, actions, and events together, pinned first then
    /// soonest. The top two render larger (and richer) as an importance signal.
    private var feed: [Reminder] { store.active }

    private func cardActions(_ r: Reminder) -> [SwipeAction] {
        [
            SwipeAction(title: "Done", icon: "checkmark", bg: Brand.crimson) { store.complete(r) },
            SwipeAction(title: r.pinned ? "Unpin" : "Pin", icon: "pin", bg: Brand.tileBlue) { store.togglePin(r) },
            SwipeAction(title: "Delete", icon: "trash", bg: Color(hex: 0xB00124)) { store.delete(r) },
        ]
    }

    private var band: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("UP NEXT")
                    .font(.system(size: 15, weight: .heavy)).tracking(2.5)
                    .foregroundStyle(Brand.tan)
                Spacer()
            }
            if feed.isEmpty {
                Text("Nothing yet — tap + to add your first.")
                    .font(.system(size: 15)).foregroundStyle(.white.opacity(0.5))
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
                        armedId: $armedReorderId,
                        actions: cardActions(rem),
                        onTap: { onOpen(rem) },
                        onMoveUp: { store.moveUpNext(rem, direction: .up) },
                        onMoveDown: { store.moveUpNext(rem, direction: .down) }
                    ) {
                        BandCard(reminder: rem, bg: c.bg, fg: c.fg, accent: c.accent, detail: detail)
                            .accessibilityIdentifier(idx == 0 ? "upNextCard0" : "upNextCard")
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

    private var shapes: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reminder shapes")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.black)
                    .accessibilityIdentifier("reminderShapes")
                Spacer()
                Text("Edit")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Brand.crimson)
            }
            HStack(alignment: .top, spacing: 10) {
                column(leftTiles)
                column(rightTiles)
            }
        }
        .padding(.top, 18)
        .padding(.horizontal, 16)
        .padding(.bottom, 150)   // clearance for the FAB + tab bar
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    private func column(_ tiles: [ShapeTileSpec]) -> some View {
        VStack(spacing: 10) {
            ForEach(tiles) { spec in
                Button { onPick(spec.title) } label: { ShapeTile(spec: spec) }
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
    var detail: CardDetail = .minimal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Type kicker — the marker that tells reminder from action from event.
            HStack(spacing: 6) {
                Image(systemName: kindIcon).font(.system(size: 11, weight: .bold))
                Text(reminder.kind.label.uppercased())
                    .font(.system(size: 11, weight: .heavy)).tracking(1.5)
            }
            .foregroundStyle(fg.opacity(0.7))

            Text(reminder.title.isEmpty ? "Untitled" : reminder.title)
                .font(Brand.serif(26, weight: .regular))
                .foregroundStyle(fg)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle().fill(accent).frame(width: 36, height: 2)

            // Prominent: the signals worth scanning for — Pattern step, priority, tags.
            if !signalText.isEmpty {
                Text(signalText)
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(fg.opacity(0.8))
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
            // Demoted but still present: date/time, Lift, location.
            if !secondaryText.isEmpty {
                Text(secondaryText).font(.system(size: 12, weight: .medium)).foregroundStyle(fg.opacity(0.5))
            }
            // Notes/outcome only on the larger cards.
            if detail != .minimal, let note = detailLine {
                Text(note)
                    .font(.system(size: 14))
                    .foregroundStyle(fg.opacity(0.78))
                    .lineLimit(detail == .full ? 3 : 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
    /// Prominent signal line — what the user scans for.
    private var signalText: String {
        var parts: [String] = []
        if reminder.context != .none { parts.append(reminder.context.label) }    // Adam Pattern step
        if reminder.priority != .none { parts.append(reminder.priority.marks) }
        parts.append(contentsOf: reminder.tags.map { "#\($0)" })
        return parts.joined(separator: "   ·   ")
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

// MARK: - Shape tile

struct ShapeTileSpec: Identifiable {
    let id = UUID()
    let title: String
    let bg: Color
    let fg: Color
    let tags: [String]
    let height: CGFloat
    let dark: Bool
}

struct ShapeTile: View {
    let spec: ShapeTileSpec
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            grip
            Spacer(minLength: 8)
            VStack(alignment: .leading, spacing: 11) {
                Text(spec.title)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(spec.fg)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    ForEach(spec.tags, id: \.self) { tag in tagPill(tag) }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: spec.height, alignment: .topLeading)
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
