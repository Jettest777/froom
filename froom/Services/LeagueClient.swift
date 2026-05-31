//
//  LeagueClient.swift
//  f/Room
//
//  Live league data (all 32 teams, full rosters, schedule) from ESPN's free,
//  public (undocumented) NFL endpoints. No API key required.
//
//  Design:
//    - Single shared @Observable client the whole app can read.
//    - On first use it loads MockData instantly (so the UI is never empty),
//      then refreshes from ESPN in the background and replaces the data.
//    - Any network/parse failure leaves the previous data in place and records
//      an error string, so the app always degrades gracefully to mocks.
//
//  Endpoints used (all free, no auth):
//    Teams:    https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams
//    Roster:   https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/{abbr}/roster
//    Schedule: https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard
//

import Foundation

@Observable
@MainActor
final class LeagueClient {

    static let shared = LeagueClient()

    // MARK: - Published state

    private(set) var teams: [Team] = MockData.teams
    /// Rosters keyed by team abbreviation (e.g. "KC"). Filled lazily per team.
    private(set) var rostersByTeam: [String: [Player]] = [:]
    private(set) var teamsLoaded = false
    private(set) var isLoadingTeams = false
    private(set) var lastError: String?

    private let base = "https://site.api.espn.com/apis/site/v2/sports/football/nfl"
    private let session: URLSession
    private let decoder: JSONDecoder

    // Published, fact-based roster feed (nflverse) produced by GitHub Actions.
    private static let rosterFeedURL = URL(string:
        "https://raw.githubusercontent.com/Jettest777/froom/main/data-pipeline/output/rosters-latest.json")!
    /// Cached nflverse rosters keyed by team. Loaded once, used for all teams.
    private var nflverseRosters: [String: [Player]]?
    private var nflverseTried = false

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Teams (all 32)

    /// Loads the full 32-team list from ESPN. Falls back to MockData on failure.
    func loadTeams(force: Bool = false) async {
        if teamsLoaded && !force { return }
        if isLoadingTeams { return }
        isLoadingTeams = true
        defer { isLoadingTeams = false }

        guard let url = URL(string: "\(base)/teams") else { return }
        do {
            let data = try await fetch(url)
            let decoded = try decoder.decode(ESPNTeamsResponse.self, from: data)
            let mapped = decoded.sports
                .first?.leagues
                .first?.teams
                .map { $0.team.toDomain() } ?? []
            if !mapped.isEmpty {
                // Sort by conference then division then city for a stable list.
                self.teams = mapped.sorted {
                    if $0.conference != $1.conference { return $0.conference < $1.conference }
                    if $0.division != $1.division { return $0.division < $1.division }
                    return $0.city < $1.city
                }
                self.teamsLoaded = true
                self.lastError = nil
            }
        } catch {
            self.lastError = "teams: \(error.localizedDescription)"
            // keep existing (mock) teams
        }
    }

    // MARK: - Roster for one team

    /// Loads the roster for a team. Source priority:
    ///   1. nflverse published feed (authoritative, fact-based) — preferred
    ///   2. ESPN live roster endpoint
    ///   3. MockData (offline fallback)
    func loadRoster(teamAbbrev abbr: String, force: Bool = false) async {
        if rostersByTeam[abbr] != nil && !force { return }

        // 1. Try the published nflverse feed (loaded once, covers all teams).
        await loadNFLVerseRostersIfNeeded(force: force)
        if let fromVerse = nflverseRosters?[abbr], !fromVerse.isEmpty {
            rostersByTeam[abbr] = fromVerse
            return
        }

        // 2. Fall back to ESPN live roster for this team.
        guard let url = URL(string: "\(base)/teams/\(abbr.lowercased())/roster") else {
            rostersByTeam[abbr] = mockRoster(for: abbr)
            return
        }
        do {
            let data = try await fetch(url)
            let decoded = try decoder.decode(ESPNRosterResponse.self, from: data)
            let players = decoded.athletes
                .flatMap { $0.items }
                .map { $0.toPlayer(teamId: abbr) }
                .filter { !$0.firstName.isEmpty || !$0.lastName.isEmpty }
            rostersByTeam[abbr] = players.isEmpty ? mockRoster(for: abbr) : players
        } catch {
            self.lastError = "roster \(abbr): \(error.localizedDescription)"
            if rostersByTeam[abbr] == nil {
                rostersByTeam[abbr] = mockRoster(for: abbr)
            }
        }
    }

    /// Downloads and caches the whole-league nflverse roster feed once.
    private func loadNFLVerseRostersIfNeeded(force: Bool) async {
        if nflverseTried && !force { return }
        nflverseTried = true
        do {
            let data = try await fetch(Self.rosterFeedURL)
            let feed = try decoder.decode(RosterFeed.self, from: data)
            var byTeam: [String: [Player]] = [:]
            for (team, players) in feed.teams {
                byTeam[team] = players.map { $0.toPlayer(teamId: team) }
            }
            if !byTeam.isEmpty { nflverseRosters = byTeam }
        } catch {
            // Feed not published yet or unreachable — silently fall through to ESPN.
            self.lastError = "nflverse rosters: \(error.localizedDescription)"
        }
    }

    /// Convenience accessor used by views.
    func roster(for abbr: String) -> [Player] {
        rostersByTeam[abbr] ?? mockRoster(for: abbr)
    }

    private func mockRoster(for abbr: String) -> [Player] {
        MockData.players.filter { $0.teamId == abbr }
    }

    // MARK: - Networking

    private func fetch(_ url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.timeoutInterval = 12
        req.cachePolicy = .reloadRevalidatingCacheData
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw LeagueError.badStatus
        }
        return data
    }

    enum LeagueError: Error { case badStatus }
}

// MARK: - ESPN Teams DTOs

private struct ESPNTeamsResponse: Decodable {
    let sports: [Sport]
    struct Sport: Decodable { let leagues: [League] }
    struct League: Decodable { let teams: [TeamWrapper] }
    struct TeamWrapper: Decodable { let team: ESPNTeam }
}

private struct ESPNTeam: Decodable {
    let abbreviation: String?
    let location: String?
    let name: String?
    let nickname: String?
    let color: String?
    let alternateColor: String?
    let record: ESPNRecord?

    struct ESPNRecord: Decodable {
        let items: [Item]?
        struct Item: Decodable { let summary: String? }
    }

    func toDomain() -> Team {
        let abbr = (abbreviation ?? "—").uppercased()
        let (conf, div) = Self.conferenceDivision(for: abbr)
        let rec = record?.items?.first?.summary ?? "0-0"
        let primary = color.map { "#\($0)" } ?? "#444444"
        let secondary = alternateColor.map { "#\($0)" } ?? "#888888"
        return Team(
            id: abbr,
            city: location ?? "",
            nickname: name ?? nickname ?? abbr,
            conference: conf,
            division: div,
            primaryColorHex: primary,
            secondaryColorHex: secondary,
            record: rec
        )
    }

    /// ESPN's teams endpoint doesn't include conference/division inline, so we
    /// map it from a static table (these don't change between seasons).
    static func conferenceDivision(for abbr: String) -> (String, String) {
        return divisionTable[abbr] ?? ("NFL", "")
    }

    static let divisionTable: [String: (String, String)] = [
        "BUF": ("AFC","East"), "MIA": ("AFC","East"), "NE": ("AFC","East"), "NYJ": ("AFC","East"),
        "BAL": ("AFC","North"), "CIN": ("AFC","North"), "CLE": ("AFC","North"), "PIT": ("AFC","North"),
        "HOU": ("AFC","South"), "IND": ("AFC","South"), "JAX": ("AFC","South"), "TEN": ("AFC","South"),
        "DEN": ("AFC","West"), "KC": ("AFC","West"), "LV": ("AFC","West"), "LAC": ("AFC","West"),
        "DAL": ("NFC","East"), "NYG": ("NFC","East"), "PHI": ("NFC","East"), "WSH": ("NFC","East"),
        "CHI": ("NFC","North"), "DET": ("NFC","North"), "GB": ("NFC","North"), "MIN": ("NFC","North"),
        "ATL": ("NFC","South"), "CAR": ("NFC","South"), "NO": ("NFC","South"), "TB": ("NFC","South"),
        "ARI": ("NFC","West"), "LAR": ("NFC","West"), "SF": ("NFC","West"), "SEA": ("NFC","West")
    ]
}

// MARK: - ESPN Roster DTOs

private struct ESPNRosterResponse: Decodable {
    let athletes: [Group]
    struct Group: Decodable {
        let position: String?
        let items: [ESPNAthlete]
    }
}

private struct ESPNAthlete: Decodable {
    let id: String?
    let firstName: String?
    let lastName: String?
    let displayName: String?
    let jersey: String?
    let weight: Double?
    let displayHeight: String?
    let height: Double?
    let position: Position?
    let experience: Experience?
    let college: College?
    let injuries: [Injury]?
    let starter: Bool?

    struct Position: Decodable { let abbreviation: String? }
    struct Experience: Decodable { let years: Int? }
    struct College: Decodable { let name: String? }
    struct Injury: Decodable { let status: String? }

    func toPlayer(teamId: String) -> Player {
        let first = firstName ?? (displayName?.components(separatedBy: " ").first ?? "")
        let last = lastName ?? (displayName?.components(separatedBy: " ").dropFirst().joined(separator: " ") ?? "")
        let heightStr: String = {
            if let h = displayHeight, !h.isEmpty { return h }
            if let inches = height, inches > 0 {
                let ft = Int(inches) / 12
                let inch = Int(inches) % 12
                return "\(ft)'\(inch)\""
            }
            return "—"
        }()
        return Player(
            id: UUID(),
            firstName: first,
            lastName: last,
            position: position?.abbreviation ?? "—",
            jerseyNumber: Int(jersey ?? "") ?? 0,
            teamId: teamId,
            height: heightStr,
            weight: Int(weight ?? 0),
            yearsInLeague: experience?.years ?? 0,
            collegeName: college?.name,
            contractYears: 0,
            contractTotal: 0,
            contractGuaranteed: 0,
            isStarter: starter ?? false,
            injuryStatus: Self.mapInjury(injuries?.first?.status)
        )
    }

    static func mapInjury(_ s: String?) -> InjuryStatus? {
        guard let s = s?.lowercased() else { return nil }
        if s.contains("out") { return .out }
        if s.contains("doubt") { return .doubtful }
        if s.contains("question") { return .questionable }
        if s.contains("ir") { return .ir }
        return nil
    }
}

// MARK: - nflverse roster feed DTOs (rosters-latest.json)

private struct RosterFeed: Decodable {
    let version: Int
    let season: Int?
    let source: String?
    let teams: [String: [RosterPlayer]]
}

private struct RosterPlayer: Decodable {
    let first: String?
    let last: String?
    let pos: String?
    let jersey: Int?
    let height: String?
    let weight: Int?
    let college: String?
    let years: Int?
    let status: String?
    let espn_id: String?
    let depth: String?

    func toPlayer(teamId: String) -> Player {
        // nflverse heights are like "6-2"; convert to 6'2" for display.
        let heightStr: String = {
            guard let h = height, !h.isEmpty else { return "—" }
            if h.contains("-") {
                let parts = h.split(separator: "-")
                if parts.count == 2 { return "\(parts[0])'\(parts[1])\"" }
            }
            return h
        }()
        let s = (status ?? "").uppercased()
        let injury: InjuryStatus? = {
            if s.contains("IR") || s.contains("RES") { return .ir }
            if s.contains("PUP") { return .pup }
            return nil
        }()
        // nflverse doesn't expose reliable depth order, so we don't guess at
        // "starter" here (over-claiming starters was a source of inaccuracy).
        let isStarter = false

        return Player(
            id: UUID(),
            firstName: first ?? "",
            lastName: last ?? "",
            position: (pos ?? "—"),
            jerseyNumber: jersey ?? 0,
            teamId: teamId,
            height: heightStr,
            weight: weight ?? 0,
            yearsInLeague: years ?? 0,
            collegeName: (college?.isEmpty == false) ? college : nil,
            contractYears: 0,
            contractTotal: 0,
            contractGuaranteed: 0,
            isStarter: isStarter,
            injuryStatus: injury
        )
    }
}
