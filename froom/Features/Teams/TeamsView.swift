//
//  TeamsView.swift
//  f/Room
//
//  32-team list → Team detail with 4 sub-tabs (Roster / Players / Coaches / Cap).
//

import SwiftUI

// MARK: - Top-level: 32-team list

struct TeamsView: View {
    @State private var selectedConference: String = "All"
    @State private var league = LeagueClient.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredTeams) { team in
                            NavigationLink(value: team) {
                                TeamRow(team: team)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable { await league.loadTeams(force: true) }
            }
            .task { await league.loadTeams() }
            .background(FRTheme.Color.bg1)
            .navigationDestination(for: Team.self) { team in
                TeamDetailView(team: team)
            }
            .navigationDestination(for: Coach.self) { coach in
                CoachDetailView(coach: coach)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                RZTLogo(style: .inline, size: .header, showsSubtitle: false)
                Spacer()
                FRIconButton(systemName: "magnifyingglass") { }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FRChip("All", isActive: selectedConference == "All") { selectedConference = "All" }
                    FRChip("AFC", isActive: selectedConference == "AFC") { selectedConference = "AFC" }
                    FRChip("NFC", isActive: selectedConference == "NFC") { selectedConference = "NFC" }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 10)
        }
        .background(FRTheme.Color.bg1)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private var filteredTeams: [Team] {
        if selectedConference == "All" { return league.teams }
        return league.teams.filter { $0.conference == selectedConference }
    }
}

// MARK: - Team row (used in the list)

struct TeamRow: View {
    let team: Team

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [hex(team.primaryColorHex), hex(team.primaryColorHex).opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                Text(team.id)
                    .font(FRTheme.Font.bebas(size: 20))
                    .foregroundColor(.white)
                    .tracking(1)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(team.nickname.uppercased())
                    .font(FRTheme.Font.bebas(size: 18))
                    .tracking(2)
                    .foregroundColor(FRTheme.Color.text0)
                Text("\(team.conference) \(team.division) · \(team.record)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(FRTheme.Color.text2)
        }
        .padding(12)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Shared helper
func hex(_ h: String) -> Color {
    var s = h
    if s.hasPrefix("#") { s.removeFirst() }
    var rgb: UInt64 = 0
    Scanner(string: s).scanHexInt64(&rgb)
    let r = Double((rgb & 0xFF0000) >> 16) / 255
    let g = Double((rgb & 0x00FF00) >> 8) / 255
    let b = Double(rgb & 0x0000FF) / 255
    return Color(red: r, green: g, blue: b)
}

// MARK: - Team Detail with 4 sub-tabs

struct TeamDetailView: View {
    let team: Team
    @State private var section: TeamSection = .roster

    enum TeamSection: String, CaseIterable {
        case roster = "Roster"
        case players = "Players"
        case coaches = "Coaches"
        case cap = "Cap"
    }

    var body: some View {
        VStack(spacing: 0) {
            heroPanel
            subTabBar
            switch section {
            case .roster:
                TeamRosterView(team: team)
            case .players:
                TeamPlayersView(team: team)
            case .coaches:
                TeamCoachesView(team: team)
            case .cap:
                TeamCapView(team: team)
            }
        }
        .background(FRTheme.Color.bg1)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(team.city.uppercased())
                    .font(FRTheme.Font.bebas(size: 18))
                    .tracking(3)
                    .foregroundColor(FRTheme.Color.text0)
            }
        }
    }

    private var heroPanel: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(
                    colors: [hex(team.primaryColorHex), hex(team.primaryColorHex).opacity(0.6)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 56, height: 56)
                .overlay(Text(team.id).font(FRTheme.Font.bebas(size: 22)).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 4) {
                Text(team.nickname.uppercased())
                    .font(FRTheme.Font.bebas(size: 28))
                    .tracking(3)
                    .foregroundColor(FRTheme.Color.text0)
                Text("\(team.record) · \(team.conference) \(team.division)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text1)
            }
            Spacer()
        }
        .padding(18)
        .background(FRTheme.Color.bg2)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private var subTabBar: some View {
        HStack(spacing: 0) {
            ForEach(TeamSection.allCases, id: \.self) { s in
                Button(action: { section = s }) {
                    Text(s.rawValue.uppercased())
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(section == s ? FRTheme.Color.text0 : FRTheme.Color.text2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(section == s ? FRTheme.Color.rust : .clear)
                                .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .background(FRTheme.Color.bg1)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }
}

// MARK: - Sub: Roster (depth chart)

struct TeamRosterView: View {
    let team: Team
    @State private var sideFilter: SideFilter = .offense
    @State private var league = LeagueClient.shared

    enum SideFilter: String, CaseIterable {
        case offense = "Offense"
        case defense = "Defense"
        case specialTeams = "Special Teams"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SideFilter.allCases, id: \.self) { side in
                        FRChip(side.rawValue, isActive: sideFilter == side) { sideFilter = side }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 10)

            ScrollView {
                let roster = league.roster(for: team.id)
                if roster.isEmpty {
                    VStack(spacing: 10) {
                        ProgressView().tint(FRTheme.Color.rust)
                        Text("ロスターを読み込み中…")
                            .font(.system(size: 12))
                            .foregroundColor(FRTheme.Color.text2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(positionsForSide, id: \.self) { pos in
                            let group = roster.filter { $0.position == pos }
                            if !group.isEmpty {
                                positionGroup(pos: pos, players: group)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .task { await league.loadRoster(teamAbbrev: team.id) }
            .refreshable { await league.loadRoster(teamAbbrev: team.id, force: true) }
        }
    }

    private var positionsForSide: [String] {
        switch sideFilter {
        case .offense: return ["QB", "RB", "FB", "WR", "TE", "LT", "LG", "C", "RG", "RT", "OL", "OT", "G", "T"]
        case .defense: return ["DE", "DT", "NT", "DL", "OLB", "ILB", "MLB", "LB", "CB", "S", "FS", "SS", "DB"]
        case .specialTeams: return ["K", "P", "LS", "PK"]
        }
    }

    private func positionGroup(pos: String, players: [Player]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(pos)
                .font(FRTheme.Font.bebas(size: 16))
                .tracking(2)
                .foregroundColor(FRTheme.Color.bronze)
            VStack(spacing: 6) {
                ForEach(Array(players.enumerated()), id: \.element.id) { (idx, p) in
                    rosterCard(rank: idx + 1, player: p)
                }
            }
        }
    }

    private func rosterCard(rank: Int, player p: Player) -> some View {
        HStack(spacing: 10) {
            Text("#\(rank)").font(.system(size: 10, weight: .heavy)).tracking(1)
                .foregroundColor(rank == 1 ? FRTheme.Color.rustBright : FRTheme.Color.text2)
                .frame(width: 26, alignment: .leading)
            Text("\(p.jerseyNumber > 0 ? "#\(String(p.jerseyNumber)) " : "")\(p.firstName) \(p.lastName)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(FRTheme.Color.text0)
            Spacer()
            Text("\(p.height) · \(String(p.weight)) LB · \(String(p.yearsInLeague)) YR")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(FRTheme.Color.text2)
            if rank == 1 {
                Text("STARTER")
                    .font(.system(size: 8, weight: .heavy)).tracking(1)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(FRTheme.Color.rust).clipShape(Capsule())
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(rank == 1 ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Sub: Players list

struct TeamPlayersView: View {
    let team: Team
    @State private var league = LeagueClient.shared

    private var players: [Player] {
        league.roster(for: team.id)
            .sorted { positionRank($0.position) < positionRank($1.position) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(players) { player in
                    NavigationLink(value: playerDetail(from: player)) {
                        playerRow(player)
                    }
                    .buttonStyle(.plain)
                }
                if players.isEmpty {
                    VStack(spacing: 10) {
                        ProgressView().tint(FRTheme.Color.rust)
                        Text("選手データを読み込み中…")
                            .font(.system(size: 12))
                            .foregroundColor(FRTheme.Color.text2)
                    }
                    .padding(40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .task { await league.loadRoster(teamAbbrev: team.id) }
        .refreshable { await league.loadRoster(teamAbbrev: team.id, force: true) }
        .navigationDestination(for: PlayerDetail.self) { detail in
            PlayerDetailView(detail: detail)
        }
    }

    /// Order players by a sensible depth-chart-ish position grouping.
    private func positionRank(_ pos: String) -> Int {
        let order = ["QB","RB","FB","WR","TE","LT","LG","C","RG","RT","OL",
                     "DE","DT","NT","DL","OLB","ILB","MLB","LB",
                     "CB","S","FS","SS","DB","K","P","LS"]
        return order.firstIndex(of: pos) ?? 99
    }

    /// Lightweight converter (inlined here to avoid cross-file extension visibility issues
    /// when the conversion helper hasn't been added to the Xcode target yet).
    private func playerDetail(from p: Player) -> PlayerDetail {
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
        let signed = max(2020, Calendar.current.component(.year, from: Date()) - 2)

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
                signedYear: signed,
                endYear: signed + p.contractYears,
                avgPerYearUSD: p.contractTotal / Double(max(1, p.contractYears)),
                capHitCurrentYear: nil,
                voidYears: nil
            ),
            teamHistory: [
                TeamStint(
                    id: UUID(),
                    teamId: p.teamId,
                    startYear: max(2015, Calendar.current.component(.year, from: Date()) - p.yearsInLeague),
                    endYear: nil,
                    endReason: nil,
                    acquisitionType: .draft
                )
            ],
            careerStats: nil,
            externalIds: ExternalIds(espnId: nil, pfrId: nil, nflId: nil),
            lastSyncedAt: Date()
        )
    }

    private func playerRow(_ p: Player) -> some View {
        HStack(spacing: 12) {
            Text("#\(p.jerseyNumber)")
                .font(FRTheme.Font.bebas(size: 22))
                .foregroundColor(FRTheme.Color.bronze)
                .frame(width: 50)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(p.firstName) \(p.lastName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FRTheme.Color.text0)
                Text("\(p.position) · \(p.height) · \(p.weight) LB · \(p.yearsInLeague) YR")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
            }
            Spacer()
            if p.isStarter {
                Text("STARTER")
                    .font(.system(size: 9, weight: .heavy)).tracking(1)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(FRTheme.Color.rust)
                    .clipShape(Capsule())
            }
            if let _ = p.injuryStatus {
                Text("IR")
                    .font(.system(size: 9, weight: .heavy)).tracking(1)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(FRTheme.Color.bad)
                    .clipShape(Capsule())
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(FRTheme.Color.text2)
        }
        .padding(12)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Sub: Coaches list

struct TeamCoachesView: View {
    let team: Team

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(teamCoaches) { coach in
                    NavigationLink(value: coach) {
                        coachRow(coach)
                    }
                    .buttonStyle(.plain)
                }
                if teamCoaches.isEmpty {
                    Text("コーチデータを読み込み中…")
                        .font(.system(size: 12))
                        .foregroundColor(FRTheme.Color.text2)
                        .padding(40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var teamCoaches: [Coach] {
        MockData.coaches.filter { $0.teamId == team.id }
    }

    private func coachRow(_ c: Coach) -> some View {
        HStack(spacing: 12) {
            Text(c.role.rawValue)
                .font(FRTheme.Font.bebas(size: 16))
                .tracking(2)
                .foregroundColor(FRTheme.Color.bronze)
                .frame(width: 50, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(c.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FRTheme.Color.text0)
                if let scheme = c.scheme {
                    Text(scheme.uppercased())
                        .font(.system(size: 9, weight: .heavy)).tracking(1)
                        .foregroundColor(FRTheme.Color.rustBright)
                }
                if let yr = c.yearsSince {
                    Text("Since \(String(yr))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(FRTheme.Color.text2)
        }
        .padding(12)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Sub: Cap (re-uses CapClient inside team scope)

struct TeamCapView: View {
    let team: Team
    @State private var capClient = CapClient()
    @State private var includesDeadMoney = true

    var body: some View {
        if let summary = capClient.summary(for: team.id) {
            ScrollView {
                VStack(spacing: 14) {
                    capSummaryPanel(summary)
                    filterRow
                    rosterList(summary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .refreshable { await capClient.refresh() }
            .task { await capClient.refresh() }
        } else {
            VStack(spacing: 10) {
                ProgressView().tint(FRTheme.Color.rust)
                Text("キャップデータを読み込み中…")
                    .font(.system(size: 12))
                    .foregroundColor(FRTheme.Color.text2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task { await capClient.refresh() }
        }
    }

    // The cap summary + roster UI mirrors CapTabView but scoped to this team.

    private func capSummaryPanel(_ s: TeamCapSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(String(s.season)) SALARY CAP")
                    .font(.system(size: 10, weight: .heavy)).tracking(2)
                    .foregroundColor(FRTheme.Color.bronze)
                Spacer()
                Text("Updated \(s.updatedAt.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("CAP SPENT").font(.system(size: 9, weight: .heavy)).tracking(2)
                        .foregroundColor(FRTheme.Color.text2)
                    Spacer()
                    Text(formatMillions(s.totalCapSpent)).font(.system(size: 11, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text0)
                    Text("/ \(formatMillions(s.salaryCap))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text2)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(FRTheme.Color.bg3).frame(height: 8)
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(LinearGradient(colors: [FRTheme.Color.rust, FRTheme.Color.bronze],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * activePct(s), height: 8)
                            Rectangle()
                                .fill(FRTheme.Color.bad)
                                .frame(width: geo.size.width * deadPct(s), height: 8)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(height: 8)
            }

            HStack(spacing: 0) {
                statTile("Cap Space", value: formatMillions(s.capSpace),
                          accent: s.capSpace < 5 ? FRTheme.Color.bad : FRTheme.Color.good)
                Divider().background(FRTheme.Color.line)
                statTile("Dead Cap", value: formatMillions(s.deadCap),
                          accent: s.deadCap > 20 ? FRTheme.Color.bad : FRTheme.Color.text1)
                Divider().background(FRTheme.Color.line)
                statTile("Contracts", value: "\(s.activeContracts)", accent: FRTheme.Color.text0)
            }
            .background(FRTheme.Color.bg3)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(14)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func activePct(_ s: TeamCapSummary) -> Double {
        guard s.salaryCap > 0 else { return 0 }
        return max(0, min(1, (s.totalCapSpent - s.deadCap) / s.salaryCap))
    }
    private func deadPct(_ s: TeamCapSummary) -> Double {
        guard s.salaryCap > 0 else { return 0 }
        return max(0, min(1, s.deadCap / s.salaryCap))
    }

    private func statTile(_ label: String, value: String, accent: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(FRTheme.Font.bebas(size: 16))
                .foregroundColor(accent)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold)).tracking(1)
                .foregroundColor(FRTheme.Color.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var filterRow: some View {
        HStack {
            Text("ROSTER")
                .font(.system(size: 11, weight: .heavy)).tracking(3)
                .foregroundColor(FRTheme.Color.text0)
            Spacer()
            Toggle(isOn: $includesDeadMoney) {
                Text("DEAD MONEY")
                    .font(.system(size: 10, weight: .semibold)).tracking(1)
                    .foregroundColor(FRTheme.Color.text1)
            }
            .toggleStyle(SwitchToggleStyle(tint: FRTheme.Color.bad))
            .scaleEffect(0.85)
        }
    }

    private func rosterList(_ s: TeamCapSummary) -> some View {
        let players = s.topCapHits.filter { includesDeadMoney ? true : !$0.isDeadMoney }
        return VStack(spacing: 4) {
            ForEach(Array(players.enumerated()), id: \.element.id) { (idx, p) in
                playerRow(rank: idx + 1, player: p, salaryCap: s.salaryCap)
            }
        }
    }

    private func playerRow(rank: Int, player: PlayerCapHit, salaryCap: Double) -> some View {
        let tierColor = colorForTier(player.tier)
        let pct = salaryCap > 0 ? player.capHit / salaryCap : 0

        return HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(FRTheme.Color.text2)
                .frame(width: 28, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.playerName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(player.isDeadMoney ? FRTheme.Color.text2 : FRTheme.Color.text0)
                    Text(player.position)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text2)
                    if player.isDeadMoney {
                        Text("DEAD")
                            .font(.system(size: 9, weight: .heavy)).tracking(1)
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(FRTheme.Color.bad)
                            .clipShape(Capsule())
                    } else if player.isTopHeavy {
                        Text("TOP-5")
                            .font(.system(size: 9, weight: .heavy)).tracking(1)
                            .foregroundColor(Color(red: 0.1, green: 0.07, blue: 0))
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(FRTheme.Color.bronze)
                            .clipShape(Capsule())
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(FRTheme.Color.bg3).frame(height: 3)
                        Rectangle().fill(tierColor).frame(width: max(2, geo.size.width * pct), height: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .frame(height: 3)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatMillions(player.capHit))
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundColor(player.isDeadMoney ? FRTheme.Color.bad : tierColor)
                Text(String(format: "%.1f%% cap", pct * 100))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(player.isDeadMoney
                    ? AnyShapeStyle(FRTheme.Color.bad.opacity(0.08))
                    : AnyShapeStyle(FRTheme.Color.bg2))
        .overlay(alignment: .leading) {
            Rectangle().fill(tierColor).frame(width: 3)
        }
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func colorForTier(_ tier: CapTier) -> Color {
        switch tier {
        case .megaContract: return Color(red: 0.96, green: 0.42, blue: 0.15)
        case .topPaid: return FRTheme.Color.bronze
        case .midTier: return FRTheme.Color.rust
        case .baseline: return FRTheme.Color.text2
        case .deadMoney: return FRTheme.Color.bad
        }
    }

    private func formatMillions(_ value: Double) -> String {
        if value >= 1 {
            return String(format: "$%.1fM", value)
        }
        return String(format: "$%.0fK", value * 1000)
    }
}

#if DEBUG
#Preview {
    TeamsView().preferredColorScheme(.dark)
}
#endif
