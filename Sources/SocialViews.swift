// SocialViews.swift
// Challenge-a-friend share card + the Game Center dashboard sheet.
//
// CHALLENGES: Apple deprecated programmatic GKScoreChallenge issuing, so
// "Challenge a Friend" shares a distance card through the iOS share sheet
// instead. The card is rendered to an image with ImageRenderer and shared
// via ShareLink, so the player can send it to a friend over Messages,
// social, or anywhere else. The Game Center dashboard sheet opens the
// system leaderboard, where the player can use iOS 26 Challenges directly.

import SwiftUI
import GameKit
import UIKit

// MARK: - Share card (rendered to an image for the share sheet)

/// A bold, readable card for a single hit: who hit it, how far, and a dare.
/// Rendered at 3x with ImageRenderer, then shared as an image.
struct ShareCardView: View {
    let distance: Int
    let sluggerName: String
    let seasonTitle: String

    var body: some View {
        VStack(spacing: 10) {
            Text("HOW FAR CAN YOU HIT IT?")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color.white)
            Text(sluggerName)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.yellow)
            Text("hit it \(distance) feet!")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(Color.white)
            Text("Season: \(seasonTitle)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))
            Text("Can you beat that?")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.top, 4)
        }
        .padding(28)
        .frame(width: 340)
        .background(
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.35, blue: 0.85),
                         Color(red: 0.10, green: 0.20, blue: 0.55)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(24)
    }
}

/// Render a share card to a UIImage, or nil if rendering fails.
@MainActor
func renderShareCard(distance: Int, sluggerName: String, seasonTitle: String) -> UIImage? {
    let view = ShareCardView(distance: distance, sluggerName: sluggerName, seasonTitle: seasonTitle)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3.0
    return renderer.uiImage
}

// MARK: - Game Center dashboard (system leaderboard + Challenges)

/// Presents Game Center's own leaderboard dashboard as a sheet. The player
/// can browse the board, see friends, and use the system's challenge UI
/// (including iOS 26 Challenges) from there.
struct GameCenterDashboardView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController(state: .leaderboards)
        vc.leaderboardIdentifier = GameCenterManager.leaderboardID
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
