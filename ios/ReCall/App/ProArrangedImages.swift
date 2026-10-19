import SwiftUI
import UniformTypeIdentifiers

struct ProArrangedImages: View {
    @ObservedObject var library: ProImageStore
    let arranging: Bool
    let importing: Bool
    let availableWidth: CGFloat
    var addImage: (UUID, ProImageImportSource) -> Void
    var open: (ProImageCard) -> Void
    var report: (String) -> Void
    @State private var saving = false

    var body: some View {
        VStack(spacing: 24) {
            ForEach(library.arrangement.areas) { area in
                if area.style == .row {
                    row(area)
                } else if arranging || !area.cardIDs.isEmpty {
                    grid(area)
                }
            }
        }
        .disabled(saving)
    }

    private func grid(_ area: ProLibraryArrangement.Area) -> some View {
        let cards = library.cards(in: area)
        return VStack(alignment: .leading, spacing: 14) {
            if arranging { heading(area) }
            HStack(alignment: .top, spacing: 12) {
                column(cards.enumerated().filter { $0.offset.isMultiple(of: 2) }.map(\.element), area: area)
                    .frame(width: max(1, availableWidth - 48) * 0.58)
                column(cards.enumerated().filter { !$0.offset.isMultiple(of: 2) }.map(\.element), area: area)
                    .frame(width: max(1, availableWidth - 48) * 0.42)
            }
            if arranging {
                dropTarget(area)
                Button {
                    change { $0.addRow(after: area.id) }
                } label: {
                    Label("Add row here", systemImage: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.plain).foregroundStyle(.white)
                .accessibilityIdentifier("proAddRow-\(area.id)")
            }
        }
        .padding(.horizontal, 18)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("proGrid-\(area.id)")
    }

    private func column(_ cards: [ProImageCard], area: ProLibraryArrangement.Area) -> some View {
        LazyVStack(spacing: 14) {
            ForEach(cards) { card in tile(card, area: area) }
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ area: ProLibraryArrangement.Area) -> some View {
        let cards = library.cards(in: area)
        let sizes = rowSizes(cards)
        return VStack(alignment: .leading, spacing: 16) {
            if arranging { heading(area).padding(.horizontal, 18) }
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(cards) { card in
                            let size = sizes[card.id] ?? CGSize(width: 164, height: 164 / card.aspectRatio)
                            tile(card, area: area, imageHeight: size.height).frame(width: size.width).id(card.id)
                        }
                        addImageTile(area)
                        if arranging { dropTarget(area).frame(width: 164, height: 210) }
                    }
                    .frame(minHeight: sizes.values.map(\.height).max().map { $0 + 54 } ?? 144, alignment: .top)
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 18, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .accessibilityIdentifier("proRow-\(area.id)")
                .onChange(of: area.cardIDs) { old, current in
                    if let added = current.last, !old.contains(added) {
                        proxy.scrollTo(added, anchor: .trailing)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    /// Keep each image's proportions and a stable size across launches. Nearby
    /// images with similar dimensions get different scales, without shuffling cards.
    private func rowSizes(_ cards: [ProImageCard]) -> [UUID: CGSize] {
        var sizes: [UUID: CGSize] = [:]
        var previous: CGSize?
        for card in cards {
            let hash = card.id.uuidString.utf8.reduce(UInt32(2_166_136_261)) { ($0 ^ UInt32($1)) &* 16_777_619 }
            let variation = CGFloat(hash % 1_000) / 999
            var width = min(140 + variation * 130, (220 + variation * 150) * card.aspectRatio)
            if let previous,
               abs(width / card.aspectRatio - previous.height) < 48 || abs(width - previous.width) < 28 {
                width *= previous.height >= 250 || previous.width >= 210 ? 0.62 : 1.5
            }
            width = max(108, min(width, min(300, 380 * card.aspectRatio)))
            let size = CGSize(width: width, height: min(380, width / card.aspectRatio))
            sizes[card.id] = size
            previous = size
        }
        return sizes
    }

    private func addImageTile(_ area: ProLibraryArrangement.Area) -> some View {
        Menu {
            Button("Photo Library", systemImage: "photo.on.rectangle") { addImage(area.id, .photos) }
            Button("Choose File", systemImage: "folder") { addImage(area.id, .files) }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus").font(.system(size: 28, weight: .light))
                Text("Add image").font(.system(size: 14, weight: .medium))
            }
            .frame(width: 112, height: 144)
            .foregroundStyle(.white)
            .background(Color.black)
        }
        .accessibilityIdentifier("proRowAddImage-\(area.id)")
        .disabled(importing)
    }

    private func heading(_ area: ProLibraryArrangement.Area) -> some View {
        HStack {
            Text(library.arrangement.name(for: area)).font(Brand.serif(22))
            Spacer()
            if area.style == .row {
                Button {
                    change { $0.removeRow(area.id) }
                } label: {
                    Image(systemName: "rectangle.grid.2x2").frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Use full-size cards for \(library.arrangement.name(for: area))")
                .accessibilityIdentifier("proRemoveRow-\(area.id)")
            }
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder private func tile(_ card: ProImageCard, area: ProLibraryArrangement.Area, imageHeight: CGFloat? = nil) -> some View {
        if arranging {
            ProSavedImageTile(card: card, url: library.url(for: card), compact: area.style == .row, imageHeight: imageHeight)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10).background(.black.opacity(0.7), in: Circle()).padding(8)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .bottomTrailing) { moveMenu(card, area: area) }
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .onDrag { NSItemProvider(object: ("pro-image:" + card.id.uuidString) as NSString) }
                .onDrop(of: [.plainText], delegate: ProImageDrop { id in
                    change { $0.move(id, to: area.id, before: card.id) }
                })
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("proArrangeCard-\(card.id)")
        } else {
            ProSavedImageCard(card: card, url: library.url(for: card), compact: area.style == .row, imageHeight: imageHeight) { open(card) }
        }
    }

    private func moveMenu(_ card: ProImageCard, area: ProLibraryArrangement.Area) -> some View {
        Menu {
            Button("Move earlier", systemImage: "arrow.up") { change { $0.shift(card.id, by: -1) } }
                .disabled(area.cardIDs.first == card.id)
                .accessibilityIdentifier("proMoveEarlier")
            Button("Move later", systemImage: "arrow.down") { change { $0.shift(card.id, by: 1) } }
                .disabled(area.cardIDs.last == card.id)
                .accessibilityIdentifier("proMoveLater")
            if area.style == .grid {
                Button("Start a row here", systemImage: "rectangle.split.3x1") { change { $0.startRow(at: card.id) } }
                    .accessibilityIdentifier("proStartRow")
            }
            ForEach(library.arrangement.areas.filter { $0.id != area.id }) { destination in
                Button("Move to \(library.arrangement.name(for: destination))") {
                    change { $0.move(card.id, to: destination.id) }
                }
                .accessibilityIdentifier("proMoveTo-\(destination.id)")
            }
        } label: {
            Image(systemName: "ellipsis").font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .foregroundStyle(.white)
        .accessibilityLabel("Move \(CardTitleStore.shared.title(for: card.cardTitle))")
        .accessibilityIdentifier("proMove-\(card.id)")
    }

    private func dropTarget(_ area: ProLibraryArrangement.Area) -> some View {
        Text(area.cardIDs.isEmpty ? "Move cards here" : "Drop here to place last")
            .font(.system(size: 13, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(.white.opacity(0.85))
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            .onDrop(of: [.plainText], delegate: ProImageDrop { id in change { $0.move(id, to: area.id) } })
            .accessibilityIdentifier("proDropArea-\(area.id)")
    }

    private func change(_ update: @Sendable @escaping (inout ProLibraryArrangement) -> Void) {
        guard !saving else { return }
        saving = true
        Task { @MainActor in
            defer { saving = false }
            do { try await library.arrange(update) }
            catch { report(error.localizedDescription) }
        }
    }
}

private struct ProImageDrop: DropDelegate {
    var move: (UUID) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.plainText]).first else { return false }
        _ = provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let value = object as? String, value.hasPrefix("pro-image:"),
                  let id = UUID(uuidString: String(value.dropFirst("pro-image:".count))) else { return }
            DispatchQueue.main.async { move(id) }
        }
        return true
    }
}
