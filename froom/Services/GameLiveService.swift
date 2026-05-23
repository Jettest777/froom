//
//  GameLiveService.swift
//  f/Room
//
//  ESPN scoreboard + game-summary client.
//
//  Endpoints used (undocumented but stable for years):
//    GET https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard
//        ?dates=YYYYMMDD or ?week=N&seasontype=2&year=2026
//    GET https://site.api.espn.com/apis/site/v2/sports/football/nfl/summary?event={gameId}
//
//  Responses are large; we map only the fields we need.
//

import Foundation

actor GameLiveService {
    static let shared = GameLiveService()

    private let baseURL = URL(string: "https://site.api.espn.com/apis/site/v2/sports/football/nfl")!
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        self.decoder = d
    }

    // MARK: - Scoreboard

    /// Fetch the scoreboard for a given week/season.
    /// `seasonType` ESPN convention: 1=preseason, 2=regular, 3=playoffs.
    func fetchScoreboard(season: Int, week: Int, seasonType: Int = 2) async throws -> [ScheduledGame] {
        var components = URLComponents(url: baseURL.appendingPathComponent("scoreboard"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "year", value: "\(season)"),
            URLQueryItem(name: "week", value: "\(week)"),
            URLQueryItem(name: "seasontype", value: "\(seasonType)")
        ]
        guard let url = components.url else { throw GameServiceError.invalidURL }
        let (data, response) = try await session.data(from: url)
        try checkStatus(response)
        let payload = try decoder.decode(ScoreboardEnvelope.self, from: data)
        return payload.events.compactMap { $0.toScheduledGame(season: season, week: week, seasonType: seasonType) }
    }

    // MARK: - Live game state

    /// Fetch the live state + play-by-play for a single game.
    func fetchGameSnapshot(gameId: String) async throws -> GameSnapshot? {
        var components = URLComponents(url: baseURL.appendingPathComponent("summary"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "event", value: gameId)]
        guard let url = components.url else { throw GameServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        try checkStatus(response)

        let payload = try decoder.decode(SummaryEnvelope.self, from: data)
        return payload.toGameSnapshot()
    }

    // MARK: - Private

    private func checkStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw GameServiceError.invalidResponse }
        guard 200..<300 ~= http.statusCode else { throw GameServiceError.httpStatus(http.statusCode) }
    }
}

enum GameServiceError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
}

// MARK: - Live polling helper (used by views)

@MainActor
@Observable
final class LiveGamePoller {
    private(set) var snapshot: GameSnapshot?
    private(set) var lastError: String?
    private(set) var isRefreshing: Bool = false

    private var task: Task<Void, Never>?
    private let pollInterval: TimeInterval

    let gameId: String

    init(gameId: String, pollInterval: TimeInterval = 30) {
        self.gameId = gameId
        self.pollInterval = pollInterval
    }

    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: UInt64((self?.pollInterval ?? 30) * 1_000_000_000))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let snap = try await GameLiveService.shared.fetchGameSnapshot(gameId: gameId)
            self.snapshot = snap
            self.lastError = nil
        } catch {
            self.lastError = "\(error)"
        }
    }
}

// MARK: - ESPN Scoreboard DTOs (minimal subset)

private struct ScoreboardEnvelope: Decodable {
    let events: [ScoreboardEvent]
}

private struct ScoreboardEvent: Decodable {
    let id: String
    let date: String
    let name: String?
    let competitions: [Competition]

    func toScheduledGame(season: Int, week: Int, seasonType: Int) -> ScheduledGame? {
        guard let comp = competitions.first,
              let kickoff = ISO8601DateFormatter().date(from: date) else { return nil }

        var awayId = "", homeId = ""
        var awayScore: Int? = nil, homeScore: Int? = nil

        for team in comp.competitors {
            let abbrev = team.team?.abbreviation ?? "—"
            let score = Int(team.score ?? "0")
            if team.homeAway == "away" {
                awayId = abbrev
                awayScore = score
            } else {
                homeId = abbrev
                homeScore = score
            }
        }

        let status = mapStatus(comp.status?.type?.state, comp.status?.type?.detail)

        let parsedSeasonType: SeasonType
        let round: PlayoffRound?
        switch seasonType {
        case 1: parsedSeasonType = .preseason; round = nil
        case 3:
            parsedSeasonType = .playoffs
            round = mapPlayoffRound(week: week)
        default: parsedSeasonType = .regular; round = nil
        }

        return ScheduledGame(
            id: id,
            season: season,
            seasonType: parsedSeasonType,
            week: week,
            playoffRound: round,
            kickoff: kickoff,
            awayTeamId: awayId,
            homeTeamId: homeId,
            status: status,
            awayScore: awayScore,
            homeScore: homeScore,
            venue: comp.venue?.fullName,
            broadcast: comp.broadcasts?.first?.names?.first
        )
    }
}

private struct Competition: Decodable {
    let id: String
    let competitors: [Competitor]
    let status: CompStatus?
    let venue: Venue?
    let broadcasts: [Broadcast]?
}

private struct Competitor: Decodable {
    let id: String
    let homeAway: String?
    let score: String?
    let team: TeamRef?
}

private struct TeamRef: Decodable {
    let abbreviation: String?
    let displayName: String?
}

private struct CompStatus: Decodable {
    let type: CompStatusType?
}

private struct CompStatusType: Decodable {
    let state: String?    // "pre" | "in" | "post"
    let detail: String?
    let shortDetail: String?
}

private struct Venue: Decodable {
    let fullName: String?
}

private struct Broadcast: Decodable {
    let names: [String]?
}

private func mapStatus(_ state: String?, _ detail: String?) -> GameStatus {
    let detail = detail?.lowercased() ?? ""
    switch state {
    case "pre": return .scheduled
    case "in":
        if detail.contains("half") { return .halftime }
        if detail.contains("ot") { return .overtime }
        return .live
    case "post":
        if detail.contains("ot") { return .finalOT }
        return .finalReg
    default: return .scheduled
    }
}

private func mapPlayoffRound(week: Int) -> PlayoffRound? {
    // ESPN convention: WC=1, DIV=2, CONF=3, SB=4 in seasontype=3
    switch week {
    case 1: return .wildcard
    case 2: return .divisional
    case 3: return .conference
    case 4, 5: return .superBowl
    default: return nil
    }
}

// MARK: - Summary endpoint DTOs

private struct SummaryEnvelope: Decodable {
    let header: Header?
    let drives: DrivesContainer?
    let scoringPlays: [ScoringPlay]?

    func toGameSnapshot() -> GameSnapshot? {
        guard let header,
              let id = header.id,
              let comp = header.competitions?.first,
              let kickoff = ISO8601DateFormatter().date(from: comp.date ?? "") else {
            return nil
        }

        var awayId = "", homeId = ""
        var awayScore = 0, homeScore = 0
        for c in comp.competitors ?? [] {
            let abbrev = c.team?.abbreviation ?? "—"
            let score = Int(c.score ?? "0") ?? 0
            if c.homeAway == "away" { awayId = abbrev; awayScore = score }
            else { homeId = abbrev; homeScore = score }
        }
        let status = mapStatus(comp.status?.type?.state, comp.status?.type?.detail)

        let scheduled = ScheduledGame(
            id: id,
            season: header.season?.year ?? Calendar.current.component(.year, from: Date()),
            seasonType: .regular,
            week: header.week ?? 0,
            playoffRound: nil,
            kickoff: kickoff,
            awayTeamId: awayId,
            homeTeamId: homeId,
            status: status,
            awayScore: awayScore,
            homeScore: homeScore,
            venue: nil,
            broadcast: nil
        )

        // Build LiveGameState from situation
        let situation = comp.situation
        let liveState = LiveGameState(
            gameId: id,
            updatedAt: Date(),
            awayScore: awayScore,
            homeScore: homeScore,
            quarter: comp.status?.period ?? 0,
            gameClock: comp.status?.displayClock ?? "",
            status: status,
            possession: situation?.possessionText,
            down: situation?.down,
            distance: situation?.distance,
            yardLine: situation?.possessionText.flatMap { _ in
                situation?.shortDownDistanceText
            },
            isRedZone: situation?.isRedZone ?? false,
            lastPlayDescription: situation?.lastPlay?.text,
            lastPlayYards: situation?.lastPlay?.statYardage,
            driveNumber: nil,
            drivePlays: nil,
            driveYards: nil,
            driveTimeOfPossession: nil
        )

        // Flatten drives → individual plays
        var allPlays: [PlayLog] = []
        var seq = 0
        for drive in drives?.previous ?? [] {
            for raw in drive.plays ?? [] {
                seq += 1
                if let log = raw.toPlayLog(gameId: id, sequence: seq) {
                    allPlays.append(log)
                }
            }
        }
        if let current = drives?.current?.plays {
            for raw in current {
                seq += 1
                if let log = raw.toPlayLog(gameId: id, sequence: seq) {
                    allPlays.append(log)
                }
            }
        }

        return GameSnapshot(scheduled: scheduled, state: liveState, plays: allPlays, lastSyncedAt: Date())
    }
}

private struct Header: Decodable {
    let id: String?
    let week: Int?
    let competitions: [HeaderCompetition]?
    let season: SeasonInfo?
}

private struct SeasonInfo: Decodable {
    let year: Int?
    let type: Int?
}

private struct HeaderCompetition: Decodable {
    let date: String?
    let competitors: [Competitor]?
    let status: CompStatusFull?
    let situation: Situation?
}

private struct CompStatusFull: Decodable {
    let period: Int?
    let displayClock: String?
    let type: CompStatusType?
}

private struct Situation: Decodable {
    let down: Int?
    let distance: Int?
    let isRedZone: Bool?
    let possessionText: String?
    let shortDownDistanceText: String?
    let lastPlay: LastPlay?
}

private struct LastPlay: Decodable {
    let text: String?
    let statYardage: Int?
}

private struct DrivesContainer: Decodable {
    let previous: [LiveDrive]?
    let current: LiveDrive?
}

private struct LiveDrive: Decodable {
    let id: String?
    let plays: [RawPlay]?
}

private struct RawPlay: Decodable {
    let id: String?
    let period: Period?
    let clock: Clock?
    let team: TeamRef?
    let down: Int?
    let distance: Int?
    let yardLine: Int?
    let text: String?
    let statYardage: Int?
    let scoringPlay: Bool?
    let type: PlayType?

    func toPlayLog(gameId: String, sequence: Int) -> PlayLog? {
        guard let id = id else { return nil }
        let result: PlayResult
        let typeName = (type?.text ?? "").lowercased()
        if typeName.contains("touchdown") { result = .touchdown }
        else if typeName.contains("interception") { result = .interception }
        else if typeName.contains("sack") { result = .sack }
        else if typeName.contains("fumble") { result = .fumble }
        else if typeName.contains("field goal") { result = .fieldGoal }
        else if typeName.contains("punt") { result = .punt }
        else if typeName.contains("rush") { result = .rush }
        else if typeName.contains("pass") { result = .pass }
        else if typeName.contains("kickoff") { result = .kickoff }
        else if typeName.contains("penalty") { result = .penalty }
        else { result = .other }

        return PlayLog(
            id: id,
            gameId: gameId,
            sequence: sequence,
            quarter: period?.number ?? 0,
            gameClock: clock?.displayValue ?? "",
            teamId: team?.abbreviation,
            down: down,
            distance: distance,
            yardLine: yardLine.map { "\($0)" },
            description: text ?? "",
            yardsGained: statYardage ?? 0,
            result: result,
            scoringPlay: scoringPlay ?? false,
            bigPlay: (statYardage ?? 0) >= 20,
            timestamp: Date()
        )
    }
}

private struct Period: Decodable { let number: Int? }
private struct Clock: Decodable { let displayValue: String? }
private struct PlayType: Decodable { let text: String? }

private struct ScoringPlay: Decodable {
    let id: String?
    let text: String?
}
