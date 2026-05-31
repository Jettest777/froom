//
//  PlayerDetail.swift
//  f/Room
//
//  Extended player profile schema beyond the lightweight `Player` model used in roster lists.
//  This is what surfaces on the player detail page.
//

import Foundation

struct PlayerDetail: Identifiable, Codable, Hashable {
    let id: UUID

    // MARK: - Identity & Position
    let firstName: String
    let lastName: String
    var fullName: String { "\(firstName) \(lastName)" }
    let position: String
    let jerseyNumber: Int
    let currentTeamId: String?

    // MARK: - Physical
    let heightInches: Int          // store as inches; render as 6'3"
    let weightPounds: Int
    let dateOfBirth: Date?
    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }

    // MARK: - Education
    let college: String?
    let highSchool: String?

    // MARK: - Draft
    let draft: Draft?

    // MARK: - Career
    let yearsInLeague: Int
    let isStarter: Bool
    let injuryStatus: InjuryStatus?

    // MARK: - Contract
    let contract: Contract?

    // MARK: - Team history (chronological, oldest first)
    let teamHistory: [TeamStint]

    // MARK: - Career totals (display only — varies by position)
    let careerStats: CareerStatLine?

    // MARK: - Sources & meta
    let externalIds: ExternalIds
    let lastSyncedAt: Date

    // MARK: - Helpers

    var heightDisplay: String {
        let feet = heightInches / 12
        let inches = heightInches % 12
        return "\(feet)'\(inches)\""
    }
}

// MARK: - Sub-models

struct Draft: Codable, Hashable {
    let year: Int
    let round: Int
    let pick: Int
    let overallPick: Int           // sometimes redundant with pick, but APIs return it separately
    let draftedByTeamId: String

    var displayLabel: String {
        "\(String(year)) · Rd \(round), Pick \(pick) (Overall \(overallPick))"
    }
}

struct Contract: Codable, Hashable {
    let years: Int
    let totalValueUSD: Double      // millions; e.g. 450.0 = $450M
    let guaranteedUSD: Double
    let signedYear: Int
    let endYear: Int
    let avgPerYearUSD: Double
    let capHitCurrentYear: Double?
    let voidYears: Int?

    var progress: Double {
        let total = Double(endYear - signedYear)
        guard total > 0 else { return 0 }
        let elapsed = Double(Calendar.current.component(.year, from: Date()) - signedYear)
        return max(0, min(1, elapsed / total))
    }

    var displayHeadline: String {
        "\(String(years))YR / $\(String(Int(totalValueUSD)))M"
    }
}

struct TeamStint: Identifiable, Codable, Hashable {
    let id: UUID
    let teamId: String
    let startYear: Int
    let endYear: Int?              // nil means current
    let endReason: EndReason?
    let acquisitionType: AcquisitionType?

    var isCurrent: Bool { endYear == nil }
    var displayYears: String {
        if let end = endYear { return "\(String(startYear))–\(String(end))" }
        return "\(String(startYear))–present"
    }
}

enum EndReason: String, Codable {
    case trade, release, freeAgent, retirement, waived, expiredContract, other
}

enum AcquisitionType: String, Codable {
    case draft, freeAgent, trade, waiverClaim, undraftedRookieFA, other
}

struct CareerStatLine: Codable, Hashable {
    // Generic; only some fields apply per position.
    let gamesPlayed: Int?
    let gamesStarted: Int?

    // QB
    let passYards: Int?
    let passTDs: Int?
    let interceptions: Int?
    let passerRating: Double?

    // RB / receiver
    let rushAttempts: Int?
    let rushYards: Int?
    let rushTDs: Int?
    let receptions: Int?
    let recYards: Int?
    let recTDs: Int?

    // Defense
    let totalTackles: Int?
    let sacks: Double?
    let defInterceptions: Int?
    let forcedFumbles: Int?
}

struct ExternalIds: Codable, Hashable {
    var espnId: String?
    var pfrId: String?            // Pro Football Reference identifier
    var nflId: String?
}

// MARK: - Converters

extension PlayerDetail {
    /// Build a lightweight PlayerDetail from the roster-level `Player` model.
    /// Used when navigating from team rosters to the detail page before the
    /// full ESPN-backed profile is loaded.
    static func from(player p: Player) -> PlayerDetail {
        // Parse "6'3\"" style height back to inches
        let inches: Int = {
            let cleaned = p.height.replacingOccurrences(of: "\"", with: "")
            let parts = cleaned.split(separator: "'")
            if parts.count == 2,
               let ft = Int(parts[0]),
               let inch = Int(parts[1]) {
                return ft * 12 + inch
            }
            return 72
        }()

        return PlayerDetail(
            id: p.id,
            firstName: p.firstName,
            lastName: p.lastName,
            position: p.position,
            jerseyNumber: p.jerseyNumber,
            currentTeamId: p.teamId,
            heightInches: inches,
            weightPounds: p.weight,
            dateOfBirth: nil,
            college: p.collegeName,
            highSchool: nil,
            draft: nil,
            yearsInLeague: p.yearsInLeague,
            isStarter: p.isStarter,
            injuryStatus: p.injuryStatus,
            contract: Contract(
                years: p.contractYears,
                totalValueUSD: p.contractTotal,
                guaranteedUSD: p.contractGuaranteed,
                signedYear: max(2020, Calendar.current.component(.year, from: Date()) - 2),
                endYear: max(2020, Calendar.current.component(.year, from: Date()) - 2) + p.contractYears,
                avgPerYearUSD: p.contractTotal / Double(max(1, p.contractYears)),
                capHitCurrentYear: nil,
                voidYears: nil
            ),
            teamHistory: [
                TeamStint(id: UUID(), teamId: p.teamId,
                          startYear: max(2015, Calendar.current.component(.year, from: Date()) - p.yearsInLeague),
                          endYear: nil, endReason: nil, acquisitionType: .draft)
            ],
            careerStats: nil,
            externalIds: ExternalIds(espnId: nil, pfrId: nil, nflId: nil),
            lastSyncedAt: Date()
        )
    }
}

// MARK: - Mock detail

extension PlayerDetail {
    static let mockMahomes: PlayerDetail = PlayerDetail(
        id: UUID(),
        firstName: "Patrick",
        lastName: "Mahomes",
        position: "QB",
        jerseyNumber: 15,
        currentTeamId: "KC",
        heightInches: 75,            // 6'3"
        weightPounds: 230,
        dateOfBirth: ISO8601DateFormatter().date(from: "1995-09-17T00:00:00Z"),
        college: "Texas Tech",
        highSchool: "Whitehouse HS (TX)",
        draft: Draft(year: 2017, round: 1, pick: 10, overallPick: 10, draftedByTeamId: "KC"),
        yearsInLeague: 8,
        isStarter: true,
        injuryStatus: nil,
        contract: Contract(
            years: 10,
            totalValueUSD: 450,
            guaranteedUSD: 141,
            signedYear: 2020,
            endYear: 2032,
            avgPerYearUSD: 45,
            capHitCurrentYear: 35.8,
            voidYears: nil
        ),
        teamHistory: [
            TeamStint(id: UUID(), teamId: "KC", startYear: 2017, endYear: nil,
                      endReason: nil, acquisitionType: .draft)
        ],
        careerStats: CareerStatLine(
            gamesPlayed: 110, gamesStarted: 105,
            passYards: 32450, passTDs: 260, interceptions: 65, passerRating: 102.6,
            rushAttempts: 420, rushYards: 1850, rushTDs: 18,
            receptions: nil, recYards: nil, recTDs: nil,
            totalTackles: nil, sacks: nil, defInterceptions: nil, forcedFumbles: nil
        ),
        externalIds: ExternalIds(espnId: "3139477", pfrId: "MahoPa00", nflId: nil),
        lastSyncedAt: Date()
    )
}
