//
//  CoachTreeView.swift
//  f/Room
//
//  Coach lineage tree with HC / OC / DC mode switcher + tree picker.
//

import SwiftUI

struct CoachTreeView: View {
    @State private var mode: CoachRole = .headCoach
    @State private var selectedTree: String = "WALSH TREE · WCO"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                modeSwitcher
                treePicker
                treeCanvas
            }
            .background(FRTheme.Color.bg1)
        }
    }

    private var header: some View {
        HStack {
            RZTLogo(style: .inline, size: .header, showsSubtitle: false)
            Spacer()
            HStack(spacing: 8) {
                FRIconButton(systemName: "magnifyingglass") { }
                FRIconButton(systemName: "list.bullet") { }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private var modeSwitcher: some View {
        HStack(spacing: 6) {
            modePill("HC", count: 12, role: .headCoach)
            modePill("OC", count: 8, role: .offensiveCoordinator)
            modePill("DC", count: 6, role: .defensiveCoordinator)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(FRTheme.Color.bg2)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private func modePill(_ label: String, count: Int, role: CoachRole) -> some View {
        let isActive = mode == role
        let bg: Color = role == .defensiveCoordinator ? Color(red: 0.165, green: 0.361, blue: 0.722) : FRTheme.Color.rust
        return Button(action: { mode = role }) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                Text("\(count)")
                    .font(.system(size: 9, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.white.opacity(isActive ? 0.2 : 0))
                    .clipShape(Capsule())
            }
            .foregroundColor(isActive ? .white : FRTheme.Color.text2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isActive ? bg : .clear)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isActive ? bg : FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var treePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                let trees = treesForMode
                ForEach(trees, id: \.self) { name in
                    FRChip(name, isActive: selectedTree == name) {
                        selectedTree = name
                    }
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.vertical, 10)
        .background(FRTheme.Color.bg1)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    private var treesForMode: [String] {
        switch mode {
        case .headCoach: return ["WALSH TREE · WCO", "BELICHICK", "REID", "PARCELLS"]
        case .offensiveCoordinator: return ["SHANAHAN OC · WIDE ZONE", "REID OC · WCO+RPO", "McVAY OC"]
        case .defensiveCoordinator: return ["FANGIO TREE · QTR-QTR", "LeBEAU · ZB BLITZ", "BELICHICK D"]
        default: return ["—"]
        }
    }

    // MARK: - Tree canvas

    private var treeCanvas: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                // Background radial accent
                RadialGradient(
                    colors: [FRTheme.Color.rust.opacity(0.08), .clear],
                    center: .center, startRadius: 0, endRadius: 220
                )

                // Lines + nodes
                CoachTreeDiagram(coaches: sampleCoaches, accent: mode == .defensiveCoordinator
                                  ? Color(red: 0.29, green: 0.47, blue: 0.84)
                                  : FRTheme.Color.rust)
                    .frame(width: 600, height: 720)
            }
            .padding(20)
        }
        .background(FRTheme.Color.bg1)
    }

    private var sampleCoaches: [Coach] {
        switch mode {
        case .headCoach: return MockData.coaches.filter { $0.role == .headCoach }
        case .offensiveCoordinator: return MockData.coaches.filter { $0.scheme?.contains("Zone") == true }
        case .defensiveCoordinator: return MockData.coaches
        default: return MockData.coaches
        }
    }
}

// MARK: - Tree Diagram (simplified layout)

struct CoachTreeDiagram: View {
    let coaches: [Coach]
    let accent: Color

    private struct LaidOut {
        let coach: Coach
        let position: CGPoint
    }

    private var laidOut: [LaidOut] {
        guard !coaches.isEmpty else { return [] }
        let columns = min(4, max(1, coaches.count))
        let rows = (coaches.count + columns - 1) / columns
        let xStep: CGFloat = 600 / CGFloat(columns + 1)
        let yStep: CGFloat = 720 / CGFloat(rows + 1)
        return coaches.enumerated().map { idx, coach in
            let row = idx / columns
            let col = idx % columns
            let x = xStep * CGFloat(col + 1)
            let y = yStep * CGFloat(row + 1)
            return LaidOut(coach: coach, position: CGPoint(x: x, y: y))
        }
    }

    var body: some View {
        ZStack {
            // Lines (connect mentor -> disciple)
            Path { path in
                for item in laidOut {
                    for mentorId in item.coach.mentorIds {
                        if let mentor = laidOut.first(where: { $0.coach.id == mentorId }) {
                            path.move(to: mentor.position)
                            path.addLine(to: item.position)
                        }
                    }
                }
            }
            .stroke(accent.opacity(0.5), lineWidth: 1.5)

            // Nodes
            ForEach(laidOut.indices, id: \.self) { idx in
                let item = laidOut[idx]
                NodeView(coach: item.coach, accent: accent)
                    .position(item.position)
            }
        }
    }
}

struct NodeView: View {
    let coach: Coach
    let accent: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(coach.role.rawValue)
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundColor(FRTheme.Color.text2)
            Text(coach.name.uppercased())
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(FRTheme.Color.text0)
                .lineLimit(1)
            if let team = coach.teamId {
                Text(team)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
            }
            if let scheme = coach.scheme {
                Text(scheme.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(accent)
                    .padding(.top, 2)
            }
        }
        .padding(8)
        .frame(width: 130)
        .background(LinearGradient(colors: [FRTheme.Color.bg2, FRTheme.Color.bg3], startPoint: .top, endPoint: .bottom))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accent, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#if DEBUG
#Preview {
    CoachTreeView().preferredColorScheme(.dark)
}
#endif
