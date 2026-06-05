import Foundation

struct TokenBudget: Codable {
    var totalTokens: Int
    var periodStart: Date
    var periodType: PeriodType

    enum PeriodType: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case custom = "Custom"
    }

    var periodEnd: Date {
        let cal = Calendar.current
        switch periodType {
        case .daily:   return cal.date(byAdding: .day, value: 1, to: periodStart) ?? periodStart
        case .weekly:  return cal.date(byAdding: .day, value: 7, to: periodStart) ?? periodStart
        case .monthly: return cal.date(byAdding: .month, value: 1, to: periodStart) ?? periodStart
        case .custom:  return cal.date(byAdding: .day, value: 30, to: periodStart) ?? periodStart
        }
    }
}

struct UsageEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var inputTokens: Int
    var outputTokens: Int
    var label: String
    var model: String

    var totalTokens: Int { inputTokens + outputTokens }
}

struct AnthropicUsageResponse: Codable {
    let data: [AnthropicUsageItem]
}

struct AnthropicUsageItem: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case timestamp
    }
}
