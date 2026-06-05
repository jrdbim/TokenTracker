import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: TokenStore

    @State private var limit5hInput = ""
    @State private var limitWeekInput = ""

    var body: some View {
        NavigationStack {
            Form {
                macSyncSection
                planLimitsSection
            }
            .navigationTitle("Settings")
            .onAppear {
                limit5hInput = store.limit5Hours > 0 ? "\(store.limit5Hours)" : ""
                limitWeekInput = store.limitWeekly > 0 ? "\(store.limitWeekly)" : ""
            }
        }
    }

    private var macSyncSection: some View {
        Section {
            TextField("192.168.1.173", text: $store.macHost)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
        } header: {
            Text("Mac IP / Hostname")
        } footer: {
            Text("Your Mac's local IP or hostname. The TokenTracker server must be running on your Mac. Data syncs every 10 minutes.")
        }
    }

    private var planLimitsSection: some View {
        Section {
            HStack {
                Text("5-hour limit")
                Spacer()
                TextField("e.g. 500000", text: $limit5hInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: limit5hInput) { _, v in
                        store.limit5Hours = Int(v) ?? 0
                    }
            }
            HStack {
                Text("Weekly limit")
                Spacer()
                TextField("e.g. 2000000", text: $limitWeekInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: limitWeekInput) { _, v in
                        store.limitWeekly = Int(v) ?? 0
                    }
            }
        } header: {
            Text("Plan Limits")
        } footer: {
            Text("Set your Claude plan's token limits. Leave blank to hide that row.")
        }
    }
}
