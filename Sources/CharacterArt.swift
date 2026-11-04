// CharacterArt.swift
// Original cartoon character art drawn with SwiftUI shapes.
// Goofy exaggerated style: big heads, big expressions, cartoonish.
// The snowman is a generic funny snowman, drawn from scratch.

import SwiftUI

/// Renders any slugger (preset or custom) in a 150 x 190 frame.
struct SluggerArtView: View {
    let slugger: Slugger

    var body: some View {
        ZStack {
            switch slugger.preset {
            case .santa: SantaArt()
            case .trump: TrumpArt()
            case .ballplayer: BallplayerArt()
            case .bigfoot: BigfootArt()
            case .snowman: SnowmanArt()
            case .none: CustomSluggerArt(slugger: slugger, expression: slugger.expression)
            }
        }
        .frame(width: 150, height: 190)
    }
}

// MARK: - Helpers

/// Simple triangle path, used for hats, noses, ties, mountains.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private let skin = Color(red: 0.98, green: 0.80, blue: 0.62)
private let skinShadow = Color(red: 0.93, green: 0.68, blue: 0.48)

// MARK: - Santa

struct SantaArt: View {
    var body: some View {
        ZStack {
            // Legs + boots
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.55, green: 0.10, blue: 0.12))
                .frame(width: 18, height: 42)
                .offset(x: -18, y: 72)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.55, green: 0.10, blue: 0.12))
                .frame(width: 18, height: 42)
                .offset(x: 18, y: 72)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.15, green: 0.12, blue: 0.10))
                .frame(width: 26, height: 16)
                .offset(x: -18, y: 90)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.15, green: 0.12, blue: 0.10))
                .frame(width: 26, height: 16)
                .offset(x: 18, y: 90)
            // Coat
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.82, green: 0.15, blue: 0.15))
                .frame(width: 84, height: 66)
                .offset(y: 28)
            Rectangle()
                .fill(Color.white)
                .frame(width: 84, height: 12)
                .offset(y: 56)
            Rectangle()
                .fill(Color(red: 0.10, green: 0.10, blue: 0.10))
                .frame(width: 84, height: 10)
                .offset(y: 30)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.yellow)
                .frame(width: 18, height: 16)
                .offset(y: 30)
            // Head
            Circle()
                .fill(skin)
                .frame(width: 66, height: 66)
                .offset(y: -42)
            // Huge flowing beard
            Ellipse()
                .fill(Color.white)
                .frame(width: 78, height: 52)
                .offset(y: -12)
            Ellipse()
                .fill(Color.white)
                .frame(width: 40, height: 22)
                .offset(y: -28)
            // Big pink nose
            Circle()
                .fill(Color(red: 0.98, green: 0.55, blue: 0.55))
                .frame(width: 22, height: 22)
                .offset(y: -32)
            // Cross-eyed grin
            Circle().fill(Color.black).frame(width: 6, height: 6).offset(x: -14, y: -52)
            Circle().fill(Color.black).frame(width: 6, height: 6).offset(x: 14, y: -52)
            Circle().fill(Color.white).frame(width: 2.5, height: 2.5).offset(x: -12, y: -53)
            Circle().fill(Color.white).frame(width: 2.5, height: 2.5).offset(x: 12, y: -53)
            // Rosy cheeks
            Circle().fill(Color(red: 0.98, green: 0.65, blue: 0.60))
                .frame(width: 12, height: 12).offset(x: -26, y: -38)
            Circle().fill(Color(red: 0.98, green: 0.65, blue: 0.60))
                .frame(width: 12, height: 12).offset(x: 26, y: -38)
            // Floppy hat
            Triangle()
                .fill(Color(red: 0.82, green: 0.15, blue: 0.15))
                .frame(width: 56, height: 42)
                .offset(x: 8, y: -84)
                .rotationEffect(.degrees(18))
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 72, height: 14)
                .offset(y: -66)
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .offset(x: 32, y: -100)
        }
    }
}

// MARK: - Donald Trump (original caricature)

struct TrumpArt: View {
    var body: some View {
        ZStack {
            // Legs + shoes
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.15, green: 0.20, blue: 0.35))
                .frame(width: 18, height: 40)
                .offset(x: -16, y: 74)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.15, green: 0.20, blue: 0.35))
                .frame(width: 18, height: 40)
                .offset(x: 16, y: 74)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.25, green: 0.18, blue: 0.12))
                .frame(width: 26, height: 14)
                .offset(x: -16, y: 90)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.25, green: 0.18, blue: 0.12))
                .frame(width: 26, height: 14)
                .offset(x: 16, y: 90)
            // Suit + shirt + long red tie
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.12, green: 0.18, blue: 0.38))
                .frame(width: 84, height: 66)
                .offset(y: 30)
            Triangle()
                .fill(Color.white)
                .frame(width: 26, height: 26)
                .offset(y: 4)
            Triangle()
                .fill(Color(red: 0.85, green: 0.12, blue: 0.12))
                .frame(width: 14, height: 52)
                .offset(y: 28)
            // Big head
            Circle()
                .fill(skin)
                .frame(width: 74, height: 74)
                .offset(y: -40)
            // Signature blond swoop / comb-over
            Ellipse()
                .fill(Color(red: 0.98, green: 0.80, blue: 0.30))
                .frame(width: 84, height: 34)
                .offset(y: -66)
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.98, green: 0.80, blue: 0.30))
                .frame(width: 72, height: 16)
                .offset(x: -4, y: -58)
                .rotationEffect(.degrees(-8))
            Ellipse()
                .fill(Color(red: 0.95, green: 0.72, blue: 0.22))
                .frame(width: 20, height: 26)
                .offset(x: -36, y: -50)
            // Furrowed scowl
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.95, green: 0.72, blue: 0.22))
                .frame(width: 22, height: 6)
                .offset(x: -15, y: -56)
                .rotationEffect(.degrees(12))
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.95, green: 0.72, blue: 0.22))
                .frame(width: 22, height: 6)
                .offset(x: 15, y: -56)
                .rotationEffect(.degrees(-12))
            Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: -15, y: -44)
            Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: 15, y: -44)
            // Scowl mouth
            Capsule()
                .fill(Color(red: 0.55, green: 0.30, blue: 0.25))
                .frame(width: 26, height: 7)
                .offset(y: -20)
        }
    }
}

// MARK: - The Ballplayer

struct BallplayerArt: View {
    var body: some View {
        ZStack {
            // Legs + cleats
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 18, height: 40)
                .offset(x: -16, y: 74)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 18, height: 40)
                .offset(x: 16, y: 74)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                .frame(width: 26, height: 14)
                .offset(x: -16, y: 90)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                .frame(width: 26, height: 14)
                .offset(x: 16, y: 90)
            // Pinstripe jersey
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .frame(width: 82, height: 64)
                .offset(y: 30)
            ForEach([-24, -12, 0, 12, 24], id: \.self) { x in
                Rectangle()
                    .fill(Color(red: 0.20, green: 0.40, blue: 0.80))
                    .frame(width: 2, height: 64)
                    .offset(x: CGFloat(x), y: 30)
            }
            // Big head
            Circle()
                .fill(skin)
                .frame(width: 70, height: 70)
                .offset(y: -40)
            // Cap
            Ellipse()
                .fill(Color(red: 0.15, green: 0.30, blue: 0.75))
                .frame(width: 74, height: 34)
                .offset(y: -66)
            Ellipse()
                .fill(Color(red: 0.15, green: 0.30, blue: 0.75))
                .frame(width: 40, height: 12)
                .offset(x: 26, y: -56)
            // Freckles + big missing-tooth grin
            Circle().fill(Color(red: 0.75, green: 0.50, blue: 0.30))
                .frame(width: 4, height: 4).offset(x: -20, y: -34)
            Circle().fill(Color(red: 0.75, green: 0.50, blue: 0.30))
                .frame(width: 4, height: 4).offset(x: -13, y: -32)
            Circle().fill(Color(red: 0.75, green: 0.50, blue: 0.30))
                .frame(width: 4, height: 4).offset(x: 20, y: -34)
            Circle().fill(Color(red: 0.75, green: 0.50, blue: 0.30))
                .frame(width: 4, height: 4).offset(x: 13, y: -32)
            Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: -14, y: -48)
            Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: 14, y: -48)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 34, height: 14)
                .offset(y: -22)
            Rectangle()
                .fill(skin)
                .frame(width: 6, height: 14)
                .offset(y: -22)
        }
    }
}

// MARK: - Bigfoot

struct BigfootArt: View {
    var body: some View {
        ZStack {
            // Big feet
            Ellipse()
                .fill(Color(red: 0.45, green: 0.30, blue: 0.20))
                .frame(width: 44, height: 18)
                .offset(x: -20, y: 90)
            Ellipse()
                .fill(Color(red: 0.45, green: 0.30, blue: 0.20))
                .frame(width: 44, height: 18)
                .offset(x: 20, y: 90)
            // Furry legs + plaid shirt
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.45, green: 0.30, blue: 0.20))
                .frame(width: 20, height: 40)
                .offset(x: -18, y: 70)
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.45, green: 0.30, blue: 0.20))
                .frame(width: 20, height: 40)
                .offset(x: 18, y: 70)
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.75, green: 0.15, blue: 0.15))
                .frame(width: 86, height: 62)
                .offset(y: 30)
            ForEach([-24, 0, 24], id: \.self) { x in
                Rectangle()
                    .fill(Color(red: 0.45, green: 0.05, blue: 0.05))
                    .frame(width: 5, height: 62)
                    .offset(x: CGFloat(x), y: 30)
            }
            Rectangle()
                .fill(Color(red: 0.45, green: 0.05, blue: 0.05))
                .frame(width: 86, height: 5)
                .offset(y: 30)
            // Shaggy head + face
            Circle()
                .fill(Color(red: 0.45, green: 0.30, blue: 0.20))
                .frame(width: 74, height: 74)
                .offset(y: -40)
            Ellipse()
                .fill(Color(red: 0.85, green: 0.70, blue: 0.55))
                .frame(width: 52, height: 44)
                .offset(y: -32)
            // USA cap
            Ellipse()
                .fill(Color(red: 0.15, green: 0.25, blue: 0.65))
                .frame(width: 76, height: 32)
                .offset(y: -66)
            Ellipse()
                .fill(Color(red: 0.85, green: 0.15, blue: 0.15))
                .frame(width: 40, height: 10)
                .offset(x: 28, y: -56)
            Text("USA")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(Color.white)
                .offset(y: -68)
            // Gold-rimmed shades + giant toothy grin
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.black)
                .frame(width: 52, height: 16)
                .offset(y: -48)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.95, green: 0.75, blue: 0.20))
                .frame(width: 56, height: 20)
                .offset(y: -48)
                .opacity(0.25)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 36, height: 14)
                .offset(y: -20)
            ForEach([-9, 0, 9], id: \.self) { x in
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 1.5, height: 14)
                    .offset(x: CGFloat(x), y: -20)
            }
        }
    }
}

// MARK: - Generic funny Snowman

struct SnowmanArt: View {
    var body: some View {
        ZStack {
            // Stick legs + red boots
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.45, green: 0.30, blue: 0.18))
                .frame(width: 6, height: 34)
                .offset(x: -14, y: 74)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.45, green: 0.30, blue: 0.18))
                .frame(width: 6, height: 34)
                .offset(x: 14, y: 74)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.85, green: 0.12, blue: 0.12))
                .frame(width: 26, height: 16)
                .offset(x: -14, y: 90)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.85, green: 0.12, blue: 0.12))
                .frame(width: 26, height: 16)
                .offset(x: 14, y: 90)
            // Belly + chest
            Circle()
                .fill(Color.white)
                .frame(width: 72, height: 72)
                .offset(y: 40)
            Circle()
                .fill(Color.white)
                .frame(width: 56, height: 56)
                .offset(y: -8)
            // Coal buttons
            Circle().fill(Color.black).frame(width: 7, height: 7).offset(y: 22)
            Circle().fill(Color.black).frame(width: 7, height: 7).offset(y: 38)
            Circle().fill(Color.black).frame(width: 7, height: 7).offset(y: 54)
            // Twig arms
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.45, green: 0.30, blue: 0.18))
                .frame(width: 34, height: 5)
                .offset(x: -48, y: -4)
                .rotationEffect(.degrees(-24))
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.45, green: 0.30, blue: 0.18))
                .frame(width: 34, height: 5)
                .offset(x: 48, y: -4)
                .rotationEffect(.degrees(24))
            // Enormous red scarf
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.85, green: 0.12, blue: 0.12))
                .frame(width: 60, height: 14)
                .offset(y: -32)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.85, green: 0.12, blue: 0.12))
                .frame(width: 14, height: 40)
                .offset(x: 16, y: -10)
            // Tiny head + long carrot nose
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .offset(y: -58)
            Circle().fill(Color.black).frame(width: 6, height: 6).offset(x: -11, y: -64)
            Circle().fill(Color.black).frame(width: 6, height: 6).offset(x: 11, y: -64)
            Triangle()
                .fill(Color.orange)
                .frame(width: 12, height: 26)
                .offset(x: 14, y: -56)
                .rotationEffect(.degrees(90))
            // Beanie with pom
            Ellipse()
                .fill(Color(red: 0.25, green: 0.55, blue: 0.30))
                .frame(width: 54, height: 26)
                .offset(y: -80)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.85, green: 0.12, blue: 0.12))
                .frame(width: 54, height: 10)
                .offset(y: -70)
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .offset(y: -94)
        }
    }
}

// MARK: - Custom slugger (Build-a-Slugger)

// Expression options for custom sluggers.
enum ExpressionStyle: String, CaseIterable, Identifiable, Codable {
    case grin, tongue, shades, wow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grin: return "Big Grin"
        case .tongue: return "Tongue Out"
        case .shades: return "Shades Smirk"
        case .wow: return "Wide-Eyed Wow"
        }
    }
}

/// A custom slugger: smaller body, larger goofy head, cartoonish person.
struct CustomSluggerArt: View {
    let slugger: Slugger
    var expression: ExpressionStyle = .grin

    var body: some View {
        ZStack {
            // Short legs + shoes
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.25, green: 0.25, blue: 0.30))
                .frame(width: 14, height: 26)
                .offset(x: -13, y: 78)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.25, green: 0.25, blue: 0.30))
                .frame(width: 14, height: 26)
                .offset(x: 13, y: 78)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                .frame(width: 22, height: 12)
                .offset(x: -13, y: 90)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                .frame(width: 22, height: 12)
                .offset(x: 13, y: 90)
            // Small jersey body
            RoundedRectangle(cornerRadius: 12)
                .fill(slugger.jerseyColor.color)
                .frame(width: 56, height: 40)
                .offset(y: 52)
            // Oversized goofy head (about two-thirds of the figure)
            Circle()
                .fill(skin)
                .frame(width: 86, height: 86)
                .offset(y: -12)
            // Hair by style
            HairArt(style: slugger.face)
            // Expression
            ExpressionArt(style: expression)
            // Hat
            HatArt(style: slugger.hat)
        }
    }
}

/// Hair shapes for each custom face style.
struct HairArt: View {
    let style: FaceStyle

    var body: some View {
        ZStack {
            switch style {
            case .swoop:
                Ellipse()
                    .fill(Color(red: 0.35, green: 0.22, blue: 0.12))
                    .frame(width: 88, height: 30)
                    .offset(y: -46)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.35, green: 0.22, blue: 0.12))
                    .frame(width: 66, height: 12)
                    .offset(x: -4, y: -38)
                    .rotationEffect(.degrees(-8))
            case .spikes:
                ForEach([-30, -15, 0, 15, 30], id: \.self) { x in
                    Triangle()
                        .fill(Color(red: 0.20, green: 0.15, blue: 0.12))
                        .frame(width: 16, height: 22)
                        .offset(x: CGFloat(x), y: -52)
                }
            case .tuft:
                Circle().fill(Color(red: 0.35, green: 0.22, blue: 0.12))
                    .frame(width: 22, height: 22).offset(x: -8, y: -54)
                Circle().fill(Color(red: 0.35, green: 0.22, blue: 0.12))
                    .frame(width: 16, height: 16).offset(x: 10, y: -56)
            case .curls:
                ForEach([-28, -10, 8, 26], id: \.self) { x in
                    Circle().fill(Color(red: 0.25, green: 0.15, blue: 0.10))
                        .frame(width: 24, height: 24)
                        .offset(x: CGFloat(x), y: -50)
                }
            case .flatTop:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.15, green: 0.12, blue: 0.10))
                    .frame(width: 72, height: 16)
                    .offset(y: -52)
            case .mohawk:
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.85, green: 0.20, blue: 0.20))
                    .frame(width: 18, height: 34)
                    .offset(y: -58)
            }
        }
    }
}

/// Eyes + mouth for each custom expression.
struct ExpressionArt: View {
    let style: ExpressionStyle

    var body: some View {
        ZStack {
            switch style {
            case .grin:
                Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: -16, y: -16)
                Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: 16, y: -16)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white)
                    .frame(width: 36, height: 14)
                    .offset(y: 8)
                Rectangle().fill(skin).frame(width: 6, height: 14).offset(y: 8)
            case .tongue:
                Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: -16, y: -16)
                Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: 16, y: -16)
                Ellipse().fill(Color(red: 0.35, green: 0.15, blue: 0.15))
                    .frame(width: 30, height: 18).offset(y: 8)
                Capsule().fill(Color(red: 0.95, green: 0.45, blue: 0.55))
                    .frame(width: 14, height: 18).offset(y: 14)
            case .shades:
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.black)
                    .frame(width: 56, height: 16)
                    .offset(y: -16)
                Capsule().fill(Color(red: 0.55, green: 0.30, blue: 0.25))
                    .frame(width: 22, height: 6).offset(x: 6, y: 10)
                    .rotationEffect(.degrees(-10))
            case .wow:
                Circle().fill(Color.white).frame(width: 16, height: 16).offset(x: -16, y: -16)
                Circle().fill(Color.white).frame(width: 16, height: 16).offset(x: 16, y: -16)
                Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: -16, y: -16)
                Circle().fill(Color.black).frame(width: 7, height: 7).offset(x: 16, y: -16)
                Ellipse().fill(Color(red: 0.35, green: 0.15, blue: 0.15))
                    .frame(width: 14, height: 18).offset(y: 10)
            }
        }
    }
}

/// Hats drawn on top of a custom slugger's head.
struct HatArt: View {
    let style: HatStyle

    var body: some View {
        ZStack {
            switch style {
            case .cap:
                Ellipse().fill(Color(red: 0.15, green: 0.30, blue: 0.75))
                    .frame(width: 80, height: 30).offset(y: -46)
                Ellipse().fill(Color(red: 0.15, green: 0.30, blue: 0.75))
                    .frame(width: 38, height: 10).offset(x: 30, y: -36)
            case .topHat:
                RoundedRectangle(cornerRadius: 4).fill(Color.black)
                    .frame(width: 44, height: 44).offset(y: -62)
                Ellipse().fill(Color.black)
                    .frame(width: 72, height: 12).offset(y: -40)
            case .crown:
                Triangle().fill(Color.yellow)
                    .frame(width: 60, height: 26).offset(y: -56)
                Circle().fill(Color.red).frame(width: 8, height: 8).offset(y: -64)
                Circle().fill(Color.blue).frame(width: 8, height: 8).offset(x: -18, y: -58)
                Circle().fill(Color.green).frame(width: 8, height: 8).offset(x: 18, y: -58)
            case .gradCap:
                RoundedRectangle(cornerRadius: 2).fill(Color.black)
                    .frame(width: 72, height: 10).offset(y: -54)
                    .rotationEffect(.degrees(-4))
                Rectangle().fill(Color.yellow).frame(width: 2, height: 18).offset(x: 30, y: -42)
                Circle().fill(Color.yellow).frame(width: 8, height: 8).offset(x: 30, y: -32)
            case .hardHat:
                Ellipse().fill(Color.yellow)
                    .frame(width: 84, height: 30).offset(y: -46)
                RoundedRectangle(cornerRadius: 4).fill(Color.yellow)
                    .frame(width: 14, height: 12).offset(y: -60)
            case .sunHat:
                Ellipse().fill(Color(red: 0.95, green: 0.85, blue: 0.60))
                    .frame(width: 96, height: 14).offset(y: -38)
                Ellipse().fill(Color(red: 0.95, green: 0.85, blue: 0.60))
                    .frame(width: 56, height: 26).offset(y: -48)
            case .helmet:
                Ellipse().fill(Color(red: 0.75, green: 0.15, blue: 0.15))
                    .frame(width: 88, height: 36).offset(y: -44)
            case .santaHat:
                Triangle().fill(Color(red: 0.82, green: 0.15, blue: 0.15))
                    .frame(width: 56, height: 40).offset(x: 8, y: -62)
                    .rotationEffect(.degrees(16))
                RoundedRectangle(cornerRadius: 8).fill(Color.white)
                    .frame(width: 76, height: 12).offset(y: -44)
                Circle().fill(Color.white).frame(width: 14, height: 14).offset(x: 30, y: -78)
            case .none:
                EmptyView()
            }
        }
    }
}
