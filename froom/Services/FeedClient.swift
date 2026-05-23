//
//  FeedClient.swift
//  f/Room
//
//  Fetches the latest intel feed JSON published by the data-pipeline GitHub Actions workflow.
//
//  How it works:
//    - data-pipeline runs every 30 minutes via GitHub Actions
//    - It writes data-pipeline/output/intel-latest.json into the repo
//    - The iOS app fetches that file from GitHub raw URL
//    - Falls back to MockData if the network call fails
//

import Foundation

@Observable
final class FeedClient {

    // MARK: - Configuration

    /// Set this to your GitHub user/repo. The app fetches:
    ///   https://raw.githubusercontent.com/{owner}/{repo}/main/data-pipeline/output/intel-latest.json
    static let owner = "Jettest777"
    static let repo = "froom"
    static let branch = "main"
    static let path = "data-pipeline/output/intel-latest.json"

    static var feedURL: URL {
        URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/\(path)")!
    }

    // MARK: - State

    private(set) var items: [NewsItem] = []
    private(set) var lastFetchedAt: Date?
    private(set) var isLoading: Bool = false
    private(set) var lastError: String?

    /// If `useMockOnFailure` is true, falls back to MockData when fetch fails.
    let useMockOnFailure: Bool

    init(useMockOnFailure: Bool = true) {
        self.useMockOnFailure = useMockOnFailure
        self.items = MockData.news
    }

    // MARK: - Fetch

    @MainActor
    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            var request = URLRequest(url: Self.feedURL)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw FeedError.badStatus
            }
            let envelope = try JSONDecoder.feedDecoder.decode(FeedEnvelope.self, from: data)
            self.items = envelope.items.map { $0.toDomain() }
            self.lastFetchedAt = Date()
        } catch {
            lastError = "\(error)"
            if useMockOnFailure {
                self.items = MockData.news
            }
        }
    }

    // MARK: - DTOs matching the Python pipeline output

    private struct FeedEnvelope: Decodable {
        let version: Int
        let generated_at: String
        let count: Int
        let items: [FeedItem]
    }

    private struct FeedItem: Decodable {
        let kind: String
        let title: String
        let title_ja: String?
        let excerpt: String
        let excerpt_ja: String?
        let sources: [String]
        let reliability: Double
        let team_abbrev: String?
        let player_name: String?
        let coach_name: String?
        let published_at: String
        let url: String?

        func toDomain() -> NewsItem {
            let date = ISO8601DateFormatter.shared.date(from: published_at) ?? Date()
            return NewsItem(
                id: UUID(),
                kind: NewsKind(rawValue: kind) ?? .other,
                title: title,
                titleJA: title_ja,
                excerpt: excerpt,
                excerptJA: excerpt_ja,
                sources: sources,
                reliability: reliability,
                teamAbbrev: team_abbrev,
                playerName: player_name,
                coachName: coach_name,
                publishedAt: date,
                url: url.flatMap(URL.init(string:))
            )
        }
    }

    enum FeedError: Error {
        case badStatus
    }
}

private extension JSONDecoder {
    static let feedDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }()
}

private extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
