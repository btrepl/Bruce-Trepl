// GameState.swift
// Shared game state: current slugger, bat, season, daily swings, and the
// local leaderboard. Persisted with UserDefaults so swings and scores
// survive app restarts. No server, no accounts in this build.

import SwiftUI

// MARK: - Game mode: practice vs ranked

/// Practice is unlimited and never counts; Ranked is 10 swings a day and
/// is the only mode that counts for the leaderboard and coins.
/// Energy gates *rewards*, not *play* — you can always practice.
enum GameMode: String, Codable {
    case practice
    case ranked
}

@MainActor
final class GameState: ObservableObject {
    // MARK: - Published state

    @Published var screen: Screen = .home
    @Published var slugger: Slugger = .presetSlugger(.ballplayer)
    @Published var bat: Bat = .signatureBat(for: .ballplayer)
    @Published var season: Season = .fall
    @Published var mode: GameMode = .practice
    @Published var rankedLeft: Int = 10
    @Published var unlimitedSwings = false  // testing: never consume ranked swings
    @Published var removeAdsUnlocked = false  // $4.99 Remove Ads: also unlimited ranked
    @Published var customSlugger: Slugger = .defaultCustom
    @Published var customBats: [Bat] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var lifetimeBest: Int = 0
    @Published var coins: Int = 0

    // MARK: - Persistence keys

    private enum Keys {
        static let rankedLeft = "hfRankedLeft"
        static let unlimitedSwings = "hfUnlimitedSwings"
        static let removeAds = "hfRemoveAds"
        static let rankedDate = "hfRankedDate"
        static let leaderboard = "hf Leaderboard"
        static let lifetimeBest = "hf LifetimeBest"
        static let customSlugger = "hf CustomSlugger"
        static let customBats = "hf CustomBats"
        static let coins = "hf Coins"
        static let season = "hf Season"
        static let sluggerID = "hf SluggerID"
    }

    private let defaults = UserDefaults.standard

    // MARK: - Init

    init() {
        loadPersistedState()
        resetRankedIfNeeded()
    }

    // MARK: - Ranked swings (10/day)

    /// 10 ranked swings per day. Resets automatically when the calendar day
    /// changes. Practice swings are unlimited and never touch this count.
    /// Called on launch and whenever the game screen appears.
    func resetRankedIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let stored = defaults.object(forKey: Keys.rankedDate) as? Date ?? .distantPast
        if !Calendar.current.isDate(stored, inSameDayAs: today) {
            rankedLeft = 10
            defaults.set(today, forKey: Keys.rankedDate)
            defaults.set(rankedLeft, forKey: Keys.rankedLeft)
        }
    }

    /// Practice can always swing; Ranked needs a ranked swing left
    /// (or unlimited ranked from testing or the Remove Ads purchase).
    var canSwing: Bool {
        if mode == .practice { return true }
        return rankedUnlimited || rankedLeft > 0
    }

    /// True when ranked swings never run out: testing toggle or Remove Ads.
    var rankedUnlimited: Bool { unlimitedSwings || removeAdsUnlocked }

    /// Consume one ranked swing. Practice swings are free and unlimited.
    func useSwing() {
        guard mode == .ranked else { return }
        // Unlimited ranked: swings are never consumed.
        guard !rankedUnlimited else { return }
        guard rankedLeft > 0 else { return }
        rankedLeft -= 1
        defaults.set(rankedLeft, forKey: Keys.rankedLeft)
    }

    /// Testing toggle: unlimited ranked swings, never consumes the daily 10.
    func setUnlimitedSwings(_ value: Bool) {
        unlimitedSwings = value
        defaults.set(value, forKey: Keys.unlimitedSwings)
    }

    /// Synced from the StoreManager when the Remove Ads purchase is owned.
    func setRemoveAdsUnlocked(_ value: Bool) {
        removeAdsUnlocked = value
        defaults.set(value, forKey: Keys.removeAds)
    }

    /// Add ranked swings (from a Ranked Refill purchase).
    func addRankedSwings(_ count: Int) {
        rankedLeft += count
        defaults.set(rankedLeft, forKey: Keys.rankedLeft)
    }

    // MARK: - Coins

    /// Earn coins from a ranked hit: 1 coin per 10 feet, minimum 5,
    /// plus a 25-coin bonus for a big hit (280+). Practice earns nothing —
    /// coins are the reward for ranked play.
    func coinsForHit(distance: Int) -> Int {
        guard distance > 0 else { return 0 }
        var earned = max(5, distance / 10)
        if distance >= 280 { earned += 25 }
        return earned
    }

    func earnCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
        defaults.set(coins, forKey: Keys.coins)
    }

    /// Spend coins. Returns false when the player cannot afford it.
    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, coins >= amount else { return false }
        coins -= amount
        defaults.set(coins, forKey: Keys.coins)
        return true
    }

    // MARK: - Bat upgrades

    /// Upgrade a custom bat: +1 level, +2% power boost, for the level's
    /// coin cost. Returns false when maxed out or unaffordable. Signature
    /// bats cannot be upgraded — their boost is fixed.
    @discardableResult
    func upgradeBat(_ bat: Bat) -> Bool {
        guard bat.isCustom else { return false }
        guard bat.upgradeLevel < Bat.maxUpgradeLevel else { return false }
        let cost = Bat.upgradeCost(for: bat.upgradeLevel)
        guard spendCoins(cost) else { return false }
        guard let index = customBats.firstIndex(where: { $0.id == bat.id }) else { return false }
        customBats[index].upgradeLevel += 1
        customBats[index].powerBoost = Double(customBats[index].upgradeLevel) * 0.02
        if self.bat.id == bat.id {
            self.bat = customBats[index]
        }
        persistCustomBats()
        return true
    }

    // MARK: - Selection

    /// Picking a preset slugger auto-equips their signature bat.
    func selectPreset(_ preset: PresetID) {
        slugger = .presetSlugger(preset)
        bat = .signatureBat(for: preset)
        defaults.set(slugger.id, forKey: Keys.sluggerID)
    }

    func selectCustomSlugger() {
        slugger = customSlugger
        defaults.set(slugger.id, forKey: Keys.sluggerID)
    }

    func selectCustomBat(_ customBat: Bat) {
        bat = customBat
    }

    func saveCustomSlugger(_ value: Slugger) {
        customSlugger = value
        if slugger.isCustom { slugger = value }
        persistCustomSlugger()
    }

    func addCustomBat(_ value: Bat) {
        customBats.append(value)
        bat = value
        persistCustomBats()
    }

    // MARK: - Scores

    /// Record a hit. Updates the local leaderboard (top 20) and lifetime best.
    /// Returns true when this hit is a new lifetime best.
    @discardableResult
    func recordHit(distance: Int) -> Bool {
        let entry = LeaderboardEntry(
            playerName: "You",
            characterName: slugger.name,
            season: season,
            distance: distance
        )
        leaderboard.append(entry)
        leaderboard.sort { $0.distance > $1.distance }
        leaderboard = Array(leaderboard.prefix(20))
        persistLeaderboard()

        let isBest = distance > lifetimeBest
        if isBest {
            lifetimeBest = distance
            defaults.set(lifetimeBest, forKey: Keys.lifetimeBest)
        }
        return isBest
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        rankedLeft = defaults.object(forKey: Keys.rankedLeft) as? Int ?? 10
        unlimitedSwings = defaults.bool(forKey: Keys.unlimitedSwings)
        removeAdsUnlocked = defaults.bool(forKey: Keys.removeAds)
        coins = defaults.object(forKey: Keys.coins) as? Int ?? 0
        lifetimeBest = defaults.object(forKey: Keys.lifetimeBest) as? Int ?? 0

        if let data = defaults.data(forKey: Keys.leaderboard),
           let decoded = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) {
            leaderboard = decoded
        }
        if let data = defaults.data(forKey: Keys.customSlugger),
           let decoded = try? JSONDecoder().decode(Slugger.self, from: data) {
            customSlugger = decoded
        }
        if let data = defaults.data(forKey: Keys.customBats),
           let decoded = try? JSONDecoder().decode([Bat].self, from: data) {
            customBats = decoded
        }
        if let rawSeason = defaults.string(forKey: Keys.season),
           let decodedSeason = Season(rawValue: rawSeason) {
            season = decodedSeason
        }
    }

    private func persistLeaderboard() {
        if let data = try? JSONEncoder().encode(leaderboard) {
            defaults.set(data, forKey: Keys.leaderboard)
        }
    }

    private func persistCustomSlugger() {
        if let data = try? JSONEncoder().encode(customSlugger) {
            defaults.set(data, forKey: Keys.customSlugger)
        }
    }

    private func persistCustomBats() {
        if let data = try? JSONEncoder().encode(customBats) {
            defaults.set(data, forKey: Keys.customBats)
        }
    }

    func persistSeason() {
        defaults.set(season.rawValue, forKey: Keys.season)
    }
}
