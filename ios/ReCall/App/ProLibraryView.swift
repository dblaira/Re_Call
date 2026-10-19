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
    var destinationAreaID: UUID?
}

enum ProImageImportSource { case photos, files }

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
    @State private var arranging = false
    @State private var importAreaID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            BrandPageHeader(title: "Pro") {
                controls
            }

            if showTemplates {
                ProfessionalTemplatesView(onPick: onPick)
            } else {
                savedImages
            }
        }
        .background(showTemplates ? Brand.tan : Color.black)
        .photosPicker(isPresented: $showPhotos, selection: $selectedPhoto, matching: .images)
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let url):
                let destination = importAreaID
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
                        try await prepare(data, title: url.deletingPathExtension().lastPathComponent, to: destination)
                    } catch { problem = error.localizedDescription }
                }
            case .failure(let error): problem = error.localizedDescription
            }
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            let destination = importAreaID
            loading = true
            defer { loading = false; self.selectedPhoto = nil }
            do {
                guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else {
                    throw ProImageError.unreadableImage
                }
                try Task.checkCancellation()
                try await prepare(data, to: destination)
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
        .alert("Pro couldn’t complete that change", isPresented: problemPresented) {
            Button("OK") { problem = nil }
        } message: { Text(problem ?? "") }
    }

    private var controls: some View {
        HStack {
                Button(showTemplates ? "Saved images" : "Templates") { arranging = false; showTemplates.toggle() }
                    .accessibilityIdentifier("proTemplatesToggle")
                Spacer()
                if !showTemplates {
                    Button(arranging ? "Done" : "Arrange") {
                        withAnimation(.snappy) { arranging.toggle() }
                    }
                    .accessibilityIdentifier("proArrange")
                    .padding(.trailing, 12)
                }
                Menu {
                    Button("Photo Library", systemImage: "photo.on.rectangle") { beginImport(.photos) }
                    Button("Choose File", systemImage: "folder") { beginImport(.files) }
                } label: {
                    Label("Add image", systemImage: "plus")
                }
                .accessibilityIdentifier("proAddImage")
                .disabled(loading)
        }
        .frame(minHeight: 44)
    }

    private var savedImages: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 22) {
                    if loading {
                        ProgressView("Opening image…").frame(maxWidth: .infinity).tint(.white)
                            .foregroundStyle(.white)
                    }
                    if library.cards.isEmpty && !arranging && !library.arrangement.areas.contains(where: { $0.style == .row }) {
                        emptyCollection
                    } else {
                        ProArrangedImages(library: library, arranging: arranging, importing: loading,
                                          availableWidth: geometry.size.width,
                                          addImage: { area, source in beginImport(source, to: area) },
                                          open: { selectedCard = $0 }, report: { problem = $0 })
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 140)
                .frame(maxWidth: .infinity)
            }
            .background(Color.black)
            .accessibilityIdentifier("proSavedImages")
        }
    }

    private var emptyCollection: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 44, weight: .light))
            Button("Add your first image") { beginImport(.photos) }
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 20).padding(.vertical, 14)
                .background(Brand.nearBlack, in: Capsule()).foregroundStyle(.white)
                .accessibilityIdentifier("proFirstImage")
        }
        .foregroundStyle(.white)
        .padding(28).frame(maxWidth: .infinity)
        .background(Color.black)
        .padding(.horizontal, 18)
    }

    private func beginImport(_ source: ProImageImportSource, to areaID: UUID? = nil) {
        importAreaID = areaID
        switch source {
        case .photos: showPhotos = true
        case .files: showFiles = true
        }
    }

    private func prepare(_ data: Data, title: String = "", to areaID: UUID? = nil) async throws {
        let preview = try await ProImageLoader.preview(data: data)
        try Task.checkCancellation()
        showTemplates = false
        draft = ProImageDraft(data: data, preview: preview, title: title, destinationAreaID: areaID)
    }

    private var problemPresented: Binding<Bool> {
        Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })
    }
}

struct ProSavedImageCard: View {
    let card: ProImageCard
    let url: URL
    var compact = false
    var imageHeight: CGFloat?
    var open: () -> Void
    @StateObject private var titleSession = CardTitleSession()

    var body: some View {
        EditableCardButton(cardTitle: card.cardTitle, session: titleSession, action: open) {
            ProSavedImageTile(card: card, url: url, compact: compact, imageHeight: imageHeight)
        }
        .accessibilityIdentifier("proImageCard-\(card.id.uuidString)")
        .overlay(alignment: .bottomTrailing) {
            if !titleSession.isEditing {
                Button { titleSession.begin(card.cardTitle) } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain).foregroundStyle(.white)
                .accessibilityLabel("Edit title")
                .accessibilityIdentifier("proEditTitle-\(card.id.uuidString)")
            }
        }
    }
}

struct ProSavedImageTile: View {
    let card: ProImageCard
    let url: URL
    var compact = false
    var imageHeight: CGFloat?
    @State private var image: UIImage?
    @State private var failed = false
    @Environment(\.isEditingRecallCardTitle) private var isEditingTitle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if let imageHeight { Color.clear.frame(height: imageHeight) }
                else { Color.clear.aspectRatio(card.aspectRatio, contentMode: .fit) }
            }
                .overlay {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else if failed {
                        Image(systemName: "photo.badge.exclamationmark").foregroundStyle(.white)
                    } else { ProgressView().tint(.white) }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                CardTitleText(card: card.cardTitle).font(.system(size: 14))
                    .lineLimit(compact && !isEditingTitle ? 2 : nil)
                if !compact, let host = card.sourceURL?.host() {
                    Text(host).font(.system(size: 11)).lineLimit(1).foregroundStyle(.white.opacity(0.65))
                }
            }
            .foregroundStyle(.white)
            .padding(.trailing, isEditingTitle ? 0 : 33)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(minHeight: 44, alignment: .topLeading)
        }
        .background(Color.black)
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
                try await library.save(data: draft.data, title: title, source: source, notes: notes,
                                       to: draft.destinationAreaID)
            }
            dismiss()
        } catch { problem = error.localizedDescription }
    }
}
