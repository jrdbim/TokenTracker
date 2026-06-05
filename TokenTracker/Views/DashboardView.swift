import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: TokenStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    planUsageCard
                    if let err = store.syncError {
                        errorBanner(err)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Plan Usage")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await store.sync() }
                    } label: {
                        if store.isSyncing {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(store.isSyncing)
                }
            }
        }
    }

    // MARK: - Plan Usage Card

    @ViewBuilder
    private var planUsageCard: some View {
        let has5h = store.limit5Hours > 0
        let hasWeekly = store.limitWeekly > 0

        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Plan usage")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if let date = store.lastSyncDate {
                    Text(date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.leading, 16)

            if !has5h && !hasWeekly {
                // Empty state
                VStack(spacing: 6) {
                    Image(systemName: "gauge.medium")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Set your plan limits in Settings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                // Rows
                if has5h {
                    LimitRow(
                        label: "5-hour limit",
                        used: store.last5HoursTokens,
                        limit: store.limit5Hours,
                        resetAt: store.reset5HoursAt
                    )
                    if hasWeekly {
                        Divider().padding(.leading, 16)
                    }
                }
                if hasWeekly {
                    LimitRow(
                        label: "Weekly · all models",
                        used: store.lastWeekTokens,
                        limit: store.limitWeekly,
                        resetAt: store.weeklyResetAt
                    )
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - LimitRow

struct LimitRow: View {
    let label: String
    let used: Int
    let limit: Int
    let resetAt: Date?

    private var pct: Double { limit > 0 ? min(Double(used) / Double(limit), 1.0) : 0 }
    private var barColor: Color {
        switch pct {
        case ..<0.6:  return .blue
        case ..<0.85: return .orange
        default:      return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(Int(pct * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(barColor)
                    if let reset = resetAt, reset > Date() {
                        Text("· resets \(resetLabel(reset))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Thin progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    Capsule()
                        .fill(barColor.gradient)
                        .frame(width: geo.size.width * pct, height: 4)
                        .animation(.easeOut(duration: 0.35), value: pct)
                }
            }
            .frame(height: 4)

            Text("\(used.compactFormatted) / \(limit.compactFormatted)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func resetLabel(_ date: Date) -> String {
        let secs = date.timeIntervalSinceNow
        if secs <= 0 { return "soon" }
        let mins = Int(secs / 60)
        let hrs  = Int(secs / 3600)
        let days = Int(secs / 86400)
        if days >= 1 { return "\(days)d" }
        if hrs  >= 1 { return "\(hrs)h" }
        return "\(mins)m"
    }
}

// MARK: - Int formatting

private extension Int {
    var compactFormatted: String {
        switch self {
        case 1_000_000...: return String(format: "%.1fM", Double(self) / 1_000_000)
        case 1_000...:     return String(format: "%.0fK", Double(self) / 1_000)
        default:           return "\(self)"
        }
    }
}
