//
//  FRComponents.swift
//  f/Room
//
//  Shared UI components used across screens.
//

import SwiftUI

// MARK: - Section Header

struct FRSectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionLabel: String?

    init(_ title: String, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .heavy))
                .tracking(2)
                .foregroundColor(FRTheme.Color.text0)
            Spacer()
            if let label = actionLabel {
                Button(action: { action?() }) {
                    Text(label.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(FRTheme.Color.rustBright)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
        .padding(.top, 14)
        .padding(.bottom, 12)
    }
}

// MARK: - Pill / Chip

struct FRChip: View {
    let label: String
    let isActive: Bool
    let action: (() -> Void)?

    init(_ label: String, isActive: Bool = false, action: (() -> Void)? = nil) {
        self.label = label
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: { action?() }) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundColor(isActive ? FRTheme.Color.text0 : FRTheme.Color.text1)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isActive ? FRTheme.Color.rust : .clear)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isActive ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Badge

enum FRBadgeKind {
    case neutral, signing, injury, trade, presser, rumor

    var bg: Color {
        switch self {
        case .neutral: return FRTheme.Color.rust
        case .signing: return FRTheme.Color.bronze
        case .injury: return FRTheme.Color.bad
        case .trade: return FRTheme.Color.rust
        case .presser: return FRTheme.Color.text1
        case .rumor: return FRTheme.Color.bg3
        }
    }

    var fg: Color {
        switch self {
        case .signing: return Color(red: 0.1, green: 0.07, blue: 0)
        case .presser: return Color(red: 0.1, green: 0.08, blue: 0.06)
        default: return FRTheme.Color.text0
        }
    }
}

struct FRBadge: View {
    let label: String
    let kind: FRBadgeKind

    var body: some View {
        Text(label.uppercased())
            .font(.system(size: 9, weight: .heavy))
            .tracking(1)
            .foregroundColor(kind.fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 3).fill(kind.bg))
    }
}

// MARK: - Icon Button (header)

struct FRIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(FRTheme.Color.text1)
                .frame(width: 36, height: 36)
                .background(FRTheme.Color.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        }
    }
}

// MARK: - App Icon view (small)

struct FRAppIcon: View {
    let size: CGFloat

    var body: some View {
        Image("AppIcon-Display")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Tab Bar

enum FRTab: String, CaseIterable {
    case news = "News"
    case games = "Game"
    case teams = "Team"
    case notes = "Note"

    var systemImage: String {
        switch self {
        case .news: return "newspaper.fill"
        case .games: return "football.fill"
        case .teams: return "shield.fill"
        case .notes: return "pencil.tip.crop.circle"
        }
    }
}

struct FRTabBar: View {
    @Binding var selection: FRTab

    var body: some View {
        HStack {
            ForEach(FRTab.allCases, id: \.self) { tab in
                Button(action: { selection = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .regular))
                        Text(tab.rawValue.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                    }
                    .foregroundColor(selection == tab ? FRTheme.Color.rustBright : FRTheme.Color.text2)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(FRTheme.Color.line).frame(height: 1)
        }
    }
}

// MARK: - Card

struct FRCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                LinearGradient(colors: [FRTheme.Color.bg2, FRTheme.Color.bg1], startPoint: .top, endPoint: .bottom)
            )
            .overlay(alignment: .leading) {
                Rectangle().fill(FRTheme.Color.rust).frame(width: 2)
            }
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
