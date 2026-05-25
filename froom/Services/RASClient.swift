//
//  RASClient.swift
//  Redzone Tracker
//
//  Fetches ras-latest.json from GitHub raw. Provides lookup by player name.
//

import Foundation

@Observable
final class RASClient {

    static let owner = "Jettest777"
    static let repo = "froom"
    static let branch = "main"
    static let path = "data-pipeline/output/ras-latest.json"

    static var feedURL: URL {
        URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/\(path)")!
    }

    private(set) var entries: [String: RASEntry] = [:]
    private(set) var isLoading: Bool = false
    private(set) var lastError: String?
    private(set) var lastFetchedAt: Date?

    init() {
        // Provide mock entry for offline development
        entries = ["Patrick Mahomes": .mockMahomes]
    }

    @MainActor
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var request = URLRequest(url: Self.feedURL)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            let env = try JSONDecoder().decode(RASEnvelope.self, from: data)
            self.entries = env.players
            self.lastFetchedAt = Date()
            self.lastError = nil
        } catch {
            self.lastError = "\(error)"
        }
    }

    /// Lookup by exact full name (case-insensitive). Tries common variants.
    func entry(for fullName: String) -> RASEntry? {
        let target = fullName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for (k, v) in entries where k.lowercased() == target {
            return v
        }
        // Try matching by last token (last name) as a fallback
        let parts = target.split(separator: " ")
        if let last = parts.last {
            for (k, v) in entries where k.lowercased().split(separator: " ").last == last {
                return v
            }
        }
        return nil
    }
}
