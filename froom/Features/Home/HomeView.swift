//
//  HomeView.swift
//  f/Room
//
//  Intel feed: breaking hero + filter chips + news cards.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedFilter: NewsFilter = .all
    @State private var translatedIds: Set<UUID> = []
    @State private var feed = FeedClient()

    enum NewsFilter: String, CaseIterable {
        case all = "All"
        case signings = "Signings"
        case trades = "Trades"
        case injury = "Injury"
        case presser = "Presser"
        case rumor = "Rumor"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    breakingHero
                    filterChips
                    sectionLatest
                }
                .padding(.bottom, 24)
            }
            .background(FRTheme.Color.bg1)
            .refreshable {
                await feed.refresh()
            }
        }
        .task {
            await feed.refresh()
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                FRAppIcon(size: 32)
                FRoomLogo(.header)
            }
            Spacer()
            HStack(spacing: 8) {
                FRIconButton(systemName: "magnifyingglass") { }
                FRIconButton(systemName: "gearshape") { }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(FRTheme.Color.bg1)
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, FRTheme.Color.rustBright.opacity(0.4), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 1)
        }
    }

    private var newsItems: [NewsItem] {
        switch selectedFilter {
        case .all: return feed.items
        case .signings: return feed.items.filter { $0.kind == .signing }
        case .trades: return feed.items.filter { $0.kind == .trade }
        case .injury: return feed.items.filter { $0.kind == .injury }
        case .presser: return feed.items.filter { $0.kind == .presser }
        case .rumor: return feed.items.filter { $0.kind == .rumor }
        }
    }

    private var breakingHero: some View {
        let topItem = feed.items.first { $0.kind == .trade } ?? feed.items.first ?? MockData.news[0]
        return ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.110, green: 0.039, blue: 0.020),
                         Color(red: 0.024, green: 0.027, blue: 0.035)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [FRTheme.Color.rust.opacity(0.55), .clear],
                center: UnitPoint(x: 0.3, y: 0.4),
                startRadius: 0, endRadius: 220
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("BREAKING · 12 MIN AGO")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(4)
                    .foregroundColor(FRTheme.Color.rustBright)
                Text(topItem.title)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(FRTheme.Color.text0)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Text("SCHEFTER · ✓ 96% RELIABILITY")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text1)
                    .tracking(1)
            }
            .padding(22)
        }
        .frame(height: 200)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NewsFilter.allCases, id: \.self) { f in
                    FRChip(f.rawValue, isActive: selectedFilter == f) {
                        selectedFilter = f
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 14)
    }

    private var sectionLatest: some View {
        VStack(alignment: .leading, spacing: 0) {
            FRSectionHeader("Latest Intel", actionLabel: "See All →") { }
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                if feed.isLoading && feed.items.isEmpty {
                    ProgressView()
                        .tint(FRTheme.Color.rust)
                        .padding(.vertical, 40)
                }
                ForEach(newsItems) { item in
                    NewsCardView(item: item, isTranslated: translatedIds.contains(item.id)) {
                        if translatedIds.contains(item.id) {
                            translatedIds.remove(item.id)
                        } else {
                            translatedIds.insert(item.id)
                        }
                    }
                }
                if let error = feed.lastError {
                    Text("⚠️ 取得失敗: \(error)\nモックデータで表示中。")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - News Card

struct NewsCardView: View {
    let item: NewsItem
    let isTranslated: Bool
    let toggleTranslate: () -> Void

    var body: some View {
        FRCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    FRBadge(label: item.kind.displayName, kind: badgeKind)
                    Text("· \(item.teamAbbrev ?? "NFL")")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(FRTheme.Color.text2)
                    Spacer()
                }

                Text((isTranslated ? item.titleJA : item.title) ?? item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FRTheme.Color.text0)
                    .lineLimit(3)

                Text((isTranslated ? item.excerptJA : item.excerpt) ?? item.excerpt)
                    .font(.system(size: 13))
                    .foregroundColor(FRTheme.Color.text1)
                    .lineLimit(4)

                Divider().background(FRTheme.Color.line)

                HStack {
                    Circle().fill(FRTheme.Color.good).frame(width: 6, height: 6)
                    Text(item.sources.joined(separator: " · "))
                        .font(.system(size: 11))
                        .foregroundColor(FRTheme.Color.text2)
                        .lineLimit(1)
                    Spacer()
                    Text("✓ \(Int(item.reliability * 100))%")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text2)
                }

                HStack(spacing: 6) {
                    actionButton(systemName: "globe", label: "和訳", isActive: isTranslated, action: toggleTranslate)
                    actionButton(systemName: "star", label: "保存", isActive: false) { }
                    actionButton(systemName: "square.and.arrow.up", label: "共有", isActive: false) { }
                    Spacer()
                }
            }
        }
    }

    private func actionButton(systemName: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemName).font(.system(size: 11))
                Text(label).font(.system(size: 10, weight: .semibold)).tracking(1).textCase(.uppercase)
            }
            .foregroundColor(isActive ? .white : FRTheme.Color.text1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? FRTheme.Color.rust : FRTheme.Color.bg3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isActive ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var badgeKind: FRBadgeKind {
        switch item.kind {
        case .signing: return .signing
        case .trade: return .trade
        case .injury: return .injury
        case .presser: return .presser
        case .rumor: return .rumor
        case .other: return .neutral
        }
    }
}

#if DEBUG
#Preview {
    HomeView()
        .background(FRTheme.Color.bg1)
        .preferredColorScheme(.dark)
}
#endif
