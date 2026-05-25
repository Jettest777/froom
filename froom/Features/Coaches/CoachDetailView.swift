//
//  CoachDetailView.swift
//  f/Room
//
//  Coach detail page with cross-shaped lineage tree:
//
//        [Mentor]
//           |
//   [Peer]--[Coach]--[Peer]
//           |
//        [Disciple]  [Disciple]  ...
//
//  Tap any node to navigate to that coach's detail page.
//  Below the tree: profile, scheme, comments.
//

import SwiftUI

struct CoachDetailView: View {
    let coach: Coach

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroPanel
                lineageTree
                profileSection
                commentsSection
            }
            .padding(.bottom, 32)
        }
        .background(FRTheme.Color.bg1)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("COACH")
                    .font(FRTheme.Font.bebas(size: 18))
                    .tracking(3)
                    .foregroundColor(FRTheme.Color.text0)
            }
        }
        .navigationDestination(for: Coach.self) { c in
            CoachDetailView(coach: c)
        }
    }

    // MARK: - Hero

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(coach.role.rawValue)
                    .font(.system(size: 10, weight: .heavy)).tracking(3)
                    .foregroundColor(FRTheme.Color.rustBright)
                Spacer()
                if let team = coach.teamId {
                    Text(team)
                        .font(FRTheme.Font.bebas(size: 16))
                        .tracking(2)
                        .foregroundColor(FRTheme.Color.bronze)
                }
            }
            Text(coach.name.uppercased())
                .font(FRTheme.Font.bebas(size: 36))
                .tracking(2)
                .foregroundColor(FRTheme.Color.text0)
            if let scheme = coach.scheme {
                Text(scheme.uppercased())
                    .font(.system(size: 10, weight: .heavy)).tracking(2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(FRTheme.Color.rust)
                    .clipShape(Capsule())
            }
            if let since = coach.yearsSince {
                Text("Since \(String(since))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [FRTheme.Color.rust.opacity(0.18), Color.clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .background(FRTheme.Color.bg2)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }

    // MARK: - Lineage cross-tree

    private var lineageTree: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("LINEAGE")
                .font(.system(size: 11, weight: .heavy)).tracking(3)
                .foregroundColor(FRTheme.Color.text1)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            ZStack {
                // Connector lines drawn behind nodes
                lineageLines
                // Nodes
                VStack(spacing: 24) {
                    // Top row: mentors (up to 2)
                    HStack(spacing: 16) {
                        ForEach(mentors.prefix(2)) { mentor in
                            nodeView(coach: mentor, kind: .mentor)
                        }
                        if mentors.isEmpty {
                            placeholderNode(label: "FOUNDER")
                        }
                    }

                    // Middle row: peers — coach — peers
                    HStack(spacing: 12) {
                        ForEach(peers.prefix(1)) { peer in
                            nodeView(coach: peer, kind: .peer)
                        }
                        nodeView(coach: coach, kind: .self_, isCenter: true)
                        ForEach(peers.dropFirst().prefix(1)) { peer in
                            nodeView(coach: peer, kind: .peer)
                        }
                    }

                    // Bottom row: disciples (up to 3)
                    HStack(spacing: 12) {
                        ForEach(disciples.prefix(3)) { disciple in
                            nodeView(coach: disciple, kind: .disciple)
                        }
                        if disciples.isEmpty {
                            placeholderNode(label: "NO DISCIPLES YET")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            // Extended lists for any overflow
            if mentors.count > 2 {
                extendedListSection("More Mentors", coaches: Array(mentors.dropFirst(2)))
            }
            if peers.count > 2 {
                extendedListSection("More Peers", coaches: Array(peers.dropFirst(2)))
            }
            if disciples.count > 3 {
                extendedListSection("More Disciples", coaches: Array(disciples.dropFirst(3)))
            }
        }
        .padding(.vertical, 14)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private var lineageLines: some View {
        // Drawn between the rows of the cross. We draw a vertical line from top center
        // down through the middle row to the bottom row, plus horizontal lines to peers.
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            Path { path in
                if !mentors.isEmpty {
                    path.move(to: CGPoint(x: centerX, y: 30))
                    path.addLine(to: CGPoint(x: centerX, y: 90))
                }
                if !disciples.isEmpty {
                    path.move(to: CGPoint(x: centerX, y: geo.size.height - 90))
                    path.addLine(to: CGPoint(x: centerX, y: geo.size.height - 30))
                    // small fan-out to disciples
                    let span: CGFloat = 80
                    path.move(to: CGPoint(x: centerX - span, y: geo.size.height - 30))
                    path.addLine(to: CGPoint(x: centerX + span, y: geo.size.height - 30))
                }
            }
            .stroke(FRTheme.Color.rust.opacity(0.5), lineWidth: 1.5)
        }
    }

    // MARK: - Node view

    enum NodeKind {
        case self_, mentor, peer, disciple
    }

    private func nodeView(coach c: Coach, kind: NodeKind, isCenter: Bool = false) -> some View {
        let isSelf = (kind == .self_)
        let borderColor: Color = {
            switch kind {
            case .self_: return FRTheme.Color.bronze
            case .mentor: return FRTheme.Color.rust
            case .peer: return FRTheme.Color.text1
            case .disciple: return FRTheme.Color.rustBright
            }
        }()
        let kindLabel: String = {
            switch kind {
            case .self_: return ""
            case .mentor: return "MENTOR"
            case .peer: return "PEER"
            case .disciple: return "DISCIPLE"
            }
        }()

        let card = VStack(spacing: 4) {
            if !kindLabel.isEmpty {
                Text(kindLabel)
                    .font(.system(size: 8, weight: .heavy)).tracking(2)
                    .foregroundColor(borderColor)
            }
            Text(c.name)
                .font(.system(size: isCenter ? 13 : 11, weight: isCenter ? .heavy : .semibold))
                .foregroundColor(FRTheme.Color.text0)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(c.role.rawValue)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(FRTheme.Color.text2)
            if let team = c.teamId {
                Text(team)
                    .font(.system(size: 9, weight: .semibold)).tracking(1)
                    .foregroundColor(borderColor)
            }
        }
        .padding(8)
        .frame(width: isCenter ? 130 : 100, height: isCenter ? 100 : 80)
        .background(
            isSelf
            ? AnyShapeStyle(LinearGradient(
                colors: [FRTheme.Color.rust, FRTheme.Color.leatherEdge],
                startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(FRTheme.Color.bg3)
        )
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(borderColor, lineWidth: isCenter ? 2 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: isSelf ? FRTheme.Color.rust.opacity(0.4) : Color.clear, radius: 8)

        return Group {
            if isSelf {
                card  // not tappable; we're already here
            } else {
                NavigationLink(value: c) { card }
                    .buttonStyle(.plain)
            }
        }
    }

    private func placeholderNode(label: String) -> some View {
        Text(label)
            .font(.system(size: 9, weight: .semibold)).tracking(2)
            .foregroundColor(FRTheme.Color.text2)
            .frame(width: 100, height: 80)
            .background(FRTheme.Color.bg2.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FRTheme.Color.line, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func extendedListSection(_ title: String, coaches: [Coach]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .heavy)).tracking(2)
                .foregroundColor(FRTheme.Color.text2)
            ForEach(coaches) { c in
                NavigationLink(value: c) {
                    HStack {
                        Text(c.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(FRTheme.Color.text0)
                        Spacer()
                        Text(c.role.rawValue)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(FRTheme.Color.text2)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(FRTheme.Color.text2)
                    }
                    .padding(8)
                    .background(FRTheme.Color.bg3)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Profile

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROFILE")
                .font(.system(size: 11, weight: .heavy)).tracking(3)
                .foregroundColor(FRTheme.Color.text1)
            Text(coach.bio)
                .font(.system(size: 13))
                .foregroundColor(FRTheme.Color.text0)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Comments

    private var commentsSection: some View {
        let comments = MockData.coachComments.filter { $0.coachId == coach.id }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("YOUR NOTES")
                    .font(.system(size: 11, weight: .heavy)).tracking(3)
                    .foregroundColor(FRTheme.Color.text1)
                Spacer()
                Text("\(comments.count)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
            }
            if comments.isEmpty {
                Text("まだメモはありません。")
                    .font(.system(size: 12))
                    .foregroundColor(FRTheme.Color.text2)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(comments) { c in
                    commentRow(c)
                }
            }
        }
        .padding(16)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private func commentRow(_ c: CoachComment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(c.createdAt.formatted(.dateTime.year().month().day()))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
                if c.isPinned {
                    Text("★ PINNED")
                        .font(.system(size: 9, weight: .heavy)).tracking(1)
                        .foregroundColor(FRTheme.Color.bronze)
                }
                Spacer()
            }
            Text(c.body)
                .font(.system(size: 13))
                .foregroundColor(FRTheme.Color.text0)
            if !c.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(c.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, weight: .semibold)).tracking(1)
                            .foregroundColor(FRTheme.Color.text1)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(FRTheme.Color.bg3)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FRTheme.Color.bg3)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Lookup helpers

    private var mentors: [Coach] {
        coach.mentorIds.compactMap { id in MockData.coaches.first(where: { $0.id == id }) }
    }
    private var peers: [Coach] {
        coach.peerIds.compactMap { id in MockData.coaches.first(where: { $0.id == id }) }
    }
    private var disciples: [Coach] {
        coach.discipleIds.compactMap { id in MockData.coaches.first(where: { $0.id == id }) }
    }
}

#if DEBUG
#Preview {
    let kyle = MockData.coaches.first(where: { $0.name == "Kyle Shanahan" })!
    return NavigationStack {
        CoachDetailView(coach: kyle)
    }
    .preferredColorScheme(.dark)
}
#endif
