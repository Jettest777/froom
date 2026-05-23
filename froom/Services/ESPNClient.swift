//
//  ESPNClient.swift
//  f/Room
//
//  Thin client for ESPN's public (undocumented) NFL endpoints.
//  Endpoints are unstable; treat 4xx/5xx as expected and degrade gracefully.
//

import Foundation

actor ESPNClient {
    static let shared = ESPNClient()

    private let baseSiteAPI = URL(string: "https://site.api.espn.com/apis/site/v2/sports/football/nfl")!
    private let baseCoreAPI = URL(string: "https://sports.core.api.espn.com/v2/sports/football/leagues/nfl")!

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Endpoints

    /// Fetch team roster. Returns lightweight athlete records suitable for depth chart lists.
    /// Example: GET https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/KC/roster
    func fetchRoster(teamAbbrev: String) async throws -> [RawAthlete] {
        var url = baseSiteAPI
        url.appendPathComponent("teams/\(teamAbbrev.lowercased())/roster")
        let (data, response) = try await session.data(from: url)
        try Self.checkResponse(response)
        let decoded = try decoder.decode(RawRosterResponse.self, from: data)
        return decoded.athletes.flatMap { $0.items }
    }

    /// Fetch full athlete profile. Returns enough data to fill the PlayerDetail screen.
    /// Example: GET https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/athletes/3139477
    func fetchAthlete(espnId: String) async throws -> RawAthlete {
        var url = baseCoreAPI
        url.appendPathComponent("athletes/\(espnId)")
        let (data, response) = try await session.data(from: url)
        try Self.checkResponse(response)
        return try decoder.decode(RawAthlete.self, from: data)
    }

    // MARK: - Helpers

    private static func checkResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ESPNError.invalidResponse
        }
        guard 200..<300 ~= http.statusCode else {
            throw ESPNError.httpStatus(http.statusCode)
        }
    }
}

// MARK: - Errors

enum ESPNError: Error {
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)
}

// MARK: - Raw API DTOs (subset of fields we care about)

struct RawRosterResponse: Decodable {
    let athletes: [RawAthleteGroup]
}

struct RawAthleteGroup: Decodable {
    let position: String?
    let items: [RawAthlete]
}

struct RawAthlete: Decodable {
    let id: String
    let firstName: String?
    let lastName: String?
    let displayName: String?
    let jersey: String?
    let position: RawPosition?
    let height: Double?            // inches
    let weight: Double?            // lbs
    let dateOfBirth: String?       // ISO 8601
    let college: RawCollege?
    let draft: RawDraft?
    let experience: RawExperience?
    let teamHistory: [RawTeamStint]?

    struct RawPosition: Decodable {
        let abbreviation: String?
        let displayName: String?
    }

    struct RawCollege: Decodable {
        let name: String?
        let mascot: String?
    }

    struct RawDraft: Decodable {
        let year: Int?
        let round: Int?
        let selection: Int?
        let team: RawTeamRef?
    }

    struct RawTeamRef: Decodable {
        let id: String?
        let abbreviation: String?
        let displayName: String?
    }

    struct RawExperience: Decodable {
        let years: Int?
    }

    struct RawTeamStint: Decodable {
        let teamId: String
        let startSeason: Int
        let endSeason: Int?
    }
}

// MARK: - Mapping to domain model

extension RawAthlete {
    /// Best-effort conversion to our domain `PlayerDetail` model.
    func toPlayerDetail() -> PlayerDetail {
        let isoFormatter = ISO8601DateFormatter()

        let stints: [TeamStint] = (teamHistory ?? []).map { raw in
            TeamStint(
                id: UUID(),
                teamId: raw.teamId,
                startYear: raw.startSeason,
                endYear: raw.endSeason,
                endReason: nil,
                acquisitionType: nil
            )
        }

        let mappedDraft: Draft? = draft.flatMap { d in
            guard let year = d.year, let round = d.round, let pick = d.selection else { return nil }
            return Draft(
                year: year,
                round: round,
                pick: pick,
                overallPick: pick,
                draftedByTeamId: d.team?.abbreviation ?? ""
            )
        }

        return PlayerDetail(
            id: UUID(),
            firstName: firstName ?? (displayName?.components(separatedBy: " ").first ?? ""),
            lastName: lastName ?? (displayName?.components(separatedBy: " ").dropFirst().joined(separator: " ") ?? ""),
            position: position?.abbreviation ?? "—",
            jerseyNumber: Int(jersey ?? "") ?? 0,
            currentTeamId: nil,
            heightInches: Int(height ?? 0),
            weightPounds: Int(weight ?? 0),
            dateOfBirth: dateOfBirth.flatMap { isoFormatter.date(from: $0) },
            college: college?.name,
            highSchool: nil,
            draft: mappedDraft,
            yearsInLeague: experience?.years ?? 0,
            isStarter: false,
            injuryStatus: nil,
            contract: nil,
            teamHistory: stints,
            careerStats: nil,
            externalIds: ExternalIds(espnId: id, pfrId: nil, nflId: nil),
            lastSyncedAt: Date()
        )
    }
}
