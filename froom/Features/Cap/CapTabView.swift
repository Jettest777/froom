//
//  CapTabView.swift
//  f/Room
//
//  Team-by-team salary cap browser. Top bar = team picker.
//  Body = summary panel + roster sorted by cap hit (descending) with dead-money highlighting.
//

import SwiftUI

struct CapTabView: View {
    @State private var capClient = CapClient()
    @State private var selectedTeamId: String = "KC"
    @State private var includesDeadMoney: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                teamPicker
                if let summary = capClient.summary(for: selectedTeamId) {
                    ScrollView {
                        VStack(spacing: 14) {
                            summaryPanel(summary)
                            filterRow
                            rosterList(summary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .refreshable { await capClient.refresh() }
                } else {
                    Spacer()
                    ProgressView().tint(FRTheme.Color.rust)
                    Spacer()
                }
            }
            .background(FRTheme.Color.bg1)
        }
        .task { await capClient.refresh() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            RZTLogo(style: .inline, size: .header, showsSubtitle: false)
            Spacer()
            if capClient.isLoading {
                ProgressView().tint(FRTheme.Color.rust).scaleEffect(0.7)
            } else {
                Button {
                    Task { await capClient.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise").foregroundColor(FRTheme.Color.text1)
                        .frame(width: 36, height: 36)
                        .background(FRTheme.Color.bg2)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    // MARK: - Team picker

    private var teamPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MockData.teams) { team in
                    Button(action: { selectedTeamId = team.id }) {
                        Text(team.id)
                            .font(FRTheme.Font.bebas(size: 16))
                            .tracking(2)
                            .foregroundColor(selectedTeamId == team.id ? .white : FRTheme.Color.text1)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(
                                selectedTeamId == team.id
                                ? AnyShapeStyle(LinearGradient(colors: [FRTheme.Color.rust, FRTheme.Color.leatherEdge],
                                                               startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(FRTheme.Color.bg2)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(selectedTeamId == team.id ? FRTheme.Color.rust : FRTheme.Color.line,
                                              lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(FRTheme.Color.bg1)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    // MARK: - Summary panel

    private func summaryPanel(_ s: TeamCapSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(selectedTeamId)
                    .font(FRTheme.Font.bebas(size: 28)).tracking(3)
                    .foregroundColor(FRTheme.Color.text0)
                Text("\(String(s.season)) SALARY CAP")
                    .font(.system(size: 10, weight: .heavy)).tracking(2)
                    .foregroundColor(FRTheme.Color.bronze)
                Spacer()
                Text("Updated \(s.updatedAt.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
            }

            // Cap usage bar
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
                        // dead money portion (orange tinged red on right)
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
                statTile(label: "Cap Space", value: formatMillions(s.capSpace), accent: s.capSpace < 5 ? FRTheme.Color.bad : FRTheme.Color.good)
                Divider().background(FRTheme.Color.line)
                statTile(label: "Dead Cap", value: formatMillions(s.deadCap), accent: s.deadCap > 20 ? FRTheme.Color.bad : FRTheme.Color.text1)
                Divider().background(FRTheme.Color.line)
                statTile(label: "Contracts", value: "\(s.activeContracts)", accent: FRTheme.Color.text0)
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

    private func statTile(label: String, value: String, accent: Color) -> some View {
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

    // MARK: - Filter row

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

    // MARK: - Roster list

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
                // Mini bar showing % of cap
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

    // MARK: - Helpers

    private func colorForTier(_ tier: CapTier) -> Color {
        switch tier {
        case .megaContract: return Color(red: 0.96, green: 0.42, blue: 0.15)  // bright orange
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
    CapTabView()
        .preferredColorScheme(.dark)
}
#endif
