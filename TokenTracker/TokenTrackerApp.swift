import SwiftUI

@main
struct TokenTrackerApp: App {
    @StateObject private var store = TokenStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    // Sync immediately on launch
                    await store.sync()
                }
        }
    }
}
