// Models.swift
// Core data types for "How Far Can You Hit It?"
// All character and bat art is original SwiftUI shapes drawn in
// CharacterArt.swift and BatArt.swift. No licensed characters, no
// trademarked bat names, and no feet anywhere in the UI.

import SwiftUI

// MARK: - Seasons

/// The three seasons the player can pick. Distance is measured ONLY in the
/// season's unit. Feet are never shown anywhere in the UI.
enum Season: String, CaseIterable, Identifiable, Codable {
    case fall
    case christmas
    case normal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fall: return "Fall"
        case .christmas: return "Christmas"
        case .normal: return "Normal"
        }
    }

    /// The unit distance is measured in for this season.
    var unitSingular: String {
        switch self {
        case .fall: return "pumpkin"
        case .christmas: return "Christmas Tree"
        case .normal: return "baseball card"
        }
    }

    var unitPlural: String {
        switch self {
        case .fall: return "pumpkins"
        case .christmas: return "Christmas Trees"
        case .normal: return "baseball cards"
        }
    }

    func unitName(for distance: Int) -> String {
        distance == 1 ? unitSingular : unitPlural
    }

}

// MARK: - Preset characters

/// The five free out-of-the-box sluggers. The snowman is a generic funny
/// snowman drawn from scratch; it is not any licensed snowman character.
enum PresetID: String, CaseIterable, Identifiable, Codable {
    case santa
    case trump
    case ballplayer
    case bigfoot
    case snowman

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .santa: return "Santa"
        case .trump: return "Donald Trump"
        case .ballplayer: return "The Ballplayer"
        case .bigfoot: return "Bigfoot"
        case .snowman: return "Snowman"
        }
    }

    var tagline: String {
        switch self {
        case .santa: return "Jolly, fast, and slightly out of breath."
        case .trump: return "Tremendous swing. Everybody says so."
        case .ballplayer: return "A kid with a dream and a big bat."
        case .bigfoot: return "He was never lost. He was practicing."
        case .snowman: return "Tall, skinny, and freezing cold."
        }
    }
}

// MARK: - Bats

/// Every bat object that can appear in the game. Preset characters each have
/// one signature bat; custom bats pick one object and split 8 points.
enum BatObject: String, CaseIterable, Identifiable, Codable {
    case giftWrap
    case driver
    case classicBat
    case bareTree
    case iceClub
    case cavemanClub
    case baguette
    case magicWand

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .giftWrap: return "Gift Wrap Roll"
        case .driver: return "Driver"
        // Generic classic American baseball bat shape. Never a brand name.
        case .classicBat: return "Classic Bat"
        case .bareTree: return "Bare Tree"
        case .iceClub: return "Ice Club"
        case .cavemanClub: return "Caveman Club"
        case .baguette: return "Baguette"
        case .magicWand: return "Magic Wand"
        }
    }
}

/// A bat: an object plus power/speed stats. Custom bats always sum to 8.
struct Bat: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var object: BatObject
    var power: Int   // 1...7
    var speed: Int   // 1...7
    var isCustom: Bool

    /// Signature bats for the five preset sluggers.
    static func signatureBat(for preset: PresetID) -> Bat {
        switch preset {
        case .santa:
            return Bat(id: "bat-giftwrap", name: "Gift Wrap Roll",
                       object: .giftWrap, power: 3, speed: 4, isCustom: false)
        case .trump:
            return Bat(id: "bat-driver", name: "Driver",
                       object: .driver, power: 4, speed: 4, isCustom: false)
        case .ballplayer:
            return Bat(id: "bat-classic", name: "Classic Bat",
                       object: .classicBat, power: 4, speed: 4, isCustom: false)
        case .bigfoot:
            return Bat(id: "bat-baretree", name: "Bare Tree",
                       object: .bareTree, power: 6, speed: 2, isCustom: false)
        case .snowman:
            return Bat(id: "bat-iceclub", name: "Ice Club",
                       object: .iceClub, power: 4, speed: 2, isCustom: false)
        }
    }
}

// MARK: - Sluggers

/// Face styles for Build-a-Slugger. Each is drawn with original shapes.
enum FaceStyle: String, CaseIterable, Identifiable, Codable {
    case swoop, spikes, tuft, curls, flatTop, mohawk

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .swoop: return "Swoop"
        case .spikes: return "Spikes"
        case .tuft: return "Tuft"
        case .curls: return "Curls"
        case .flatTop: return "Flat Top"
        case .mohawk: return "Mohawk"
        }
    }
}

/// Hats for Build-a-Slugger, drawn with original shapes.
enum HatStyle: String, CaseIterable, Identifiable, Codable {
    case cap, topHat, crown, gradCap, hardHat, sunHat, helmet, santaHat, none

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cap: return "Cap"
        case .topHat: return "Top Hat"
        case .crown: return "Crown"
        case .gradCap: return "Grad Cap"
        case .hardHat: return "Hard Hat"
        case .sunHat: return "Sun Hat"
        case .helmet: return "Helmet"
        case .santaHat: return "Santa Hat"
        case .none: return "No Hat"
        }
    }
}

/// A slugger: either one of the five presets or a custom build.
struct Slugger: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var preset: PresetID?
    var face: FaceStyle
    var hat: HatStyle
    var jerseyColor: ColorChoice
    var expression: ExpressionStyle = .grin
    var isCustom: Bool

    static func presetSlugger(_ preset: PresetID) -> Slugger {
        Slugger(id: "slugger-\(preset.rawValue)", name: preset.displayName,
                preset: preset, face: .swoop, hat: .none,
                jerseyColor: .red, isCustom: false)
    }

    static let defaultCustom = Slugger(id: "slugger-custom", name: "My Slugger",
                                       preset: nil, face: .swoop, hat: .cap,
                                       jerseyColor: .blue, isCustom: true)
}

/// Jersey colors for custom sluggers.
enum ColorChoice: String, CaseIterable, Identifiable, Codable {
    case red, blue, green, purple, orange, teal

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: return Color(red: 0.85, green: 0.20, blue: 0.20)
        case .blue: return Color(red: 0.20, green: 0.45, blue: 0.85)
        case .green: return Color(red: 0.20, green: 0.65, blue: 0.30)
        case .purple: return Color(red: 0.55, green: 0.30, blue: 0.80)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.15)
        case .teal: return Color(red: 0.10, green: 0.65, blue: 0.65)
        }
    }

    var displayName: String { rawValue.capitalized }
}

// MARK: - Sayings

/// Post-swing sayings, tiered by hit size. Thresholds are in the season's
/// displayed unit (never feet): big >= 280, medium 150...279, small 1...149,
/// miss = 0 (whiff or no contact).
enum HitTier {
    case big, medium, small, miss

    static func tier(for distance: Int, swung: Bool) -> HitTier {
        guard swung else { return .miss }
        switch distance {
        case 280...: return .big
        case 150..<280: return .medium
        case 1..<150: return .small
        default: return .miss
        }
    }
}

struct Sayings {
    static let big = [
        "It's outta here!",
        "Bye-bye!",
        "See ya!",
        "Oooooofffff!",
        "That one is GONE!",
        "Somebody get that ball a passport!",
    ]

    static let medium = [
        "Not bad… for you",
        "Solid-ish. If you squint, that's almost impressive",
        "Okay, that one actually left the infield. Barely",
        "Hey, it moved! Progress!",
    ]

    static let small = [
        "Nice swing, Alice",
        "Your mom swings harder than that",
        "Wow, that sucked",
        "My grandma's sneeze went further than that",
        "Did you swing with your eyes closed?",
    ]

    static let miss = [
        "Swing and a miss!",
        "You whiffed it!",
        "The ball called — it said nice try.",
        "Strike! And not the good kind.",
    ]

    static func random(for tier: HitTier) -> String {
        switch tier {
        case .big: return big.randomElement() ?? big[0]
        case .medium: return medium.randomElement() ?? medium[0]
        case .small: return small.randomElement() ?? small[0]
        case .miss: return miss.randomElement() ?? miss[0]
        }
    }

    static func resultLabel(for tier: HitTier) -> String {
        switch tier {
        case .big: return "What a blast!"
        case .medium: return "Solid-ish hit… don't brag!"
        case .small: return "Ouch. That one hurt to watch."
        case .miss: return "Whiff!"
        }
    }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var playerName: String
    var characterName: String
    var season: Season
    var distance: Int
    var date: Date = Date()

    var distanceText: String {
        "It flew \(distance) \(season.unitName(for: distance))!"
    }
}

// MARK: - App screens

enum Screen {
    case home
    case characters
    case seasons
    case buildSlugger
    case buildBat
    case game
    case leaderboard
}
