import XCTest
@testable import TokenTracker

final class LocalSyncServiceTests: XCTestCase {

    // MARK: - MacUsageResponse decoding

    private let sampleJSON = """
    {
        "generatedAt": "2026-06-05T18:00:00+00:00",
        "totals": {
            "inputTokens": 500,
            "outputTokens": 2000,
            "cacheReadTokens": 10000,
            "cacheCreateTokens": 3000,
            "totalTokens": 2500
        },
        "last5Hours": {
            "inputTokens": 100,
            "outputTokens": 400,
            "totalTokens": 500
        },
        "lastWeek": {
            "inputTokens": 300,
            "outputTokens": 1200,
            "totalTokens": 1500
        },
        "sessions": [
            {
                "sessionId": "abc-123",
                "project": "-Users-bim-MyProject",
                "cwd": "/Users/bim/MyProject",
                "firstTimestamp": "2026-06-05T10:00:00.000Z",
                "lastTimestamp": "2026-06-05T11:00:00.000Z",
                "inputTokens": 100,
                "outputTokens": 400,
                "cacheReadTokens": 5000,
                "cacheCreateTokens": 1500,
                "messageCount": 10
            }
        ]
    }
    """

    func test_decodesMacUsageResponse() throws {
        let data = Data(sampleJSON.utf8)
        let response = try JSONDecoder().decode(MacUsageResponse.self, from: data)

        XCTAssertEqual(response.totals.inputTokens, 500)
        XCTAssertEqual(response.totals.outputTokens, 2000)
        XCTAssertEqual(response.totals.totalTokens, 2500)
        XCTAssertEqual(response.last5Hours.totalTokens, 500)
        XCTAssertEqual(response.lastWeek.totalTokens, 1500)
        XCTAssertEqual(response.sessions.count, 1)
    }

    func test_decodesSession() throws {
        let data = Data(sampleJSON.utf8)
        let response = try JSONDecoder().decode(MacUsageResponse.self, from: data)
        let session = try XCTUnwrap(response.sessions.first)

        XCTAssertEqual(session.sessionId, "abc-123")
        XCTAssertEqual(session.project, "-Users-bim-MyProject")
        XCTAssertEqual(session.inputTokens, 100)
        XCTAssertEqual(session.outputTokens, 400)
        XCTAssertEqual(session.messageCount, 10)
    }

    func test_decodingFailsWithMissingRequiredFields() {
        let badJSON = """
        { "generatedAt": "2026-06-05T18:00:00+00:00" }
        """
        let data = Data(badJSON.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(MacUsageResponse.self, from: data))
    }

    // MARK: - SyncError descriptions

    func test_syncError_noHostConfigured() {
        let err = SyncError.noHostConfigured
        XCTAssertNotNil(err.errorDescription)
        XCTAssertFalse(err.errorDescription!.isEmpty)
    }

    func test_syncError_decodingError() {
        let err = SyncError.decodingError
        XCTAssertNotNil(err.errorDescription)
        XCTAssertFalse(err.errorDescription!.isEmpty)
    }

    // MARK: - fetchUsage with no host

    func test_fetchUsage_throwsWhenHostEmpty() async {
        do {
            _ = try await LocalSyncService.shared.fetchUsage(
                host: "",
                periodStart: Date().addingTimeInterval(-86400),
                periodEnd: Date()
            )
            XCTFail("Expected SyncError.noHostConfigured")
        } catch SyncError.noHostConfigured {
            // ✓ expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func test_fetchUsage_throwsNetworkErrorForUnreachableHost() async {
        do {
            _ = try await LocalSyncService.shared.fetchUsage(
                host: "192.0.2.1",  // TEST-NET, guaranteed unreachable
                periodStart: Date().addingTimeInterval(-86400),
                periodEnd: Date()
            )
            XCTFail("Expected network error")
        } catch SyncError.networkError {
            // ✓ expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
