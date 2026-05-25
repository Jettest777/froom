//
//  DailyDigest.swift
//  Redzone Tracker
//
//  AI-generated daily summary of NFL news. Generated 2x/day by Claude on GitHub Actions.
//

import Foundation

struct DailyDigest: Codable, Hashable {
    let headlineEN: String
    let headlineJA: String
    let leadEN: String
    let leadJA: String
    let topics: [DigestTopic]
    let watchTomorrowEN: String
    let watchTomorrowJA: String

    enum CodingKeys: String, CodingKey {
        case headlineEN = "headline_en"
        case headlineJA = "headline_ja"
        case leadEN = "lead_en"
        case leadJA = "lead_ja"
        case topics
        case watchTomorrowEN = "watch_tomorrow_en"
        case watchTomorrowJA = "watch_tomorrow_ja"
    }
}

struct DigestTopic: Codable, Hashable, Identifiable {
    var id: String { titleEN }
    let titleEN: String
    let titleJA: String
    let bodyEN: String
    let bodyJA: String
    let teamAbbrev: String?
    let importance: TopicImportance

    enum CodingKeys: String, CodingKey {
        case titleEN = "title_en"
        case titleJA = "title_ja"
        case bodyEN = "body_en"
        case bodyJA = "body_ja"
        case teamAbbrev = "team_abbrev"
        case importance
    }
}

enum TopicImportance: String, Codable {
    case high, medium, low
}

struct DigestEnvelope: Codable {
    let version: Int
    let generatedAt: String
    let timeOfDay: String
    let sourceItemCount: Int
    let rankedItemCount: Int
    let digest: DailyDigest

    enum CodingKeys: String, CodingKey {
        case version
        case generatedAt = "generated_at"
        case timeOfDay = "time_of_day"
        case sourceItemCount = "source_item_count"
        case rankedItemCount = "ranked_item_count"
        case digest
    }

    var generatedDate: Date {
        ISO8601DateFormatter().date(from: generatedAt) ?? Date()
    }
}

// MARK: - Mock for offline / preview

extension DailyDigest {
    static let mock = DailyDigest(
        headlineEN: "Stafford to Denver shakes the AFC West",
        headlineJA: "スタッフォードがデンバー入り、AFC西地区が激変",
        leadEN: "The Broncos sent two first-round picks to LA in exchange for Matthew Stafford, instantly reshaping the AFC West QB hierarchy.",
        leadJA: "ブロンコスが1巡指名権2つでスタッフォードを獲得。AFC西地区のQB勢力図が一夜にして塗り替えられた。",
        topics: [
            DigestTopic(
                titleEN: "Stafford trade reshapes AFC West",
                titleJA: "スタッフォード移籍がAFC西を再編",
                bodyEN: "Denver landed the veteran QB they needed. The Chiefs now face a more competitive division road.",
                bodyJA: "デンバーは念願のベテランQBを獲得。チーフスの地区制覇への道のりは厳しくなる。",
                teamAbbrev: "DEN",
                importance: .high
            ),
            DigestTopic(
                titleEN: "Chiefs lock in WR for 3 years",
                titleJA: "チーフスがWRと3年契約",
                bodyEN: "Kansas City's $42M deal with $24M guaranteed keeps Mahomes' depth chart elite through 2028.",
                bodyJA: "$42M総額・保証額$24Mで2028年まで主力WRを確保。マホームズの武器が増強される。",
                teamAbbrev: "KC",
                importance: .medium
            ),
            DigestTopic(
                titleEN: "Bills LB enters concussion protocol",
                titleJA: "ビルズLBが脳震盪プロトコル入り",
                bodyEN: "McDermott confirmed the news at the presser. Practice squad LB elevated for Sunday vs MIA.",
                bodyJA: "マクダーモットHCが会見で確認。MIA戦に向けPS所属LBが昇格。",
                teamAbbrev: "BUF",
                importance: .medium
            ),
        ],
        watchTomorrowEN: "Watch how the Chiefs respond in their next divisional matchup.",
        watchTomorrowJA: "次節の地区対決でチーフスがどう対応するか注目。"
    )
}
