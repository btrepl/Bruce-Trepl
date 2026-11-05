// BatArt.swift
// Original bat art drawn with SwiftUI shapes. Every bat is drawn upright
// (handle at the bottom, head at the top) in a 40 x 120 frame so the game
// can rotate it around its bottom anchor like a real swing.

import SwiftUI

/// Renders any bat upright in a 40 x 120 frame.
struct BatArtView: View {
    let bat: Bat

    var body: some View {
        ZStack {
            switch bat.object {
            case .classicBat: ClassicBatArt()
            case .giftWrap: GiftWrapArt()
            case .driver: DriverArt()
            case .bareTree: BareTreeArt()
            case .iceClub: IceClubArt()
            case .cavemanClub: CavemanClubArt()
            case .baguette: BaguetteArt()
            case .magicWand: MagicWandArt()
            }
        }
        .frame(width: 40, height: 120)
        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 2, y: 3)
    }
}

// MARK: - Classic Bat (generic classic American baseball bat)

struct ClassicBatArt: View {
    var body: some View {
        ZStack {
            // Tapered barrel: narrow handle widening to a round barrel.
            Path { p in
                p.move(to: CGPoint(x: 17, y: 118))
                p.addLine(to: CGPoint(x: 17, y: 62))
                p.addQuadCurve(to: CGPoint(x: 20, y: 8),
                               control: CGPoint(x: 14, y: 34))
                p.addQuadCurve(to: CGPoint(x: 28, y: 8),
                               control: CGPoint(x: 24, y: 2))
                p.addQuadCurve(to: CGPoint(x: 26, y: 62),
                               control: CGPoint(x: 30, y: 34))
                p.addLine(to: CGPoint(x: 23, y: 118))
                p.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.92, green: 0.78, blue: 0.58), Color(red: 0.85, green: 0.68, blue: 0.45), Color(red: 0.68, green: 0.50, blue: 0.30)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            // Wood grain
            Path { p in
                p.move(to: CGPoint(x: 20, y: 100))
                p.addLine(to: CGPoint(x: 20, y: 20))
            }
            .stroke(Color(red: 0.65, green: 0.48, blue: 0.28), lineWidth: 1)
            // Barrel mark
            Ellipse()
                .fill(Color(red: 0.65, green: 0.48, blue: 0.28))
                .frame(width: 10, height: 6)
                .offset(y: -38)
            // Flared knob
            Ellipse()
                .fill(Color(red: 0.70, green: 0.52, blue: 0.32))
                .frame(width: 16, height: 8)
                .offset(y: 56)
        }
    }
}

// MARK: - Gift Wrap Roll (Santa's bat)

struct GiftWrapArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.85, green: 0.12, blue: 0.12))
                .frame(width: 26, height: 104)
            // Gold diagonal stripes, clipped to the roll
            ZStack {
                ForEach([-40, -16, 8, 32], id: \.self) { y in
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 40, height: 7)
                        .offset(y: CGFloat(y))
                        .rotationEffect(.degrees(-28))
                }
            }
            .frame(width: 26, height: 104)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            // Hollow cardboard end
            Ellipse()
                .fill(Color(red: 0.45, green: 0.32, blue: 0.20))
                .frame(width: 16, height: 8)
                .offset(y: -50)
            Ellipse()
                .fill(Color(red: 0.25, green: 0.17, blue: 0.10))
                .frame(width: 8, height: 4)
                .offset(y: -50)
        }
    }
}

// MARK: - Driver (Trump's bat: just a golf driver)

struct DriverArt: View {
    var body: some View {
        ZStack {
            // Grip + long thin shaft
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.20, green: 0.20, blue: 0.22))
                .frame(width: 9, height: 26)
                .offset(y: 46)
            Rectangle()
                .fill(Color.gray)
                .frame(width: 4, height: 66)
                .offset(y: 0)
            // One big rounded club head
            Ellipse()
                .fill(Color(red: 0.85, green: 0.87, blue: 0.90))
                .frame(width: 36, height: 26)
                .offset(y: -46)
            Ellipse()
                .fill(Color(red: 0.95, green: 0.97, blue: 1.0))
                .frame(width: 24, height: 14)
                .offset(y: -48)
        }
    }
}

// MARK: - Bare Tree (Bigfoot's bat: trunk + twigs, no leaves)

struct BareTreeArt: View {
    var body: some View {
        ZStack {
            // Trunk
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.45, green: 0.30, blue: 0.18))
                .frame(width: 10, height: 112)
            // Bare branches (no leaves anywhere)
            ForEach([(-28, -38), (28, -30), (-24, -52), (24, -46)], id: \.0) { pair in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.45, green: 0.30, blue: 0.18))
                    .frame(width: 26, height: 5)
                    .offset(y: CGFloat(pair.1))
                    .rotationEffect(.degrees(Double(pair.0)))
            }
            // Twigs
            ForEach([(-40, -58), (40, -54)], id: \.0) { pair in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.50, green: 0.35, blue: 0.22))
                    .frame(width: 16, height: 3.5)
                    .offset(y: CGFloat(pair.1))
                    .rotationEffect(.degrees(Double(pair.0)))
            }
        }
    }
}

// MARK: - Ice Club (Snowman's bat: chunky frozen club)

struct IceClubArt: View {
    var body: some View {
        ZStack {
            // Handle
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.75, green: 0.88, blue: 0.95))
                .frame(width: 10, height: 52)
                .offset(y: 32)
            // Chunky knobby frozen head
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.65, green: 0.85, blue: 0.95))
                .frame(width: 34, height: 56)
                .offset(y: -26)
            Circle()
                .fill(Color(red: 0.65, green: 0.85, blue: 0.95))
                .frame(width: 22, height: 22)
                .offset(x: -14, y: -44)
            Circle()
                .fill(Color(red: 0.65, green: 0.85, blue: 0.95))
                .frame(width: 18, height: 18)
                .offset(x: 14, y: -38)
            // Facets, cracks, icy shine
            Path { p in
                p.move(to: CGPoint(x: -8, y: -48))
                p.addLine(to: CGPoint(x: 6, y: -30))
                p.addLine(to: CGPoint(x: -4, y: -12))
            }
            .stroke(Color.white, lineWidth: 1.5)
            Path { p in
                p.move(to: CGPoint(x: 10, y: -50))
                p.addLine(to: CGPoint(x: 2, y: -36))
            }
            .stroke(Color.white, lineWidth: 1.5)
            Ellipse()
                .fill(Color.white)
                .frame(width: 10, height: 16)
                .offset(x: -8, y: -30)
                .opacity(0.7)
        }
    }
}

// MARK: - Caveman Club

struct CavemanClubArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.50, green: 0.35, blue: 0.22))
                .frame(width: 12, height: 56)
                .offset(y: 30)
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.55, green: 0.40, blue: 0.25))
                .frame(width: 30, height: 58)
                .offset(y: -26)
            Circle()
                .fill(Color(red: 0.60, green: 0.45, blue: 0.28))
                .frame(width: 16, height: 16)
                .offset(x: -10, y: -44)
            Circle()
                .fill(Color(red: 0.60, green: 0.45, blue: 0.28))
                .frame(width: 14, height: 14)
                .offset(x: 11, y: -40)
        }
    }
}

// MARK: - Baguette

struct BaguetteArt: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.90, green: 0.70, blue: 0.40))
                .frame(width: 20, height: 108)
            ForEach([-36, -12, 12, 36], id: \.self) { y in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.70, green: 0.50, blue: 0.25))
                    .frame(width: 16, height: 4)
                    .offset(y: CGFloat(y))
                    .rotationEffect(.degrees(-24))
            }
        }
    }
}

// MARK: - Magic Wand

struct MagicWandArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.30, green: 0.20, blue: 0.35))
                .frame(width: 6, height: 84)
                .offset(y: 14)
            Circle()
                .fill(Color.yellow)
                .frame(width: 26, height: 26)
                .offset(y: -42)
            ForEach([0, 45, 90, 135], id: \.self) { deg in
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 2, height: 12)
                    .offset(y: -42)
                    .rotationEffect(.degrees(Double(deg)))
            }
        }
    }
}
