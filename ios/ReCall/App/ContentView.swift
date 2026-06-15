import SwiftUI

/// App root: the native Reminders list owns the store, requests notification permission, and
/// kicks off the Supabase sync.
struct ContentView: View {
    @StateObject private var store = ReminderStore()

    var body: some View {
        ReminderListView()
            .environmentObject(store)
            .task {
                await NotificationScheduler.requestAuth()
                await store.bootstrap()
            }
    }
}

#Preview {
    ContentView()
}
