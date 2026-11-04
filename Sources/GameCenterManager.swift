// GameCenterManager.swift
// Global leaderboard for "How Far Can You Hit It?"
//
// CURRENT STATE: local leaderboard only (GameState stores the top 20 hits
// on-device). This manager is the integration point for Apple's Game Center:
// authentication is wired up, and submitScore() calls the real Game Center
// API whenever the player is signed in. Until a Game Center leaderboard is
// created in App Store Connect, scores simply stay local and nothing breaks.
//
// TO GO LIVE:
//   1. Enable Game Center in the App ID / Xcode Signing & Capabilities.
//   2. Create a leaderboard in App Store Connect with this ID:
//        com.tntfamily.howfar.leaderboard
//   3. Set leaderboardID below to match (it already does).
//   4. Test with a sandbox Game Center account in TestFlight.

import SwiftUI
import GameKit
import UIKit

@MainActor
final class GameCenterManager: ObservableObject {
    /// Must match the leaderboard ID in App Store Connect.
    static let leaderboardID = "com.tntfamily.howfar.leaderboard"

    @Published private(set) var isAuthenticated = false
    @Published private(set) var playerName = "You"

    /// Sign the player into Game Center. If Game Center is unavailable or
    /// the player declines, the game keeps working with local scores.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            Task { @MainActor in
                if let viewController {
                    // Present Game Center's sign-in sheet from the key window.
                    let root = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .flatMap { $0.windows }
                        .first { $0.isKeyWindow }?.rootViewController
                    root?.present(viewController, animated: true)
                    return
                }
                if GKLocalPlayer.local.isAuthenticated {
                    self.isAuthenticated = true
                    self.playerName = GKLocalPlayer.local.displayName
                } else {
                    self.isAuthenticated = false
                    if let error {
                        print("Game Center sign-in unavailable: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// Submit a hit distance to the global leaderboard. Safe to call even
    /// when Game Center is not configured or the player is not signed in —
    /// in those cases the score stays local only.
    func submitScore(_ distance: Int) async {
        guard isAuthenticated else { return }
        do {
            try await GKLeaderboard.submitScore(
                distance,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [Self.leaderboardID]
            )
        } catch {
            // A failed submit must never break the game; local scores remain.
            print("Game Center submit failed: \(error.localizedDescription)")
        }
    }
}
