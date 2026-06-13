import SwiftUI

/// Background matching the prototype's dark canvas so there is no white flash
/// behind the web content during load or in the safe-area insets.
private let canvasBackground = Color(red: 0x2B / 255, green: 0x2E / 255, blue: 0x38 / 255)

struct ContentView: View {
    @StateObject private var nativeCaptureBridge = NativeCaptureBridge()

    var body: some View {
        WebView(nativeCaptureBridge: nativeCaptureBridge)
            .background(canvasBackground)
            .ignoresSafeArea()
            .sheet(isPresented: $nativeCaptureBridge.isPresentingMacBookCapture) {
                NativeCaptureSheet(seedTitle: nativeCaptureBridge.seedTitle) { payload in
                    nativeCaptureBridge.onSave?(payload)
                }
            }
    }
}

#Preview {
    ContentView()
}
