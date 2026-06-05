import XCTest
@testable import TokenTracker

final class TokenModelsTests: XCTestCase {

    // MARK: - UsageEntry

    func test_usageEntry_totalTokens() {
        let entry = UsageEntry(date: Date(), inputTokens: 1200, outputTokens: 800, label: "Test", model: "claude")
        XCTAssertEqual(entry.totalTokens, 2000)
    }

    func test_usageEntry_totalTokens_zeroOutput() {
        let entry = UsageEntry(date: Date(), inputTokens: 500, outputTokens: 0, label: "Test", model: "claude")
        XCTAssertEqual(entry.totalTokens, 500)
    }

    func test_usageEntry_uniqueIDs() {
        let a = UsageEntry(date: Date(), inputTokens: 100, outputTokens: 100, label: "A", model: "claude")
        let b = UsageEntry(date: Date(), inputTokens: 100, outputTokens: 100, label: "B", model: "claude")
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - UsageEntry Codable round-trip

    func test_usageEntry_codableRoundTrip() throws {
        let original = UsageEntry(date: Date(), inputTokens: 123, outputTokens: 456, label: "Round-trip", model: "claude-opus-4")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsageEntry.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.inputTokens, original.inputTokens)
        XCTAssertEqual(decoded.outputTokens, original.outputTokens)
        XCTAssertEqual(decoded.label, original.label)
        XCTAssertEqual(decoded.model, original.model)
    }

    // MARK: - TokenBudget Codable round-trip

    func test_tokenBudget_codableRoundTrip() throws {
        let original = TokenBudget(totalTokens: 5_000_000, periodStart: Date(), periodType: .weekly)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TokenBudget.self, from: data)
        XCTAssertEqual(decoded.totalTokens, original.totalTokens)
        XCTAssertEqual(decoded.periodType, original.periodType)
    }

    // MARK: - TokenBudget.PeriodType

    func test_periodType_allCasesExist() {
        let cases = TokenBudget.PeriodType.allCases
        XCTAssertTrue(cases.contains(.daily))
        XCTAssertTrue(cases.contains(.weekly))
        XCTAssertTrue(cases.contains(.monthly))
        XCTAssertTrue(cases.contains(.custom))
    }

    func test_periodType_rawValues() {
        XCTAssertEqual(TokenBudget.PeriodType.daily.rawValue, "Daily")
        XCTAssertEqual(TokenBudget.PeriodType.weekly.rawValue, "Weekly")
        XCTAssertEqual(TokenBudget.PeriodType.monthly.rawValue, "Monthly")
        XCTAssertEqual(TokenBudget.PeriodType.custom.rawValue, "Custom")
    }
}
