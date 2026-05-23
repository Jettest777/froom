//
//  LiveGameDetailView.swift
//  f/Room
//
//  Live game text broadcast with sticky situation bar + play-by-play log.
//
//  Layout:
//    ┌────────────────────────────────────┐
//    │   Scoreboard hero (away vs home)   │
//    │   Status: LIVE · Q3 8:42           │
//    ├────────────────────────────────────┤
//    │   Situation bar (sticky)           │
//    │   Possession · Down & Distance     │
//    │   "Last play: Mahomes → Worthy +12"│
//    ├────────────────────────────────────┤
//    │   Play-by-Play log (newest first)  │
//    │   ▸ Q3 8:42 · 2&7 BUF32           │
//    │     Mahomes pass to Worthy +12    │
//    │     [✎ note attached] [+ add memo] │
//    │   ▸ ...                           │
//    └────────────────────────────────────┘
//

import SwiftUI
import SwiftData

struct LiveGameDetailView: View {
    let scheduled: ScheduledGame
    @State private var poller: LiveGamePoller?
    @Query private var notes: [ScoutNote]
    @Environment(\.modelContext) private var modelContext

    init(scheduled: ScheduledGame) {
        self.scheduled = scheduled
        let scheduledId = scheduled.id
        let homeId = scheduled.homeTeamId
        let awayId = scheduled.awayTeamId
        _notes = Query(filter: #Predicate<ScoutNote> { note in
            note.homeTeamId == homeId && note.awayTeamId == awayId
        })
        // Note: gameId is UUID; ESPN gameId is String. We link via externalPlayId on the play level.
    }

    var body: some View {
        VStack(spacing: 0) {
            hero
            if let state = poller?.snapshot?.state {
                situationBar(state)
            }
            playByPlayList
        }
        .background(FRTheme.Color.bg1)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(scheduled.awayTeamId) @ \(scheduled.homeTeamId)")
                    .font(FRTheme.Font.bebas(size: 18)).tracking(2)
                    .foregroundColor(FRTheme.Color.text0)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let isRefreshing = poller?.isRefreshing, isRefreshing {
                    ProgressView().tint(FRTheme.Color.rust).scaleEffect(0.7)
                } else {
                    Button {
                        Task { await poller?.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(FRTheme.Color.text1)
                    }
                }
            }
        }
        .navigationDestination(for: PlayLog.self) { play in
            // Build a CanvasContext from the play for the existing canvas view
            canvasContextFor(play: play)
        }
        .onAppear {
            if poller == nil { poller = LiveGamePoller(gameId: scheduled.id, pollInterval: 30) }
            poller?.start()
        }
        .onDisappear {
            poller?.stop()
        }
    }

    // MARK: - Hero scoreboard

    private var hero: some View {
        let state = poller?.snapshot?.state
        let awayScore = state?.awayScore ?? scheduled.awayScore ?? 0
        let homeScore = state?.homeScore ?? scheduled.homeScore ?? 0
        let isLive = (state?.status ?? scheduled.status).isInProgress

        return VStack(spacing: 12) {
            HStack {
                Text(scheduled.weekLabel)
                    .font(.system(size: 10, weight: .heavy)).tracking(2)
                    .foregroundColor(FRTheme.Color.bronze)
                Spacer()
                HStack(spacing: 6) {
                    if isLive {
                        Circle().fill(FRTheme.Color.rustBright)
                            .frame(width: 6, height: 6)
                    }
                    Text((state?.status ?? scheduled.status).displayLabel)
                        .font(.system(size: 11, weight: .heavy)).tracking(2)
                        .foregroundColor(isLive ? .white : FRTheme.Color.text1)
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(isLive ? FRTheme.Color.rust : FRTheme.Color.bg3)
                .clipShape(Capsule())
            }

            HStack(spacing: 16) {
                teamScoreColumn(scheduled.awayTeamId, score: awayScore, hasBall: state?.possession == scheduled.awayTeamId)
                VStack(spacing: 2) {
                    if let state {
                        Text("Q\(state.quarter)")
                            .font(FRTheme.Font.bebas(size: 18)).foregroundColor(FRTheme.Color.bronze)
                        Text(state.gameClock)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(FRTheme.Color.text1)
                    } else {
                        Text("vs").font(.system(size: 14, weight: .heavy)).italic()
                            .foregroundColor(FRTheme.Color.rustBright)
                    }
                }
                teamScoreColumn(scheduled.homeTeamId, score: homeScore, hasBall: state?.possession == scheduled.homeTeamId)
            }
        }
        .padding(18)
        .background(
            LinearGradient(colors: [FRTheme.Color.rust.opacity(0.15), Color.clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .background(FRTheme.Color.bg2)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private func teamScoreColumn(_ abbrev: String, score: Int, hasBall: Bool) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                if hasBall {
                    Image(systemName: "football.fill")
                        .font(.system(size: 11))
                        .foregroundColor(FRTheme.Color.bronze)
                }
                Text(abbrev)
                    .font(FRTheme.Font.bebas(size: 24)).tracking(2)
                    .foregroundColor(FRTheme.Color.text0)
            }
            Text("\(score)")
                .font(FRTheme.Font.bebas(size: 46))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Situation bar (sticky-ish)

    private func situationBar(_ state: LiveGameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let poss = state.possession {
                    HStack(spacing: 4) {
                        Image(systemName: "football.fill")
                            .font(.system(size: 10))
                            .foregroundColor(FRTheme.Color.bronze)
                        Text(poss).font(FRTheme.Font.bebas(size: 14))
                    }
                    .foregroundColor(FRTheme.Color.text0)
                }
                if let d = state.down, let dist = state.distance {
                    Text("\(ordinal(d)) & \(dist)")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text0)
                }
                if let yard = state.yardLine {
                    Text(yard)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text1)
                }
                if state.isRedZone {
                    Text("RED ZONE")
                        .font(.system(size: 9, weight: .heavy)).tracking(1.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(FRTheme.Color.bad)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            if let lastPlay = state.lastPlayDescription {
                HStack(alignment: .top, spacing: 8) {
                    Text("Last play")
                        .font(.system(size: 9, weight: .heavy)).tracking(2)
                        .foregroundColor(FRTheme.Color.text2)
                        .padding(.top, 2)
                    Text(lastPlay)
                        .font(.system(size: 12))
                        .foregroundColor(FRTheme.Color.text1)
                    if let yards = state.lastPlayYards {
                        Text(yards >= 0 ? "+\(yards)" : "\(yards)")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(yards >= 20 ? FRTheme.Color.bronze : (yards < 0 ? FRTheme.Color.bad : FRTheme.Color.good))
                    }
                }
            }
        }
        .padding(14)
        .background(FRTheme.Color.bg3.opacity(0.6))
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private func ordinal(_ n: Int) -> String {
        switch n {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        case 4: return "4th"
        default: return "\(n)th"
        }
    }

    // MARK: - Play-by-play

    private var playByPlayList: some View {
        let plays = (poller?.snapshot?.plays ?? []).sorted(by: { $0.sequence > $1.sequence })
        return ScrollView {
            LazyVStack(spacing: 8) {
                if plays.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 30))
                            .foregroundColor(FRTheme.Color.text2)
                        Text(scheduled.status == .scheduled
                             ? "試合開始までお待ちください"
                             : "プレーデータ取得中…")
                            .font(.system(size: 12))
                            .foregroundColor(FRTheme.Color.text2)
                    }
                    .padding(.vertical, 60)
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(plays) { play in
                        playRow(play)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func playRow(_ play: PlayLog) -> some View {
        let playId: String = play.id
        let hasNote: Bool = notes.contains(where: { (note: ScoutNote) -> Bool in
            note.externalPlayId == playId
        })

        return NavigationLink(value: play) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Q\(play.quarter) \(play.gameClock)")
                        .font(.system(size: 10, weight: .heavy)).tracking(1.5)
                        .foregroundColor(FRTheme.Color.bronze)
                    if let team = play.teamId {
                        Text(team).font(FRTheme.Font.bebas(size: 13)).foregroundColor(FRTheme.Color.text0)
                    }
                    if let d = play.down, let dist = play.distance {
                        Text("\(ordinal(d))&\(dist)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(FRTheme.Color.text2)
                    }
                    if play.scoringPlay {
                        Text("SCORE")
                            .font(.system(size: 9, weight: .heavy)).tracking(1)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(FRTheme.Color.good)
                            .clipShape(Capsule())
                    }
                    if play.bigPlay {
                        Text("BIG")
                            .font(.system(size: 9, weight: .heavy)).tracking(1)
                            .foregroundColor(Color(red: 0.1, green: 0.07, blue: 0))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(FRTheme.Color.bronze)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text(play.result.label)
                        .font(.system(size: 10, weight: .semibold)).tracking(1)
                        .foregroundColor(resultColor(play.result))
                }
                Text(play.description)
                    .font(.system(size: 13))
                    .foregroundColor(FRTheme.Color.text0)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(play.yardsGained >= 0 ? "+\(play.yardsGained) yds" : "\(play.yardsGained) yds")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(play.yardsGained >= 0 ? FRTheme.Color.good : FRTheme.Color.bad)
                    Spacer()
                    if hasNote {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.tip").font(.system(size: 11))
                            Text("Note attached").font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(FRTheme.Color.bronze)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "plus").font(.system(size: 11))
                            Text("Add note").font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(FRTheme.Color.text2)
                    }
                }
            }
            .padding(12)
            .background(FRTheme.Color.bg2)
            .overlay(alignment: .leading) {
                if hasNote {
                    Rectangle().fill(FRTheme.Color.bronze).frame(width: 2)
                } else if play.scoringPlay {
                    Rectangle().fill(FRTheme.Color.good).frame(width: 2)
                } else if play.bigPlay {
                    Rectangle().fill(FRTheme.Color.bronze.opacity(0.5)).frame(width: 2)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func resultColor(_ r: PlayResult) -> Color {
        switch r {
        case .touchdown, .fieldGoal, .twoPointConversion: return FRTheme.Color.good
        case .interception, .fumble, .sack: return FRTheme.Color.bad
        default: return FRTheme.Color.text2
        }
    }

    // MARK: - Canvas context builder

    @ViewBuilder
    private func canvasContextFor(play: PlayLog) -> some View {
        // Build a synthetic Game from the scheduled game + a synthetic Play from PlayLog,
        // then hand off to CanvasView which knows how to load/create a ScoutNote.
        let game = Game(
            id: UUID(),
            week: scheduled.week,
            season: scheduled.season,
            date: scheduled.kickoff,
            awayTeamId: scheduled.awayTeamId,
            homeTeamId: scheduled.homeTeamId,
            awayScore: poller?.snapshot?.state?.awayScore ?? scheduled.awayScore ?? 0,
            homeScore: poller?.snapshot?.state?.homeScore ?? scheduled.homeScore ?? 0,
            isFinal: !scheduled.status.isInProgress,
            overtime: scheduled.status == .finalOT || scheduled.status == .overtime,
            lineScore: LineScore(away: [], home: []),
            teamStats: TeamStatsPair(
                away: emptyStats, home: emptyStats
            ),
            driveChart: [],
            playerStats: PlayerStatsBundle(passing: [], rushing: [], receiving: [], defense: []),
            playByPlay: []
        )

        let internalPlay = Play(
            id: UUID(),
            gameId: game.id,
            quarter: play.quarter,
            gameClock: play.gameClock,
            down: play.down,
            distance: play.distance,
            yardLine: play.yardLine ?? "—",
            teamId: play.teamId ?? scheduled.awayTeamId,
            description: play.description,
            yardsGained: play.yardsGained,
            isBigPlay: play.bigPlay,
            isTouchdown: play.result == .touchdown,
            isTurnover: play.result == .interception || play.result == .fumble,
            canvasNoteIds: []
        )

        CanvasViewWithExternalPlay(
            context: CanvasContext(game: game, play: internalPlay),
            externalPlayId: play.id
        )
    }

    private var emptyStats: TeamStats {
        TeamStats(totalYards: 0, passingYards: 0, rushingYards: 0,
                  thirdDown: "0/0", fourthDown: nil, timeOfPossession: "0:00",
                  turnovers: 0, penalties: 0, firstDowns: 0)
    }
}

/// A small wrapper around CanvasView that, after the underlying ScoutNote is created,
/// stamps the externalPlayId so the live game's play-by-play can link back to it.
private struct CanvasViewWithExternalPlay: View {
    let context: CanvasContext
    let externalPlayId: String

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        CanvasView(context: context)
            .onAppear {
                // Find the most recent ScoutNote for this game/play and stamp externalPlayId
                let homeId = context.game.homeTeamId
                let awayId = context.game.awayTeamId
                let externalId = externalPlayId
                let descriptor = FetchDescriptor<ScoutNote>(
                    predicate: #Predicate { $0.homeTeamId == homeId && $0.awayTeamId == awayId },
                    sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                )
                let fetched: [ScoutNote] = (try? modelContext.fetch(descriptor)) ?? []
                let note = fetched.first(where: { (n: ScoutNote) -> Bool in
                    n.externalPlayId == nil || n.externalPlayId == externalId
                })
                if let note {
                    note.externalPlayId = externalId
                    try? modelContext.save()
                }
            }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        LiveGameDetailView(scheduled: ScheduledGame(
            id: "401547405",
            season: 2026,
            seasonType: .regular,
            week: 14,
            playoffRound: nil,
            kickoff: Date(),
            awayTeamId: "KC", homeTeamId: "BUF",
            status: .live,
            awayScore: 17, homeScore: 21,
            venue: "Highmark Stadium", broadcast: "SNF"
        ))
    }
    .modelContainer(for: [ScoutNote.self], inMemory: true)
    .preferredColorScheme(.dark)
}
#endif
