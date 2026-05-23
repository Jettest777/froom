//
//  FRoomLogo.swift
//  f/Room
//
//  The brand wordmark: F/ROOM rendered in copper gradient + slanted rust slash.
//  Matches the embossed leather feel of the app icon.
//

import SwiftUI

struct FRoomLogo: View {
    enum Size {
        case header   // small, used in nav bars (~26pt)
        case splash   // medium, splash screen (~52pt)
        case hero     // large, marketing / settings (~64pt)
        case custom(CGFloat)

        var fontSize: CGFloat {
            switch self {
            case .header: return 26
            case .splash: return 52
            case .hero: return 64
            case .custom(let s): return s
            }
        }

        var letterSpacing: CGFloat {
            switch self {
            case .header: return 1.5
            default: return 2
            }
        }
    }

    let size: Size

    init(_ size: Size = .header) {
        self.size = size
    }

    var body: some View {
        HStack(spacing: 0) {
            letter("F")
            slash
            letter("R")
            letter("O")
            letter("O")
            letter("M")
        }
    }

    // MARK: - Letters

    private func letter(_ char: String) -> some View {
        Text(char)
            .font(FRTheme.Font.logoFallback(size: size.fontSize))
            .tracking(size.letterSpacing)
            .foregroundStyle(FRTheme.Color.copperGradient)
            .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
            .shadow(color: .white.opacity(0.06), radius: 0, x: 0, y: 1)
    }

    private var slash: some View {
        Text("/")
            .font(FRTheme.Font.logoFallback(size: size.fontSize * 1.0).italic())
            .foregroundStyle(FRTheme.Color.slashGradient)
            .rotationEffect(.degrees(-4))
            .padding(.horizontal, -size.fontSize * 0.04)
            .shadow(color: FRTheme.Color.rustBright.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Logo Sizes") {
    VStack(spacing: 24) {
        FRoomLogo(.hero)
        FRoomLogo(.splash)
        FRoomLogo(.header)
        FRoomLogo(.custom(40))
    }
    .padding(40)
    .background(FRTheme.Color.bg0)
}
#endif
