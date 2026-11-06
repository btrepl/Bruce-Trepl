// StoreManager.swift
// In-app purchases for "How Far Can You Hit It?"
//
// The app is FREE to download. Monetization (build 16, free-to-play rebuild):
//   - Build-a-Slugger (custom characters): $0.99
//   - Build-a-Bat (custom bats):          $0.99
//   - Ranked Refill: 20 ranked swings for $0.99 (consumable)
//   - Remove Ads + Unlimited Ranked:      $4.99 (non-consumable)
//   - Coin bundles: 1,000 coins $0.99, 5,000 coins $2.99 (consumable)
//   - Rewarded ads (watch an ad for extra ranked swings) arrive in a later
//     build; Remove Ads turns those off too.
//
// STUB STATUS: `stubMode` is OFF (real StoreKit). The real StoreKit 2 code
// path runs when matching products exist in App Store Connect.
//
// TO GO LIVE:
//   1. Create these product IDs in App Store Connect (same bundle ID):
//        com.tntfamily.howfar.customslugger  (non-consumable, $0.99)
//        com.tntfamily.howfar.custombat     (non-consumable, $0.99)
//        com.tntfamily.howfar.rankedrefill20 (consumable, $0.99)
//        com.tntfamily.howfar.removeads     (non-consumable, $4.99)
//        com.tntfamily.howfar.coins1000     (consumable, $0.99)
//        com.tntfamily.howfar.coins5000     (consumable, $2.99)
//   2. Set the app price tier to Free in App Store Connect.
//   3. Test in the sandbox / TestFlight before submitting.
//   4. Enroll in the App Store Small Business Program (15% commission).
//   NOTE: the old swingpack5 product ($1.00 for 5 swings) is retired;
//   ranked refills replace it. Do not re-create it.

import SwiftUI
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    // MARK: - Product IDs

    static let customSluggerID = "com.tntfamily.howfar.customslugger"
    static let customBatID = "com.tntfamily.howfar.custombat"
    static let rankedRefillID = "com.tntfamily.howfar.rankedrefill20"
    static let removeAdsID = "com.tntfamily.howfar.removeads"
    static let coins1000ID = "com.tntfamily.howfar.coins1000"
    static let coins5000ID = "com.tntfamily.howfar.coins5000"

    // MARK: - State

    @Published private(set) var customSluggerUnlocked = false
    @Published private(set) var customBatUnlocked = false
    @Published private(set) var removeAdsUnlocked = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var lastError: String?

    /// STUB SWITCH. true = simulated purchases (no real charges).
    /// Set to false once the products above exist in App Store Connect.
    private let stubMode = false

    private let defaults = UserDefaults.standard

    init() {
        customSluggerUnlocked = defaults.bool(forKey: "hfUnlockSlugger")
        customBatUnlocked = defaults.bool(forKey: "hfUnlockBat")
        removeAdsUnlocked = defaults.bool(forKey: "hfUnlockRemoveAds")
    }

    // MARK: - Public purchase API (used by the views)

    /// Unlock Build-a-Slugger ($0.99). Returns true on success.
    func purchaseCustomSlugger() async -> Bool {
        let ok = await purchase(productID: Self.customSluggerID)
        if ok {
            customSluggerUnlocked = true
            defaults.set(true, forKey: "hfUnlockSlugger")
        }
        return ok
    }

    /// Unlock Build-a-Bat ($0.99). Returns true on success.
    func purchaseCustomBat() async -> Bool {
        let ok = await purchase(productID: Self.customBatID)
        if ok {
            customBatUnlocked = true
            defaults.set(true, forKey: "hfUnlockBat")
        }
        return ok
    }

    /// Buy 20 ranked swings ($0.99). Returns true on success.
    func purchaseRankedRefill() async -> Bool {
        await purchase(productID: Self.rankedRefillID)
    }

    /// Buy 1,000 coins ($0.99). Returns true on success. Coins are
    /// credited by the caller (GameState) via the returned amount.
    func purchaseCoins1000() async -> Bool {
        await purchase(productID: Self.coins1000ID)
    }

    /// Buy 5,000 coins ($2.99). Returns true on success.
    func purchaseCoins5000() async -> Bool {
        await purchase(productID: Self.coins5000ID)
    }

    /// Remove Ads + Unlimited Ranked ($4.99). Returns true on success.
    func purchaseRemoveAds() async -> Bool {
        let ok = await purchase(productID: Self.removeAdsID)
        if ok {
            removeAdsUnlocked = true
            defaults.set(true, forKey: "hfUnlockRemoveAds")
        }
        return ok
    }

    /// Restore non-consumable purchases (real StoreKit path only; the stub
    /// path keeps whatever UserDefaults already recorded).
    func restorePurchases() async {
        guard !stubMode else { return }
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                apply(productID: transaction.productID)
            }
        }
    }

    // MARK: - Purchase engine

    private func purchase(productID: String) async -> Bool {
        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }

        // ---- STUB PATH (current behavior) ----
        if stubMode {
            // Simulate a store round-trip. No real charge happens here.
            try? await Task.sleep(nanoseconds: 700_000_000)
            return true
        }

        // ---- REAL STOREKIT 2 PATH (runs when stubMode is false) ----
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                lastError = "That item isn't on sale yet."
                return false
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    apply(productID: productID)
                    return true
                case .unverified:
                    lastError = "Purchase could not be verified."
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                lastError = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    private func apply(productID: String) {
        switch productID {
        case Self.customSluggerID:
            customSluggerUnlocked = true
            defaults.set(true, forKey: "hfUnlockSlugger")
        case Self.customBatID:
            customBatUnlocked = true
            defaults.set(true, forKey: "hfUnlockBat")
        case Self.removeAdsID:
            removeAdsUnlocked = true
            defaults.set(true, forKey: "hfUnlockRemoveAds")
        default:
            break
        }
    }
}
