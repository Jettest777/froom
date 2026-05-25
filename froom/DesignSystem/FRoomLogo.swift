//
//  RZTLogo.swift
//  Redzone Tracker — The Sideline View
//
//  Brand wordmark with two readings:
//    1. Two-line stacked (REDZONE / TRACKER) — used in splash and headers
//    2. Single-line inline                    — used when horizontal space is tight
//
//  Design motif:
//    - Tight letter spacing, modern sans-serif (Inter Black fallback)
//    - "REDZONE" rendered in red gradient
//    - "TRACKER" rendered in white with subtle grey tint
//    - Red vertical bar separator (evokes yard markers / pylon)
//
//  Subtitle: "THE SIDELINE VIEW" — letter-spaced caps in muted text.
//

import SwiftUI

struct RZTLogo: View {
    enum Style {
        /// Two-line stacked: REDZONE / TRACKER. Use for splash, settings.
        case stacked
        /// Single-line: REDZONE • TRACKER. Use for nav bars.
        case inline
        /// Compact: just "RZT" mark for tiny spaces.
        case mark
    }

    enum Size {
        case hero        // splash / marketing
        case headline    // page hero
        case header      // nav bar
        case caption     // small captions

        var primary: CGFloat {
            switch self {
            case .hero: return 56
            case .headline: return 40
            case .header: return 22
            case .caption: return 14
            }
        }

        var subtitleSize: CGFloat {
            switch self {
            case .hero: return 12
            case .headline: return 10
            case .header: return 8
            case .caption: return 7
            }
        }

        var tracking: CGFloat {
            switch self {
            case .hero: return 6
            case .headline: return 5
            case .header: return 3
            case .caption: return 2
            }
        }
    }

    let style: Style
    let size: Size
    let showsSubtitle: Bool

    init(style: Style = .stacked, size: Size = .header, showsSubtitle: Bool = false) {
        self.style = style
        self.size = size
        self.showsSubtitle = showsSubtitle
    }

    var body: some View {
        switch style {
        case .stacked:
            stackedLayout
        case .inline:
            inlineLayout
        case .mark:
            markLayout
        }
    }

    // MARK: - Stacked (REDZONE / TRACKER)

    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("REDZONE")
                    .font(FRTheme.Font.logoFallback(size: size.primary))
                    .tracking(size.tracking)
                    .foregroundStyle(FRTheme.Color.logoGradient)
                    .shadow(color: FRTheme.Color.rzRed.opacity(0.4), radius: 12, x: 0, y: 0)
            }
            HStack(alignment: .center, spacing: 8) {
                Rectangle()
                    .fill(FRTheme.Color.rzRed)
                    .frame(width: size.primary * 0.06, height: size.primary * 0.7)
                Text("TRACKER")
                    .font(FRTheme.Font.logoFallback(size: size.primary * 0.78))
                    .tracking(size.tracking * 1.1)
                    .foregroundColor(FRTheme.Color.text0)
            }
            if showsSubtitle {
                Text("THE SIDELINE VIEW")
                    .font(.system(size: size.subtitleSize, weight: .semibold))
                    .tracking(size.tracking * 1.4)
                    .foregroundColor(FRTheme.Color.text1)
                    .padding(.top, size.primary * 0.12)
            }
        }
    }

    // MARK: - Inline (REDZONE | TRACKER)

    private var inlineLayout: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text("REDZONE")
                    .font(FRTheme.Font.logoFallback(size: size.primary))
                    .tracking(size.tracking)
                    .foregroundStyle(FRTheme.Color.logoGradient)
                Rectangle()
                    .fill(FRTheme.Color.rzRed)
                    .frame(width: 3, height: size.primary * 0.75)
                Text("TRACKER")
                    .font(FRTheme.Font.logoFallback(size: size.primary))
                    .tracking(size.tracking)
                    .foregroundColor(FRTheme.Color.text0)
            }
            if showsSubtitle {
                Text("THE SIDELINE VIEW")
                    .font(.system(size: size.subtitleSize, weight: .semibold))
                    .tracking(size.tracking * 1.4)
                    .foregroundColor(FRTheme.Color.text1)
            }
        }
    }

    // MARK: - Mark (RZT)

    private var markLayout: some View {
        HStack(spacing: 1) {
            Text("R").foregroundStyle(FRTheme.Color.logoGradient)
            Text("Z").foregroundStyle(FRTheme.Color.logoGradient)
            Text("T").foregroundColor(FRTheme.Color.text0)
        }
        .font(FRTheme.Font.logoFallback(size: size.primary))
        .tracking(size.tracking * 0.5)
    }
}

// MARK: - Legacy alias for incremental migration

/// @deprecated. Use RZTLogo instead. Kept temporarily so older code keeps building.
struct FRoomLogo: View {
    enum Size {
        case header, splash, hero
        case custom(CGFloat)
    }

    let size: Size

    init(_ size: Size = .header) {
        self.size = size
    }

    var body: some View {
        switch size {
        case .header:
            RZTLogo(style: .inline, size: .header, showsSubtitle: false)
        case .splash:
            RZTLogo(style: .stacked, size: .headline, showsSubtitle: true)
        case .hero:
            RZTLogo(style: .stacked, size: .hero, showsSubtitle: true)
        case .custom(let s):
            // Map custom size to closest preset
            if s >= 50 {
                RZTLogo(style: .stacked, size: .hero, showsSubtitle: true)
            } else if s >= 30 {
                RZTLogo(style: .stacked, size: .headline, showsSubtitle: false)
            } else {
                RZTLogo(style: .inline, size: .header, showsSubtitle: false)
            }
        }
    }
}

#if DEBUG
#Preview("Logo Variants") {
    VStack(alignment: .leading, spacing: 32) {
        RZTLogo(style: .stacked, size: .hero, showsSubtitle: true)
        RZTLogo(style: .stacked, size: .headline, showsSubtitle: true)
        RZTLogo(style: .inline, size: .header, showsSubtitle: false)
        RZTLogo(style: .mark, size: .headline, showsSubtitle: false)
    }
    .padding(40)
    .background(FRTheme.Color.bg0)
    .preferredColorScheme(.dark)
}
#endif
