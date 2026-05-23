//
//  LiveGame.swift
//  f/Room
//
//  Models for scheduled / in-progress / completed games and the play-by-play stream.
//

import Foundation

// MARK: - Schedule

enum SeasonType: String, Codable, CaseIterable {
    case preseason
    case regular
    case playoffs

    var displayName: String {
        switch self {
        case .preseason: return "Preseason"
        case .regular: return "Regular Season"
        case .playoffs: return "Playoffs"
        }
    }
}

enum PlayoffRound: String, Codable, CaseIterable {
    case wildcard = "Wild Card"
    case divisional = "Divisional"
    case conference = "Conference"
    case superBowl = "Super Bowl"

    var shortName: String {
        switch self {
        case .wildcard: return "WC"
        case .divisional: return "DIV"
        case .conference: return "CONF"
        case .superBowl: return "SB"
        }
    }
}

/// Lightweight schedule entry. Loaded from ESPN's scoreboard endpoint.
struct ScheduledGame: Identifiable, Codable, Hashable {
    let id: String              // ESPN game id
    let season: Int
    let seasonType: SeasonType
    let week: Int
    let playoffRound: PlayoffRound?
    let kickoff: Date
    let awayTeamId: String      // abbrev, e.g. "KC"
    let homeTeamId: String
    let status: GameStatus
    var awayScore: Int?
    var homeScore: Int?
    let venue: String?
    let broadcast: String?      // "SNF", "MNF", "CBS" etc

    /// For Playoff games, returns "WC / DIV / CONF / SB". For regular season, "WK 14".
    var weekLabel: String {
        if let round = playoffRound { return round.rawValue }
        return "WK \(week)"
    }
}

enum GameStatus: String, Codable {
    case scheduled
    case live
    case halftime
    case overtime
    case finalReg = "final"
    case finalOT = "final_ot"
    case postponed
    case cancelled

    var displayLabel: String {
        switch self {
        case .scheduled: return "SCHEDULED"
        case .live: return "LIVE"
        case .halftime: return "HALFTIME"
        case .overtime: return "OT"
        case .finalReg: return "FINAL"
        case .finalOT: return "FINAL · OT"
        case .postponed: return "POSTPONED"
        case .cancelled: return "CANCELLED"
        }
    }

    var isInProgress: Bool {
        self == .live || self == .halftime || self == .overtime
    }
}

// MARK: - Live state (current moment-in-game info)

struct LiveGameState: Codable, Hashable {
    let gameId: String
    let updatedAt: Date

    // Score
    let awayScore: Int
    let homeScore: Int

    // Quarter & clock
    let quarter: Int           // 1..4, 5=OT
    let gameClock: String      // "8:42"
    let status: GameStatus

    // Field position / down & distance
    let possession: String?    // team abbrev with the ball
    let down: Int?             // 1..4
    let distance: Int?         // yards to go
    let yardLine: String?      // "BUF 32"
    let isRedZone: Bool

    // Most recent play summary
    let lastPlayDescription: String?
    let lastPlayYards: Int?

    // Drive context
    let driveNumber: Int?
    let drivePlays: Int?
    let driveYards: Int?
    let driveTimeOfPossession: String?
}

// MARK: - Play-by-play log entries

struct PlayLog: Identifiable, Codable, Hashable {
    let id: String              // ESPN play id
    let gameId: String
    let sequence: Int           // chronological ordering
    let quarter: Int
    let gameClock: String
    let teamId: String?         // offense
    let down: Int?
    let distance: Int?
    let yardLine: String?
    let description: String     // raw play description from ESPN
    let yardsGained: Int
    let result: PlayResult
    let scoringPlay: Bool
    let bigPlay: Bool           // 20+ yards or sack/turnover
    let timestamp: Date
}

enum PlayResult: String, Codable {
    case rush
    case pass
    case incomplete
    case sack
    case interception
    case fumble
    case punt
    case fieldGoal
    case touchdown
    case extraPoint
    case twoPointConversion
    case kickoff
    case penalty
    case timeout
    case endOfQuarter
    case endOfGame
    case other

    var label: String {
        switch self {
        case .rush: return "RUSH"
        case .pass: return "PASS"
        case .incomplete: return "INC"
        case .sack: return "SACK"
        case .interception: return "INT"
        case .fumble: return "FUM"
        case .punt: return "PUNT"
        case .fieldGoal: return "FG"
        case .touchdown: return "TD"
        case .extraPoint: return "XP"
        case .twoPointConversion: return "2PT"
        case .kickoff: return "KO"
        case .penalty: return "PEN"
        case .timeout: return "TO"
        case .endOfQuarter: return "EOQ"
        case .endOfGame: return "EOG"
        case .other: return "—"
        }
    }
}

// MARK: - Aggregate (loaded together when opening Game detail)

/// Aggregated live snapshot used by the Game detail view.
struct GameSnapshot: Hashable {
    let scheduled: ScheduledGame
    var state: LiveGameState?
    var plays: [PlayLog]
    let lastSyncedAt: Date

    /// Find scout notes (SwiftData) related to a specific play.
    /// Resolved at the view layer because SwiftData needs ModelContext.
    var playIds: [String] { plays.map(\.id) }
}
