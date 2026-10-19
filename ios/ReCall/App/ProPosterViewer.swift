import SwiftUI
import UIKit

struct ProPosterViewer: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: ProImageStore
    @ObservedObject private var titles = CardTitleStore.shared
    let originalCard: ProImageCard
    @State private var image: UIImage?
    @State private var failed = false
    @State private var zoom = 1.0
    @State private var command = PosterZoomCommand()
    @State private var editingCard: ProImageCard?
    @State private var showDetails = false
    @State private var confirmRemoval = false
    @State private var problem: String?
    @State private var copiedSource = false

    private var card: ProImageCard { library.cards.first { $0.id == originalCard.id } ?? originalCard }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    Color.black
                    if let image {
                        ZoomablePoster(image: image, command: command) { zoom = $0 }
                            .accessibilityIdentifier("proPosterCanvas")
                    } else if failed {
                        ContentUnavailableView("Image unavailable", systemImage: "photo.badge.exclamationmark",
                                               description: Text("The saved image file couldn’t be opened."))
                    } else { ProgressView("Opening poster…").tint(.white) }
                }
                .frame(maxHeight: .infinity)
                HStack(spacing: 24) {
                    zoomButton("Zoom out", symbol: "minus.magnifyingglass", action: .out)
                    Button { command = PosterZoomCommand(action: .fit) } label: {
                        Text("\(Int((zoom * 100).rounded()))%")
                            .monospacedDigit().frame(minWidth: 56, minHeight: 44)
                    }
                    .accessibilityLabel("Fit image")
                    .accessibilityValue("\(Int((zoom * 100).rounded())) percent")
                    .accessibilityIdentifier("proZoomLevel")
                    zoomButton("Zoom in", symbol: "plus.magnifyingglass", action: .in)
                    Spacer()
                    Button { showDetails.toggle() } label: {
                        Image(systemName: "info.circle").frame(width: 44, height: 44)
                    }.accessibilityLabel("Image details").accessibilityIdentifier("proShowDetails")
                }
                .font(.system(size: 18, weight: .medium)).foregroundStyle(.white)
                .padding(.horizontal, 18).background(Brand.nearBlack)
                if showDetails {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(titles.title(for: card.cardTitle)).font(.headline)
                            if let url = card.sourceURL {
                                HStack {
                                    Link(destination: url) {
                                        Label(url.host() ?? "Open source", systemImage: "arrow.up.right.square")
                                    }.accessibilityIdentifier("proSourceLink")
                                    Spacer()
                                    Button { UIPasteboard.general.url = url; copiedSource = true } label: {
                                        Image(systemName: copiedSource ? "checkmark" : "doc.on.doc").frame(width: 44, height: 44)
                                    }
                                    .accessibilityLabel(copiedSource ? "Source copied" : "Copy source")
                                    .accessibilityIdentifier("proCopySource")
                                }
                            }
                            if !card.notes.isEmpty { Text(card.notes).textSelection(.enabled) }
                            Button("Edit details") { editingCard = card }.accessibilityIdentifier("proEditDetails")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                    }
                    .frame(maxHeight: 200).background(Brand.nearBlack)
                }
            }
            .background(Color.black)
            .navigationTitle(titles.title(for: card.cardTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.nearBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close poster").accessibilityIdentifier("proClosePoster")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Edit details", systemImage: "pencil") { editingCard = card }
                        ShareLink(item: library.url(for: card)) { Label("Share image", systemImage: "square.and.arrow.up") }
                        Button("Remove image", systemImage: "trash", role: .destructive) { confirmRemoval = true }
                    } label: { Image(systemName: "ellipsis") }
                    .accessibilityLabel("Image options").accessibilityIdentifier("proImageOptions")
                }
            }
        }
        .preferredColorScheme(.dark)
        .task(id: originalCard.id) {
            let loaded = await ProImageLoader.load(url: library.url(for: originalCard), maxPixelSize: 6_000)
            guard !Task.isCancelled else { return }
            image = loaded
            failed = loaded == nil
        }
        .sheet(item: $editingCard) { ProImageEditor(library: library, card: $0) }
        .onChange(of: card.source) { _, _ in copiedSource = false }
        .confirmationDialog("Remove this image from Pro?", isPresented: $confirmRemoval, titleVisibility: .visible) {
            Button("Remove image", role: .destructive) {
                Task {
                    do { try await library.remove(card); dismiss() }
                    catch { problem = error.localizedDescription }
                }
            }
        }
        .alert("Image couldn’t be removed", isPresented: Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })) {
            Button("OK") { problem = nil }
        } message: { Text(problem ?? "") }
    }

    private func zoomButton(_ label: String, symbol: String, action: PosterZoomCommand.Action) -> some View {
        Button { command = PosterZoomCommand(action: action) } label: {
            Image(systemName: symbol).frame(width: 44, height: 44)
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(action == .in ? "proZoomIn" : "proZoomOut")
        .disabled(image == nil)
    }
}

struct PosterZoomCommand {
    enum Action { case fit, `in`, out }
    let id = UUID()
    var action: Action = .fit
}

private struct ZoomablePoster: UIViewRepresentable {
    let image: UIImage
    let command: PosterZoomCommand
    let onZoom: (Double) -> Void

    func makeUIView(context: Context) -> PosterScrollView {
        let view = PosterScrollView()
        view.setImage(image)
        view.onZoom = onZoom
        view.lastCommand = command.id
        return view
    }

    func updateUIView(_ view: PosterScrollView, context: Context) {
        view.onZoom = onZoom
        guard view.lastCommand != command.id else { return }
        view.lastCommand = command.id
        view.apply(command.action)
    }
}

/// UIKit owns the pinch, pan, and double tap so a zoomed poster behaves like a native photo.
private final class PosterScrollView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()
    private var previousSize = CGSize.zero
    var lastCommand: UUID?
    var onZoom: ((Double) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        backgroundColor = .black
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        bouncesZoom = true
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        isAccessibilityElement = true
        accessibilityLabel = "Poster"
        accessibilityHint = "Pinch or double tap to zoom. Drag to read another part of the poster."
        accessibilityTraits = .image
        accessibilityIdentifier = "proPosterCanvas"
    }

    required init?(coder: NSCoder) { nil }

    func setImage(_ image: UIImage) {
        imageView.image = image
        imageView.frame = CGRect(origin: .zero, size: image.size)
        contentSize = image.size
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let image = imageView.image, bounds.width > 0, bounds.height > 0 else { return }
        if previousSize != bounds.size {
            previousSize = bounds.size
            let fit = min(bounds.width / image.size.width, bounds.height / image.size.height)
            minimumZoomScale = fit
            maximumZoomScale = fit * 8
            zoomScale = fit
            centerImage()
            setContentOffset(CGPoint(x: -contentInset.left, y: -contentInset.top), animated: false)
            reportZoom()
        }
        centerImage()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerImage(); reportZoom() }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if scale <= minimumZoomScale * 1.001 {
            setContentOffset(CGPoint(x: -contentInset.left, y: -contentInset.top), animated: false)
        }
    }

    private func centerImage() {
        contentInset = UIEdgeInsets(top: max(0, (bounds.height - contentSize.height) / 2), left: max(0, (bounds.width - contentSize.width) / 2), bottom: 0, right: 0)
    }

    private func reportZoom() {
        let scale = Double(zoomScale / max(minimumZoomScale, 0.0001))
        accessibilityValue = "\(Int((scale * 100).rounded())) percent"
        DispatchQueue.main.async { [weak self] in self?.onZoom?(scale) }
    }

    func apply(_ action: PosterZoomCommand.Action) {
        switch action {
        case .fit: setZoomScale(minimumZoomScale, animated: true)
        case .in: setZoomScale(min(maximumZoomScale, zoomScale * 2), animated: true)
        case .out: setZoomScale(max(minimumZoomScale, zoomScale / 2), animated: true)
        }
    }

    @objc private func doubleTapped(_ tap: UITapGestureRecognizer) {
        guard zoomScale < minimumZoomScale * 1.05 else {
            setZoomScale(minimumZoomScale, animated: true)
            return
        }
        let scale = min(maximumZoomScale, minimumZoomScale * 3)
        let point = tap.location(in: imageView)
        let size = CGSize(width: bounds.width / scale, height: bounds.height / scale)
        zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                        width: size.width, height: size.height), animated: true)
    }
}
