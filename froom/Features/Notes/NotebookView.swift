//
//  NotebookView.swift
//  f/Room
//
//  Game-by-game / tag-based notebook of canvas scouting notes.
//

import SwiftUI

struct NotebookView: View {
    @State private var mode: Mode = .byGame
    @State private var selectedTag: String = "ALL TAGS"

    enum Mode: String, CaseIterable { case byGame = "By Game", byTag = "By Tag", recent = "Recent" }

    private let tags = ["ALL TAGS", "RPO", "COVER 2", "RED ZONE", "3RD & LONG", "BLITZ", "PA"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                modeTabs
                tagChips
                gamesList
            }
            .background(FRTheme.Color.bg1)
        }
    }

    private var header: some View {
        HStack {
            FRoomLogo(.header)
            Spacer()
            FRIconButton(systemName: "plus") { }
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

    private var tagChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    FRChip(tag, isActive: selectedTag == tag) { selectedTag = tag }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }

    private var gamesList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<6) { i in
                    NavigationLink(value: MockData.sampleGame) {
                        gameRow(week: 14 - i / 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(FRTheme.Color.bg1)
        .navigationDestination(for: Game.self) { game in
            GameDetailView(game: game)
        }
    }

    private func gameRow(week: Int) -> some View {
        HStack(spacing: 10) {
            VStack {
                Text("\(week)")
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
                    Text("KC").font(FRTheme.Font.bebas(size: 16)).tracking(1)
                    Text("vs").foregroundColor(FRTheme.Color.rustBright).italic()
                    Text("BUF").font(FRTheme.Font.bebas(size: 16)).tracking(1)
                }
                .foregroundColor(FRTheme.Color.text0)
                Text("2026.12.07 · SUN NIGHT")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
                HStack(spacing: 4) {
                    playTag("RPO", isOn: true)
                    playTag("RED ZONE", isOn: false)
                    playTag("PA", isOn: false)
                }
            }
            Spacer()
            Text("12 plays")
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

    private func playTag(_ label: String, isOn: Bool) -> some View {
        Text(label)
            .font(.system(size: 9, weight: .semibold))
            .tracking(1)
            .foregroundColor(isOn ? .white : FRTheme.Color.text1)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(isOn ? FRTheme.Color.rust : FRTheme.Color.bg3)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(isOn ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#if DEBUG
#Preview {
    NotebookView().preferredColorScheme(.dark)
}
#endif
