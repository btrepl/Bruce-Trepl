// StoreManager.swift
// In-app purchases for "How Far Can You Hit It?"
//
// PRICING (matches the game design):
//   - Build-a-Slugger (custom characters): $0.99
//   - Build-a-Bat (custom bats):          $0.99
//   - Extra swings: 5 swings for $1.00
//   - The app itself is a $1.00 paid download (set in App Store Connect).
//
// STUB STATUS: `stubMode` is ON. While it is on, purchases are simulated
// (short delay, then success) so the game is fully playable before any
// App Store Connect products exist. The real StoreKit 2 code path is already
// written below and runs automatically once stubMode is set to false AND
// matching products exist in App Store Connect.
//
// TO GO LIVE:
//   1. Create these product IDs in App Store Connect (same bundle ID):
//        com.tntfamily.howfar.customslugger  (non-consumable, $0.99)
//        com.tntfamily.howfar.custombat     (non-consumable, $0.99)
//        com.tntfamily.howfar.swingpack5    (consumable, $1.00)
//   2. Set stubMode = false.
//   3. Test in the sandbox / TestFlight before submitting.
//   4. Enroll in the App Store Small Business Program (15% commission).

import SwiftUI
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    // MARK: - Product IDs

    static let customSluggerID = "com.tntfamily.howfar.customslugger"
    static let customBatID = "com.tntfamily.howfar.custombat"
    static let swingPackID = "com.tntfamily.howfar.swingpack5"

    // MARK: - State

    @Published private(set) var customSluggerUnlocked = false
    @Published private(set) var customBatUnlocked = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var lastError: String?

    /// STUB SWITCH. true = simulated purchases (no real charges).
    /// Set to false once the products above exist in App Store Connect.
    private let stubMode = false

    private let defaults = UserDefaults.standard

    init() {
        customSluggerUnlocked = defaults.bool(forKey: "hfUnlockSlugger")
        customBatUnlocked = defaults.bool(forKey: "hfUnlockBat")
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

    /// Buy 5 extra swings ($1.00). Returns true on success.
    func purchaseSwingPack() async -> Bool {
        await purchase(productID: Self.swingPackID)
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
        default:
            break
        }
    }
}
