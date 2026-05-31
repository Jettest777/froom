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
        height: 75.0, weight: 230.0,
        fortyYard: 4.80, verticalJump: 30.0, broadJump: 113.0,
        benchPress: nil, threeConeShuttle: 6.88, shortShuttle: 4.08,
        rasOverall: 7.74, rasSize: 9.05, rasSpeed: 6.96,
        rasExplosion: 5.76, rasAgility: 8.69, rasStrength: nil,
        college: "Texas Tech", draftYear: 2017,
        sourceURL: "https://ras.football/ras-card/?first=Patrick&last=Mahomes"
    )

    static let mockKelce = RASEntry(
        playerName: "Travis Kelce",
        position: "TE",
        height: 77.0, weight: 255.0,
        fortyYard: 4.61, verticalJump: 35.0, broadJump: 119.0,
        benchPress: nil, threeConeShuttle: 7.09, shortShuttle: 4.42,
        rasOverall: 9.81, rasSize: 9.34, rasSpeed: 9.55,
        rasExplosion: 9.62, rasAgility: 8.91, rasStrength: nil,
        college: "Cincinnati", draftYear: 2013,
        sourceURL: "https://ras.football/ras-card/?first=Travis&last=Kelce"
    )

    static let mockPacheco = RASEntry(
        playerName: "Isiah Pacheco",
        position: "RB",
        height: 70.0, weight: 216.0,
        fortyYard: 4.37, verticalJump: 33.5, broadJump: 121.0,
        benchPress: 21, threeConeShuttle: nil, shortShuttle: nil,
        rasOverall: 9.30, rasSize: 7.80, rasSpeed: 9.95,
        rasExplosion: 9.20, rasAgility: nil, rasStrength: 8.70,
        college: "Rutgers", draftYear: 2022,
        sourceURL: "https://ras.football/ras-card/?first=Isiah&last=Pacheco"
    )

    static let mockJones = RASEntry(
        playerName: "Chris Jones",
        position: "DT",
        height: 78.0, weight: 310.0,
        fortyYard: 5.07, verticalJump: 30.0, broadJump: 116.0,
        benchPress: 32, threeConeShuttle: 7.81, shortShuttle: 4.65,
        rasOverall: 9.27, rasSize: 9.86, rasSpeed: 9.13,
        rasExplosion: 8.31, rasAgility: 8.42, rasStrength: 8.95,
        college: "Mississippi State", draftYear: 2016,
        sourceURL: "https://ras.football/ras-card/?first=Chris&last=Jones"
    )

    static let mockRice = RASEntry(
        playerName: "Rashee Rice",
        position: "WR",
        height: 73.0, weight: 204.0,
        fortyYard: 4.51, verticalJump: 33.5, broadJump: 124.0,
        benchPress: 19, threeConeShuttle: nil, shortShuttle: nil,
        rasOverall: 9.04, rasSize: 8.74, rasSpeed: 8.78,
        rasExplosion: 8.85, rasAgility: nil, rasStrength: 9.55,
        college: "SMU", draftYear: 2023,
        sourceURL: "https://ras.football/ras-card/?first=Rashee&last=Rice"
    )

    static let mockAllen = RASEntry(
        playerName: "Josh Allen",
        position: "QB",
        height: 77.0, weight: 237.0,
        fortyYard: 4.75, verticalJump: 33.5, broadJump: 119.0,
        benchPress: nil, threeConeShuttle: 6.90, shortShuttle: 4.40,
        rasOverall: 9.93, rasSize: 9.95, rasSpeed: 9.78,
        rasExplosion: 9.59, rasAgility: 9.39, rasStrength: nil,
        college: "Wyoming", draftYear: 2018,
        sourceURL: "https://ras.football/ras-card/?first=Josh&last=Allen"
    )

    static let mockCook = RASEntry(
        playerName: "James Cook",
        position: "RB",
        height: 71.0, weight: 199.0,
        fortyYard: 4.42, verticalJump: 32.5, broadJump: 121.0,
        benchPress: nil, threeConeShuttle: nil, shortShuttle: nil,
        rasOverall: 8.32, rasSize: 5.93, rasSpeed: 9.69,
        rasExplosion: 8.65, rasAgility: nil, rasStrength: nil,
        college: "Georgia", draftYear: 2022,
        sourceURL: "https://ras.football/ras-card/?first=James&last=Cook"
    )

    static let mockMcCaffrey = RASEntry(
        playerName: "Christian McCaffrey",
        position: "RB",
        height: 71.0, weight: 202.0,
        fortyYard: 4.48, verticalJump: 37.5, broadJump: 121.0,
        benchPress: 10, threeConeShuttle: 6.57, shortShuttle: 4.22,
        rasOverall: 9.89, rasSize: 7.39, rasSpeed: 9.43,
        rasExplosion: 9.69, rasAgility: 9.94, rasStrength: 8.42,
        college: "Stanford", draftYear: 2017,
        sourceURL: "https://ras.football/ras-card/?first=Christian&last=McCaffrey"
    )

    static let mockPurdy = RASEntry(
        playerName: "Brock Purdy",
        position: "QB",
        height: 73.0, weight: 220.0,
        fortyYard: 4.84, verticalJump: 28.0, broadJump: 112.0,
        benchPress: nil, threeConeShuttle: nil, shortShuttle: nil,
        rasOverall: 4.46, rasSize: 4.43, rasSpeed: 5.96,
        rasExplosion: 3.34, rasAgility: nil, rasStrength: nil,
        college: "Iowa State", draftYear: 2022,
        sourceURL: "https://ras.football/ras-card/?first=Brock&last=Purdy"
    )

    static let mockPrescott = RASEntry(
        playerName: "Dak Prescott",
        position: "QB",
        height: 74.0, weight: 226.0,
        fortyYard: 4.79, verticalJump: 32.5, broadJump: 116.0,
        benchPress: nil, threeConeShuttle: 6.99, shortShuttle: 4.39,
        rasOverall: 8.94, rasSize: 8.07, rasSpeed: 8.07,
        rasExplosion: 8.91, rasAgility: 8.85, rasStrength: nil,
        college: "Mississippi State", draftYear: 2016,
        sourceURL: "https://ras.football/ras-card/?first=Dak&last=Prescott"
    )

    static let mockParsons = RASEntry(
        playerName: "Micah Parsons",
        position: "LB",
        height: 75.0, weight: 246.0,
        fortyYard: 4.36, verticalJump: 34.0, broadJump: 121.0,
        benchPress: 19, threeConeShuttle: nil, shortShuttle: nil,
        rasOverall: 9.98, rasSize: 9.06, rasSpeed: 9.99,
        rasExplosion: 9.51, rasAgility: nil, rasStrength: 9.55,
        college: "Penn State", draftYear: 2021,
        sourceURL: "https://ras.football/ras-card/?first=Micah&last=Parsons"
    )

    static let mockHurts = RASEntry(
        playerName: "Jalen Hurts",
        position: "QB",
        height: 73.0, weight: 222.0,
        fortyYard: 4.59, verticalJump: 35.0, broadJump: 119.0,
        benchPress: nil, threeConeShuttle: nil, shortShuttle: nil,
        rasOverall: 9.05, rasSize: 6.86, rasSpeed: 9.66,
        rasExplosion: 9.59, rasAgility: nil, rasStrength: nil,
        college: "Oklahoma", draftYear: 2020,
        sourceURL: "https://ras.football/ras-card/?first=Jalen&last=Hurts"
    )

    static let mockBarkley = RASEntry(
        playerName: "Saquon Barkley",
        position: "RB",
        height: 72.0, weight: 233.0,
        fortyYard: 4.40, verticalJump: 41.0, broadJump: 124.0,
        benchPress: 29, threeConeShuttle: nil, shortShuttle: nil,
        rasOverall: 9.99, rasSize: 9.34, rasSpeed: 9.91,
        rasExplosion: 9.99, rasAgility: nil, rasStrength: 9.93,
        college: "Penn State", draftYear: 2018,
        sourceURL: "https://ras.football/ras-card/?first=Saquon&last=Barkley"
    )

    static let mockLamar = RASEntry(
        playerName: "Lamar Jackson",
        position: "QB",
        height: 74.0, weight: 216.0,
        fortyYard: 4.34, verticalJump: nil, broadJump: nil,
        benchPress: nil, threeConeShuttle: nil, shortShuttle: nil,
        rasOverall: 6.71, rasSize: 5.96, rasSpeed: 9.93,
        rasExplosion: nil, rasAgility: nil, rasStrength: nil,
        college: "Louisville", draftYear: 2018,
        sourceURL: "https://ras.football/ras-card/?first=Lamar&last=Jackson"
    )

    /// Lookup table used by RASClient as offline fallback so the Athleticism tab
    /// always has something to render during development.
    static let allMocks: [String: RASEntry] = [
        "Patrick Mahomes": .mockMahomes,
        "Travis Kelce": .mockKelce,
        "Isiah Pacheco": .mockPacheco,
        "Chris Jones": .mockJones,
        "Rashee Rice": .mockRice,
        "Josh Allen": .mockAllen,
        "James Cook": .mockCook,
        "Christian McCaffrey": .mockMcCaffrey,
        "Brock Purdy": .mockPurdy,
        "Dak Prescott": .mockPrescott,
        "Micah Parsons": .mockParsons,
        "Jalen Hurts": .mockHurts,
        "Saquon Barkley": .mockBarkley,
        "Lamar Jackson": .mockLamar,
    ]
}
