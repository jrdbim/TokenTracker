import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TokenStore

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Usage", systemImage: "gauge.medium")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
