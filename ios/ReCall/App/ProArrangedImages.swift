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
    @State private var choosingSquare: ProLibraryArrangement.Area?

    // Pinterest's supplied 1320 px screenshot uses 270 × 405 px thumbnails.
    private let rowWidth: CGFloat = 90
    private let rowHeight: CGFloat = 135

    var body: some View {
        VStack(spacing: 24) {
            ForEach(library.arrangement.areas) { area in
                if area.style == .row {
                    row(area)
                } else if area.style == .square {
                    square(area)
                } else if arranging || !area.cardIDs.isEmpty {
                    grid(area)
                }
            }
        }
        .disabled(saving)
        .sheet(item: $choosingSquare) { area in
            NavigationStack {
                List(library.cards) { card in
                    Button(CardTitleStore.shared.title(for: card.cardTitle)) {
                        choosingSquare = nil
                        change { $0.move(card.id, to: area.id) }
                    }
                    .accessibilityIdentifier("proChooseSquareImage-\(card.id)")
                }
                .navigationTitle("Choose image")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { choosingSquare = nil }
                    }
                }
            }
        }
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
                addSquareButton(after: area)
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
        return VStack(alignment: .leading, spacing: 16) {
            if arranging { heading(area).padding(.horizontal, 18) }
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 4) {
                        ForEach(cards) { card in
                            tile(card, area: area, imageHeight: rowHeight).frame(width: rowWidth).id(card.id)
                        }
                        addImageTile(area)
                        if arranging { dropTarget(area).frame(width: rowWidth, height: rowHeight) }
                    }
                    .frame(minHeight: rowHeight, alignment: .top)
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 4, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .accessibilityIdentifier("proRow-\(area.id)")
                .onChange(of: area.cardIDs) { old, current in
                    if let added = current.last, !old.contains(added) {
                        proxy.scrollTo(added, anchor: .trailing)
                    }
                }
            }
            if arranging { addSquareButton(after: area).padding(.horizontal, 18) }
        }
        .padding(.vertical, 8)
    }

    private func square(_ area: ProLibraryArrangement.Area) -> some View {
        let side = max(1, availableWidth - 8)
        return VStack(alignment: .leading, spacing: 14) {
            if arranging { heading(area).padding(.horizontal, 14) }
            if let card = library.cards(in: area).first {
                tile(card, area: area, imageHeight: side).frame(width: side)
            } else {
                Menu {
                    Button("Photo Library", systemImage: "photo.on.rectangle") { addImage(area.id, .photos) }
                    Button("Choose File", systemImage: "folder") { addImage(area.id, .files) }
                    if !library.cards.isEmpty {
                        Button("Choose saved image", systemImage: "photo") { choosingSquare = area }
                    }
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "plus").font(.system(size: 32, weight: .light))
                        Text("Add image").font(.system(size: 15, weight: .medium))
                    }
                    .frame(width: side, height: side)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.22)))
                    .foregroundStyle(.white)
                }
                .accessibilityIdentifier("proSquareAddImage-\(area.id)")
                .disabled(importing)
                .onDrop(of: [.plainText], delegate: ProImageDrop { id in change { $0.move(id, to: area.id) } })
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("proSquare-\(area.id)")
    }

    @ViewBuilder private func addSquareButton(after area: ProLibraryArrangement.Area) -> some View {
        if !library.arrangement.areas.contains(where: { $0.style == .square }) {
            Button {
                change { $0.addSquare(after: area.id) }
            } label: {
                Label("Add square here", systemImage: "square")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .buttonStyle(.plain).foregroundStyle(.white)
            .accessibilityIdentifier("proAddSquare-\(area.id)")
        }
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
            .frame(width: rowWidth, height: rowHeight)
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
            if area.style != .grid {
                Button { change { $0.moveArea(area.id, by: -1) } } label: {
                    Image(systemName: "arrow.up").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Move \(area.style == .square ? "square" : library.arrangement.name(for: area)) earlier")
                .accessibilityIdentifier(area.style == .square ? "proSquareEarlier" : "proRowEarlier-\(area.id)")
                Button { change { $0.moveArea(area.id, by: 1) } } label: {
                    Image(systemName: "arrow.down").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Move \(area.style == .square ? "square" : library.arrangement.name(for: area)) later")
                .accessibilityIdentifier(area.style == .square ? "proSquareLater" : "proRowLater-\(area.id)")
            }
            if area.style != .grid {
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
            ProSavedImageTile(card: card, url: library.url(for: card), compact: area.style != .grid,
                              imageHeight: imageHeight, fillsImage: area.style != .grid)
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
            ProSavedImageCard(card: card, url: library.url(for: card), compact: area.style != .grid,
                              imageHeight: imageHeight, fillsImage: area.style != .grid) { open(card) }
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
            ForEach(library.arrangement.areas.filter {
                $0.id != area.id && ($0.style != .square || $0.cardIDs.isEmpty)
            }) { destination in
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
