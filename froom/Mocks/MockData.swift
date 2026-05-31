//
//  MockData.swift
//  f/Room
//
//  In-memory mock data for development and SwiftUI previews.
//  Replace with real data sources when the data pipeline is wired up.
//

import Foundation

enum MockData {

    // MARK: - Teams

    static let teams: [Team] = [
        Team(id: "KC",  city: "Kansas City",  nickname: "Chiefs",  conference: "AFC", division: "West",
             primaryColorHex: "#E31837", secondaryColorHex: "#FFB81C", record: "11-3"),
        Team(id: "BUF", city: "Buffalo",      nickname: "Bills",   conference: "AFC", division: "East",
             primaryColorHex: "#00338D", secondaryColorHex: "#C60C30", record: "10-4"),
        Team(id: "SF",  city: "San Francisco", nickname: "49ers",  conference: "NFC", division: "West",
             primaryColorHex: "#AA0000", secondaryColorHex: "#B3995D", record: "9-5"),
        Team(id: "DAL", city: "Dallas",       nickname: "Cowboys", conference: "NFC", division: "East",
             primaryColorHex: "#003594", secondaryColorHex: "#869397", record: "8-6"),
        Team(id: "PHI", city: "Philadelphia", nickname: "Eagles",  conference: "NFC", division: "East",
             primaryColorHex: "#004C54", secondaryColorHex: "#A5ACAF", record: "10-4"),
        Team(id: "BAL", city: "Baltimore",    nickname: "Ravens",  conference: "AFC", division: "North",
             primaryColorHex: "#241773", secondaryColorHex: "#9E7C0C", record: "9-5"),
    ]

    static func team(_ id: String) -> Team {
        teams.first(where: { $0.id == id }) ?? teams[0]
    }

    // MARK: - News

    static let news: [NewsItem] = [
        NewsItem(
            id: UUID(),
            kind: .trade,
            title: "QB TRADE: Stafford Headed to Denver for 2 Firsts",
            titleJA: "QBトレード: スタッフォード、1巡目指名権2つでデンバーへ",
            excerpt: "League sources confirm a blockbuster trade sending Matthew Stafford to the Broncos.",
            excerptJA: "リーグ筋が、スタッフォードをブロンコスへ送る大型トレードを確認。",
            sources: ["@AdamSchefter"],
            reliability: 0.96,
            teamAbbrev: "DEN",
            playerName: "Matthew Stafford",
            coachName: nil,
            publishedAt: Date().addingTimeInterval(-60 * 12),
            url: URL(string: "https://x.com/AdamSchefter")
        ),
        NewsItem(
            id: UUID(),
            kind: .signing,
            title: "Chiefs sign WR on 3-yr / $42M deal with $24M guaranteed",
            titleJA: "チーフス、WRと3年/$42M契約合意 — 保証額$24M",
            excerpt: "Travis Kelce's new running mate locked up through 2028. Deal includes void years to reduce 2026 cap hit by $4.5M.",
            excerptJA: "トラビス・ケルシーの新たな相棒が2028年まで確保。Void Yearsを含む構造で2026年のキャップヒットを$4.5M削減。",
            sources: ["NFL.com", "ESPN", "@RapSheet"],
            reliability: 0.94,
            teamAbbrev: "KC",
            playerName: nil,
            coachName: nil,
            publishedAt: Date().addingTimeInterval(-3600 * 2),
            url: nil
        ),
        NewsItem(
            id: UUID(),
            kind: .injury,
            title: "Bills LB enters concussion protocol, week-to-week",
            titleJA: "ビルズLB、脳震盪プロトコル入り — week-to-week",
            excerpt: "Coach McDermott confirmed at presser. Practice squad LB elevated for Sunday vs MIA.",
            excerptJA: "マクダーモットHCが会見で確認。日曜のMIA戦に向けプラクティスチームLBを昇格。",
            sources: ["Official Team", "BillsWire"],
            reliability: 0.98,
            teamAbbrev: "BUF",
            playerName: nil,
            coachName: "Sean McDermott",
            publishedAt: Date().addingTimeInterval(-3600 * 4),
            url: nil
        ),
        NewsItem(
            id: UUID(),
            kind: .presser,
            title: "Shanahan: \"We're going to lean on the run more in December\"",
            titleJA: "シャナハン: 「12月はランをもっと重視する」",
            excerpt: "Hints at heavier 12-personnel usage with both TEs healthy. McCaffrey snap count expected to increase.",
            excerptJA: "両TEが健康なら12人員構成の使用増を示唆。マッカフリーのスナップ数増加が見込まれる。",
            sources: ["SF Chronicle", "@MattMaiocco"],
            reliability: 0.78,
            teamAbbrev: "SF",
            playerName: "Christian McCaffrey",
            coachName: "Kyle Shanahan",
            publishedAt: Date().addingTimeInterval(-3600 * 6),
            url: nil
        ),
        NewsItem(
            id: UUID(),
            kind: .rumor,
            title: "Cowboys exploring veteran S addition before trade deadline",
            titleJA: "カウボーイズ、トレード期限前にベテランS獲得を模索",
            excerpt: "Multiple beat writers connect Dallas to two available safeties. No imminent move per league sources.",
            excerptJA: "複数のビート記者がダラスと2人のセーフティを結びつけ。リーグ筋によれば近日中の動きはなし。",
            sources: ["Multiple Beat Writers"],
            reliability: 0.62,
            teamAbbrev: "DAL",
            playerName: nil,
            coachName: nil,
            publishedAt: Date().addingTimeInterval(-3600 * 8),
            url: nil
        ),
    ]

    // MARK: - Coaches (Walsh tree sample)

    static let coaches: [Coach] = {
        let walshId = UUID()
        let mShanahanId = UUID()
        let kShanahanId = UUID()
        let mcvayId = UUID()
        let mcdanielId = UUID()
        let lafleurId = UUID()

        return [
            Coach(id: walshId, name: "Bill Walsh", role: .headCoach, teamId: nil,
                  scheme: "West Coast Offense", mentorIds: [], peerIds: [], discipleIds: [mShanahanId],
                  bio: "Founder of the West Coast Offense. 3× Super Bowl champion with SF.",
                  yearsSince: 1979),
            Coach(id: mShanahanId, name: "Mike Shanahan", role: .headCoach, teamId: "DEN",
                  scheme: "Wide Zone", mentorIds: [walshId], peerIds: [],
                  discipleIds: [kShanahanId, mcvayId, lafleurId],
                  bio: "Wide Zone pioneer. 2× Super Bowl champion with Denver.",
                  yearsSince: 1995),
            Coach(id: kShanahanId, name: "Kyle Shanahan", role: .headCoach, teamId: "SF",
                  scheme: "Wide Zone / YAC", mentorIds: [mShanahanId], peerIds: [mcvayId, lafleurId],
                  discipleIds: [mcdanielId],
                  bio: "Son of Mike. SF HC since 2017.",
                  yearsSince: 2017),
            Coach(id: mcvayId, name: "Sean McVay", role: .headCoach, teamId: "LAR",
                  scheme: "11 Personnel / Outside Zone", mentorIds: [], peerIds: [kShanahanId, lafleurId],
                  discipleIds: [],
                  bio: "LA Rams HC. Brought 11-personnel revolution to the NFL.",
                  yearsSince: 2017),
            Coach(id: lafleurId, name: "Matt LaFleur", role: .headCoach, teamId: "GB",
                  scheme: "PA Heavy / Wide Zone", mentorIds: [mShanahanId], peerIds: [kShanahanId, mcvayId],
                  discipleIds: [],
                  bio: "GB Packers HC. Spent time as OC under Kyle Shanahan in ATL.",
                  yearsSince: 2019),
            Coach(id: mcdanielId, name: "Mike McDaniel", role: .headCoach, teamId: "MIA",
                  scheme: "Wide Zone / Motion", mentorIds: [kShanahanId], peerIds: [],
                  discipleIds: [],
                  bio: "MIA HC. Former SF run-game coordinator under Kyle Shanahan.",
                  yearsSince: 2022),
        ]
    }()

    static let coachComments: [CoachComment] = [
        CoachComment(
            id: UUID(),
            coachId: coaches[2].id, // Kyle Shanahan
            body: "Wide Zoneの中で「ハーフバックモーション」を最近かなり使ってる。下半期は12 personnel偏重。",
            tags: ["SCHEME", "PA"],
            createdAt: Date().addingTimeInterval(-3600 * 24 * 7),
            isPinned: true
        ),
        CoachComment(
            id: UUID(),
            coachId: coaches[2].id,
            body: "McVayと比較してKyleの方が伏線回収を意識してる。McDanielはこれをさらに極端にした弟子。",
            tags: [],
            createdAt: Date().addingTimeInterval(-3600 * 24 * 14),
            isPinned: false
        ),
    ]

    // MARK: - Players (sample roster across multiple teams)

    static let players: [Player] = [
        // KC Chiefs
        Player(id: UUID(), firstName: "Patrick", lastName: "Mahomes", position: "QB", jerseyNumber: 15,
               teamId: "KC", height: "6'3\"", weight: 230, yearsInLeague: 8, collegeName: "Texas Tech",
               contractYears: 10, contractTotal: 450, contractGuaranteed: 141, isStarter: true, injuryStatus: nil),
        Player(id: UUID(), firstName: "Travis", lastName: "Kelce", position: "TE", jerseyNumber: 87,
               teamId: "KC", height: "6'5\"", weight: 250, yearsInLeague: 13, collegeName: "Cincinnati",
               contractYears: 2, contractTotal: 34, contractGuaranteed: 17, isStarter: true, injuryStatus: nil),
        Player(id: UUID(), firstName: "Isiah", lastName: "Pacheco", position: "RB", jerseyNumber: 10,
               teamId: "KC", height: "5'10\"", weight: 216, yearsInLeague: 4, collegeName: "Rutgers",
               contractYears: 4, contractTotal: 4, contractGuaranteed: 0.8, isStarter: true, injuryStatus: nil),
        Player(id: UUID(), firstName: "Chris", lastName: "Jones", position: "DT", jerseyNumber: 95,
               teamId: "KC", height: "6'6\"", weight: 310, yearsInLeague: 11, collegeName: "Mississippi State",
               contractYears: 5, contractTotal: 158, contractGuaranteed: 95, isStarter: true, injuryStatus: nil),
        Player(id: UUID(), firstName: "Rashee", lastName: "Rice", position: "WR", jerseyNumber: 4,
               teamId: "KC", height: "6'1\"", weight: 203, yearsInLeague: 3, collegeName: "SMU",
               contractYears: 4, contractTotal: 5, contractGuaranteed: 3, isStarter: true, injuryStatus: nil),

        // BUF Bills
        Player(id: UUID(), firstName: "Josh", lastName: "Allen", position: "QB", jerseyNumber: 17,
               teamId: "BUF", height: "6'5\"", weight: 237, yearsInLeague: 8, collegeName: "Wyoming",
               contractYears: 6, contractTotal: 250, contractGuaranteed: 150, isStarter: true, injuryStatus: nil),
        Player(id: UUID(), firstName: "James", lastName: "Cook", position: "RB", jerseyNumber: 28,
               teamId: "BUF", height: "5'11\"", weight: 199, yearsInLeague: 4, collegeName: "Georgia",
               contractYears: 4, contractTotal: 4, contractGuaranteed: 1, isStarter: true, injuryStatus: nil),

        // SF 49ers
        Player(id: UUID(), firstName: "Christian", lastName: "McCaffrey", position: "RB", jerseyNumber: 23,
               teamId: "SF", height: "5'11\"", weight: 210, yearsInLeague: 9, collegeName: "Stanford",
               contractYears: 2, contractTotal: 38, contractGuaranteed: 24, isStarter: true, injuryStatus: nil),
        Player(id: UUID(), firstName: "Brock", lastName: "Purdy", position: "QB", jerseyNumber: 13,
               teamId: "SF", height: "6'1\"", weight: 220, yearsInLeague: 4, collegeName: "Iowa State",
               contractYears: 5, contractTotal: 265, contractGuaranteed: 181, isStarter: true, injuryStatus: nil),

        // DAL Cowboys
        Player(id: UUID(), firstName: "Dak", lastName: "Prescott", position: "QB", jerseyNumber: 4,
               teamId: "DAL", height: "6'2\"", weight: 238, yearsInLeague: 10, collegeName: "Mississippi State",
               contractYears: 4, contractTotal: 240, contractGuaranteed: 231, isStarter: true, injuryStatus: nil),
        Player(id: UUID(), firstName: "Micah", lastName: "Parsons", position: "LB", jerseyNumber: 11,
               teamId: "DAL", height: "6'3\"", weight: 246, yearsInLeague: 5, collegeName: "Penn State",
               contractYears: 4, contractTotal: 188, contractGuaranteed: 120, isStarter: true, injuryStatus: nil),

        // PHI Eagles
        Player(id: UUID(), firstName: "Jalen", lastName: "Hurts", position: "QB", jerseyNumber: 1,
               teamId: "PHI", height: "6'1\"", weight: 223, yearsInLeague: 6, collegeName: "Oklahoma",
               contractYears: 5, contractTotal: 255, contractGuaranteed: 179, isStarter: true, injuryStatus: nil),
        Player(id: UUID(), firstName: "Saquon", lastName: "Barkley", position: "RB", jerseyNumber: 26,
               teamId: "PHI", height: "6'0\"", weight: 232, yearsInLeague: 8, collegeName: "Penn State",
               contractYears: 3, contractTotal: 37, contractGuaranteed: 26, isStarter: true, injuryStatus: nil),

        // BAL Ravens
        Player(id: UUID(), firstName: "Lamar", lastName: "Jackson", position: "QB", jerseyNumber: 8,
               teamId: "BAL", height: "6'2\"", weight: 212, yearsInLeague: 8, collegeName: "Louisville",
               contractYears: 5, contractTotal: 260, contractGuaranteed: 185, isStarter: true, injuryStatus: nil),
    ]

    // MARK: - Sample game

    static let sampleGame: Game = {
        let kcStats = TeamStats(totalYards: 438, passingYards: 312, rushingYards: 126,
                                 thirdDown: "7/13", fourthDown: "1/2",
                                 timeOfPossession: "31:22", turnovers: 0, penalties: 4, firstDowns: 24)
        let bufStats = TeamStats(totalYards: 392, passingYards: 288, rushingYards: 104,
                                 thirdDown: "5/12", fourthDown: "0/1",
                                 timeOfPossession: "28:38", turnovers: 2, penalties: 7, firstDowns: 21)

        let drives: [Drive] = [
            Drive(id: UUID(), quarter: 1, teamId: "KC", plays: 8, yards: 75, timeOfDriveSeconds: 252,
                  summary: "Mahomes 22-yd TD pass to Rice. Opening drive.", result: .touchdown),
            Drive(id: UUID(), quarter: 1, teamId: "BUF", plays: 11, yards: 60, timeOfDriveSeconds: 334,
                  summary: "Bass 38-yd FG.", result: .fieldGoal),
            Drive(id: UUID(), quarter: 2, teamId: "KC", plays: 3, yards: 5, timeOfDriveSeconds: 68,
                  summary: "3-and-out. Pacheco stuffed on 3rd & 2.", result: .punt),
            Drive(id: UUID(), quarter: 4, teamId: "BUF", plays: 6, yards: 24, timeOfDriveSeconds: 128,
                  summary: "Allen INT by McDuffie at the KC 38.", result: .interception),
        ]

        let plays: [Play] = [
            Play(id: UUID(), gameId: UUID(), quarter: 1, gameClock: "14:42",
                 down: 1, distance: 10, yardLine: "KC 25", teamId: "KC",
                 description: "Mahomes pass deep right to Rice for 22 yds.",
                 yardsGained: 22, isBigPlay: true, isTouchdown: false, isTurnover: false, canvasNoteIds: []),
            Play(id: UUID(), gameId: UUID(), quarter: 1, gameClock: "11:18",
                 down: 1, distance: 4, yardLine: "BUF 4", teamId: "KC",
                 description: "Mahomes pass short middle to Kelce for 4 yds, TOUCHDOWN.",
                 yardsGained: 4, isBigPlay: false, isTouchdown: true, isTurnover: false, canvasNoteIds: [UUID()]),
            Play(id: UUID(), gameId: UUID(), quarter: 3, gameClock: "08:42",
                 down: 2, distance: 7, yardLine: "BUF 32", teamId: "KC",
                 description: "PA / Trips Right. Mahomes to Worthy for 12 yds. 1st down.",
                 yardsGained: 12, isBigPlay: true, isTouchdown: false, isTurnover: false, canvasNoteIds: [UUID()]),
            Play(id: UUID(), gameId: UUID(), quarter: 4, gameClock: "02:07",
                 down: 3, distance: 8, yardLine: "KC 38", teamId: "BUF",
                 description: "Allen pass deep middle INTERCEPTED by McDuffie at KC 22.",
                 yardsGained: 0, isBigPlay: false, isTouchdown: false, isTurnover: true, canvasNoteIds: [UUID()]),
        ]

        let bundle = PlayerStatsBundle(
            passing: [
                PassingStat(id: UUID(), playerName: "P. Mahomes", teamId: "KC", completions: 28, attempts: 41,
                            yards: 312, touchdowns: 3, interceptions: 0, rating: 118.4),
                PassingStat(id: UUID(), playerName: "J. Allen", teamId: "BUF", completions: 24, attempts: 38,
                            yards: 288, touchdowns: 2, interceptions: 2, rating: 78.1),
            ],
            rushing: [
                RushingStat(id: UUID(), playerName: "I. Pacheco", teamId: "KC", carries: 18, yards: 87, touchdowns: 1, longest: 22),
                RushingStat(id: UUID(), playerName: "J. Cook", teamId: "BUF", carries: 14, yards: 71, touchdowns: 0, longest: 18),
                RushingStat(id: UUID(), playerName: "J. Allen", teamId: "BUF", carries: 6, yards: 33, touchdowns: 1, longest: 14),
            ],
            receiving: [
                ReceivingStat(id: UUID(), playerName: "T. Kelce", teamId: "KC", receptions: 9, targets: 11, yards: 102, touchdowns: 1),
                ReceivingStat(id: UUID(), playerName: "R. Rice", teamId: "KC", receptions: 7, targets: 10, yards: 98, touchdowns: 2),
                ReceivingStat(id: UUID(), playerName: "S. Diggs", teamId: "BUF", receptions: 8, targets: 13, yards: 112, touchdowns: 1),
            ],
            defense: [
                DefenseStat(id: UUID(), playerName: "C. Jones", teamId: "KC", tackles: 5, sacks: 2.0, tacklesForLoss: 3, passesDefended: 1, interceptions: 0),
                DefenseStat(id: UUID(), playerName: "T. McDuffie", teamId: "KC", tackles: 7, sacks: 0, tacklesForLoss: 0, passesDefended: 3, interceptions: 1),
                DefenseStat(id: UUID(), playerName: "M. Milano", teamId: "BUF", tackles: 11, sacks: 0.5, tacklesForLoss: 1, passesDefended: 2, interceptions: 0),
            ]
        )

        return Game(
            id: UUID(),
            week: 14,
            season: 2026,
            date: Date(timeIntervalSince1970: 1796563200),  // 2026-12-07
            awayTeamId: "KC",
            homeTeamId: "BUF",
            awayScore: 31,
            homeScore: 28,
            isFinal: true,
            overtime: true,
            lineScore: LineScore(away: [7, 10, 0, 11, 3], home: [3, 7, 14, 4, 0]),
            teamStats: TeamStatsPair(away: kcStats, home: bufStats),
            driveChart: drives,
            playerStats: bundle,
            playByPlay: plays
        )
    }()
}
