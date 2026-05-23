//
//  NotebookView.swift
//  f/Room
//
//  Lists saved ScoutNote items from SwiftData, grouped by game or filtered by tag.
//

import SwiftUI
import SwiftData

struct NotebookView: View {
    @State private var mode: Mode = .byGame
    @State private var selectedTag: String = "ALL"

    enum Mode: String, CaseIterable { case byGame = "By Game", byTag = "By Tag", recent = "Recent" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                modeTabs
                contentForMode
            }
            .background(FRTheme.Color.bg1)
            .navigationDestination(for: ScoutNote.self) { note in
                ScoutNoteDetailView(note: note)
            }
            .navigationDestination(for: CanvasContext.self) { ctx in
                CanvasView(context: ctx)
            }
        }
    }

    @ViewBuilder
    private var contentForMode: some View {
        switch mode {
        case .byGame:
            ByGameList()
        case .byTag:
            ByTagList(selectedTag: $selectedTag)
        case .recent:
            RecentList()
        }
    }

    private var header: some View {
        HStack {
            FRoomLogo(.header)
            Spacer()
            // Quick-create new note from sample game (in real app: open game picker)
            NavigationLink(value: CanvasContext(game: MockData.sampleGame, play: nil)) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(FRTheme.Color.text1)
                    .frame(width: 36, height: 36)
                    .background(FRTheme.Color.bg2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private var modeTabs: some View {
        HStack(spacing: 0) {
            ForEach(Mode.allCases, id: \.self) { m in
                Button(action: { mode = m }) {
                    Text(m.rawValue.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(mode == m ? FRTheme.Color.text0 : FRTheme.Color.text2)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(mode == m ? FRTheme.Color.rust : Color.clear)
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

// MARK: - By Game

private struct ByGameList: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScoutNote.updatedAt, order: .reverse) private var notes: [ScoutNote]

    private var groups: [(key: String, games: [ScoutNote])] {
        let grouped = Dictionary(grouping: notes) {
            "\($0.season)-W\($0.week)-\($0.awayTeamId)-\($0.homeTeamId)"
        }
        return grouped
            .sorted { ($0.value.first?.updatedAt ?? .distantPast) > ($1.value.first?.updatedAt ?? .distantPast) }
            .map { (key: $0.key, games: $0.value) }
    }

    var body: some View {
        ScrollView {
            if notes.isEmpty {
                EmptyState(message: "まだノートはありません。\n試合ページから✎を押してノートを作成しましょう。")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(groups, id: \.key) { (_, gameNotes) in
                        gameRow(notes: gameNotes)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private func gameRow(notes: [ScoutNote]) -> some View {
        let first = notes.first!
        return NavigationLink(value: first) {
            HStack(spacing: 10) {
                VStack {
                    Text("\(first.week)")
                        .font(FRTheme.Font.bebas(size: 24))
                        .foregroundColor(FRTheme.Color.text0)
                    Text("WK")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(FRTheme.Color.bronze)
                }
                .frame(width: 50)
                .overlay(alignment: .trailing) {
                    Rectangle().fill(FRTheme.Color.line).frame(width: 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(first.awayTeamId).font(FRTheme.Font.bebas(size: 16)).tracking(1)
                        Text("vs").foregroundColor(FRTheme.Color.rustBright).italic().font(.system(size: 11))
                        Text(first.homeTeamId).font(FRTheme.Font.bebas(size: 16)).tracking(1)
                    }
                    .foregroundColor(FRTheme.Color.text0)
                    Text(first.updatedAt.formatted(.dateTime.year().month().day()))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text2)
                    HStack(spacing: 4) {
                        ForEach(Array(allTags(in: notes).prefix(3)), id: \.self) { tag in
                            tagPill(tag)
                        }
                    }
                }
                Spacer()
                Text("\(notes.count) \(notes.count == 1 ? "note" : "notes")")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text1)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(FRTheme.Color.bg3)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(12)
            .background(FRTheme.Color.bg2)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func allTags(in notes: [ScoutNote]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for n in notes {
            for t in n.tags {
                if seen.insert(t).inserted { out.append(t) }
            }
        }
        return out
    }

    private func tagPill(_ tag: String) -> some View {
        Text(tag)
            .font(.system(size: 9, weight: .semibold))
            .tracking(1)
            .foregroundColor(FRTheme.Color.text1)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(FRTheme.Color.bg3)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - By Tag

private struct ByTagList: View {
    @Binding var selectedTag: String
    @Query(sort: \ScoutNote.updatedAt, order: .reverse) private var notes: [ScoutNote]

    private var availableTags: [String] {
        var set = Set<String>()
        for n in notes { for t in n.tags { set.insert(t) } }
        return ["ALL"] + Array(set).sorted()
    }

    private var filteredNotes: [ScoutNote] {
        if selectedTag == "ALL" { return notes }
        return notes.filter { $0.tags.contains(selectedTag) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableTags, id: \.self) { tag in
                        FRChip(tag, isActive: selectedTag == tag) { selectedTag = tag }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)

            ScrollView {
                if filteredNotes.isEmpty {
                    EmptyState(message: "このタグのノートはありません。")
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredNotes) { note in
                            NavigationLink(value: note) {
                                noteRow(note)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private func noteRow(_ n: ScoutNote) -> some View {
        HStack(spacing: 12) {
            VStack {
                Text("Q\(n.quarter ?? 1)").font(FRTheme.Font.bebas(size: 16)).foregroundColor(FRTheme.Color.bronze)
                Text(n.gameClock ?? "—").font(.system(size: 9, design: .monospaced)).foregroundColor(FRTheme.Color.text2)
            }
            .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(n.gameLabel).font(FRTheme.Font.bebas(size: 14)).tracking(1).foregroundColor(FRTheme.Color.text0)
                if let f = n.formationLabel {
                    Text(f).font(.system(size: 10)).foregroundColor(FRTheme.Color.text2)
                }
                HStack(spacing: 4) {
                    ForEach(Array(n.tags.prefix(4)), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(FRTheme.Color.text1)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(FRTheme.Color.bg3)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundColor(FRTheme.Color.text2)
        }
        .padding(12)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Recent

private struct RecentList: View {
    @Query(sort: \ScoutNote.updatedAt, order: .reverse) private var notes: [ScoutNote]

    var body: some View {
        ScrollView {
            if notes.isEmpty {
                EmptyState(message: "まだノートはありません。")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(notes) { note in
                        NavigationLink(value: note) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(note.gameLabel)
                                        .font(FRTheme.Font.bebas(size: 14)).tracking(1)
                                        .foregroundColor(FRTheme.Color.text0)
                                    Text("Updated \(note.updatedAt.formatted(.relative(presentation: .named)))")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(FRTheme.Color.text2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(FRTheme.Color.text2).font(.system(size: 11))
                            }
                            .padding(12)
                            .background(FRTheme.Color.bg2)
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FRTheme.Color.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Detail view (opens canvas for the saved note)

struct ScoutNoteDetailView: View {
    let note: ScoutNote

    var body: some View {
        // Rebuild a CanvasContext from the saved note so the canvas can reopen it.
        // We synthesize a minimal Game from stored fields, then CanvasView's loadOrCreateNote
        // will find this same ScoutNote and reuse it.
        let game = Game(
            id: note.gameId ?? UUID(),
            week: note.week,
            season: note.season,
            date: note.updatedAt,
            awayTeamId: note.awayTeamId,
            homeTeamId: note.homeTeamId,
            awayScore: 0,
            homeScore: 0,
            isFinal: true,
            overtime: false,
            lineScore: LineScore(away: [], home: []),
            teamStats: TeamStatsPair(
                away: TeamStats(totalYards: 0, passingYards: 0, rushingYards: 0,
                                thirdDown: "0/0", fourthDown: nil, timeOfPossession: "0:00",
                                turnovers: 0, penalties: 0, firstDowns: 0),
                home: TeamStats(totalYards: 0, passingYards: 0, rushingYards: 0,
                                thirdDown: "0/0", fourthDown: nil, timeOfPossession: "0:00",
                                turnovers: 0, penalties: 0, firstDowns: 0)
            ),
            driveChart: [],
            playerStats: PlayerStatsBundle(passing: [], rushing: [], receiving: [], defense: []),
            playByPlay: []
        )

        let play: Play? = note.playId.map { pid in
            Play(id: pid, gameId: game.id,
                 quarter: note.quarter ?? 1,
                 gameClock: note.gameClock ?? "00:00",
                 down: note.down, distance: note.distance,
                 yardLine: note.yardLine ?? "—",
                 teamId: note.awayTeamId, description: "",
                 yardsGained: 0, isBigPlay: false, isTouchdown: false, isTurnover: false,
                 canvasNoteIds: [note.id])
        }

        return CanvasView(context: CanvasContext(game: game, play: play))
    }
}

// MARK: - Empty State

private struct EmptyState: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "pencil.tip.crop.circle.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(FRTheme.Color.text2)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(FRTheme.Color.text2)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    NotebookView()
        .modelContainer(for: [ScoutNote.self], inMemory: true)
        .preferredColorScheme(.dark)
}
#endif
