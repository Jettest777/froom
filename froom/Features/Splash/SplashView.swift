//
//  SplashView.swift
//  f/Room
//
//  Launch screen. Icon floats softly while loader scans below.
//

import SwiftUI

struct SplashView: View {
    @State private var iconFloat: CGFloat = 0
    @State private var loaderPosition: CGFloat = -1.0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.051, green: 0.055, blue: 0.078),
                         Color(red: 0.024, green: 0.027, blue: 0.035)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Radial glow
            RadialGradient(
                colors: [FRTheme.Color.rust.opacity(0.18), .clear],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0, endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {
                FRAppIcon(size: 168)
                    .offset(y: iconFloat)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: iconFloat)

                VStack(spacing: 18) {
                    FRoomLogo(.splash)

                    HStack(spacing: 0) {
                        Text("FILM")
                        Text("  |  ").foregroundColor(FRTheme.Color.rustBright)
                        Text("FOCUS")
                        Text("  |  ").foregroundColor(FRTheme.Color.rustBright)
                        Text("FUNDAMENTAL")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(4)
                    .foregroundColor(FRTheme.Color.text1)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }

            // Loader
            VStack {
                Spacer()
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                        .frame(width: 120, height: 2)
                    LinearGradient(
                        colors: [.clear, FRTheme.Color.rustBright, .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: 48, height: 2)
                    .offset(x: loaderPosition * 120)
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            iconFloat = -6
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
