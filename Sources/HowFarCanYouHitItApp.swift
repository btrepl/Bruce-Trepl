// HowFarCanYouHitItApp.swift
// App entry point for "How Far Can You Hit It?"
// Target: iOS 17+, Xcode 15+.
//
// SETUP: Create a new iOS App project in Xcode (SwiftUI interface, Swift
// language), delete the template's ContentView.swift and <ProjectName>App.swift,
// then add every .swift file in Sources/ to the project target. This file
// provides the @main entry point, so do not keep a second @main struct.

import SwiftUI

@main
struct HowFarCanYouHitItApp: App {
    @StateObject private var gameState = GameState()
    @StateObject private var store = StoreManager()
    @StateObject private var gameCenter = GameCenterManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .environmentObject(store)
                .environmentObject(gameCenter)
                .onAppear {
                    gameCenter.authenticate()
                    Task {
                        await store.restorePurchases()
                        gameState.setRemoveAdsUnlocked(store.removeAdsUnlocked)
                    }
                }
        }
    }
}
