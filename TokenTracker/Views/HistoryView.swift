import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: TokenStore
    @State private var showAddEntry = false

    var body: some View {
        NavigationStack {
            Group {
                if store.entriesInPeriod.isEmpty {
                    ContentUnavailableView(
                        "No entries yet",
                        systemImage: "doc.text",
                        description: Text("Add usage manually or sync with your API key.")
                    )
                } else {
                    List {
                        ForEach(store.entriesInPeriod) { entry in
                            EntryRow(entry: entry)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                store.deleteEntry(id: store.entriesInPeriod[i].id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddEntry) {
                AddUsageView()
            }
        }
    }
}

struct EntryRow: View {
    let entry: UsageEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.label)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(entry.model)
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12), in: Capsule())
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.totalTokens.formatted())
                    .font(.system(.subheadline, design: .rounded))
                    .bold()
                Text("↑\(entry.inputTokens.formatted()) ↓\(entry.outputTokens.formatted())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
