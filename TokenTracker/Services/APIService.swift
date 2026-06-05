import Foundation

enum SyncError: LocalizedError {
    case noHostConfigured
    case networkError(Error)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .noHostConfigured:    return "Mac hostname not set. Add it in Settings."
        case .networkError(let e): return e.localizedDescription
        case .decodingError:       return "Failed to decode response from Mac"
        }
    }
}

struct MacUsageResponse: Codable {
    let generatedAt: String
    let totals: MacTotals
    let last5Hours: MacWindowUsage
    let lastWeek: MacWindowUsage
    let sessions: [MacSession]
}

struct MacTotals: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let cacheCreateTokens: Int
    let totalTokens: Int
}

struct MacWindowUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
}

struct MacSession: Codable {
    let sessionId: String
    let project: String
    let cwd: String
    let firstTimestamp: String
    let lastTimestamp: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let cacheCreateTokens: Int
    let messageCount: Int
}

actor LocalSyncService {
    static let shared = LocalSyncService()
    private let port = 8765

    func fetchUsage(host: String, periodStart: Date, periodEnd: Date) async throws -> ([UsageEntry], Int, Int) {
        guard !host.isEmpty else { throw SyncError.noHostConfigured }

        let urlString = "http://\(host):\(port)/usage.json"
        guard let url = URL(string: urlString) else { throw SyncError.noHostConfigured }

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw SyncError.networkError(error)
        }

        let response: MacUsageResponse
        do {
            response = try JSONDecoder().decode(MacUsageResponse.self, from: data)
        } catch {
            throw SyncError.decodingError
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let entries = response.sessions.compactMap { session -> UsageEntry? in
            let date = isoFormatter.date(from: session.lastTimestamp) ?? Date()
            guard date >= periodStart && date <= periodEnd else { return nil }
            return UsageEntry(
                date: date,
                inputTokens: session.inputTokens,
                outputTokens: session.outputTokens,
                label: session.project,
                model: "claude-code"
            )
        }

        return (entries, response.last5Hours.totalTokens, response.lastWeek.totalTokens)
    }
}
