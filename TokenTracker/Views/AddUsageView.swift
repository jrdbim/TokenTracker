import SwiftUI

struct AddUsageView: View {
    @EnvironmentObject var store: TokenStore
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var model = "claude-opus-4"
    @State private var inputTokens = ""
    @State private var outputTokens = ""
    @State private var date = Date()

    private let models = [
        "claude-opus-4",
        "claude-sonnet-4",
        "claude-haiku-4",
        "claude-opus-3-5",
        "claude-sonnet-3-5",
        "other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Label (e.g. Chat session)", text: $label)
                    Picker("Model", selection: $model) {
                        ForEach(models, id: \.self) { Text($0) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Tokens") {
                    HStack {
                        Text("Input")
                        Spacer()
                        TextField("0", text: $inputTokens)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Output")
                        Spacer()
                        TextField("0", text: $outputTokens)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let total = totalTokens {
                        HStack {
                            Text("Total")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(total.formatted())
                                .bold()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var totalTokens: Int? {
        guard let i = Int(inputTokens), let o = Int(outputTokens) else { return nil }
        return i + o
    }

    private var isValid: Bool {
        !label.isEmpty && (Int(inputTokens) != nil || Int(outputTokens) != nil)
    }

    private func save() {
        let entry = UsageEntry(
            date: date,
            inputTokens: Int(inputTokens) ?? 0,
            outputTokens: Int(outputTokens) ?? 0,
            label: label.isEmpty ? "Manual entry" : label,
            model: model
        )
        store.addEntry(entry)
        dismiss()
    }
}
