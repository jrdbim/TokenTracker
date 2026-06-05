import Foundation
import Combine

@MainActor
final class TokenStore: ObservableObject {
    @Published var budget: TokenBudget {
        didSet { saveBudget() }
    }
    @Published var entries: [UsageEntry] = [] {
        didSet { saveEntries() }
    }
    @Published var macHost: String = "" {
        didSet { UserDefaults.standard.set(macHost, forKey: macHostKey) }
    }
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var lastSyncDate: Date?
    @Published var last5HoursTokens: Int = 0
    @Published var lastWeekTokens: Int = 0
    /// When the 5-hour rolling window resets (oldest entry in window + 5h)
    @Published var reset5HoursAt: Date?
    /// When the weekly window resets — Claude Code resets every Friday at 6pm local time
    var weeklyResetAt: Date { Self.nextFriday6pm() }
    @Published var limit5Hours: Int = 0 {
        didSet { UserDefaults.standard.set(limit5Hours, forKey: "limit5Hours") }
    }
    @Published var limitWeekly: Int = 0 {
        didSet { UserDefaults.standard.set(limitWeekly, forKey: "limitWeekly") }
    }

    private let budgetKey = "tokenBudget"
    private let entriesKey = "tokenEntries"
    private let lastSyncKey = "lastSyncDate"
    private let macHostKey = "macHost"

    init() {
        budget = TokenBudget(totalTokens: 1_000_000, periodStart: Date(), periodType: .monthly)
        macHost = UserDefaults.standard.string(forKey: "macHost") ?? "Jiradets-MacBook-Pro.local"
        limit5Hours = UserDefaults.standard.integer(forKey: "limit5Hours")
        limitWeekly = UserDefaults.standard.integer(forKey: "limitWeekly")
        loadBudget()
        loadEntries()
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    // MARK: - Computed

    var tokensUsedInPeriod: Int {
        entries
            .filter { $0.date >= budget.periodStart && $0.date <= budget.periodEnd }
            .reduce(0) { $0 + $1.totalTokens }
    }

    var tokensRemaining: Int {
        max(0, budget.totalTokens - tokensUsedInPeriod)
    }

    var usagePercentage: Double {
        guard budget.totalTokens > 0 else { return 0 }
        return Double(tokensUsedInPeriod) / Double(budget.totalTokens)
    }

    var entriesInPeriod: [UsageEntry] {
        entries
            .filter { $0.date >= budget.periodStart && $0.date <= budget.periodEnd }
            .sorted { $0.date > $1.date }
    }

    var dailyUsage: [(date: Date, tokens: Int)] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entriesInPeriod) {
            cal.startOfDay(for: $0.date)
        }
        return grouped
            .map { (date: $0.key, tokens: $0.value.reduce(0) { $0 + $1.totalTokens }) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Actions

    func addEntry(_ entry: UsageEntry) {
        entries.append(entry)
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
    }

    func resetPeriod() {
        budget.periodStart = Date()
    }

    func sync() async {
        isSyncing = true
        syncError = nil
        do {
            let (fetched, fetched5h, fetchedWeek) = try await LocalSyncService.shared.fetchUsage(
                host: macHost,
                periodStart: budget.periodStart,
                periodEnd: budget.periodEnd
            )
            entries.removeAll { $0.model == "claude-code" }
            entries.append(contentsOf: fetched)
            last5HoursTokens = fetched5h
            lastWeekTokens = fetchedWeek
            // 5-hour rolling window: resets when oldest entry in window ages out
            let fiveHoursAgo = Date().addingTimeInterval(-5 * 3600)
            let windowEntries = entries.filter { $0.model == "claude-code" && $0.date >= fiveHoursAgo }
            reset5HoursAt = windowEntries.min(by: { $0.date < $1.date })?.date.addingTimeInterval(5 * 3600)
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
        } catch {
            syncError = error.localizedDescription
        }
        isSyncing = false
    }

    // MARK: - Reset time helpers

    /// Computes the next (or current) Friday 6pm local time — matching Claude Code's weekly reset.
    static func nextFriday6pm() -> Date {
        var cal = Calendar.current
        cal.timeZone = .current
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=Sun … 7=Sat; Friday=6
        // Days until next Friday (0 means today is Friday)
        let daysUntilFriday = (6 - weekday + 7) % 7
        let targetDay = cal.date(byAdding: .day, value: daysUntilFriday, to: now)!
        var comps = cal.dateComponents([.year, .month, .day], from: targetDay)
        comps.hour = 18; comps.minute = 0; comps.second = 0
        let friday6pm = cal.date(from: comps)!
        // If today is Friday but we're already past 6pm, use next week's Friday
        if friday6pm <= now {
            return cal.date(byAdding: .day, value: 7, to: friday6pm)!
        }
        return friday6pm
    }

    // MARK: - Persistence

    private func saveBudget() {
        if let data = try? JSONEncoder().encode(budget) {
            UserDefaults.standard.set(data, forKey: budgetKey)
        }
    }

    private func loadBudget() {
        guard let data = UserDefaults.standard.data(forKey: budgetKey),
              let saved = try? JSONDecoder().decode(TokenBudget.self, from: data) else { return }
        budget = saved
    }

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let saved = try? JSONDecoder().decode([UsageEntry].self, from: data) else { return }
        entries = saved
    }
}
