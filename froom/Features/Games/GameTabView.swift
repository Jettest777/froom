//
//  GameTabView.swift
//  f/Room
//
//  Top-level Game tab: season + week picker, live games at top, schedule grid.
//

import SwiftUI

struct GameTabView: View {
    @State private var season: Int = Calendar.current.component(.year, from: Date())
    @State private var seasonType: SeasonType = .regular
    @State private var week: Int = 1
    @State private var games: [ScheduledGame] = []
    @State private var isLoading: Bool = false
    @State private var lastError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                seasonBar
                weekBar
                ScrollView {
                    if isLoading && games.isEmpty {
                        ProgressView()
                            .tint(FRTheme.Color.rust)
                            .padding(.vertical, 40)
                    }
                    LazyVStack(spacing: 12) {
                        if !liveGames.isEmpty {
                            sectionHeader("LIVE NOW", color: FRTheme.Color.rustBright)
                            ForEach(liveGames) { game in
                                NavigationLink(value: game) {
                                    GameCard(game: game, isLive: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if !upcomingGames.isEmpty {
                            sectionHeader("UPCOMING", color: FRTheme.Color.bronze)
                            ForEach(upcomingGames) { game in
                                NavigationLink(value: game) {
                                    GameCard(game: game, isLive: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if !completedGames.isEmpty {
                            sectionHeader("FINAL", color: FRTheme.Color.text2)
                            ForEach(completedGames) { game in
                                NavigationLink(value: game) {
                                    GameCard(game: game, isLive: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if let error = lastError {
                            Text("⚠️ \(error)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(FRTheme.Color.text2)
                                .padding(.top, 20)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable { await reload() }
            }
            .background(FRTheme.Color.bg1)
            .navigationDestination(for: ScheduledGame.self) { game in
                LiveGameDetailView(scheduled: game)
            }
        }
        .task { await reload() }
        .onChange(of: season) { _, _ in Task { await reload() } }
        .onChange(of: seasonType) { _, _ in Task { await reload() } }
        .onChange(of: week) { _, _ in Task { await reload() } }
    }

    // MARK: - Sections

    private var liveGames: [ScheduledGame] { games.filter { $0.status.isInProgress } }
    private var upcomingGames: [ScheduledGame] { games.filter { $0.status == .scheduled }.sorted { $0.kickoff < $1.kickoff } }
    private var completedGames: [ScheduledGame] { games.filter { $0.status == .finalReg || $0.status == .finalOT } }

    private func sectionHeader(_ label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .heavy)).tracking(3)
                .foregroundColor(color)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Header / bars

    private var header: some View {
        HStack {
            RZTLogo(style: .inline, size: .header, showsSubtitle: false)
            Spacer()
            FRIconButton(systemName: "magnifyingglass") { }
            FRIconButton(systemName: "arrow.clockwise") {
                Task { await reload() }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private var seasonBar: some View {
        HStack(spacing: 12) {
            // Season picker
            Menu {
                ForEach((2020...2030), id: \.self) { yr in
                    Button(String(yr)) { season = yr }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(String(season)).font(FRTheme.Font.bebas(size: 20)).foregroundColor(FRTheme.Color.text0)
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold)).foregroundColor(FRTheme.Color.text2)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(FRTheme.Color.bg2)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FRTheme.Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Season type segmented
            HStack(spacing: 0) {
                ForEach(SeasonType.allCases, id: \.self) { t in
                    Button(action: { seasonType = t; week = 1 }) {
                        Text(t.displayName.uppercased())
                            .font(.system(size: 10, weight: .semibold)).tracking(2)
                            .foregroundColor(seasonType == t ? .white : FRTheme.Color.text2)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(seasonType == t ? FRTheme.Color.rust : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(FRTheme.Color.bg2)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private var weekBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(weeksForSeasonType, id: \.self) { w in
                    Button(action: { week = w }) {
                        Text(weekLabel(w))
                            .font(.system(size: 11, weight: .semibold)).tracking(2)
                            .foregroundColor(week == w ? .white : FRTheme.Color.text1)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(week == w ? FRTheme.Color.rust : FRTheme.Color.bg2)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(week == w ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }

    private var weeksForSeasonType: [Int] {
        switch seasonType {
        case .preseason: return Array(1...3)
        case .regular: return Array(1...18)
        case .playoffs: return Array(1...4)
        }
    }

    private func weekLabel(_ w: Int) -> String {
        if seasonType == .playoffs {
            switch w {
            case 1: return "WC"
            case 2: return "DIV"
            case 3: return "CONF"
            case 4: return "SB"
            default: return "—"
            }
        }
        return "WK \(w)"
    }

    // MARK: - Data

    @MainActor
    private func reload() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        let typeCode: Int
        switch seasonType {
        case .preseason: typeCode = 1
        case .regular: typeCode = 2
        case .playoffs: typeCode = 3
        }
        do {
            let result = try await GameLiveService.shared.fetchScoreboard(season: season, week: week, seasonType: typeCode)
            self.games = result
        } catch {
            self.lastError = "\(error)"
            self.games = []
        }
    }
}

// MARK: - Game Card

struct GameCard: View {
    let game: ScheduledGame
    let isLive: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(game.weekLabel)
                        .font(.system(size: 10, weight: .heavy)).tracking(2)
                        .foregroundColor(FRTheme.Color.bronze)
                    if let bcast = game.broadcast {
                        Text(bcast)
                            .font(.system(size: 9, weight: .semibold)).tracking(1)
                            .foregroundColor(FRTheme.Color.text2)
                    }
                    Spacer()
                    statusPill
                }
                HStack(spacing: 14) {
                    teamRow(game.awayTeamId, score: game.awayScore, isWinner: isWinner(away: true))
                    Text("@")
                        .font(.system(size: 10, weight: .heavy)).tracking(1)
                        .foregroundColor(FRTheme.Color.text2)
                    teamRow(game.homeTeamId, score: game.homeScore, isWinner: isWinner(away: false))
                }
                HStack {
                    Text(game.kickoff.formatted(.dateTime.month().day().hour().minute()))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text2)
                    if let venue = game.venue {
                        Text("· \(venue)")
                            .font(.system(size: 10))
                            .foregroundColor(FRTheme.Color.text2)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(FRTheme.Color.text2)
        }
        .padding(14)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(isLive ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: isLive ? 1.5 : 1))
        .overlay(alignment: .leading) {
            if isLive {
                Rectangle().fill(FRTheme.Color.rust).frame(width: 3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func teamRow(_ abbrev: String, score: Int?, isWinner: Bool) -> some View {
        HStack(spacing: 10) {
            Text(abbrev)
                .font(FRTheme.Font.bebas(size: 18)).tracking(2)
                .foregroundColor(isWinner ? FRTheme.Color.bronze : FRTheme.Color.text0)
            if let s = score {
                Text("\(s)")
                    .font(FRTheme.Font.bebas(size: 22))
                    .foregroundColor(isWinner ? FRTheme.Color.bronze : FRTheme.Color.text0)
            }
        }
    }

    private func isWinner(away: Bool) -> Bool {
        guard game.status == .finalReg || game.status == .finalOT,
              let a = game.awayScore, let h = game.homeScore else { return false }
        return away ? a > h : h > a
    }

    private var statusPill: some View {
        HStack(spacing: 4) {
            if game.status.isInProgress {
                Circle().fill(FRTheme.Color.rustBright)
                    .frame(width: 6, height: 6)
            }
            Text(game.status.displayLabel)
                .font(.system(size: 9, weight: .heavy)).tracking(1.5)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8).padding(.vertical, 2)
        .background(statusBg)
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch game.status {
        case .live, .halftime, .overtime: return .white
        case .finalReg, .finalOT: return FRTheme.Color.text1
        default: return FRTheme.Color.text2
        }
    }
    private var statusBg: Color {
        switch game.status {
        case .live, .halftime, .overtime: return FRTheme.Color.rust
        case .finalReg, .finalOT: return FRTheme.Color.bg3
        default: return Color.clear
        }
    }
}

#if DEBUG
#Preview {
    GameTabView()
        .preferredColorScheme(.dark)
}
#endif
