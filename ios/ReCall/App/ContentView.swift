import SwiftUI

/// App root: the native Reminders list owns the store and starts sync after first paint.
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = ReminderStore()
    @State private var didStartBootstrap = false

    var body: some View {
        ReminderListView()
            .environmentObject(store)
            .task {
                await bootstrapAfterFirstFrame()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, didStartBootstrap else { return }
                Task { await store.refresh() }
            }
    }

    private func bootstrapAfterFirstFrame() async {
        guard !didStartBootstrap else { return }
        didStartBootstrap = true
        await Task.yield()
        await store.bootstrap()
    }
}

#Preview {
    ContentView()
}
