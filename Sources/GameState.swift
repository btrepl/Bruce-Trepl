// GameState.swift
// Shared game state: current slugger, bat, season, daily swings, and the
// local leaderboard. Persisted with UserDefaults so swings and scores
// survive app restarts. No server, no accounts in this build.

import SwiftUI

@MainActor
final class GameState: ObservableObject {
    // MARK: - Published state

    @Published var screen: Screen = .home
    @Published var slugger: Slugger = .presetSlugger(.ballplayer)
    @Published var bat: Bat = .signatureBat(for: .ballplayer)
    @Published var season: Season = .fall
    @Published var swingsLeft: Int = 10
    @Published var unlimitedSwings = false  // testing: never consume swings
    @Published var customSlugger: Slugger = .defaultCustom
    @Published var customBats: [Bat] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var lifetimeBest: Int = 0

    // MARK: - Persistence keys

    private enum Keys {
        static let swingsLeft = "hfSwingsLeft"
        static let unlimitedSwings = "hfUnlimitedSwings"
        static let swingsDate = "hf SwingsDate"
        static let leaderboard = "hf Leaderboard"
        static let lifetimeBest = "hf LifetimeBest"
        static let customSlugger = "hf CustomSlugger"
        static let customBats = "hf CustomBats"
        static let season = "hf Season"
        static let sluggerID = "hf SluggerID"
    }

    private let defaults = UserDefaults.standard

    // MARK: - Init

    init() {
        loadPersistedState()
        resetSwingsIfNeeded()
    }

    // MARK: - Daily swings

    /// 10 free swings per day. Resets automatically when the calendar day
    /// changes. Called on launch and whenever the game screen appears.
    func resetSwingsIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let stored = defaults.object(forKey: Keys.swingsDate) as? Date ?? .distantPast
        if !Calendar.current.isDate(stored, inSameDayAs: today) {
            swingsLeft = 10
            defaults.set(today, forKey: Keys.swingsDate)
            defaults.set(swingsLeft, forKey: Keys.swingsLeft)
        }
    }

    var canSwing: Bool { unlimitedSwings || swingsLeft > 0 }

    func useSwing() {
        // Testing mode: swings are never consumed.
        guard !unlimitedSwings else { return }
        guard swingsLeft > 0 else { return }
        swingsLeft -= 1
        defaults.set(swingsLeft, forKey: Keys.swingsLeft)
    }

    /// Testing toggle: unlimited swings, never consumes the daily 10.
    func setUnlimitedSwings(_ value: Bool) {
        unlimitedSwings = value
        defaults.set(value, forKey: Keys.unlimitedSwings)
    }

    func addSwings(_ count: Int) {
        swingsLeft += count
        defaults.set(swingsLeft, forKey: Keys.swingsLeft)
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
        swingsLeft = defaults.object(forKey: Keys.swingsLeft) as? Int ?? 10
        unlimitedSwings = defaults.bool(forKey: Keys.unlimitedSwings)
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
