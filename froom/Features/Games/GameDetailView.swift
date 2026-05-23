//
//  GameDetailView.swift
//  f/Room
//
//  Full box score: line score, team stats, drives, player stats, plays.
//

import SwiftUI

struct GameDetailView: View {
    let game: Game
    @State private var tab: Tab = .box

    enum Tab: String, CaseIterable { case box = "Box", drives = "Drives", players = "Players", plays = "Plays", notes = "Notes" }

    var body: some View {
        VStack(spacing: 0) {
            hero
            tabBar
            ScrollView {
                switch tab {
                case .box: boxTab
                case .drives: drivesTab
                case .players: playersTab
                case .plays: playsTab
                case .notes:
                    Text("Notes coming next.")
                        .foregroundColor(FRTheme.Color.text2)
                        .padding(24)
                }
            }
        }
        .background(FRTheme.Color.bg1)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("GAME").font(FRTheme.Font.bebas(size: 18)).tracking(3).foregroundColor(FRTheme.Color.text0)
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: CanvasContext(game: game, play: nil)) {
                    Image(systemName: "pencil.tip.crop.circle").foregroundColor(FRTheme.Color.text1)
                }
            }
        }
        .navigationDestination(for: CanvasContext.self) { ctx in
            CanvasView(context: ctx)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("WK \(game.week) · 2026.12.07")
                    .font(.system(size: 10, weight: .heavy)).tracking(2)
                    .foregroundColor(FRTheme.Color.text2)
                Spacer()
                Text(game.overtime ? "FINAL · OT" : "FINAL")
                    .font(.system(size: 10, weight: .heavy)).tracking(2)
                    .foregroundColor(FRTheme.Color.rustBright)
            }

            HStack {
                teamSide(team: MockData.team(game.awayTeamId), score: game.awayScore, isWin: game.awayScore > game.homeScore)
                VStack(spacing: 0) {
                    Text("\(game.awayScore)")
                        .font(FRTheme.Font.bebas(size: 44))
                        .foregroundColor(game.awayScore > game.homeScore ? FRTheme.Color.bronze : FRTheme.Color.text0)
                    Text("vs").font(.system(size: 10, design: .monospaced)).foregroundColor(FRTheme.Color.rustBright)
                    Text("\(game.homeScore)")
                        .font(FRTheme.Font.bebas(size: 44))
                        .foregroundColor(game.homeScore > game.awayScore ? FRTheme.Color.bronze : FRTheme.Color.text0)
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(colors: [FRTheme.Color.rust.opacity(0.18), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .background(FRTheme.Color.bg2)
        )
        .overlay(alignment: .bottom) { Rectangle().fill(FRTheme.Color.line).frame(height: 1) }
    }

    private func teamSide(team: Team, score: Int, isWin: Bool) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color.red.opacity(0.7), Color.red.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 48, height: 48)
                .overlay(Text(team.id).font(FRTheme.Font.bebas(size: 18)).foregroundColor(.white).tracking(2))
            VStack(alignment: .leading, spacing: 2) {
                Text(team.nickname.uppercased()).font(FRTheme.Font.bebas(size: 22)).tracking(2)
                Text(team.record).font(.system(size: 10, design: .monospaced)).foregroundColor(FRTheme.Color.text2)
            }
            .foregroundColor(FRTheme.Color.text0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button(action: { tab = t }) {
                        Text(t.rawValue.uppercased())
                            .font(.system(size: 12, weight: .semibold)).tracking(2)
                            .foregroundColor(tab == t ? FRTheme.Color.text0 : FRTheme.Color.text2)
                            .padding(.vertical, 12).padding(.horizontal, 14)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(tab == t ? FRTheme.Color.rust : .clear).frame(height: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(FRTheme.Color.bg1)
        .overlay(alignment: .bottom) { Rectangle().fill(FRTheme.Color.line).frame(height: 1) }
    }

    // MARK: - Tabs

    private var boxTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            lineScore.padding(.horizontal, 16).padding(.top, 12)
            FRSectionHeader("Team Stats", actionLabel: "SOURCE: NFL.COM").padding(.horizontal, 16)
            teamStatsCompare.padding(.horizontal, 16)
        }
        .padding(.bottom, 32)
    }

    private var lineScore: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(["TEAM", "Q1", "Q2", "Q3", "Q4", "OT", "T"], id: \.self) { h in
                    Text(h)
                        .font(.system(size: 10, weight: .heavy)).tracking(2)
                        .foregroundColor(FRTheme.Color.text2)
                        .frame(maxWidth: .infinity, alignment: h == "TEAM" ? .leading : .center)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(FRTheme.Color.bg3)

            row(label: "KC", values: game.lineScore.away, total: game.awayScore)
            row(label: "BUF", values: game.lineScore.home, total: game.homeScore)
        }
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func row(label: String, values: [Int], total: Int) -> some View {
        HStack {
            Text(label).font(FRTheme.Font.bebas(size: 16)).frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(FRTheme.Color.text0)
            ForEach(values.indices, id: \.self) { idx in
                Text("\(values[idx])")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text0)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            Text("\(total)")
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundColor(FRTheme.Color.bronze)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private var teamStatsCompare: some View {
        VStack(spacing: 12) {
            statRow(label: "Total Yards", away: game.teamStats.away.totalYards, home: game.teamStats.home.totalYards)
            statRow(label: "Passing Yards", away: game.teamStats.away.passingYards, home: game.teamStats.home.passingYards)
            statRow(label: "Rushing Yards", away: game.teamStats.away.rushingYards, home: game.teamStats.home.rushingYards)
            statRow(label: "Turnovers", away: game.teamStats.away.turnovers, home: game.teamStats.home.turnovers, lowerIsBetter: true)
        }
        .padding(14)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statRow(label: String, away: Int, home: Int, lowerIsBetter: Bool = false) -> some View {
        let total = max(away + home, 1)
        let awayPct = CGFloat(away) / CGFloat(total)
        return VStack(alignment: .center, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .heavy)).tracking(2)
                .foregroundColor(FRTheme.Color.text2)
            HStack {
                Text("\(away)").font(.system(size: 13, weight: .heavy, design: .monospaced)).foregroundColor(FRTheme.Color.text0)
                Spacer()
                Text("\(home)").font(.system(size: 13, weight: .heavy, design: .monospaced)).foregroundColor(FRTheme.Color.text0)
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(red: 0.42, green: 0.012, blue: 0.012), FRTheme.Color.rust], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * awayPct)
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(red: 0.0, green: 0.2, blue: 0.55), Color(red: 0.27, green: 0.47, blue: 0.87)], startPoint: .leading, endPoint: .trailing))
                }
            }
            .frame(height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    // MARK: - Drives

    private var drivesTab: some View {
        VStack(spacing: 0) {
            ForEach(game.driveChart) { drive in
                driveRow(drive)
            }
        }
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func driveRow(_ drive: Drive) -> some View {
        HStack(spacing: 10) {
            Text("Q\(drive.quarter)")
                .font(FRTheme.Font.bebas(size: 18))
                .foregroundColor(FRTheme.Color.bronze)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(drive.teamId) · \(drive.plays) PLAYS · \(drive.yards) YDS")
                    .font(.system(size: 10, weight: .heavy)).tracking(1)
                    .foregroundColor(FRTheme.Color.text2)
                Text(drive.summary).font(.system(size: 12)).foregroundColor(FRTheme.Color.text1)
            }
            Spacer()
            Text(drive.result.rawValue)
                .font(.system(size: 11, weight: .heavy)).tracking(1)
                .foregroundColor(resultColor(drive.result))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(resultBg(drive.result))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private func resultColor(_ r: DriveResult) -> Color {
        switch r {
        case .touchdown: return Color(red: 0.04, green: 0.4, blue: 0.13)
        case .fieldGoal: return Color(red: 0.1, green: 0.08, blue: 0)
        case .interception, .turnover, .fumble: return .white
        default: return FRTheme.Color.text2
        }
    }
    private func resultBg(_ r: DriveResult) -> Color {
        switch r {
        case .touchdown: return FRTheme.Color.good
        case .fieldGoal: return FRTheme.Color.bronze
        case .interception, .turnover, .fumble: return FRTheme.Color.bad
        default: return FRTheme.Color.bg3
        }
    }

    // MARK: - Players

    private var playersTab: some View {
        VStack(spacing: 14) {
            statTable(title: "Passing", headers: ["Player", "C/A", "Yds", "TD", "INT", "RTG"], rows: game.playerStats.passing.map {
                ["\($0.playerName) (\($0.teamId))", "\($0.completions)/\($0.attempts)", "\($0.yards)", "\($0.touchdowns)", "\($0.interceptions)", String(format: "%.1f", $0.rating)]
            })
            statTable(title: "Rushing", headers: ["Player", "Car", "Yds", "Avg", "Lng", "TD"], rows: game.playerStats.rushing.map {
                ["\($0.playerName) (\($0.teamId))", "\($0.carries)", "\($0.yards)", String(format: "%.1f", $0.average), "\($0.longest)", "\($0.touchdowns)"]
            })
            statTable(title: "Receiving", headers: ["Player", "Rec", "Tgt", "Yds", "Avg", "TD"], rows: game.playerStats.receiving.map {
                ["\($0.playerName) (\($0.teamId))", "\($0.receptions)", "\($0.targets)", "\($0.yards)", String(format: "%.1f", $0.average), "\($0.touchdowns)"]
            })
            statTable(title: "Defense", headers: ["Player", "Tkl", "Sck", "TFL", "PD", "INT"], rows: game.playerStats.defense.map {
                ["\($0.playerName) (\($0.teamId))", "\($0.tackles)", String(format: "%.1f", $0.sacks), "\($0.tacklesForLoss)", "\($0.passesDefended)", "\($0.interceptions)"]
            })
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func statTable(title: String, headers: [String], rows: [[String]]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy)).tracking(2)
                .foregroundColor(FRTheme.Color.text1)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FRTheme.Color.bg3)
                .overlay(alignment: .bottom) { Rectangle().fill(FRTheme.Color.line).frame(height: 1) }
            // header
            HStack {
                ForEach(headers.indices, id: \.self) { i in
                    Text(headers[i].uppercased())
                        .font(.system(size: 9, weight: .semibold)).tracking(1)
                        .foregroundColor(FRTheme.Color.text2)
                        .frame(maxWidth: .infinity, alignment: i == 0 ? .leading : .trailing)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .overlay(alignment: .bottom) { Rectangle().fill(FRTheme.Color.line).frame(height: 1) }
            ForEach(rows.indices, id: \.self) { i in
                HStack {
                    ForEach(rows[i].indices, id: \.self) { j in
                        Text(rows[i][j])
                            .font(.system(size: 11, design: j == 0 ? .default : .monospaced))
                            .foregroundColor(FRTheme.Color.text0)
                            .frame(maxWidth: .infinity, alignment: j == 0 ? .leading : .trailing)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .overlay(alignment: .bottom) { Rectangle().fill(FRTheme.Color.line).frame(height: 1) }
            }
        }
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Plays

    private var playsTab: some View {
        VStack(spacing: 0) {
            ForEach(game.playByPlay) { play in
                playRow(play)
            }
        }
        .padding(.bottom, 24)
    }

    private func playRow(_ play: Play) -> some View {
        let hasNote = !play.canvasNoteIds.isEmpty
        return HStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("Q\(play.quarter)").font(FRTheme.Font.bebas(size: 14)).foregroundColor(FRTheme.Color.bronze)
                Text(play.gameClock).font(.system(size: 9, design: .monospaced)).foregroundColor(FRTheme.Color.text2)
            }
            .frame(width: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(play.teamId) · \(play.down ?? 1) & \(play.distance ?? 0) · \(play.yardLine)")
                    .font(.system(size: 10, weight: .semibold)).tracking(1)
                    .foregroundColor(FRTheme.Color.text2).textCase(.uppercase)
                Text(play.description)
                    .font(.system(size: 12)).foregroundColor(FRTheme.Color.text0).lineLimit(2)
            }

            Text(play.isTouchdown ? "TD" : (play.isTurnover ? "TO" : (play.yardsGained >= 0 ? "+\(play.yardsGained)" : "\(play.yardsGained)")))
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundColor(play.isTurnover || play.yardsGained < 0 ? FRTheme.Color.bad : (play.isBigPlay ? FRTheme.Color.good : FRTheme.Color.text0))
                .frame(minWidth: 50, alignment: .trailing)

            // Pencil button → open canvas for this play
            NavigationLink(value: CanvasContext(game: game, play: play)) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(hasNote ?
                              AnyShapeStyle(LinearGradient(colors: [FRTheme.Color.rust, FRTheme.Color.leatherEdge], startPoint: .topLeading, endPoint: .bottomTrailing))
                              : AnyShapeStyle(FRTheme.Color.bg3))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(hasNote ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: hasNote ? 1 : 1).opacity(hasNote ? 1 : 0.6))
                        .frame(width: 34, height: 34)
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(hasNote ? .white : FRTheme.Color.text2)
                        .frame(width: 34, height: 34)
                    if hasNote {
                        Circle().fill(FRTheme.Color.good)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().strokeBorder(FRTheme.Color.bg1, lineWidth: 1.5))
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            play.isBigPlay ? LinearGradient(colors: [FRTheme.Color.bronze.opacity(0.08), .clear], startPoint: .leading, endPoint: .trailing) :
                (hasNote ? LinearGradient(colors: [FRTheme.Color.good.opacity(0.05), .clear], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing))
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }
}

// Routing payload for opening canvas from a specific play
struct CanvasContext: Hashable {
    let game: Game
    let play: Play?
}

#if DEBUG
#Preview {
    NavigationStack {
        GameDetailView(game: MockData.sampleGame)
    }
    .preferredColorScheme(.dark)
}
#endif
