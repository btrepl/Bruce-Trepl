// GameCenterManager.swift
// Global + friends leaderboards for "How Far Can You Hit It?"
//
// CURRENT STATE: local leaderboard only (GameState stores the top 20 hits
// on-device). This manager is the integration point for Apple's Game Center:
// authentication is wired up, submitScore() calls the real Game Center API
// whenever the player is signed in, and loadLeaderboards() pulls the
// friends-only and global boards into the app. Until a Game Center
// leaderboard is created in App Store Connect, scores simply stay local
// and nothing breaks.
//
// CHALLENGES: Apple deprecated programmatic GKScoreChallenge issuing, so
// this game does NOT issue challenges in code. Instead, "Challenge a
// Friend" shares a distance card through the iOS share sheet (Messages,
// social, etc.), and the in-app Game Center dashboard button opens the
// system leaderboard where the player can use iOS 26 Challenges directly.
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

    /// Friends-only leaderboard entries (Game Center), newest load.
    @Published private(set) var friendsEntries: [GKLeaderboard.Entry] = []
    /// Global leaderboard entries (Game Center), newest load.
    @Published private(set) var globalEntries: [GKLeaderboard.Entry] = []
    /// True while a leaderboard load is in flight.
    @Published private(set) var isLoadingBoards = false
    /// Human-readable reason the boards could not load, if any.
    @Published private(set) var boardsError: String?

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

    /// Load the friends-only and global leaderboard entries. Safe to call
    /// when not signed in — it just sets boardsError and leaves the
    /// entries empty, so the app falls back to the local board.
    func loadLeaderboards() async {
        guard isAuthenticated else {
            boardsError = "Sign in to Game Center to see the friends board."
            return
        }
        isLoadingBoards = true
        boardsError = nil
        defer { isLoadingBoards = false }
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID])
            guard let board = leaderboards.first else {
                boardsError = "Leaderboard not set up yet."
                return
            }
            let (_, friends, _) = try await board.loadEntries(
                for: .friendsOnly, timeScope: .allTime,
                range: NSRange(location: 1, length: 25))
            let (_, global, _) = try await board.loadEntries(
                for: .global, timeScope: .allTime,
                range: NSRange(location: 1, length: 25))
            friendsEntries = friends
            globalEntries = global
        } catch {
            boardsError = "Could not load the boards right now."
            print("Game Center load failed: \(error.localizedDescription)")
        }
    }
}
