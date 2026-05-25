//
//  RASData.swift
//  Redzone Tracker
//
//  Relative Athletic Score (RAS) data — Combine measurements + composite scores.
//  Loaded from ras-latest.json published by the data-pipeline.
//

import Foundation

struct RASEntry: Codable, Hashable {
    let playerName: String
    let position: String
    let height: Double?              // inches
    let weight: Double?              // pounds
    let fortyYard: Double?           // seconds
    let verticalJump: Double?        // inches
    let broadJump: Double?           // inches
    let benchPress: Int?             // reps @ 225
    let threeConeShuttle: Double?
    let shortShuttle: Double?
    let rasOverall: Double?          // 0..10
    let rasSize: Double?
    let rasSpeed: Double?
    let rasExplosion: Double?
    let rasAgility: Double?
    let rasStrength: Double?
    let college: String?
    let draftYear: Int?
    let sourceURL: String

    /// Returns a 0..1 normalized value for the overall RAS score (where 10 is elite).
    var overallNormalized: Double {
        guard let r = rasOverall else { return 0 }
        return max(0, min(1, r / 10.0))
    }

    /// Returns a grade label based on RAS overall (Kent Lee Platte's tiers).
    var gradeLabel: String {
        guard let r = rasOverall else { return "—" }
        switch r {
        case 9.5...: return "ELITE"
        case 8.5..<9.5: return "GREAT"
        case 7.0..<8.5: return "GOOD"
        case 5.0..<7.0: return "OKAY"
        case 3.0..<5.0: return "POOR"
        default: return "BAD"
        }
    }

    var heightDisplay: String {
        guard let h = height else { return "—" }
        let feet = Int(h) / 12
        let inches = Int(h) % 12
        return "\(feet)'\(inches)\""
    }
}

struct RASEnvelope: Codable {
    let version: Int
    let generatedAt: String
    let count: Int
    let players: [String: RASEntry]

    enum CodingKeys: String, CodingKey {
        case version
        case generatedAt = "generated_at"
        case count
        case players
    }
}

extension RASEntry {
    static let mockMahomes = RASEntry(
        playerName: "Patrick Mahomes",
        position: "QB",
        height: 75.0,
        weight: 230.0,
        fortyYard: 4.80,
        verticalJump: 30.0,
        broadJump: 113.0,
        benchPress: nil,
        threeConeShuttle: 6.88,
        shortShuttle: 4.08,
        rasOverall: 7.74,
        rasSize: 9.05,
        rasSpeed: 6.96,
        rasExplosion: 5.76,
        rasAgility: 8.69,
        rasStrength: nil,
        college: "Texas Tech",
        draftYear: 2017,
        sourceURL: "https://ras.football/ras-card/?first=Patrick&last=Mahomes"
    )
}
