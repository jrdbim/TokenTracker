import XCTest
@testable import TokenTracker

@MainActor
final class TokenStoreTests: XCTestCase {

    // MARK: - Helpers

    private func makeStore() -> TokenStore {
        // Use fresh UserDefaults suite so tests don't pollute each other
        let store = TokenStore()
        store.entries = []
        store.limit5Hours = 0
        store.limitWeekly = 0
        return store
    }

    private func makeEntry(hoursAgo: Double, input: Int = 1000, output: Int = 500) -> UsageEntry {
        UsageEntry(
            date: Date().addingTimeInterval(-hoursAgo * 3600),
            inputTokens: input,
            outputTokens: output,
            label: "Test",
            model: "claude-code"
        )
    }

    // MARK: - tokensUsedInPeriod

    func test_tokensUsedInPeriod_sumsEntriesWithinPeriod() {
        let store = makeStore()
        store.budget = TokenBudget(totalTokens: 1_000_000, periodStart: Date().addingTimeInterval(-86400), periodType: .monthly)
        store.entries = [
            makeEntry(hoursAgo: 1),
            makeEntry(hoursAgo: 2),
        ]
        // Each entry: input 1000 + output 500 = 1500, ×2 = 3000
        XCTAssertEqual(store.tokensUsedInPeriod, 3000)
    }

    func test_tokensUsedInPeriod_excludesEntriesBeforePeriodStart() {
        let store = makeStore()
        // Period started 1 hour ago
        store.budget = TokenBudget(totalTokens: 1_000_000, periodStart: Date().addingTimeInterval(-3600), periodType: .monthly)
        store.entries = [
            makeEntry(hoursAgo: 0.5), // inside
            makeEntry(hoursAgo: 5),   // outside (before period start)
        ]
        XCTAssertEqual(store.tokensUsedInPeriod, 1500)
    }

    // MARK: - tokensRemaining

    func test_tokensRemaining_isNonNegative() {
        let store = makeStore()
        store.budget = TokenBudget(totalTokens: 100, periodStart: Date().addingTimeInterval(-3600), periodType: .monthly)
        store.entries = [makeEntry(hoursAgo: 0.5, input: 1000, output: 1000)]
        XCTAssertGreaterThanOrEqual(store.tokensRemaining, 0)
    }

    func test_tokensRemaining_calculatesCorrectly() {
        let store = makeStore()
        store.budget = TokenBudget(totalTokens: 10_000, periodStart: Date().addingTimeInterval(-3600), periodType: .monthly)
        store.entries = [makeEntry(hoursAgo: 0.5, input: 2000, output: 1000)] // uses 3000
        XCTAssertEqual(store.tokensRemaining, 7000)
    }

    // MARK: - usagePercentage

    func test_usagePercentage_zeroWhenNoBudget() {
        let store = makeStore()
        store.budget = TokenBudget(totalTokens: 0, periodStart: Date(), periodType: .monthly)
        XCTAssertEqual(store.usagePercentage, 0)
    }

    func test_usagePercentage_calculatesCorrectly() {
        let store = makeStore()
        store.budget = TokenBudget(totalTokens: 10_000, periodStart: Date().addingTimeInterval(-3600), periodType: .monthly)
        store.entries = [makeEntry(hoursAgo: 0.5, input: 2500, output: 2500)] // uses 5000 = 50%
        XCTAssertEqual(store.usagePercentage, 0.5, accuracy: 0.001)
    }

    // MARK: - entriesInPeriod

    func test_entriesInPeriod_sortedNewestFirst() {
        let store = makeStore()
        store.budget = TokenBudget(totalTokens: 1_000_000, periodStart: Date().addingTimeInterval(-86400), periodType: .monthly)
        let older = makeEntry(hoursAgo: 5)
        let newer = makeEntry(hoursAgo: 1)
        store.entries = [older, newer]
        XCTAssertEqual(store.entriesInPeriod.first?.date, newer.date)
    }

    // MARK: - addEntry / deleteEntry

    func test_addEntry_appendsToEntries() {
        let store = makeStore()
        let entry = makeEntry(hoursAgo: 1)
        store.addEntry(entry)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.id, entry.id)
    }

    func test_deleteEntry_removesById() {
        let store = makeStore()
        let e1 = makeEntry(hoursAgo: 1)
        let e2 = makeEntry(hoursAgo: 2)
        store.entries = [e1, e2]
        store.deleteEntry(id: e1.id)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.id, e2.id)
    }

    func test_deleteEntry_nonexistentIdIsNoop() {
        let store = makeStore()
        store.entries = [makeEntry(hoursAgo: 1)]
        store.deleteEntry(id: UUID()) // random, nonexistent
        XCTAssertEqual(store.entries.count, 1)
    }

    // MARK: - nextFriday6pm

    func test_nextFriday6pm_isFriday() {
        let friday = TokenStore.nextFriday6pm()
        let weekday = Calendar.current.component(.weekday, from: friday)
        XCTAssertEqual(weekday, 6, "Should be Friday (weekday 6)")
    }

    func test_nextFriday6pm_isAt6pm() {
        let friday = TokenStore.nextFriday6pm()
        let hour = Calendar.current.component(.hour, from: friday)
        XCTAssertEqual(hour, 18)
    }

    func test_nextFriday6pm_isInFuture() {
        XCTAssertGreaterThan(TokenStore.nextFriday6pm(), Date())
    }

    // MARK: - TokenBudget period end

    func test_tokenBudget_dailyPeriodEnd() {
        let start = Date()
        let budget = TokenBudget(totalTokens: 1000, periodStart: start, periodType: .daily)
        let diff = budget.periodEnd.timeIntervalSince(start)
        XCTAssertEqual(diff, 86400, accuracy: 1)
    }

    func test_tokenBudget_weeklyPeriodEnd() {
        let start = Date()
        let budget = TokenBudget(totalTokens: 1000, periodStart: start, periodType: .weekly)
        let diff = budget.periodEnd.timeIntervalSince(start)
        XCTAssertEqual(diff, 7 * 86400, accuracy: 1)
    }
}
