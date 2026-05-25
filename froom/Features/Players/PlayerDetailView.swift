//
//  PlayerDetailView.swift
//  f/Room
//
//  Detailed player profile: physical, draft, contract, team history, career stats.
//

import SwiftUI

struct PlayerDetailView: View {
    let detail: PlayerDetail
    @State private var section: Section = .profile
    @State private var rasClient = RASClient()

    enum Section: String, CaseIterable {
        case profile = "Profile"
        case athleticism = "Athleticism"
        case career = "Career"
    }

    var body: some View {
        VStack(spacing: 0) {
            hero
            subTabBar
            ScrollView {
                switch section {
                case .profile:
                    VStack(spacing: 0) {
                        contractCard
                        draftSection
                        teamHistorySection
                    }
                case .athleticism:
                    AthleticismView(entry: rasClient.entry(for: detail.fullName))
                case .career:
                    VStack(spacing: 0) {
                        statGrid
                        careerStatsSection
                    }
                }
            }
        }
        .background(FRTheme.Color.bg1)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PLAYER")
                    .font(FRTheme.Font.bebas(size: 18)).tracking(3)
                    .foregroundColor(FRTheme.Color.text0)
            }
        }
        .task { await rasClient.refresh() }
    }

    private var subTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases, id: \.self) { s in
                Button(action: { section = s }) {
                    Text(s.rawValue.uppercased())
                        .font(.system(size: 11, weight: .heavy)).tracking(2)
                        .foregroundColor(section == s ? FRTheme.Color.text0 : FRTheme.Color.text2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(section == s ? FRTheme.Color.rzRed : .clear)
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

    // MARK: - Hero (jersey number + name)

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [
                Color(red: 0.835, green: 0.039, blue: 0.039),
                Color(red: 0.408, green: 0.012, blue: 0.012)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)

            // Faded jersey number background
            Text("\(detail.jerseyNumber)")
                .font(FRTheme.Font.bebas(size: 200))
                .foregroundColor(.white.opacity(0.12))
                .position(x: UIScreen.main.bounds.width - 80, y: 90)

            VStack(alignment: .leading, spacing: 6) {
                Text(detail.firstName.uppercased())
                    .font(.system(size: 14, weight: .heavy)).tracking(3)
                    .foregroundColor(FRTheme.Color.text1)
                Text(detail.lastName.uppercased())
                    .font(FRTheme.Font.bebas(size: 38)).tracking(2)
                    .foregroundColor(.white)
                Text("\(detail.position) · \(detail.currentTeamId ?? "—") · \(detail.heightDisplay) · \(detail.weightPounds) LB · \(detail.yearsInLeague) YR")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text1)
            }
            .padding(20)
        }
        .frame(height: 220)
        .clipped()
    }

    // MARK: - Career stat highlights (varies by position)

    private var statGrid: some View {
        let stats = detail.careerStats
        let cells: [(value: String, label: String)] = {
            switch detail.position {
            case "QB":
                return [
                    ("\(stats?.passYards ?? 0)", "Pass Yds"),
                    ("\(stats?.passTDs ?? 0)", "Pass TD"),
                    ("\(stats?.interceptions ?? 0)", "INT"),
                    (String(format: "%.1f", stats?.passerRating ?? 0), "Rating"),
                ]
            case "RB":
                return [
                    ("\(stats?.rushAttempts ?? 0)", "Carries"),
                    ("\(stats?.rushYards ?? 0)", "Rush Yds"),
                    ("\(stats?.rushTDs ?? 0)", "Rush TD"),
                    ("\(stats?.receptions ?? 0)", "Rec"),
                ]
            case "WR", "TE":
                return [
                    ("\(stats?.receptions ?? 0)", "Rec"),
                    ("\(stats?.recYards ?? 0)", "Rec Yds"),
                    ("\(stats?.recTDs ?? 0)", "TD"),
                    (String(format: "%.1f", Double(stats?.recYards ?? 0) / Double(max(1, stats?.receptions ?? 1))), "YPC"),
                ]
            default:
                return [
                    ("\(stats?.totalTackles ?? 0)", "Tackles"),
                    (String(format: "%.1f", stats?.sacks ?? 0), "Sacks"),
                    ("\(stats?.defInterceptions ?? 0)", "INT"),
                    ("\(stats?.forcedFumbles ?? 0)", "FF"),
                ]
            }
        }()

        return HStack(spacing: 1) {
            ForEach(cells.indices, id: \.self) { i in
                VStack(spacing: 4) {
                    Text(cells[i].value)
                        .font(FRTheme.Font.bebas(size: 22))
                        .foregroundColor(.white)
                    Text(cells[i].label.uppercased())
                        .font(.system(size: 9, weight: .semibold)).tracking(2)
                        .foregroundColor(FRTheme.Color.text2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(FRTheme.Color.bg2)
            }
        }
        .background(FRTheme.Color.line)
        .overlay(Rectangle().strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .padding(.horizontal, 16).padding(.top, 14)
    }

    // MARK: - Contract

    private var contractCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            FRSectionHeader("Contract")
            if let c = detail.contract {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(c.displayHeadline)
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            .foregroundColor(FRTheme.Color.text0)
                        Spacer()
                        Text("\(String(c.endYear)) まで")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(FRTheme.Color.bronze)
                    }
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(FRTheme.Color.bg3).frame(height: 6)
                            LinearGradient(colors: [FRTheme.Color.rust, FRTheme.Color.bronze],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: geo.size.width * c.progress, height: 6)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    .frame(height: 6)
                    HStack {
                        Text(String(c.signedYear)).font(.system(size: 10, design: .monospaced))
                        Spacer()
                        Text("進行中").font(.system(size: 10, design: .monospaced)).foregroundColor(FRTheme.Color.bronze)
                        Spacer()
                        Text(String(c.endYear)).font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(FRTheme.Color.text2)
                    HStack {
                        statTile(label: "Guaranteed", value: "$\(Int(c.guaranteedUSD))M")
                        statTile(label: "Avg/Yr", value: "$\(String(format: "%.1f", c.avgPerYearUSD))M")
                        if let cap = c.capHitCurrentYear {
                            statTile(label: "Cap Hit", value: "$\(String(format: "%.1f", cap))M")
                        }
                    }
                }
                .padding(14)
                .background(FRTheme.Color.bg2)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                emptyValue("契約情報なし")
            }
        }
        .padding(.horizontal, 16)
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(FRTheme.Font.bebas(size: 16)).foregroundColor(FRTheme.Color.text0)
            Text(label.uppercased()).font(.system(size: 9)).tracking(1).foregroundColor(FRTheme.Color.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(FRTheme.Color.bg3)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Draft

    private var draftSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FRSectionHeader("Draft")
            if let d = detail.draft {
                HStack(spacing: 14) {
                    VStack {
                        Text("\(d.overallPick)")
                            .font(FRTheme.Font.bebas(size: 36))
                            .foregroundColor(FRTheme.Color.bronze)
                        Text("OVR")
                            .font(.system(size: 9, weight: .semibold)).tracking(2)
                            .foregroundColor(FRTheme.Color.text2)
                    }
                    .frame(width: 70)
                    .padding(8)
                    .background(FRTheme.Color.bg3)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(String(d.year)) NFL Draft")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(FRTheme.Color.text0)
                        Text("Rd \(d.round), Pick \(d.pick)")
                            .font(.system(size: 11, design: .monospaced)).foregroundColor(FRTheme.Color.text1)
                        Text("by \(d.draftedByTeamId)")
                            .font(.system(size: 11, design: .monospaced)).foregroundColor(FRTheme.Color.text2)
                    }
                    Spacer()
                }
                .padding(14)
                .background(FRTheme.Color.bg2)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let college = detail.college {
                    HStack {
                        Image(systemName: "graduationcap").foregroundColor(FRTheme.Color.text2).font(.system(size: 12))
                        Text("College: \(college)")
                            .font(.system(size: 12)).foregroundColor(FRTheme.Color.text1)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            } else {
                emptyValue("Undrafted Free Agent")
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Team history

    private var teamHistorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FRSectionHeader("Team History")
            if detail.teamHistory.isEmpty {
                emptyValue("履歴データなし")
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(detail.teamHistory.indices, id: \.self) { idx in
                        let stint = detail.teamHistory[idx]
                        HStack(spacing: 12) {
                            // timeline dot
                            ZStack {
                                Circle().fill(stint.isCurrent ? FRTheme.Color.rust : FRTheme.Color.text2)
                                    .frame(width: 10, height: 10)
                                if idx != detail.teamHistory.count - 1 {
                                    Rectangle().fill(FRTheme.Color.line)
                                        .frame(width: 1, height: 40).offset(y: 24)
                                }
                            }
                            .frame(width: 24, height: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(stint.teamId)
                                        .font(FRTheme.Font.bebas(size: 18)).tracking(2)
                                        .foregroundColor(FRTheme.Color.text0)
                                    if stint.isCurrent {
                                        Text("Current")
                                            .font(.system(size: 9, weight: .semibold)).tracking(1)
                                            .foregroundColor(FRTheme.Color.bronze)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(FRTheme.Color.bg3)
                                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                    }
                                }
                                Text(stint.displayYears)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(FRTheme.Color.text2)
                                if let reason = stint.endReason {
                                    Text("via \(reason.rawValue)")
                                        .font(.system(size: 10)).foregroundColor(FRTheme.Color.text2)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .padding(14)
                .background(FRTheme.Color.bg2)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Career stats

    private var careerStatsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FRSectionHeader("Career Stats")
            HStack {
                if let gp = detail.careerStats?.gamesPlayed {
                    statTile(label: "Games", value: "\(gp)")
                }
                if let gs = detail.careerStats?.gamesStarted {
                    statTile(label: "Started", value: "\(gs)")
                }
                if let yrs = detail.yearsInLeague as Int? {
                    statTile(label: "Years", value: "\(yrs)")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    private func emptyValue(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 12)).foregroundColor(FRTheme.Color.text2)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FRTheme.Color.bg2)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PlayerDetailView(detail: .mockMahomes)
    }
    .preferredColorScheme(.dark)
}
#endif
