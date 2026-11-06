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

/// Which kind of game to play. Classic is one pitch, one swing. Derby,
/// Timing Streak, and Pitch Challenge are 10-pitch modes.
enum PlayMode: String, CaseIterable, Codable {
    case classic
    case derby
    case streak
    case pitchChallenge

    var title: String {
        switch self {
        case .classic: return "Classic"
        case .derby: return "Home Run Derby"
        case .streak: return "Timing Streak"
        case .pitchChallenge: return "Pitch Challenge"
        }
    }

    var detail: String {
        switch self {
        case .classic: return "One pitch, one swing"
        case .derby: return "10 pitches — total distance wins"
        case .streak: return "10 pitches — chain perfect hits"
        case .pitchChallenge: return "10 pitches — fastballs, curves, changeups"
        }
    }

    /// Pitches per game in this mode.
    var pitchCount: Int {
        switch self {
        case .classic: return 1
        case .derby, .streak, .pitchChallenge: return 10
        }
    }
}

/// Pitch types for Pitch Challenge mode. Each has its own speed and
/// timing feel, so the player has to adapt every pitch.
enum PitchType: String, CaseIterable {
    case fastball
    case curveball
    case changeup

    var title: String {
        switch self {
        case .fastball: return "Fastball"
        case .curveball: return "Curveball"
        case .changeup: return "Changeup"
        }
    }

    /// Seconds for the ball to travel to the plate.
    var travelTime: Double {
        switch self {
        case .fastball: return 0.9
        case .curveball: return 1.2
        case .changeup: return 1.8
        }
    }
}

@MainActor
final class GameState: ObservableObject {
    // MARK: - Published state

    @Published var screen: Screen = .home
    @Published var slugger: Slugger = .presetSlugger(.ballplayer)
    @Published var bat: Bat = .signatureBat(for: .ballplayer)
    @Published var season: Season = .fall
    @Published var mode: GameMode = .practice
    @Published var playMode: PlayMode = .classic
    @Published var rankedLeft: Int = 10
    @Published var unlimitedSwings = false  // testing: never consume ranked swings
    @Published var removeAdsUnlocked = false  // $4.99 Remove Ads: also unlimited ranked
    @Published var customSlugger: Slugger = .defaultCustom
    @Published var customBats: [Bat] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var lifetimeBest: Int = 0
    @Published var coins: Int = 0

    // MARK: - Daily rewards, quests, season pass, achievements

    /// Consecutive days the daily reward was claimed.
    @Published var dailyStreak: Int = 0
    /// True when today's daily reward is still unclaimed.
    @Published var dailyRewardAvailable: Bool = true
    /// Today's three quests (reset every day).
    @Published var quests: [Quest] = Quest.Kind.allCases.map { Quest(kind: $0) }
    /// Total Season XP earned (ranked hits only).
    @Published var seasonXP: Int = 0
    /// Free-track pass rewards already claimed, by level.
    @Published var claimedFreeRewards: Set<Int> = []
    /// Premium-track pass rewards already claimed, by level.
    @Published var claimedPremiumRewards: Set<Int> = []
    /// True when the premium season pass ($4.99) is owned.
    @Published var premiumPassOwned: Bool = false
    /// Lifetime totals for achievements.
    @Published var totalCoinsEarned: Int = 0
    @Published var totalRankedSwings: Int = 0

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
        static let dailyClaimDate = "hf DailyClaimDate"
        static let dailyStreak = "hf DailyStreak"
        static let quests = "hf Quests"
        static let questsDate = "hf QuestsDate"
        static let seasonXP = "hf SeasonXP"
        static let claimedFree = "hf ClaimedFree"
        static let claimedPremium = "hf ClaimedPremium"
        static let premiumPass = "hf PremiumPass"
        static let totalCoinsEarned = "hf TotalCoinsEarned"
        static let totalRankedSwings = "hf TotalRankedSwings"
        static let season = "hf Season"
        static let playMode = "hf PlayMode"
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
        totalCoinsEarned += amount
        defaults.set(coins, forKey: Keys.coins)
        defaults.set(totalCoinsEarned, forKey: Keys.totalCoinsEarned)
    }

    /// Spend coins. Returns false when the player cannot afford it.
    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, coins >= amount else { return false }
        coins -= amount
        defaults.set(coins, forKey: Keys.coins)
        return true
    }

    // MARK: - Daily rewards

    /// Refresh the daily-reward state for today. Call on launch and when
    /// Home appears. The streak survives only on consecutive days.
    func refreshDailyReward() {
        let today = Calendar.current.startOfDay(for: Date())
        let last = defaults.object(forKey: Keys.dailyClaimDate) as? Date
        if let last {
            if Calendar.current.isDate(last, inSameDayAs: today) {
                dailyRewardAvailable = false
                return
            }
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if Calendar.current.isDate(last, inSameDayAs: yesterday) {
                // Streak continues; it is claimed below, not here.
            } else {
                dailyStreak = 0
                defaults.set(0, forKey: Keys.dailyStreak)
            }
        }
        dailyRewardAvailable = true
    }

    /// Claim today's daily reward. Returns the coins (and ranked swings)
    /// granted, or nil when it was already claimed today.
    @discardableResult
    func claimDailyReward() -> (coins: Int, rankedSwings: Int)? {
        guard dailyRewardAvailable else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        dailyStreak += 1
        let coins = DailyReward.coins(for: dailyStreak)
        let swings = DailyReward.rankedSwings(for: dailyStreak)
        earnCoins(coins)
        if swings > 0 { addRankedSwings(swings) }
        dailyRewardAvailable = false
        defaults.set(today, forKey: Keys.dailyClaimDate)
        defaults.set(dailyStreak, forKey: Keys.dailyStreak)
        return (coins, swings)
    }

    // MARK: - Daily quests

    /// Reset quests when the calendar day changes. Call on launch and
    /// when Home appears.
    func resetQuestsIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let stored = defaults.object(forKey: Keys.questsDate) as? Date ?? .distantPast
        if !Calendar.current.isDate(stored, inSameDayAs: today) {
            quests = Quest.Kind.allCases.map { Quest(kind: $0) }
            defaults.set(today, forKey: Keys.questsDate)
            persistQuests()
        }
    }

    /// Advance quest progress from one ranked swing. Call after every
    /// ranked swing with the hit distance (0 for a whiff).
    func advanceQuests(distance: Int) {
        totalRankedSwings += 1
        defaults.set(totalRankedSwings, forKey: Keys.totalRankedSwings)
        for i in quests.indices {
            switch quests[i].kind {
            case .longBall:
                if distance >= 300 { quests[i].progress = max(quests[i].progress, 1) }
            case .consistent:
                if distance >= 200 { quests[i].progress += 1 }
            case .grinder:
                quests[i].progress += 1
            }
        }
        persistQuests()
    }

    /// Claim a completed quest's coin reward. Returns the coins, or nil
    /// when the quest is not complete or was already claimed.
    @discardableResult
    func claimQuest(_ quest: Quest) -> Int? {
        guard let index = quests.firstIndex(where: { $0.kind == quest.kind }) else { return nil }
        guard quests[index].isComplete, !quests[index].claimed else { return nil }
        quests[index].claimed = true
        persistQuests()
        earnCoins(quests[index].coinReward)
        return quests[index].coinReward
    }

    private func persistQuests() {
        if let data = try? JSONEncoder().encode(quests) {
            defaults.set(data, forKey: Keys.quests)
        }
    }

    // MARK: - Season pass

    /// Current pass level (0...10) from total Season XP.
    var passLevel: Int { SeasonPass.level(for: seasonXP) }

    /// XP progress within the current level (0..<150).
    var passXPIntoLevel: Int { SeasonPass.xpIntoLevel(for: seasonXP) }

    /// Add Season XP from a ranked hit.
    func addSeasonXP(_ amount: Int) {
        guard amount > 0 else { return }
        seasonXP += amount
        defaults.set(seasonXP, forKey: Keys.seasonXP)
    }

    /// Claim a free-track reward for a reached level. Returns the coins,
    /// or nil when the level is not reached or was already claimed.
    @discardableResult
    func claimFreeReward(level: Int) -> Int? {
        guard level <= passLevel, !claimedFreeRewards.contains(level) else { return nil }
        guard let row = SeasonPass.levels.first(where: { $0.level == level }) else { return nil }
        claimedFreeRewards.insert(level)
        defaults.set(Array(claimedFreeRewards), forKey: Keys.claimedFree)
        earnCoins(row.freeCoins)
        return row.freeCoins
    }

    /// Claim a premium-track reward. Requires the premium pass.
    /// Returns the coins (the Golden Bat at level 10 is noted in the UI).
    @discardableResult
    func claimPremiumReward(level: Int) -> Int? {
        guard premiumPassOwned else { return nil }
        guard level <= passLevel, !claimedPremiumRewards.contains(level) else { return nil }
        guard let row = SeasonPass.levels.first(where: { $0.level == level }) else { return nil }
        claimedPremiumRewards.insert(level)
        defaults.set(Array(claimedPremiumRewards), forKey: Keys.claimedPremium)
        earnCoins(row.premiumCoins)
        return row.premiumCoins
    }

    /// Mark the premium season pass as owned (synced from the store).
    func setPremiumPassOwned(_ value: Bool) {
        premiumPassOwned = value
        defaults.set(value, forKey: Keys.premiumPass)
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

    /// Set the play mode (Classic / Derby / Timing Streak / Pitch Challenge).
    func setPlayMode(_ value: PlayMode) {
        playMode = value
        defaults.set(value.rawValue, forKey: Keys.playMode)
    }

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
        dailyStreak = defaults.object(forKey: Keys.dailyStreak) as? Int ?? 0
        seasonXP = defaults.object(forKey: Keys.seasonXP) as? Int ?? 0
        premiumPassOwned = defaults.bool(forKey: Keys.premiumPass)
        totalCoinsEarned = defaults.object(forKey: Keys.totalCoinsEarned) as? Int ?? 0
        totalRankedSwings = defaults.object(forKey: Keys.totalRankedSwings) as? Int ?? 0
        if let free = defaults.array(forKey: Keys.claimedFree) as? [Int] {
            claimedFreeRewards = Set(free)
        }
        if let premium = defaults.array(forKey: Keys.claimedPremium) as? [Int] {
            claimedPremiumRewards = Set(premium)
        }
        if let data = defaults.data(forKey: Keys.quests),
           let decoded = try? JSONDecoder().decode([Quest].self, from: data) {
            quests = decoded
        }
        lifetimeBest = defaults.object(forKey: Keys.lifetimeBest) as? Int ?? 0
        if let modeRaw = defaults.string(forKey: Keys.playMode),
           let saved = PlayMode(rawValue: modeRaw) {
            playMode = saved
        }

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
