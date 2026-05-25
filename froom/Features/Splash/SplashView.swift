//
//  SplashView.swift
//  Redzone Tracker — The Sideline View
//
//  Launch screen: stadium spotlight + animated wordmark + scan-line loader.
//

import SwiftUI

struct SplashView: View {
    @State private var spotPulse: CGFloat = 1.0
    @State private var loaderPosition: CGFloat = -1.0
    @State private var revealOffset: CGFloat = -8

    var body: some View {
        ZStack {
            // Deep stadium background
            FRTheme.Color.stadiumGradient
                .ignoresSafeArea()

            // Pulsing red spotlight
            RadialGradient(
                colors: [FRTheme.Color.rzRed.opacity(0.30), .clear],
                center: UnitPoint(x: 0.5, y: 0.45),
                startRadius: 0, endRadius: 320
            )
            .scaleEffect(spotPulse)
            .ignoresSafeArea()

            // Subtle field-line texture (horizontal yard markers)
            VStack(spacing: 60) {
                ForEach(0..<6) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.025))
                        .frame(height: 1)
                }
            }
            .ignoresSafeArea()

            // Logo column
            VStack(spacing: 32) {
                // Red zone pylon icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(FRTheme.Color.logoGradient)
                        .frame(width: 80, height: 80)
                        .frIconShadow()
                    // pylon corner accent
                    VStack(spacing: 0) {
                        Rectangle().fill(Color.white.opacity(0.18)).frame(height: 24)
                        Spacer()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    // RZT mark
                    HStack(spacing: 0) {
                        Text("RZT")
                            .font(FRTheme.Font.logoFallback(size: 32))
                            .foregroundColor(.white)
                            .tracking(2)
                    }
                }
                .offset(y: revealOffset)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: revealOffset)

                RZTLogo(style: .stacked, size: .headline, showsSubtitle: true)
            }

            // Bottom scan-line loader
            VStack {
                Spacer()
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                        .frame(width: 140, height: 2)
                    LinearGradient(
                        colors: [.clear, FRTheme.Color.rzRedBright, .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: 56, height: 2)
                    .offset(x: loaderPosition * 140)
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            revealOffset = 4
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                spotPulse = 1.1
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) {
                loaderPosition = 1.4
            }
        }
    }
}

#if DEBUG
#Preview {
    SplashView()
}
#endif
