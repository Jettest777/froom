//
//  CapClient.swift
//  f/Room
//
//  Fetches cap-{season}.json from the GitHub raw URL. Mirrors FeedClient pattern.
//

import Foundation

@Observable
final class CapClient {

    static let owner = "Jettest777"
    static let repo = "froom"
    static let branch = "main"

    static func feedURL(season: Int) -> URL {
        URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/data-pipeline/output/cap-\(season).json")!
    }

    private(set) var teams: [String: TeamCapSummary] = [:]
    private(set) var lastFetchedAt: Date?
    private(set) var isLoading: Bool = false
    private(set) var lastError: String?
    private(set) var season: Int

    init(season: Int = Calendar.current.component(.year, from: Date())) {
        self.season = season
        self.teams = MockCapData.byTeam
    }

    @MainActor
    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            var request = URLRequest(url: Self.feedURL(season: season))
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            let envelope = try JSONDecoder().decode(CapEnvelope.self, from: data)
            self.teams = envelope.teams
            self.lastFetchedAt = Date()
        } catch {
            lastError = "\(error)"
            // Keep showing mock data when offline
            self.teams = MockCapData.byTeam
        }
    }

    func summary(for teamId: String) -> TeamCapSummary? {
        teams[teamId]
    }

    // MARK: - DTOs

    private struct CapEnvelope: Decodable {
        let version: Int
        let season: Int
        let generated_at: String
        let teams: [String: TeamCapSummary]
    }
}

// MARK: - Mock for previews & offline fallback

enum MockCapData {
    static let kcMock = TeamCapSummary(
        teamId: "KC",
        season: 2026,
        salaryCap: 279.2,
        totalCapSpent: 268.5,
        activeContracts: 52,
        deadCap: 8.3,
        capSpace: 10.7,
        topCapHits: [
            PlayerCapHit(teamId: "KC", season: 2026, playerName: "Patrick Mahomes", position: "QB", jerseyNumber: 15,
                          capHit: 66.4, baseSalary: 47.4, signingBonusProration: 12.5, restructureBonus: 6.5,
                          roster: .active, isDeadMoney: false, isTopHeavy: true),
            PlayerCapHit(teamId: "KC", season: 2026, playerName: "Chris Jones", position: "DT", jerseyNumber: 95,
                          capHit: 32.1, baseSalary: 22.0, signingBonusProration: 8.0, restructureBonus: 2.1,
                          roster: .active, isDeadMoney: false, isTopHeavy: true),
            PlayerCapHit(teamId: "KC", season: 2026, playerName: "Travis Kelce", position: "TE", jerseyNumber: 87,
                          capHit: 19.0, baseSalary: 11.5, signingBonusProration: 5.0, restructureBonus: 2.5,
                          roster: .active, isDeadMoney: false, isTopHeavy: true),
            PlayerCapHit(teamId: "KC", season: 2026, playerName: "Trent McDuffie", position: "CB", jerseyNumber: 21,
                          capHit: 16.8, baseSalary: 12.2, signingBonusProration: 4.6, restructureBonus: nil,
                          roster: .active, isDeadMoney: false, isTopHeavy: true),
            PlayerCapHit(teamId: "KC", season: 2026, playerName: "Joe Thuney", position: "G", jerseyNumber: 62,
                          capHit: 16.3, baseSalary: 11.8, signingBonusProration: 4.5, restructureBonus: nil,
                          roster: .active, isDeadMoney: false, isTopHeavy: true),
            PlayerCapHit(teamId: "KC", season: 2026, playerName: "DeAndre Hopkins", position: "WR", jerseyNumber: 8,
                          capHit: 4.6, baseSalary: 0, signingBonusProration: 4.6, restructureBonus: nil,
                          roster: .released, isDeadMoney: true, isTopHeavy: false),
        ],
        updatedAt: Date()
    )

    static let byTeam: [String: TeamCapSummary] = [
        "KC": kcMock,
    ]
}
