//
//  TeamsView.swift
//  f/Room
//
//  Teams list → team detail (depth chart, news, injury).
//

import SwiftUI

struct TeamsView: View {
    @State private var selectedConference: String = "All"

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
            }
            .background(FRTheme.Color.bg1)
            .navigationDestination(for: Team.self) { team in
                TeamDetailView(team: team)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                FRoomLogo(.header)
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
        if selectedConference == "All" { return MockData.teams }
        return MockData.teams.filter { $0.conference == selectedConference }
    }
}

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

    private func hex(_ h: String) -> Color {
        var s = h
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Team Detail (depth chart placeholder)

struct TeamDetailView: View {
    let team: Team

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // hero
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [Color.black.opacity(0.5), Color.clear], startPoint: .bottomLeading, endPoint: .topTrailing)
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
                }
                .frame(height: 110)
                .background(FRTheme.Color.bg2)

                Text("Depth chart, injuries, and team news coming next.")
                    .font(.system(size: 13))
                    .foregroundColor(FRTheme.Color.text2)
                    .padding(24)

                ForEach(["OFFENSE", "DEFENSE", "SPECIAL TEAMS"], id: \.self) { section in
                    VStack(alignment: .leading) {
                        Text(section)
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(3)
                            .foregroundColor(FRTheme.Color.rust)
                            .padding(.bottom, 6)
                        ForEach(["QB", "RB", "WR", "TE"], id: \.self) { pos in
                            HStack {
                                Text(pos)
                                    .font(FRTheme.Font.bebas(size: 14))
                                    .foregroundColor(FRTheme.Color.bronze)
                                    .frame(width: 40, alignment: .leading)
                                Text("Starter · Backup · 3rd")
                                    .font(.system(size: 11))
                                    .foregroundColor(FRTheme.Color.text2)
                            }
                            .padding(.vertical, 6)
                            .overlay(alignment: .bottom) { Rectangle().fill(FRTheme.Color.line).frame(height: 1) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
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

    private func hex(_ h: String) -> Color {
        var s = h
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        return Color(red: r, green: g, blue: b)
    }
}

#if DEBUG
#Preview {
    TeamsView().preferredColorScheme(.dark)
}
#endif
