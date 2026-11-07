// Models.swift
// Core data types for "How Far Can You Hit It?"
// All character and bat art is original SwiftUI shapes drawn in
// CharacterArt.swift and BatArt.swift. No licensed characters, no
// trademarked bat names. Distance is measured in feet.

import SwiftUI

// MARK: - Seasons

/// The three seasons the player can pick. Distance is measured in feet
/// in every season; the season only changes the field decoration.
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

    /// Distance is measured in feet in every season.
    var unitSingular: String { "foot" }

    var unitPlural: String { "feet" }

    func unitName(for distance: Int) -> String {
        distance == 1 ? unitSingular : unitPlural
    }

    /// What the season decorates the field with (minimal).
    var decoration: String {
        switch self {
        case .fall: return "A few pumpkins on the ground"
        case .christmas: return "Christmas lights dangling"
        case .normal: return "Plain field, no decoration"
        }
    }

}

// MARK: - Preset characters

/// The six free out-of-the-box sluggers.
enum PresetID: String, CaseIterable, Identifiable, Codable {
    case santa
    case ballplayer
    case bigfoot
    case snowman
    case princess
    case adventurer

    var id: String { rawValue }

    /// Front-facing portrait asset (the fun pose on the Home screen and in
    /// the character picker). Portraits live in Sprites/ as
    /// portrait-<preset>.base64.txt and decode to the same name.
    var portraitAsset: String { "portrait-\(rawValue)" }

    var displayName: String {
        switch self {
        case .santa: return "Santa"
        case .ballplayer: return "The Ballplayer"
        case .bigfoot: return "Bigfoot"
        case .snowman: return "Snowman"
        case .princess: return "Princess Tillie"
        case .adventurer: return "Indiana Jane"
        }
    }

    var tagline: String {
        switch self {
        case .santa: return "Jolly, fast, and slightly out of breath."
        case .ballplayer: return "A kid with a dream and a big bat."
        case .bigfoot: return "He was never lost. He was practicing."
        case .snowman: return "Tall, skinny, and freezing cold."
        case .princess: return "Royalty with a really big microphone."
        case .adventurer: return "She explores. She swings. She conquers."
        }
    }
}

// MARK: - Sprite catalog (illustrated characters)

/// One illustrated sprite in the catalog: the five presets plus the
/// Build-a-Slugger variations. Cut lines are fractions of the image height;
/// the sprites are cropped at 92% (home plate + ground shadow removed), so
/// the fractions below are relative to the cropped image. The grip is where
/// the hands hold the bat, as a fraction of the image.
struct SpriteSpec: Identifiable {
    let id: String
    let displayName: String
    let headEnd: CGFloat
    let torsoEnd: CGFloat
    let grip: CGPoint

    /// Source pixels the stacked parts overlap by when composing a custom.
    static let overlap: CGFloat = 6
}

enum SpriteCatalog {
    static let all: [SpriteSpec] = [
        SpriteSpec(id: "santa", displayName: "Santa",
                   headEnd: 0.500, torsoEnd: 0.728, grip: CGPoint(x: 0.70, y: 0.30)),
        SpriteSpec(id: "ballplayer", displayName: "The Ballplayer",
                   headEnd: 0.500, torsoEnd: 0.674, grip: CGPoint(x: 0.79, y: 0.35)),
        SpriteSpec(id: "bigfoot", displayName: "Bigfoot",
                   headEnd: 0.391, torsoEnd: 0.652, grip: CGPoint(x: 0.68, y: 0.18)),
        SpriteSpec(id: "snowman", displayName: "Snowman",
                   headEnd: 0.480, torsoEnd: 0.739, grip: CGPoint(x: 0.84, y: 0.20)),
        SpriteSpec(id: "princess", displayName: "Princess Tillie",
                   headEnd: 0.45, torsoEnd: 0.62, grip: CGPoint(x: 0.78, y: 0.38)),
        SpriteSpec(id: "adventurer", displayName: "Indiana Jane",
                   headEnd: 0.45, torsoEnd: 0.60, grip: CGPoint(x: 0.80, y: 0.38)),
        SpriteSpec(id: "santa-yardcap", displayName: "Yard-Cap Santa",
                   headEnd: 0.500, torsoEnd: 0.728, grip: CGPoint(x: 0.75, y: 0.29)),
        SpriteSpec(id: "pumpkin-head", displayName: "Pumpkin Head",
                   headEnd: 0.500, torsoEnd: 0.674, grip: CGPoint(x: 0.79, y: 0.33)),
        SpriteSpec(id: "santa-greensweater", displayName: "Green Sweater Santa",
                   headEnd: 0.500, torsoEnd: 0.728, grip: CGPoint(x: 0.74, y: 0.29)),
        SpriteSpec(id: "reindeer-head", displayName: "Reindeer Head",
                   headEnd: 0.391, torsoEnd: 0.652, grip: CGPoint(x: 0.68, y: 0.18)),
        SpriteSpec(id: "girl-head", displayName: "Slugger Girl",
                   headEnd: 0.500, torsoEnd: 0.674, grip: CGPoint(x: 0.79, y: 0.33)),
        SpriteSpec(id: "pirate-head", displayName: "Pirate Head",
                   headEnd: 0.391, torsoEnd: 0.652, grip: CGPoint(x: 0.68, y: 0.18)),
        SpriteSpec(id: "halloween-jersey", displayName: "Halloween Jersey",
                   headEnd: 0.500, torsoEnd: 0.674, grip: CGPoint(x: 0.79, y: 0.33)),
        SpriteSpec(id: "santa-elfhat", displayName: "Elf-Hat Santa",
                   headEnd: 0.500, torsoEnd: 0.728, grip: CGPoint(x: 0.74, y: 0.29)),
        SpriteSpec(id: "snowman-tophat", displayName: "Top-Hat Snowman",
                   headEnd: 0.480, torsoEnd: 0.739, grip: CGPoint(x: 0.84, y: 0.20)),
        SpriteSpec(id: "bigfoot-hoodie", displayName: "Hoodie Bigfoot",
                   headEnd: 0.391, torsoEnd: 0.652, grip: CGPoint(x: 0.68, y: 0.18)),
        SpriteSpec(id: "santa-greenpants", displayName: "Green-Pants Santa",
                   headEnd: 0.500, torsoEnd: 0.728, grip: CGPoint(x: 0.74, y: 0.29)),
        SpriteSpec(id: "ballplayer-sunglasses", displayName: "Cool Shades Ballplayer",
                   headEnd: 0.500, torsoEnd: 0.674, grip: CGPoint(x: 0.79, y: 0.33)),
        SpriteSpec(id: "ballplayer-greenjersey", displayName: "Green Jersey Ballplayer",
                   headEnd: 0.500, torsoEnd: 0.674, grip: CGPoint(x: 0.79, y: 0.33)),
        SpriteSpec(id: "snowman-bluescarf", displayName: "Blue-Scarf Snowman",
                   headEnd: 0.480, torsoEnd: 0.739, grip: CGPoint(x: 0.84, y: 0.20)),
    ]

    static func spec(for id: String) -> SpriteSpec {
        all.first { $0.id == id } ?? all[0]
    }
}

// MARK: - Bats

/// Every bat object that can appear in the game. Preset characters each have
/// one signature bat; custom bats pick one object and split 8 points.
enum BatObject: String, CaseIterable, Identifiable, Codable {
    case giftWrap
    case classicBat
    case bareTree
    case iceClub
    case cavemanClub
    case baguette
    case magicWand
    case scepter
    case machete
    case microphone
    case goldenBat

    var id: String { rawValue }

    /// Objects a player may pick in Build-a-Bat. The Golden Bat is
    /// excluded: it is earned only by reaching level 10 on the premium
    /// season pass, never built for free.
    static var buildableObjects: [BatObject] {
        allCases.filter { $0 != .goldenBat }
    }

    var displayName: String {
        switch self {
        case .giftWrap: return "Gift Wrap Roll"
        // Generic classic American baseball bat shape. Never a brand name.
        case .classicBat: return "Classic Bat"
        // The case is still named bareTree (its raw value is stored in saved
        // bats), but it now draws a wooden club — Bruce's call, 2026-11-05:
        // the tree "didn't look like anything" next to a real club.
        case .bareTree: return "Wooden Club"
        case .iceClub: return "Ice Club"
        case .cavemanClub: return "Caveman Club"
        case .baguette: return "Baguette"
        case .magicWand: return "Magic Wand"
        case .scepter: return "Royal Scepter"
        case .machete: return "Machete"
        case .microphone: return "Microphone"
        case .goldenBat: return "Golden Bat"
        }
    }
}

/// A bat: an object plus power/speed stats. Custom bats always sum to 8.
/// Certain bats and clubs carry a power boost — a percentage increase to
/// hit distance (Bruce's call, build 18: 1%–10%). The boost comes from
/// the bat itself (signature bats) and from upgrades (custom bats).
struct Bat: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var object: BatObject
    var power: Int   // 1...7
    var speed: Int   // 1...7
    var isCustom: Bool
    /// Power boost as a fraction: 0.10 = +10% distance. Signature bats
    /// have a fixed boost; custom bats gain it from upgrades.
    var powerBoost: Double = 0
    /// Upgrade level, 0...5. Each level adds +2% power boost (max +10%).
    var upgradeLevel: Int = 0

    /// Whole-number percent for display, e.g. 10 for +10%.
    var powerBoostPercent: Int { Int((powerBoost * 100).rounded()) }

    /// Coins to buy the next upgrade level (level is 0-based here).
    /// Level 1 costs 100, then 250, 500, 1000, 2000.
    static func upgradeCost(for level: Int) -> Int {
        switch level {
        case 0: return 100
        case 1: return 250
        case 2: return 500
        case 3: return 1000
        default: return 2000
        }
    }

    static let maxUpgradeLevel = 5

    /// Signature bats for the six preset sluggers. Each carries a power
    /// boost: the heavy clubs hit hardest, the light ones less so.
    static func signatureBat(for preset: PresetID) -> Bat {
        switch preset {
        case .santa:
            return Bat(id: "bat-giftwrap", name: "Gift Wrap Roll",
                       object: .giftWrap, power: 3, speed: 4, isCustom: false,
                       powerBoost: 0.03)
        case .ballplayer:
            return Bat(id: "bat-classic", name: "Classic Bat",
                       object: .classicBat, power: 4, speed: 4, isCustom: false,
                       powerBoost: 0.05)
        case .bigfoot:
            return Bat(id: "bat-baretree", name: "Wooden Club",
                       object: .bareTree, power: 6, speed: 2, isCustom: false,
                       powerBoost: 0.10)
        case .snowman:
            return Bat(id: "bat-iceclub", name: "Ice Club",
                       object: .iceClub, power: 4, speed: 2, isCustom: false,
                       powerBoost: 0.04)
        case .princess:
            return Bat(id: "bat-microphone", name: "Microphone",
                       object: .microphone, power: 5, speed: 3, isCustom: false,
                       powerBoost: 0.08)
        case .adventurer:
            return Bat(id: "bat-machete", name: "Machete",
                       object: .machete, power: 3, speed: 5, isCustom: false,
                       powerBoost: 0.06)
        }
    }

    /// The Golden Bat: the level-10 premium season-pass reward.
    /// It lives in the player's "My Bats" list (isCustom: true) so it can
    /// be picked in the bat picker, but it is already maxed out
    /// (upgradeLevel 5, +10%) so the upgrade button never shows for it.
    static func goldenBat() -> Bat {
        Bat(id: "bat-golden", name: "Golden Bat",
            object: .goldenBat, power: 5, speed: 4, isCustom: true,
            powerBoost: 0.10, upgradeLevel: Bat.maxUpgradeLevel)
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
/// Customs are built from illustrated sprite parts: a head, a torso, and
/// legs, each picked from the 20-entry sprite catalog.
struct Slugger: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var preset: PresetID?
    var face: FaceStyle
    var hat: HatStyle
    var jerseyColor: ColorChoice
    var expression: ExpressionStyle = .grin
    var isCustom: Bool
    /// Build-a-Slugger part assets (sprite catalog ids). Ignored for presets.
    var headAsset: String = "santa"
    var torsoAsset: String = "santa"
    var legsAsset: String = "santa"

    static func presetSlugger(_ preset: PresetID) -> Slugger {
        Slugger(id: "slugger-\(preset.rawValue)", name: preset.displayName,
                preset: preset, face: .swoop, hat: .none,
                jerseyColor: .red, isCustom: false)
    }

    static let defaultCustom = Slugger(id: "slugger-custom", name: "My Slugger",
                                       preset: nil, face: .swoop, hat: .cap,
                                       jerseyColor: .blue, isCustom: true,
                                       headAsset: "santa-yardcap", torsoAsset: "santa",
                                       legsAsset: "santa")
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

/// Post-swing sayings, tiered by hit size. Thresholds are in feet:
/// big >= 280, medium 150...279, small 1...149, miss = 0 (whiff or no contact).
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
    case seasonPass
}
