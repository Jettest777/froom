//
//  CapData.swift
//  f/Room
//
//  Salary-cap models. Built around Spotrac's "Cap Hit / Dead Cap / Cap Savings" view.
//

import Foundation

struct TeamCapSummary: Identifiable, Codable, Hashable {
    var id: String { teamId }   // e.g. "KC"
    let teamId: String
    let season: Int

    let salaryCap: Double        // league cap, e.g. 255.4 ($M)
    let totalCapSpent: Double    // sum of active player cap hits
    let activeContracts: Int
    let deadCap: Double          // dead money
    let capSpace: Double         // remaining

    let topCapHits: [PlayerCapHit]    // sorted desc, includes both active + dead
    let updatedAt: Date

    var capSpentPct: Double {
        guard salaryCap > 0 else { return 0 }
        return totalCapSpent / salaryCap
    }
}

struct PlayerCapHit: Identifiable, Codable, Hashable {
    var id: String { "\(teamId)-\(playerName)-\(season)" }
    let teamId: String
    let season: Int
    let playerName: String
    let position: String
    let jerseyNumber: Int?

    let capHit: Double           // $M
    let baseSalary: Double?
    let signingBonusProration: Double?
    let restructureBonus: Double?
    let roster: PlayerRosterState

    let isDeadMoney: Bool        // counted but not on roster
    let isTopHeavy: Bool         // top 5 cap hit on team

    /// Color tier based on cap hit (display-only)
    var tier: CapTier {
        if isDeadMoney { return .deadMoney }
        switch capHit {
        case 30...: return .megaContract
        case 15..<30: return .topPaid
        case 5..<15: return .midTier
        default: return .baseline
        }
    }
}

enum CapTier: String, Codable {
    case megaContract   // $30M+
    case topPaid        // $15-30M
    case midTier        // $5-15M
    case baseline       // <$5M
    case deadMoney
}

enum PlayerRosterState: String, Codable {
    case active
    case injuredReserve = "IR"
    case practiceSquad = "PS"
    case nonFootballInjury = "NFI"
    case released
    case retired
    case traded
}
