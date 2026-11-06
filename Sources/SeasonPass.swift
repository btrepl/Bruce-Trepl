// SeasonPass.swift
// Season pass, daily rewards, and daily quests for "How Far Can You Hit It?"
//
// THE PASS (lite): 10 levels, 150 Season XP per level. Earn XP from ranked
// hits (10 XP per hit + 1 XP per 10 feet). The free track pays coins at
// every level; the premium track ($4.99, one-time) pays more coins plus a
// Golden Bat (+10% power, exclusive) at level 10. The pass is themed to
// the player's selected season (Fall / Christmas / Normal).
//
// DAILY REWARDS: claim once a day; the streak climbs on consecutive days
// and resets when a day is missed. Day 7 pays 500 coins + 5 ranked swings.
//
// DAILY QUESTS: three quests that reset every day. Completing one pays
// coins. Progress is tracked from ranked play only.

import SwiftUI

// MARK: - Season pass

/// One level of the season pass: what the free track and the premium track pay.
struct PassLevel: Identifiable {
    let level: Int
    let xpNeeded: Int       // XP to go from the previous level to this one
    let freeCoins: Int
    let premiumCoins: Int
    let premiumBonus: String?  // non-coin premium reward, if any

    var id: Int { level }
}

enum SeasonPass {
    /// XP to complete one level.
    static let xpPerLevel = 150

    /// The 10 levels. Free coins climb; premium pays roughly double plus a
    /// Golden Bat at level 10.
    static let levels: [PassLevel] = [
        PassLevel(level: 1, xpNeeded: 150, freeCoins: 50, premiumCoins: 100, premiumBonus: nil),
        PassLevel(level: 2, xpNeeded: 150, freeCoins: 75, premiumCoins: 150, premiumBonus: nil),
        PassLevel(level: 3, xpNeeded: 150, freeCoins: 100, premiumCoins: 200, premiumBonus: nil),
        PassLevel(level: 4, xpNeeded: 150, freeCoins: 125, premiumCoins: 250, premiumBonus: nil),
        PassLevel(level: 5, xpNeeded: 150, freeCoins: 150, premiumCoins: 300, premiumBonus: nil),
        PassLevel(level: 6, xpNeeded: 150, freeCoins: 200, premiumCoins: 400, premiumBonus: nil),
        PassLevel(level: 7, xpNeeded: 150, freeCoins: 250, premiumCoins: 500, premiumBonus: nil),
        PassLevel(level: 8, xpNeeded: 150, freeCoins: 300, premiumCoins: 600, premiumBonus: nil),
        PassLevel(level: 9, xpNeeded: 150, freeCoins: 400, premiumCoins: 750, premiumBonus: nil),
        PassLevel(level: 10, xpNeeded: 150, freeCoins: 500, premiumCoins: 1000, premiumBonus: "Golden Bat (+10% power)"),
    ]

    /// Season XP from one ranked hit: 10 XP per hit + 1 XP per 10 feet.
    static func xpForHit(distance: Int) -> Int {
        guard distance > 0 else { return 0 }
        return 10 + distance / 10
    }

    /// Which level a total XP amount has reached (0...10).
    static func level(for totalXP: Int) -> Int {
        min(totalXP / xpPerLevel, levels.count)
    }

    /// XP progress within the current level (0..<150).
    static func xpIntoLevel(for totalXP: Int) -> Int {
        totalXP % xpPerLevel
    }
}

// MARK: - Daily rewards

/// Daily reward by streak day (1-based). Day 7 repeats for longer streaks.
enum DailyReward {
    static func coins(for streakDay: Int) -> Int {
        switch min(streakDay, 7) {
        case 1: return 50
        case 2: return 75
        case 3: return 100
        case 4: return 150
        case 5: return 200
        case 6: return 250
        default: return 500
        }
    }

    /// Day 7 also grants ranked swings.
    static func rankedSwings(for streakDay: Int) -> Int {
        min(streakDay, 7) >= 7 ? 5 : 0
    }
}

// MARK: - Daily quests

/// A daily quest: what to do, how far along the player is, and the payout.
struct Quest: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        case longBall      // hit 300+ feet once
        case consistent    // land 3 hits of 200+ feet
        case grinder       // take 5 ranked swings
    }

    var kind: Kind
    var progress: Int = 0
    var claimed: Bool = false

    var id: Kind { kind }

    var title: String {
        switch kind {
        case .longBall: return "Long Ball"
        case .consistent: return "Consistent"
        case .grinder: return "Grinder"
        }
    }

    var detail: String {
        switch kind {
        case .longBall: return "Hit 300+ feet once"
        case .consistent: return "Land 3 hits of 200+ feet"
        case .grinder: return "Take 5 ranked swings"
        }
    }

    var target: Int {
        switch kind {
        case .longBall: return 1
        case .consistent: return 3
        case .grinder: return 5
        }
    }

    var coinReward: Int {
        switch kind {
        case .longBall: return 50
        case .consistent: return 75
        case .grinder: return 50
        }
    }

    var isComplete: Bool { progress >= target }
}

// MARK: - Achievements (Game Center)

/// Achievements reported to Game Center. The matching achievement IDs must
/// be created in App Store Connect; reporting one that does not exist yet
/// simply does nothing, so the game never breaks.
enum GameAchievement: String, CaseIterable {
    case firstHit = "com.tntfamily.howfar.achievement.firsthit"
    case hit300 = "com.tntfamily.howfar.achievement.hit300"
    case hit400 = "com.tntfamily.howfar.achievement.hit400"
    case swings100 = "com.tntfamily.howfar.achievement.swings100"
    case coins1000 = "com.tntfamily.howfar.achievement.coins1000"
    case maxBat = "com.tntfamily.howfar.achievement.maxbat"

    var title: String {
        switch self {
        case .firstHit: return "First Hit"
        case .hit300: return "300 Club"
        case .hit400: return "400 Club"
        case .swings100: return "Century"
        case .coins1000: return "Coin Hoarder"
        case .maxBat: return "Maxed Out"
        }
    }

    var detail: String {
        switch self {
        case .firstHit: return "Record your first hit"
        case .hit300: return "Hit 300+ feet"
        case .hit400: return "Hit 400+ feet"
        case .swings100: return "Take 100 ranked swings"
        case .coins1000: return "Earn 1,000 total coins"
        case .maxBat: return "Upgrade a bat to max level"
        }
    }
}
