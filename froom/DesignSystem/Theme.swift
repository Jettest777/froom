//
//  Theme.swift
//  Redzone Tracker — The Sideline View
//
//  Brand identity: NFL stadium energy.
//    • Red Zone Red: sharp, urgent, decisive
//    • End Zone Gold: spotlight, premium moments
//    • Electric Blue: data, analysis, "scout view"
//    • Midnight ink: deep dark for contrast
//
//  Typography: Inter for legibility, Bebas Neue for stadium headers,
//  JetBrains Mono for stats / clocks.
//

import SwiftUI

enum FRTheme {

    // MARK: - Colors
    enum Color {
        // Background scale — deep midnight blue-black with a slight cool tint
        static let bg0 = SwiftUI.Color(red: 0.039, green: 0.039, blue: 0.058)   // #0A0A0F
        static let bg1 = SwiftUI.Color(red: 0.063, green: 0.067, blue: 0.094)   // #101118
        static let bg2 = SwiftUI.Color(red: 0.094, green: 0.102, blue: 0.137)   // #181A23
        static let bg3 = SwiftUI.Color(red: 0.137, green: 0.145, blue: 0.184)   // #23252F
        static let line = SwiftUI.Color(red: 0.196, green: 0.204, blue: 0.247)  // #32343F

        // Text
        static let text0 = SwiftUI.Color(red: 0.980, green: 0.980, blue: 0.992) // #FAFAFD
        static let text1 = SwiftUI.Color(red: 0.737, green: 0.745, blue: 0.808) // #BCBECF
        static let text2 = SwiftUI.Color(red: 0.471, green: 0.475, blue: 0.541) // #787A8A

        // Primary — Red Zone Red
        static let rzRed = SwiftUI.Color(red: 0.863, green: 0.149, blue: 0.149)         // #DC2626
        static let rzRedBright = SwiftUI.Color(red: 0.957, green: 0.275, blue: 0.275)   // #F44646
        static let rzRedDeep = SwiftUI.Color(red: 0.604, green: 0.090, blue: 0.090)     // #9A1717

        // Accent — End Zone Gold
        static let ezGold = SwiftUI.Color(red: 0.984, green: 0.749, blue: 0.141)        // #FBBF24
        static let ezGoldDeep = SwiftUI.Color(red: 0.706, green: 0.475, blue: 0.071)    // #B47912

        // Secondary — Electric Blue (data accents)
        static let elecBlue = SwiftUI.Color(red: 0.220, green: 0.741, blue: 0.973)      // #38BDF8
        static let elecBlueDeep = SwiftUI.Color(red: 0.118, green: 0.388, blue: 0.737)  // #1E63BC

        // Status
        static let good = SwiftUI.Color(red: 0.133, green: 0.776, blue: 0.369)  // #22C55E
        static let bad = SwiftUI.Color(red: 0.937, green: 0.267, blue: 0.267)   // #EF4444
        static let warning = SwiftUI.Color(red: 0.961, green: 0.620, blue: 0.043)  // #F59E0B

        // Whiteboard surfaces (kept for canvas)
        static let whiteboard = SwiftUI.Color(red: 0.969, green: 0.973, blue: 0.980)  // #F7F8FA
        static let memoPad = SwiftUI.Color(red: 0.992, green: 0.992, blue: 0.957)     // #FDFDF4

        // MARK: - Legacy aliases (keep older code building while we transition)
        /// @deprecated: use rzRed
        static let rust = rzRed
        /// @deprecated: use rzRedBright
        static let rustBright = rzRedBright
        /// @deprecated: use rzRedDeep
        static let leatherEdge = rzRedDeep
        /// @deprecated: use ezGold
        static let bronze = ezGold
        /// @deprecated: use ezGoldDeep
        static let copper = ezGoldDeep

        // MARK: - Gradients

        /// Hero gradient used for splash + key visuals
        static let stadiumGradient = LinearGradient(
            colors: [
                SwiftUI.Color(red: 0.024, green: 0.024, blue: 0.039),
                SwiftUI.Color(red: 0.169, green: 0.024, blue: 0.024)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Sharp red gradient for the wordmark
        static let logoGradient = LinearGradient(
            colors: [
                SwiftUI.Color(red: 0.969, green: 0.376, blue: 0.376),
                SwiftUI.Color(red: 0.863, green: 0.149, blue: 0.149),
                SwiftUI.Color(red: 0.498, green: 0.063, blue: 0.063)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        /// Gold spotlight gradient for highlights
        static let goldGradient = LinearGradient(
            colors: [
                SwiftUI.Color(red: 1.000, green: 0.851, blue: 0.376),
                SwiftUI.Color(red: 0.984, green: 0.749, blue: 0.141),
                SwiftUI.Color(red: 0.706, green: 0.475, blue: 0.071)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        /// Legacy gradient names (still referenced by older code)
        static let copperGradient = logoGradient
        static let slashGradient = logoGradient
    }

    // MARK: - Typography
    enum Font {
        /// Headline display — Bebas Neue (stadium feel)
        static func bebas(size: CGFloat) -> SwiftUI.Font {
            .custom("BebasNeue-Regular", size: size)
        }

        /// Logo wordmark — Inter Black (tight, bold, modern). Falls back gracefully.
        static func logoFallback(size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .black, design: .default)
        }

        /// Body / UI — Inter
        static func body(size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }

        /// Numbers / stats / clocks
        static func mono(size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        /// Handwritten memo
        static func handwriting(size: CGFloat) -> SwiftUI.Font {
            .custom("Kalam-Regular", size: size)
        }
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Radius
    enum Radius {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let icon: CGFloat = 22
    }
}

// MARK: - Shadow modifiers

extension View {
    func frEmbossedShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
            .shadow(color: .white.opacity(0.05), radius: 0, x: 0, y: -1)
    }

    func frCardShadow() -> some View {
        self.shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
    }

    func frIconShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.8), radius: 24, x: 0, y: 16)
            .shadow(color: FRTheme.Color.rzRed.opacity(0.35), radius: 50, x: 0, y: 0)
    }

    /// Stadium spotlight glow — useful behind hero elements
    func frSpotlight() -> some View {
        self
            .background(
                RadialGradient(
                    colors: [FRTheme.Color.rzRed.opacity(0.25), .clear],
                    center: .center, startRadius: 0, endRadius: 200
                )
            )
    }
}
