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
    /// Long-form analysis paragraphs (separated by \n\n). Optional for backwards compat.
    let bodyEN: String?
    let bodyJA: String?
    let topics: [DigestTopic]
    let watchTomorrowEN: String
    let watchTomorrowJA: String

    enum CodingKeys: String, CodingKey {
        case headlineEN = "headline_en"
        case headlineJA = "headline_ja"
        case leadEN = "lead_en"
        case leadJA = "lead_ja"
        case bodyEN = "body_en"
        case bodyJA = "body_ja"
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
        bodyEN: """
The Broncos' aggressive move signals an all-in push for 2026. By surrendering two first-round picks, Denver is betting that Stafford's veteran presence and proven playoff experience can vault them past Kansas City in the division — a bold wager given the Chiefs' continued dominance under Patrick Mahomes.

For the Rams, this is the long-anticipated reset. Sean McVay now has the draft capital to rebuild around a younger core, and the franchise's cap sheet finally has breathing room after years of "F them picks" mortgaging. Expect Los Angeles to be active in next year's draft and a stealth contender in 2027.

The ripple effects across the AFC West are immediate. The Raiders and Chargers, both retooling their QB rooms, now face a division where every game matters. Denver's defense, already strong, paired with Stafford's downfield arm could create matchup nightmares for everyone — including Kansas City.

In Kansas City, expect Andy Reid to keep his foot on the gas. The Chiefs' WR signing earlier this week (3yr/\\$42M) suggests they're not standing pat. Mahomes versus Stafford twice a year, with playoff implications hanging in the balance, is exactly what the league wanted.
""",
        bodyJA: """
ブロンコスの大胆な動きは、2026年シーズンへの「オールイン」を明確に示している。1巡目指名権を2つ手放してまでスタッフォードを獲得したのは、ベテランの経験とプレーオフでの実績がチーフス超えへの最短距離だと判断した賭けだ。マホームズ率いるKCの牙城は依然高いが、勝負には出る価値があった。

ラムズにとっては、待ち望んだリセットの瞬間だ。マクヴェイは若手中心の再構築に必要なドラフト資本を取り戻し、長年抵当に入れていたキャップシートにもようやく余裕が生まれる。来年のドラフトでアグレッシブに動き、2027年にダークホースとして浮上する可能性は十分にある。

AFC西地区への波及効果は即座に表れる。レイダースもチャージャーズもQB陣を再編成中で、地区全試合が重みを増す。元々強力なデンバーのディフェンスと、スタッフォードのディープボール能力の組み合わせは、KCにとっても厄介な対戦カードになる。

カンザスシティ側もアクセルを緩める気配はない。今週成立した3年4,200万ドルのWR契約は、現状維持で満足しない意思表示だ。マホームズ対スタッフォードが年2回、しかもプレーオフを左右する展開——リーグが望んでいたシーズンが始まる。
""",
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
