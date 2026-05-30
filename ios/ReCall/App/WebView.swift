import SwiftUI
import WebKit

/// Hosts the bundled Re_Call prototype full-screen, edge-to-edge, with no Safari
/// chrome. The HTML and its relative `covers/*.png` assets ship inside the app
/// bundle (folder reference `Web/`) and load entirely offline.
struct WebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Allow the prototype's inline media to play without forcing fullscreen.
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        // The prototype is a single mobile screen; kill the rubber-band bounce so
        // it reads like a native app rather than a scrollable web page.
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        loadBundledPrototype(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func loadBundledPrototype(into webView: WKWebView) {
        // `Web` is bundled as a folder reference, so index.html and covers/ keep
        // their relative layout. Read access is granted to the whole Web dir so
        // the relative cover images resolve.
        guard let webDir = Bundle.main.url(forResource: "Web", withExtension: nil) else {
            assertionFailure("Bundled Web/ directory missing from app target")
            return
        }
        let indexURL = webDir.appendingPathComponent("index.html")
        webView.loadFileURL(indexURL, allowingReadAccessTo: webDir)
    }
}
