//
//  DigestClient.swift
//  Redzone Tracker
//
//  Fetches digest-latest.json from the GitHub raw URL.
//

import Foundation

@Observable
final class DigestClient {

    static let owner = "Jettest777"
    static let repo = "froom"
    static let branch = "main"
    static let path = "data-pipeline/output/digest-latest.json"

    static var feedURL: URL {
        URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/\(path)")!
    }

    private(set) var envelope: DigestEnvelope?
    private(set) var isLoading: Bool = false
    private(set) var lastError: String?

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
            let env = try JSONDecoder().decode(DigestEnvelope.self, from: data)
            self.envelope = env
            self.lastError = nil
        } catch {
            self.lastError = "\(error)"
            if envelope == nil {
                envelope = DigestEnvelope(
                    version: 1,
                    generatedAt: ISO8601DateFormatter().string(from: Date()),
                    timeOfDay: "morning",
                    sourceItemCount: 0,
                    rankedItemCount: 0,
                    digest: .mock
                )
            }
        }
    }
}
