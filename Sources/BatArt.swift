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
            case .bareTree: WoodenClubArt()
            case .iceClub: IceClubArt()
            case .cavemanClub: CavemanClubArt()
            case .baguette: BaguetteArt()
            case .magicWand: MagicWandArt()
            case .scepter: ScepterArt()
            case .machete: MacheteArt()
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

// MARK: - Club outline (shared by the wooden club and the ice club)

/// The club silhouette: a tapered handle widening into a chunky rounded
/// head, like a caveman's club. Both Bigfoot's wooden club and the Snowman's
/// ice club use this exact shape — only the material differs.
/// Coordinates assume the 40 x 120 bat frame.
struct ClubOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 16, y: 118))
        p.addLine(to: CGPoint(x: 15, y: 78))
        p.addQuadCurve(to: CGPoint(x: 6, y: 52), control: CGPoint(x: 10, y: 64))
        p.addQuadCurve(to: CGPoint(x: 8, y: 16), control: CGPoint(x: 4, y: 34))
        p.addQuadCurve(to: CGPoint(x: 20, y: 6), control: CGPoint(x: 12, y: 6))
        p.addQuadCurve(to: CGPoint(x: 32, y: 16), control: CGPoint(x: 28, y: 6))
        p.addQuadCurve(to: CGPoint(x: 34, y: 52), control: CGPoint(x: 36, y: 34))
        p.addQuadCurve(to: CGPoint(x: 25, y: 78), control: CGPoint(x: 30, y: 64))
        p.addLine(to: CGPoint(x: 24, y: 118))
        p.closeSubpath()
        return p
    }
}

// MARK: - Wooden Club (Bigfoot's bat: a chunky caveman-style club)

struct WoodenClubArt: View {
    var body: some View {
        ZStack {
            // Club body: tapered handle, chunky rounded head.
            ClubOutline()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.72, green: 0.48, blue: 0.28), Color(red: 0.58, green: 0.36, blue: 0.18), Color(red: 0.45, green: 0.28, blue: 0.14)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            // Wood grain
            Path { p in
                p.move(to: CGPoint(x: 18, y: 100))
                p.addQuadCurve(to: CGPoint(x: 16, y: 30), control: CGPoint(x: 14, y: 65))
            }
            .stroke(Color(red: 0.45, green: 0.28, blue: 0.14), lineWidth: 1)
            Path { p in
                p.move(to: CGPoint(x: 24, y: 100))
                p.addQuadCurve(to: CGPoint(x: 26, y: 34), control: CGPoint(x: 28, y: 66))
            }
            .stroke(Color(red: 0.45, green: 0.28, blue: 0.14), lineWidth: 1)
            // Rope wrap around the handle just below the head
            ForEach([72, 78, 84], id: \.self) { y in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.85, green: 0.75, blue: 0.55))
                    .frame(width: 16, height: 4)
                    .offset(y: CGFloat(y) - 60)
            }
            // Knob at the bottom of the handle
            Ellipse()
                .fill(Color(red: 0.45, green: 0.28, blue: 0.14))
                .frame(width: 14, height: 7)
                .offset(y: 56)
        }
    }
}

// MARK: - Ice Club (Snowman's bat: the same club shape, out of ice)

struct IceClubArt: View {
    var body: some View {
        ZStack {
            // Same club silhouette as the wooden club, rendered in ice.
            ClubOutline()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.75, green: 0.90, blue: 1.0), Color(red: 0.45, green: 0.75, blue: 0.95), Color(red: 0.25, green: 0.55, blue: 0.85)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            // Frosty edge
            ClubOutline()
                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
            // Wavy ice cracks, like an icicle's veins
            Path { p in
                p.move(to: CGPoint(x: 14, y: 100))
                p.addQuadCurve(to: CGPoint(x: 20, y: 70), control: CGPoint(x: 10, y: 85))
                p.addQuadCurve(to: CGPoint(x: 16, y: 40), control: CGPoint(x: 24, y: 55))
                p.addQuadCurve(to: CGPoint(x: 20, y: 14), control: CGPoint(x: 12, y: 26))
            }
            .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
            Path { p in
                p.move(to: CGPoint(x: 26, y: 96))
                p.addQuadCurve(to: CGPoint(x: 22, y: 66), control: CGPoint(x: 30, y: 80))
                p.addQuadCurve(to: CGPoint(x: 26, y: 38), control: CGPoint(x: 18, y: 52))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 1.2)
            // Frosty highlight along the left edge
            Path { p in
                p.move(to: CGPoint(x: 10, y: 90))
                p.addQuadCurve(to: CGPoint(x: 10, y: 24), control: CGPoint(x: 6, y: 56))
            }
            .stroke(Color.white.opacity(0.9), lineWidth: 2)
            // Frosty band where the rope wrap is on the wooden club
            ForEach([72, 78, 84], id: \.self) { y in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.75))
                    .frame(width: 16, height: 4)
                    .offset(y: CGFloat(y) - 60)
            }
            // Icy knob at the bottom of the handle
            Ellipse()
                .fill(Color(red: 0.65, green: 0.85, blue: 1.0))
                .frame(width: 14, height: 7)
                .offset(y: 56)
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

// MARK: - Royal Scepter (Princess Ruby's bat: golden rod + ruby jewel)

struct ScepterArt: View {
    var body: some View {
        ZStack {
            // Golden shaft.
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.85, green: 0.65, blue: 0.20))
                .frame(width: 8, height: 88)
                .offset(y: 14)
            // Gold bands on the shaft.
            ForEach([-6, 18], id: \.self) { y in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.65, green: 0.48, blue: 0.12))
                    .frame(width: 12, height: 4)
                    .offset(y: CGFloat(y))
            }
            // Ruby jewel on top (a faceted diamond).
            Path { p in
                p.move(to: CGPoint(x: 20, y: 4))
                p.addLine(to: CGPoint(x: 32, y: 18))
                p.addLine(to: CGPoint(x: 20, y: 34))
                p.addLine(to: CGPoint(x: 8, y: 18))
                p.closeSubpath()
            }
            .fill(Color(red: 0.85, green: 0.15, blue: 0.35))
            // Facet lines on the jewel.
            Path { p in
                p.move(to: CGPoint(x: 20, y: 4))
                p.addLine(to: CGPoint(x: 20, y: 34))
                p.move(to: CGPoint(x: 8, y: 18))
                p.addLine(to: CGPoint(x: 32, y: 18))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 1)
            // Sparkle on the jewel.
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)
                .offset(x: -4, y: -32)
            // Gold collar under the jewel.
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.65, green: 0.48, blue: 0.12))
                .frame(width: 14, height: 6)
                .offset(y: -26)
            // Knob at the bottom of the shaft.
            Circle()
                .fill(Color(red: 0.65, green: 0.48, blue: 0.12))
                .frame(width: 12, height: 12)
                .offset(y: 54)
        }
    }
}

// MARK: - Machete (Indiana Jane's bat: a jungle machete)

struct MacheteArt: View {
    var body: some View {
        ZStack {
            // Blade: long flat steel blade, wider toward the curved tip.
            Path { p in
                p.move(to: CGPoint(x: 14, y: 82))
                p.addLine(to: CGPoint(x: 13, y: 20))
                p.addQuadCurve(to: CGPoint(x: 20, y: 6), control: CGPoint(x: 13, y: 8))
                p.addQuadCurve(to: CGPoint(x: 27, y: 20), control: CGPoint(x: 27, y: 8))
                p.addLine(to: CGPoint(x: 26, y: 82))
                p.closeSubpath()
            }
            .fill(Color(red: 0.75, green: 0.78, blue: 0.82))
            // Sharp edge highlight along the blade.
            Path { p in
                p.move(to: CGPoint(x: 24, y: 78))
                p.addLine(to: CGPoint(x: 24, y: 22))
            }
            .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
            // Handle: dark grip.
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.25, green: 0.18, blue: 0.12))
                .frame(width: 11, height: 38)
                .offset(y: 41)
            // Grip grooves on the handle.
            ForEach([34, 42, 50], id: \.self) { y in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(red: 0.45, green: 0.35, blue: 0.22))
                    .frame(width: 13, height: 2.5)
                    .offset(y: CGFloat(y))
            }
            // Brass guard between blade and handle.
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.75, green: 0.60, blue: 0.25))
                .frame(width: 18, height: 5)
                .offset(y: 22)
        }
    }
}
