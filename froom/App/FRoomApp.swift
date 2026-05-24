//
//  FRoomApp.swift
//  f/Room
//
//  Application entry point. Sets up SwiftData container and splash → root flow.
//

import SwiftUI
import SwiftData

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
        .modelContainer(for: [ScoutNote.self])  // SwiftData container for canvas notes
    }
}

// MARK: - RootView (tab navigation)

struct RootView: View {
    @State private var selectedTab: FRTab = .news

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
        case .news:
            HomeView()
        case .games:
            GameTabView()
        case .teams:
            TeamsView()
        case .notes:
            NotebookView()
        }
    }
}
