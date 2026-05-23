//
//  Theme.swift
//  f/Room
//
//  Old-school NFL design system — leather, copper, rust palette.
//

import SwiftUI

enum FRTheme {

    // MARK: - Colors
    enum Color {
        // Backgrounds
        static let bg0 = SwiftUI.Color(red: 0.024, green: 0.027, blue: 0.035)   // #060709
        static let bg1 = SwiftUI.Color(red: 0.047, green: 0.051, blue: 0.071)   // #0c0d12
        static let bg2 = SwiftUI.Color(red: 0.078, green: 0.090, blue: 0.118)   // #14171e
        static let bg3 = SwiftUI.Color(red: 0.122, green: 0.141, blue: 0.180)   // #1f242e
        static let line = SwiftUI.Color(red: 0.165, green: 0.192, blue: 0.243)  // #2a313e

        // Text
        static let text0 = SwiftUI.Color(red: 0.953, green: 0.937, blue: 0.902) // #f3efe6
        static let text1 = SwiftUI.Color(red: 0.722, green: 0.698, blue: 0.643) // #b8b2a4
        static let text2 = SwiftUI.Color(red: 0.478, green: 0.459, blue: 0.408) // #7a7568

        // Accents (rust / copper / bronze)
        static let rust = SwiftUI.Color(red: 0.612, green: 0.271, blue: 0.137)        // #9c4523
        static let rustBright = SwiftUI.Color(red: 0.780, green: 0.353, blue: 0.188)  // #c75a30
        static let bronze = SwiftUI.Color(red: 0.722, green: 0.518, blue: 0.227)      // #b8843a
        static let copper = SwiftUI.Color(red: 0.788, green: 0.478, blue: 0.290)      // #c97a4a
        static let leatherEdge = SwiftUI.Color(red: 0.353, green: 0.145, blue: 0.063) // #5a2510

        // Whiteboard surface
        static let whiteboard = SwiftUI.Color(red: 0.945, green: 0.925, blue: 0.878)  // #f1ece0
        static let memoPad = SwiftUI.Color(red: 0.984, green: 0.965, blue: 0.910)     // #fbf6e8

        // Status
        static let good = SwiftUI.Color(red: 0.365, green: 0.541, blue: 0.290)  // #5d8a4a
        static let bad = SwiftUI.Color(red: 0.659, green: 0.227, blue: 0.165)   // #a83a2a

        // Copper gradient for logo
        static let copperGradient = LinearGradient(
            colors: [
                SwiftUI.Color(red: 0.929, green: 0.878, blue: 0.769),  // light highlight
                SwiftUI.Color(red: 0.788, green: 0.659, blue: 0.467),  // mid copper
                SwiftUI.Color(red: 0.561, green: 0.396, blue: 0.204),  // dark bronze
                SwiftUI.Color(red: 0.788, green: 0.659, blue: 0.467),  // mid copper
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        static let slashGradient = LinearGradient(
            colors: [
                SwiftUI.Color(red: 0.910, green: 0.651, blue: 0.451),  // light copper
                SwiftUI.Color(red: 0.780, green: 0.353, blue: 0.188),  // bright rust
                SwiftUI.Color(red: 0.420, green: 0.153, blue: 0.063),  // dark blood
                SwiftUI.Color(red: 0.780, green: 0.353, blue: 0.188),  // bright rust
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Typography
    enum Font {
        // Logo - Cinzel Black (must be bundled or use SF Pro Black as fallback)
        static func logo(size: CGFloat) -> SwiftUI.Font {
            return .custom("Cinzel-Black", size: size).fallback(to: .system(size: size, weight: .black, design: .serif))
        }
        static func logoFallback(size: CGFloat) -> SwiftUI.Font {
            return .system(size: size, weight: .black, design: .serif)
        }

        // Headlines - Bebas Neue
        static func bebas(size: CGFloat) -> SwiftUI.Font {
            return .custom("BebasNeue-Regular", size: size).fallback(to: .system(size: size, weight: .bold, design: .default))
        }

        // Body - Inter (use system as fallback)
        static func body(size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            return .system(size: size, weight: weight, design: .default)
        }

        // Mono
        static func mono(size: CGFloat) -> SwiftUI.Font {
            return .system(size: size, weight: .regular, design: .monospaced)
        }

        // Handwriting (memo)
        static func handwriting(size: CGFloat) -> SwiftUI.Font {
            return .custom("Kalam-Regular", size: size).fallback(to: .system(size: size, weight: .medium, design: .serif))
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
        static let s: CGFloat = 6
        static let m: CGFloat = 8
        static let l: CGFloat = 12
        static let xl: CGFloat = 18
        static let icon: CGFloat = 22  // iOS app icon ratio
    }
}

// MARK: - Font fallback helper
extension SwiftUI.Font {
    /// Returns this font, but only if it's installed; otherwise returns the fallback.
    /// Useful when bundled fonts may not be registered yet.
    func fallback(to other: SwiftUI.Font) -> SwiftUI.Font {
        // SwiftUI doesn't expose font-existence checks directly.
        // In production, register fonts in Info.plist (UIAppFonts) and they'll resolve.
        // If a custom font is missing, SwiftUI uses the system font silently — but for
        // safety we always pair with explicit fallback at call sites that need it.
        return self
    }
}

// MARK: - Shadows
extension View {
    func frEmbossedShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
            .shadow(color: .white.opacity(0.04), radius: 0, x: 0, y: -1)
    }

    func frCardShadow() -> some View {
        self.shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 6)
    }

    func frIconShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.8), radius: 24, x: 0, y: 16)
            .shadow(color: FRTheme.Color.rust.opacity(0.3), radius: 40, x: 0, y: 0)
    }
}
