//
//  Models.swift
//  f/Room
//
//  Core domain models for news, teams, players, coaches, games, plays, notes.
//

import Foundation

// MARK: - News / Intel

enum NewsKind: String, Codable, CaseIterable {
    case signing, trade, injury, presser, rumor, other

    var displayName: String {
        switch self {
        case .signing: return "Signing"
        case .trade: return "Trade"
        case .injury: return "Injury"
        case .presser: return "Presser"
        case .rumor: return "Rumor"
        case .other: return "News"
        }
    }
}

struct NewsItem: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: NewsKind
    let title: String           // original (English)
    let titleJA: String?        // optional Japanese translation
    let excerpt: String
    let excerptJA: String?
    let sources: [String]       // e.g. ["NFL.com", "@RapSheet"]
    let reliability: Double     // 0...1
    let teamAbbrev: String?     // e.g. "KC"
    let playerName: String?     // related player
    let coachName: String?      // related coach
    let publishedAt: Date
    let url: URL?
}

// MARK: - Team

struct Team: Identifiable, Codable, Hashable {
    let id: String              // team abbreviation as ID, e.g. "KC"
    let city: String
    let nickname: String
    let conference: String      // "AFC" / "NFC"
    let division: String        // "West" / "East" / "North" / "South"
    let primaryColorHex: String
    let secondaryColorHex: String
    let record: String          // e.g. "11-3"

    var fullName: String { "\(city) \(nickname)" }
}

// MARK: - Player

struct Player: Identifiable, Codable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let position: String        // QB / RB / WR / ...
    let jerseyNumber: Int
    let teamId: String          // Team.id
    let height: String
    let weight: Int
    let yearsInLeague: Int
    let collegeName: String?
    let contractYears: Int
    let contractTotal: Double   // millions
    let contractGuaranteed: Double
    let isStarter: Bool
    let injuryStatus: InjuryStatus?

    // Draft info (optional; populated from the nflverse roster feed).
    // 0 / nil means undrafted or unknown.
    var draftYear: Int? = nil
    var draftRound: Int? = nil
    var draftPick: Int? = nil
    var draftClub: String? = nil

    /// Human-readable draft summary, e.g. "2017 · Rd 1 · Pick 10 · KC".
    /// Returns "Undrafted" when we have a year but no pick, or nil when unknown.
    var draftSummary: String? {
        // If we have nothing at all, return nil so the UI can hide the row.
        let hasAny = (draftYear ?? 0) > 0 || (draftPick ?? 0) > 0 || (draftClub?.isEmpty == false)
        guard hasAny else { return nil }
        if (draftPick ?? 0) <= 0 && (draftClub?.isEmpty ?? true) {
            // Year known but no pick/club -> treat as undrafted free agent.
            if let y = draftYear, y > 0 { return "Undrafted (\(y))" }
            return "Undrafted"
        }
        var parts: [String] = []
        if let y = draftYear, y > 0 { parts.append(String(y)) }
        if let r = draftRound, r > 0 { parts.append("Rd \(r)") }
        if let p = draftPick, p > 0 { parts.append("Pick \(p)") }
        if let c = draftClub, !c.isEmpty { parts.append(c) }
        return parts.joined(separator: " · ")
    }
}

enum InjuryStatus: String, Codable {
    case questionable, doubtful, out, ir, pup
}

// MARK: - Coach

enum CoachRole: String, Codable, CaseIterable {
    case headCoach = "HC"
    case offensiveCoordinator = "OC"
    case defensiveCoordinator = "DC"
    case positionCoach
    case other
}

struct Coach: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let role: CoachRole
    let teamId: String?
    let scheme: String?         // "Wide Zone" / "WCO" / "Cover 3 Match" etc
    let mentorIds: [UUID]       // people who taught them
    let peerIds: [UUID]         // colleagues (worked together as assistants)
    let discipleIds: [UUID]     // people they taught
    let bio: String
    let yearsSince: Int?        // year they started in HC/OC/DC
}

struct CoachComment: Identifiable, Codable, Hashable {
    let id: UUID
    let coachId: UUID
    let body: String
    let tags: [String]
    let createdAt: Date
    let isPinned: Bool
}

// MARK: - Game

struct Game: Identifiable, Codable, Hashable {
    let id: UUID
    let week: Int
    let season: Int
    let date: Date
    let awayTeamId: String
    let homeTeamId: String
    let awayScore: Int
    let homeScore: Int
    let isFinal: Bool
    let overtime: Bool
    let lineScore: LineScore
    let teamStats: TeamStatsPair
    let driveChart: [Drive]
    let playerStats: PlayerStatsBundle
    let playByPlay: [Play]

    var winnerId: String? {
        guard isFinal else { return nil }
        if homeScore > awayScore { return homeTeamId }
        if awayScore > homeScore { return awayTeamId }
        return nil
    }
}

struct LineScore: Codable, Hashable {
    let away: [Int]    // e.g. [7, 10, 0, 11, 3] (Q1, Q2, Q3, Q4, OT)
    let home: [Int]
}

struct TeamStatsPair: Codable, Hashable {
    let away: TeamStats
    let home: TeamStats
}

struct TeamStats: Codable, Hashable {
    let totalYards: Int
    let passingYards: Int
    let rushingYards: Int
    let thirdDown: String     // "7/13"
    let fourthDown: String?
    let timeOfPossession: String  // "31:22"
    let turnovers: Int
    let penalties: Int
    let firstDowns: Int
}

struct Drive: Identifiable, Codable, Hashable {
    let id: UUID
    let quarter: Int            // 1..5 (OT=5)
    let teamId: String
    let plays: Int
    let yards: Int
    let timeOfDriveSeconds: Int
    let summary: String
    let result: DriveResult
}

enum DriveResult: String, Codable {
    case touchdown = "TD"
    case fieldGoal = "FG"
    case punt = "PUNT"
    case turnover = "TO"
    case interception = "INT"
    case fumble = "FUM"
    case downs = "DOWNS"
    case missedFG = "MISSED FG"
    case endOfHalf = "EOH"
    case endOfGame = "EOG"
}

struct PlayerStatsBundle: Codable, Hashable {
    let passing: [PassingStat]
    let rushing: [RushingStat]
    let receiving: [ReceivingStat]
    let defense: [DefenseStat]
}

struct PassingStat: Identifiable, Codable, Hashable {
    let id: UUID
    let playerName: String
    let teamId: String
    let completions: Int
    let attempts: Int
    let yards: Int
    let touchdowns: Int
    let interceptions: Int
    let rating: Double
}

struct RushingStat: Identifiable, Codable, Hashable {
    let id: UUID
    let playerName: String
    let teamId: String
    let carries: Int
    let yards: Int
    let touchdowns: Int
    let longest: Int
    var average: Double { carries > 0 ? Double(yards) / Double(carries) : 0 }
}

struct ReceivingStat: Identifiable, Codable, Hashable {
    let id: UUID
    let playerName: String
    let teamId: String
    let receptions: Int
    let targets: Int
    let yards: Int
    let touchdowns: Int
    var average: Double { receptions > 0 ? Double(yards) / Double(receptions) : 0 }
}

struct DefenseStat: Identifiable, Codable, Hashable {
    let id: UUID
    let playerName: String
    let teamId: String
    let tackles: Int
    let sacks: Double
    let tacklesForLoss: Int
    let passesDefended: Int
    let interceptions: Int
}

// MARK: - Play (one row in PLAYS tab)

struct Play: Identifiable, Codable, Hashable {
    let id: UUID
    let gameId: UUID
    let quarter: Int
    let gameClock: String      // "8:42"
    let down: Int?             // 1..4
    let distance: Int?
    let yardLine: String       // "BUF 32"
    let teamId: String         // offense
    let description: String
    let yardsGained: Int
    let isBigPlay: Bool
    let isTouchdown: Bool
    let isTurnover: Bool

    /// Returns the IDs of canvas notes associated with this play.
    let canvasNoteIds: [UUID]
}

// MARK: - Canvas Note (handwritten scouting page)

struct CanvasNote: Identifiable, Codable, Hashable {
    let id: UUID
    let gameId: UUID
    let playId: UUID?
    let pageIndex: Int
    let strokeData: Data?      // PencilKit PKDrawing as Data
    let memoData: Data?        // PencilKit PKDrawing for the memo area (separate layer)
    let tags: [String]
    let formationLabel: String?
    let resultYards: Int?
    let resultLabel: String?
    let perspective: Perspective
    let createdAt: Date
    let updatedAt: Date
}

enum Perspective: String, Codable {
    case offense, defense, neutral
}
