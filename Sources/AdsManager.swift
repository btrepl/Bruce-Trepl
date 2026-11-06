// AdsManager.swift
// Rewarded ads (Google AdMob) for "How Far Can You Hit It?"
//
// A rewarded ad grants +5 ranked swings. The player watches only when
// they choose to — ads never interrupt play, and Remove Ads ($4.99)
// hides the ad buttons entirely.
//
// ADMOB SETUP (Bruce): the ad unit ID below is Google's OFFICIAL TEST
// rewarded ID, so the button works in TestFlight with test ads. To go
// live with real ads:
//   1. Create an AdMob account and an app in AdMob.
//   2. Create a Rewarded ad unit and copy its ad unit ID.
//   3. Replace `rewardedAdUnitID` below with the real ID.
//   4. Replace the `GADApplicationIdentifier` build setting in the Xcode
//      project (INFOPLIST_KEY_GADApplicationIdentifier) with the real
//      AdMob app ID.
// Until then, test ads serve and no real revenue is earned.

import SwiftUI
import GoogleMobileAds
import UIKit

@MainActor
final class AdsManager: NSObject, ObservableObject {
    /// Google's official test rewarded ad unit ID (iOS). Replace with the
    /// real AdMob ad unit ID before submitting for real revenue.
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// True when a rewarded ad is loaded and ready to show.
    @Published private(set) var isAdReady = false
    /// True while a rewarded ad is on screen.
    @Published private(set) var isShowingAd = false

    private var rewardedAd: GADRewardedAd?
    private var rewardHandler: (() -> Void)?

    /// Start the AdMob SDK and preload the first rewarded ad.
    func start() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loadRewardedAd()
    }

    /// Preload a rewarded ad. Called at start and after each ad dismisses.
    func loadRewardedAd() {
        GADRewardedAd.load(withAdUnitID: Self.rewardedAdUnitID, request: GADRequest()) { [weak self] ad, error in
            // The load callback is a Sendable closure, so hop back to the
            // main actor before touching this manager's state.
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("Rewarded ad failed to load: \(error.localizedDescription)")
                    self.isAdReady = false
                    return
                }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.isAdReady = true
            }
        }
    }

    /// Show a rewarded ad. When the player earns the reward, `onReward`
    /// runs (the caller grants +5 ranked swings). Does nothing when no
    /// ad is loaded or one is already showing.
    func showRewardedAd(onReward: @escaping () -> Void) {
        guard let ad = rewardedAd, !isShowingAd else { return }
        guard let root = rootViewController() else { return }
        rewardHandler = onReward
        isShowingAd = true
        ad.present(fromRootViewController: root) { [weak self] in
            self?.rewardHandler?()
            self?.rewardHandler = nil
        }
    }

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}

@MainActor
extension AdsManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isShowingAd = false
        rewardedAd = nil
        isAdReady = false
        loadRewardedAd()
    }
}
