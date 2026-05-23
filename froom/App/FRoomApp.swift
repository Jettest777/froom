//
//  FRoomApp.swift
//  f/Room
//
//  Application entry point.
//

import SwiftUI

@main
struct FRoomApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                FRTheme.Color.bg0.ignoresSafeArea()
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .onAppear {
                            // Auto-dismiss splash after 1.6s
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    RootView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - RootView (tab navigation)

struct RootView: View {
    @State private var selectedTab: FRTab = .home

    var body: some View {
        VStack(spacing: 0) {
            TabContent(tab: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            FRTabBar(selection: $selectedTab)
        }
        .background(FRTheme.Color.bg1)
    }
}

struct TabContent: View {
    let tab: FRTab

    var body: some View {
        switch tab {
        case .home:
            HomeView()
        case .teams:
            TeamsView()
        case .coach:
            CoachTreeView()
        case .notes:
            NotebookView()
        }
    }
}
