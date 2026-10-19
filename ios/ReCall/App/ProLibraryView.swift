import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

extension ProImageCard {
    var cardTitle: CardTitle { CardTitle(id: "pro-image:\(id.uuidString)", original: title.isEmpty ? "Saved image" : title) }
}

struct ProImageDraft: Identifiable {
    let id = UUID()
    let data: Data
    let preview: UIImage
    var title = ""
}

struct ProLibraryView: View {
    @ObservedObject var library: ProImageStore
    var onPick: (ShapeTileSpec) -> Void
    @State private var showTemplates = false
    @State private var showPhotos = false
    @State private var showFiles = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var draft: ProImageDraft?
    @State private var selectedCard: ProImageCard?
    @State private var loading = false
    @State private var problem: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(showTemplates ? "Saved images" : "Templates") { showTemplates.toggle() }
                    .accessibilityIdentifier("proTemplatesToggle")
                Spacer()
                Menu {
                    Button("Photo Library", systemImage: "photo.on.rectangle") { showPhotos = true }
                    Button("Choose File", systemImage: "folder") { showFiles = true }
                } label: {
                    Label("Add image", systemImage: "plus")
                }
                .accessibilityIdentifier("proAddImage")
                .disabled(loading)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Brand.nearBlack)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Brand.tan)

            if showTemplates {
                ProfessionalTemplatesView(onPick: onPick)
            } else {
                savedImages
            }
        }
        .background(Brand.tan.ignoresSafeArea(edges: .top))
        .photosPicker(isPresented: $showPhotos, selection: $selectedPhoto, matching: .images)
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let url):
                Task {
                    loading = true
                    defer { loading = false }
                    do {
                        let data = try await Task.detached(priority: .userInitiated) {
                            let access = url.startAccessingSecurityScopedResource()
                            defer { if access { url.stopAccessingSecurityScopedResource() } }
                            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                            guard size <= 80 * 1_024 * 1_024 else { throw ProImageError.imageTooLarge }
                            return try Data(contentsOf: url)
                        }.value
                        try await prepare(data, title: url.deletingPathExtension().lastPathComponent)
                    } catch { problem = error.localizedDescription }
                }
            case .failure(let error): problem = error.localizedDescription
            }
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            loading = true
            defer { loading = false; self.selectedPhoto = nil }
            do {
                guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else {
                    throw ProImageError.unreadableImage
                }
                try Task.checkCancellation()
                try await prepare(data)
            } catch is CancellationError { }
            catch { problem = error.localizedDescription }
        }
        .task {
            do {
                try await library.refresh()
                #if DEBUG
                try await ProImageUITestFixtures.seedIfRequested(library)
                #endif
            } catch { problem = error.localizedDescription }
        }
        .sheet(item: $draft) { draft in
            ProImageEditor(library: library, draft: draft)
        }
        .fullScreenCover(item: $selectedCard) { card in
            ProPosterViewer(library: library, originalCard: card)
        }
        .alert("Image couldn’t be opened", isPresented: problemPresented) {
            Button("OK") { problem = nil }
        } message: { Text(problem ?? "") }
    }

    private var savedImages: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pro").font(Brand.serif(44))
                        Text("Images & ideas to explore.").font(.system(size: 17, weight: .medium))
                    }
                    .foregroundStyle(Brand.nearBlack)
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                    if loading {
                        ProgressView("Opening image…").frame(maxWidth: .infinity).tint(Brand.nearBlack)
                            .foregroundStyle(Brand.nearBlack)
                    }
                    if library.cards.isEmpty {
                        emptyCollection
                    } else {
                        let columns = columns(width: max(1, (geometry.size.width - 48) / 2))
                        HStack(alignment: .top, spacing: 12) {
                            imageColumn(columns.0)
                            imageColumn(columns.1)
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.bottom, 140)
            }
            .accessibilityIdentifier("proSavedImages")
        }
    }

    private var emptyCollection: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 44, weight: .light))
            Text("Save something that catches your eye.").font(Brand.serif(26)).multilineTextAlignment(.center)
            Text("Keep images, posters, and ideas here to explore.")
                .font(.system(size: 16)).multilineTextAlignment(.center)
            Button("Add your first image") { showPhotos = true }
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 20).padding(.vertical, 14)
                .background(Brand.nearBlack, in: Capsule()).foregroundStyle(.white)
                .accessibilityIdentifier("proFirstImage")
        }
        .foregroundStyle(Brand.nearBlack)
        .padding(28).frame(maxWidth: .infinity)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 18)
    }

    private func imageColumn(_ cards: [ProImageCard]) -> some View {
        LazyVStack(spacing: 14) {
            ForEach(cards) { card in
                ProSavedImageCard(card: card, url: library.url(for: card)) { selectedCard = card }
            }
        }.frame(maxWidth: .infinity)
    }

    private func columns(width: CGFloat) -> ([ProImageCard], [ProImageCard]) {
        var left: [ProImageCard] = [], right: [ProImageCard] = []
        var leftHeight: CGFloat = 0, rightHeight: CGFloat = 0
        for card in library.cards {
            let height = width / card.aspectRatio + 78
            if leftHeight <= rightHeight { left.append(card); leftHeight += height }
            else { right.append(card); rightHeight += height }
        }
        return (left, right)
    }

    private func prepare(_ data: Data, title: String = "") async throws {
        let preview = try await ProImageLoader.preview(data: data)
        try Task.checkCancellation()
        showTemplates = false
        draft = ProImageDraft(data: data, preview: preview, title: title)
    }

    private var problemPresented: Binding<Bool> {
        Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })
    }
}

private struct ProSavedImageCard: View {
    let card: ProImageCard
    let url: URL
    var open: () -> Void
    @StateObject private var titleSession = CardTitleSession()

    var body: some View {
        EditableCardButton(cardTitle: card.cardTitle, session: titleSession, action: open) {
            ProSavedImageTile(card: card, url: url)
        }
        .accessibilityIdentifier("proImageCard-\(card.id.uuidString)")
        .overlay(alignment: .bottomTrailing) {
            if !titleSession.isEditing {
                Button { titleSession.begin(card.cardTitle) } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain).foregroundStyle(Brand.nearBlack)
                .accessibilityLabel("Edit title")
                .accessibilityIdentifier("proEditTitle-\(card.id.uuidString)")
            }
        }
    }
}

private struct ProSavedImageTile: View {
    let card: ProImageCard
    let url: URL
    @State private var image: UIImage?
    @State private var failed = false
    @Environment(\.isEditingRecallCardTitle) private var isEditingTitle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.aspectRatio(card.aspectRatio, contentMode: .fit)
                .overlay {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else if failed {
                        Image(systemName: "photo.badge.exclamationmark").foregroundStyle(Brand.nearBlack)
                    } else { ProgressView().tint(Brand.nearBlack) }
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                CardTitleText(card: card.cardTitle).font(.system(size: 15, weight: .semibold))
                if let host = card.sourceURL?.host() {
                    Text(host).font(.system(size: 11)).lineLimit(1).foregroundStyle(Brand.nearBlack.opacity(0.65))
                }
            }
            .foregroundStyle(Brand.nearBlack)
            .padding(.trailing, isEditingTitle ? 0 : 33)
            .padding(11)
        }
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .task(id: url) {
            let loaded = await ProImageLoader.load(url: url, maxPixelSize: 700)
            guard !Task.isCancelled else { return }
            image = loaded
            failed = loaded == nil
        }
    }
}

struct ProImageEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: ProImageStore
    let draft: ProImageDraft?
    let card: ProImageCard?
    @State private var title: String
    @State private var source: String
    @State private var notes: String
    @State private var saving = false
    @State private var problem: String?

    init(library: ProImageStore, draft: ProImageDraft? = nil, card: ProImageCard? = nil) {
        self.library = library; self.draft = draft; self.card = card
        _title = State(initialValue: card.map { CardTitleStore.shared.title(for: $0.cardTitle) } ?? draft?.title ?? "")
        _source = State(initialValue: card?.source ?? "")
        _notes = State(initialValue: card?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                if let preview = draft?.preview {
                    Image(uiImage: preview).resizable().scaledToFit().frame(maxHeight: 260)
                        .frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }
                Section {
                    TextField("Title (optional)", text: $title).accessibilityIdentifier("proImageTitle")
                    TextField("Source URL (optional)", text: $source)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("proImageSource")
                    TextField("Notes (optional)", text: $notes, axis: .vertical).lineLimit(3...8)
                        .accessibilityIdentifier("proImageNotes")
                }
                if let problem { Section { Text(problem).foregroundStyle(.red) } }
            }
            .navigationTitle(card == nil ? "Save image" : "Image details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") {
                        Task { await save() }
                    }.disabled(saving).accessibilityIdentifier("proSaveImage")
                }
            }
            .interactiveDismissDisabled(saving)
        }
        .preferredColorScheme(.light)
    }

    private func save() async {
        saving = true
        defer { saving = false }
        do {
            if let card {
                try await library.update(card, title: title, source: source, notes: notes)
            } else if let draft {
                try await library.save(data: draft.data, title: title, source: source, notes: notes)
            }
            dismiss()
        } catch { problem = error.localizedDescription }
    }
}
