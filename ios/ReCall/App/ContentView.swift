import SwiftUI

/// Background matching the prototype's dark canvas so there is no white flash
/// behind the web content during load or in the safe-area insets.
private let canvasBackground = Color(red: 0x2B / 255, green: 0x2E / 255, blue: 0x38 / 255)

struct ContentView: View {
    var body: some View {
        WebView()
            .background(canvasBackground)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
