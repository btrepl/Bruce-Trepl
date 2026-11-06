// GameView.swift
// The field: a pitcher throws a BASEBALL, the player times a swing,
// and the hit is measured in feet. The season decorates the field
// (seasonal background scenery, Christmas lights, a few Fall pumpkins).
// The camera pans to follow the ball as it bounces and rolls to a stop.

import SwiftUI
import UIKit

struct GameView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var gameCenter: GameCenterManager

    private enum Phase { case idle, pitching, swinging, flying, result, tookPitch }

    @State private var phase: Phase = .idle
    @State private var pitchStart = Date()
    @State private var flightStart = Date()
    @State private var finalDistance = 0
    @State private var isNewBest = false
    @State private var saying = ""
    @State private var tier: HitTier = .miss
    @State private var swingAngle: Double = 15
    @State private var showSwoosh = false
    @State private var batterRotation: Double = 0
    @State private var batterShift: CGFloat = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var impactFlash = false
    @State private var flightDistance: CGFloat = 0
    @State private var flightDuration: Double = 2.6

    private let pitchDuration = 1.4
    private let sweetSpot = 0.85

    /// Flat ground strip the ball bounces on. Stays the same green in every
    /// season so the white ball always reads against it.
    private let groundColor = Color(red: 0.42, green: 0.68, blue: 0.38)

    /// Where the bat handle sits, from the slugger's grip point on the
    /// sprite. The sprite displays at ~103 x 190 inside the 150 x 190
    /// frame, and the bat is 40 x 120 with its handle at the bottom
    /// (+60 from the bat view's center).
    private var batOffset: CGSize {
        let grip = SpriteRenderer.gripPoint(for: game.slugger)
        let gripX = (grip.x - 0.5) * 103
        let gripY = (grip.y - 0.5) * 190
        return CGSize(width: gripX, height: gripY - 60)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Seasonal background scenery, fixed to the screen (it never pans).
                SeasonBackgroundView(season: game.season)
                    .ignoresSafeArea()

                // The world: ground, pitcher, batter, ball. This pans to
                // follow the ball after a hit. HUD and cards stay fixed.
                TimelineView(.animation) { timeline in
                    let date = timeline.date
                    let cam = cameraOffset(date: date, geo: geo)
                    ZStack {
                        // Flat ground strip, wide enough to cover the whole
                        // camera pan. Uniform color, so it never looks wrong.
                        Rectangle()
                            .fill(groundColor)
                            .frame(width: 5000, height: 64)
                            .position(
                                x: (geo.size.width - 195) - flightDistance / 2,
                                y: geo.size.height - 32
                            )

                        // Pitcher machine (left)
                        PitchMachineView()
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 2, y: 2)
                            .position(x: 74, y: geo.size.height - 119)

                        // Fall pumpkins sitting on the ground, left of the
                        // plate (season decor; out of the ball's path).
                        if game.season == .fall {
                            ForEach([25, 95, 160], id: \.self) { x in
                                GroundPumpkinView()
                                    .position(x: CGFloat(x), y: geo.size.height - 79)
                            }
                        }

                        // Batter + bat: the whole figure twists through the
                        // swing, so the character is seen actually swinging.
                        ZStack {
                            SluggerArtView(slugger: game.slugger)
                            BatArtView(bat: game.bat)
                                .rotationEffect(.degrees(swingAngle), anchor: .bottom)
                                .offset(batOffset)
                            if showSwoosh {
                                SwooshArc()
                                    .offset(x: -70, y: -120)
                            }
                            ImpactFlash()
                                .opacity(impactFlash ? 1 : 0)
                                .offset(x: -87, y: 10)
                        }
                        .rotationEffect(.degrees(batterRotation), anchor: .bottom)
                        .offset(x: batterShift)
                        .position(x: geo.size.width - 108, y: geo.size.height - 150)

                        // Ball, driven by the animation clock
                        ballLayer(date: date, geo: geo)
                    }
                    .offset(x: -cam + shakeOffset)
                    // Smooth camera return when a new swing starts.
                    .animation(.easeOut(duration: 0.6), value: phase)
                }

                // HUD + controls (fixed, never pans)
                VStack {
                    HStack {
                        Button { game.screen = .home } label: {
                            Image(systemName: "chevron.left")
                            Text("Exit")
                        }
                        Spacer()
                        Text(game.season.title)
                            .bold()
                        Spacer()
                        Label(game.unlimitedSwings ? "Unlimited" : "\(game.swingsLeft) left", systemImage: "bolt.fill")
                            .font(.subheadline)
                    }
                    // Christmas lights dangling from the top (season decor).
                    if game.season == .christmas {
                        ChristmasLightsView()
                            .frame(height: 44)
                    }
                    Spacer()
                    controls
                }
                .padding()

                // Result card
                if phase == .result {
                    resultCard
                }
                if phase == .tookPitch {
                    tookPitchCard
                }
            }
        }
        .onAppear { game.resetSwingsIfNeeded() }
    }

    // MARK: - Ball flight + camera

    /// Where the ball is in world coordinates at a given moment of the
    /// flight. The ball arcs up off the bat, descends to the ground, then
    /// bounces in shrinking hops and rolls to a stop.
    private func flightPosition(elapsed: TimeInterval, geo: GeometryProxy) -> CGPoint {
        let p = CGFloat(min(max(elapsed / flightDuration, 0), 1))
        let ease = 1 - pow(1 - p, 3)  // decelerating: fast off the bat, rolling stop
        let plateX = geo.size.width - 195
        let contactY = geo.size.height - 140
        let groundY = geo.size.height - 79
        let x = plateX - flightDistance * ease
        // Baseline sinks from contact height to the ground as it travels.
        let baseY = contactY + (groundY - contactY) * p * p
        let hops: CGFloat = finalDistance > 0 ? 3 + min(CGFloat(finalDistance) / 120, 3) : 1
        let amp: CGFloat = finalDistance > 0 ? 50 + min(CGFloat(finalDistance), 400) * 0.25 : 10
        let hop = amp * (1 - p) * abs(sin(p * hops * .pi))
        return CGPoint(x: x, y: baseY - hop)
    }

    /// Camera offset: 0 until the ball flies past the left part of the
    /// screen, then the view pans to keep the ball in frame.
    private func cameraOffset(date: Date, geo: GeometryProxy) -> CGFloat {
        guard phase == .flying || phase == .result else { return 0 }
        let elapsed = date.timeIntervalSince(flightStart)
        let point = flightPosition(elapsed: elapsed, geo: geo)
        return min(0, point.x - geo.size.width * 0.42)
    }

    @ViewBuilder
    private func ballLayer(date: Date, geo: GeometryProxy) -> some View {
        let ballY = geo.size.height - 140
        let groundY = geo.size.height - 79
        let plateX = geo.size.width - 195
        switch phase {
        case .idle:
            // Ball resting in the pitcher's hand
            BaseballView()
                .position(x: 108, y: ballY)
        case .swinging:
            // Ball frozen at the plate while the batter winds up.
            BaseballView()
                .position(x: plateX, y: ballY)
        case .pitching:
            let elapsed = date.timeIntervalSince(pitchStart)
            let progress = min(max(elapsed / pitchDuration, 0), 1)
            let x = 108 + (plateX - 108) * progress
            let y = ballY - sin(progress * .pi) * 26
            BaseballView()
                .position(x: x, y: y)
            // Ball got past the batter without a swing: no swing used.
            if progress >= 1 {
                Color.clear.onAppear {
                    DispatchQueue.main.async {
                        if phase == .pitching { phase = .tookPitch }
                    }
                }
            }
        case .flying:
            let elapsed = date.timeIntervalSince(flightStart)
            let point = flightPosition(elapsed: elapsed, geo: geo)
            // Ground shadow: shrinks and fades as the ball climbs.
            let heightAbove = max(0, groundY - point.y)
            let shadowScale = max(0.35, 1 - heightAbove / 260)
            Ellipse()
                .fill(Color.black.opacity(0.25 * shadowScale))
                .frame(width: 36 * shadowScale, height: 9 * shadowScale)
                .position(x: point.x, y: groundY + 14)
            // Motion trail: fading ghosts of where the ball just was.
            ForEach([0.18, 0.12, 0.06], id: \.self) { lag in
                if elapsed - lag > 0 {
                    let trail = flightPosition(elapsed: elapsed - lag, geo: geo)
                    BaseballView()
                        .opacity(lag > 0.15 ? 0.12 : lag > 0.09 ? 0.22 : 0.35)
                        .position(trail)
                }
            }
            BaseballView()
                .position(point)
            if elapsed >= flightDuration + 0.45 {
                Color.clear.onAppear {
                    DispatchQueue.main.async {
                        if phase == .flying { phase = .result }
                    }
                }
            }
        case .result, .tookPitch:
            EmptyView()
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 12) {
            switch phase {
            case .idle:
                if game.canSwing {
                    Button("PITCH") {
                        pitchStart = Date()
                        phase = .pitching
                    }
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .cornerRadius(16)
                    Text("\(game.slugger.name) · \(game.bat.name) · \(game.season.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Out of swings for today!")
                        .bold()
                    Button {
                        Task {
                            if await store.purchaseSwingPack() {
                                game.addSwings(5)
                            }
                        }
                    } label: {
                        Text("Get 5 more swings — $1.00")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(Color.white)
                            .cornerRadius(16)
                    }
                }
            case .pitching:
                Button("SWING!") { swingNow() }
                    .font(.system(size: 34, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundStyle(Color.white)
                    .cornerRadius(20)
            case .swinging:
                Text("Swinging…")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            case .flying:
                Text("It's flying…")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            case .result, .tookPitch:
                EmptyView()
            }
        }
    }

    // MARK: - Swing

    private func swingNow() {
        guard phase == .pitching else { return }
        let progress = min(Date().timeIntervalSince(pitchStart) / pitchDuration, 1)
        guard progress < 1 else {
            phase = .tookPitch
            return
        }

        // Timing window widens slightly with bat speed; power scales distance.
        let window = 0.30 + Double(game.bat.speed) * 0.01
        let quality = max(0, 1 - abs(progress - sweetSpot) / window)

        game.useSwing()

        phase = .swinging

        let distance: Int
        if quality <= 0.05 {
            distance = 0  // whiff
        } else {
            let factor = 0.85 + Double(game.bat.power) * 0.05
            distance = Int((quality * 380 + Double.random(in: 0...40)) * factor)
        }

        finalDistance = distance
        tier = HitTier.tier(for: distance, swung: true)
        saying = Sayings.random(for: tier)
        if distance > 0 {
            isNewBest = game.recordHit(distance: distance)
            Task { await gameCenter.submitScore(distance) }
        } else {
            isNewBest = false
        }
        // Flight plan: bigger hits fly farther and bounce longer.
        flightDistance = distance > 0 ? 260 + CGFloat(distance) * 3.2 : 150
        flightDuration = distance > 0 ? 2.6 : 1.3

        // Full-body swing, slow enough to actually see: wind up (lean back,
        // bat cocks), whip through (whole figure twists, bat sweeps down
        // through the zone), hold the follow-through, then reset.
        withAnimation(.easeIn(duration: 0.20)) {
            batterRotation = -20
            batterShift = -10
            swingAngle = 60
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.easeOut(duration: 0.28)) {
                batterRotation = 42
                batterShift = 12
                swingAngle = -82
                showSwoosh = true
            }
            // The ball leaves the plate as the bat whips through it.
            flightStart = Date()
            phase = .flying
            if quality > 0.05 {
                // Contact: impact flash + a screen-shake kick.
                impactFlash = true
                shakeOffset = 9
                withAnimation(.interpolatingSpring(stiffness: 320, damping: 7)) {
                    shakeOffset = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                    withAnimation(.easeOut(duration: 0.2)) { impactFlash = false }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.55)) {
                    batterRotation = 0
                    batterShift = 0
                    swingAngle = 15
                    showSwoosh = false
                }
            }
        }
    }

    // MARK: - Cards

    private var resultCard: some View {
        VStack(spacing: 12) {
            Text(Sayings.resultLabel(for: tier))
                .font(.headline)
                .foregroundStyle(.secondary)
            if finalDistance > 0 {
                Text("It flew \(finalDistance) \(game.season.unitName(for: finalDistance))!")
                    .font(.system(size: 26, weight: .black))
                    .multilineTextAlignment(.center)
                if isNewBest {
                    Text("NEW BEST!")
                        .font(.headline)
                        .foregroundStyle(Color.orange)
                }
            } else {
                Text("Whiff!")
                    .font(.system(size: 30, weight: .black))
            }
            // The saying, like a speech bubble
            Text("“\(saying)”")
                .font(.title3)
                .italic()
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.yellow.opacity(0.25))
                .cornerRadius(14)

            if game.canSwing {
                Button("Swing Again") { phase = .idle }
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .cornerRadius(14)
            } else {
                Button {
                    Task {
                        if await store.purchaseSwingPack() {
                            game.addSwings(5)
                            phase = .idle
                        }
                    }
                } label: {
                    Text("Get 5 more swings — $1.00")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(Color.white)
                        .cornerRadius(14)
                }
            }
            Button("Back to Home") { game.screen = .home }
                .font(.subheadline)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 12)
        .padding(.horizontal, 24)
    }

    private var tookPitchCard: some View {
        VStack(spacing: 12) {
            Text("Took the pitch!")
                .font(.title2).bold()
            Text("No swing used. The baseball sailed by.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Pitch Again") { phase = .idle }
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(Color.white)
                .cornerRadius(14)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 12)
        .padding(.horizontal, 24)
    }
}

// MARK: - Field pieces

/// The pitched ball: a regular baseball — white with red seams.
struct BaseballView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color(red: 0.88, green: 0.88, blue: 0.90)
                        ]),
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 16
                    )
                )
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color(red: 0.55, green: 0.55, blue: 0.58), lineWidth: 1))
            // Red seams: two curved arcs
            Path { p in
                p.move(to: CGPoint(x: 7, y: 4))
                p.addQuadCurve(to: CGPoint(x: 7, y: 26), control: CGPoint(x: 13, y: 15))
            }
            .stroke(Color.red, lineWidth: 1.6)
            Path { p in
                p.move(to: CGPoint(x: 23, y: 4))
                p.addQuadCurve(to: CGPoint(x: 23, y: 26), control: CGPoint(x: 17, y: 15))
            }
            .stroke(Color.red, lineWidth: 1.6)
            // Stitch ticks across the seams
            ForEach([9, 14, 19], id: \.self) { y in
                Path { p in
                    p.move(to: CGPoint(x: 5, y: CGFloat(y)))
                    p.addLine(to: CGPoint(x: 10, y: CGFloat(y) + 1))
                }
                .stroke(Color.red, lineWidth: 1.2)
                Path { p in
                    p.move(to: CGPoint(x: 20, y: CGFloat(y) + 1))
                    p.addLine(to: CGPoint(x: 25, y: CGFloat(y)))
                }
                .stroke(Color.red, lineWidth: 1.2)
            }
        }
        .frame(width: 30, height: 30)
    }
}

/// The pitching machine on the left side of the field.
struct PitchMachineView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.35, green: 0.35, blue: 0.40))
                .frame(width: 64, height: 54)
            Circle()
                .fill(Color(red: 0.20, green: 0.20, blue: 0.25))
                .frame(width: 26, height: 26)
                .offset(x: 22, y: -6)
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
                .offset(x: 22, y: -6)
            Rectangle()
                .fill(Color(red: 0.25, green: 0.25, blue: 0.30))
                .frame(width: 8, height: 30)
                .offset(x: -14, y: 40)
            Rectangle()
                .fill(Color(red: 0.25, green: 0.25, blue: 0.30))
                .frame(width: 8, height: 30)
                .offset(x: 14, y: 40)
            Text("PITCH-O-MATIC")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(Color.white)
                .offset(y: -4)
        }
        .frame(width: 80, height: 90)
    }
}

/// Swoosh arc shown during the swing.
struct SwooshArc: View {
    var body: some View {
        Path { p in
            p.addArc(center: .zero, radius: 65,
                     startAngle: .degrees(-160), endAngle: .degrees(-20),
                     clockwise: false)
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
        .opacity(0.9)
        .frame(width: 140, height: 140)
    }
}

/// Bright starburst at the contact point when the bat meets the ball.
struct ImpactFlash: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 46, height: 46)
                .blur(radius: 6)
            Image(systemName: "star.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.yellow)
        }
    }
}

/// Minimal Christmas decoration: a string of lights dangling from the top.
struct ChristmasLightsView: View {
    private let bulbColors: [Color] = [.red, .green, .yellow, .blue, .red, .green, .yellow, .blue, .red]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // The sagging string.
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addQuadCurve(to: CGPoint(x: w, y: 0), control: CGPoint(x: w / 2, y: 60))
                }
                .stroke(Color(red: 0.25, green: 0.35, blue: 0.25), lineWidth: 2)
                // Bulbs hanging from the string.
                ForEach(0..<9) { i in
                    let t = Double(i) / 8.0
                    let x = w * t
                    let y = 120 * t * (1 - t)
                    Rectangle()
                        .fill(Color(red: 0.25, green: 0.35, blue: 0.25))
                        .frame(width: 1.5, height: 8)
                        .position(x: x, y: y + 4)
                    Circle()
                        .fill(bulbColors[i])
                        .frame(width: 11, height: 11)
                        .shadow(color: bulbColors[i].opacity(0.7), radius: 4)
                        .position(x: x, y: y + 12)
                }
            }
        }
    }
}

/// Minimal Fall decoration: a pumpkin sitting on the ground.
struct GroundPumpkinView: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.orange).frame(width: 34, height: 30)
            Ellipse().fill(Color(red: 0.85, green: 0.45, blue: 0.10))
                .frame(width: 6, height: 28)
            Rectangle().fill(Color.green).frame(width: 4, height: 8).offset(y: -16)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 1, y: 1)
    }
}

/// Seasonal background scenery, fixed to the screen (it never pans).
/// Changes with the season picker: warm sky + autumn trees + falling
/// leaves (Fall), pale sky + snowy pines + snowfall (Christmas), blue
/// sky + green trees + sun (Normal). Kept soft and distant so the batter
/// and the ball stay readable. The ground strip stays the same green in
/// every season so the white ball always reads against it.
struct SeasonBackgroundView: View {
    let season: Season

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sky gradient.
                LinearGradient(colors: skyColors, startPoint: .top, endPoint: .bottom)
                // Sun, soft and upper-left, out of the ball's path.
                Circle()
                    .fill(sunColor)
                    .frame(width: 54, height: 54)
                    .shadow(color: sunColor.opacity(0.5), radius: 18)
                    .position(x: geo.size.width * 0.14, y: geo.size.height * 0.13)
                // A few soft clouds.
                cloud(at: CGPoint(x: geo.size.width * 0.38, y: geo.size.height * 0.10), scale: 1.0)
                cloud(at: CGPoint(x: geo.size.width * 0.68, y: geo.size.height * 0.07), scale: 0.75)
                cloud(at: CGPoint(x: geo.size.width * 0.88, y: geo.size.height * 0.16), scale: 0.6)
                // Falling leaves (Fall) or snowfall (Christmas).
                if season == .fall {
                    fallingLeaves(in: geo)
                } else if season == .christmas {
                    snowfall(in: geo)
                }
                // Distant tree line on the horizon.
                treeLine(in: geo)
            }
        }
    }

    // MARK: - Sky

    private var skyColors: [Color] {
        switch season {
        case .fall:
            return [Color(red: 0.98, green: 0.80, blue: 0.55),
                    Color(red: 0.99, green: 0.88, blue: 0.68),
                    Color(red: 0.99, green: 0.94, blue: 0.80)]
        case .christmas:
            return [Color(red: 0.78, green: 0.86, blue: 0.96),
                    Color(red: 0.88, green: 0.92, blue: 0.98),
                    Color(red: 0.96, green: 0.97, blue: 1.0)]
        case .normal:
            return [Color(red: 0.55, green: 0.80, blue: 0.98),
                    Color(red: 0.75, green: 0.89, blue: 1.0),
                    Color(red: 0.93, green: 0.96, blue: 1.0)]
        }
    }

    private var sunColor: Color {
        switch season {
        case .fall: return Color(red: 1.0, green: 0.78, blue: 0.35)
        case .christmas: return Color(red: 1.0, green: 0.97, blue: 0.85).opacity(0.85)
        case .normal: return Color(red: 1.0, green: 0.88, blue: 0.45)
        }
    }

    // MARK: - Clouds

    private func cloud(at center: CGPoint, scale: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Color.white.opacity(0.9)).frame(width: 70 * scale, height: 22 * scale)
            Ellipse().fill(Color.white.opacity(0.9)).frame(width: 44 * scale, height: 20 * scale).offset(x: -18 * scale, y: 4 * scale)
            Ellipse().fill(Color.white.opacity(0.9)).frame(width: 40 * scale, height: 18 * scale).offset(x: 18 * scale, y: 5 * scale)
        }
        .position(center)
    }

    // MARK: - Falling leaves / snowfall

    private func fallingLeaves(in geo: GeometryProxy) -> some View {
        let xs: [CGFloat] = [0.08, 0.25, 0.42, 0.58, 0.74, 0.90]
        let ys: [CGFloat] = [0.22, 0.30, 0.18, 0.34, 0.26, 0.20]
        let leafColors: [Color] = [.orange, .red, .yellow]
        return ZStack {
            ForEach(0..<6, id: \.self) { i in
                Ellipse()
                    .fill(leafColors[i % 3].opacity(0.85))
                    .frame(width: 10, height: 6)
                    .rotationEffect(.degrees(Double(i * 37 % 90 - 45)))
                    .position(x: geo.size.width * xs[i], y: geo.size.height * ys[i])
            }
        }
    }

    private func snowfall(in geo: GeometryProxy) -> some View {
        ZStack {
            ForEach(0..<14, id: \.self) { i in
                let x = geo.size.width * CGFloat((i * 37 % 100)) / 100.0
                let y = geo.size.height * CGFloat((i * 53 % 45)) / 100.0
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: i % 3 == 0 ? 6 : 4, height: i % 3 == 0 ? 6 : 4)
                    .position(x: x, y: y)
            }
        }
    }

    // MARK: - Tree line

    private func treeLine(in geo: GeometryProxy) -> some View {
        let horizon = geo.size.height - 64
        let spots: [(x: CGFloat, h: CGFloat)] = [
            (0.04, 52), (0.13, 40), (0.22, 58), (0.33, 44),
            (0.45, 56), (0.57, 42), (0.68, 50), (0.93, 44)
        ]
        return ZStack {
            ForEach(0..<spots.count, id: \.self) { i in
                tree(at: CGPoint(x: geo.size.width * spots[i].x, y: horizon),
                     height: spots[i].h)
            }
        }
    }

    private func tree(at base: CGPoint, height: CGFloat) -> some View {
        ZStack {
            if season == .christmas {
                // Snowy pine: dark green triangle + white snow cap.
                Triangle()
                    .fill(Color(red: 0.20, green: 0.42, blue: 0.28))
                    .frame(width: height * 0.75, height: height)
                Triangle()
                    .fill(Color.white)
                    .frame(width: height * 0.35, height: height * 0.28)
                    .offset(y: -height * 0.36)
                Rectangle()
                    .fill(Color(red: 0.45, green: 0.32, blue: 0.20))
                    .frame(width: 5, height: 8)
                    .offset(y: height / 2 + 2)
            } else {
                // Leafy tree: trunk + round canopy.
                Rectangle()
                    .fill(Color(red: 0.45, green: 0.32, blue: 0.20))
                    .frame(width: 6, height: height * 0.30)
                    .offset(y: height * 0.35)
                Circle()
                    .fill(canopyColor)
                    .frame(width: height * 0.85, height: height * 0.85)
                    .offset(y: -height * 0.18)
                Circle()
                    .fill(canopyColor)
                    .frame(width: height * 0.55, height: height * 0.55)
                    .offset(x: -height * 0.22, y: -height * 0.05)
                Circle()
                    .fill(canopyColor)
                    .frame(width: height * 0.55, height: height * 0.55)
                    .offset(x: height * 0.22, y: -height * 0.05)
            }
        }
        .position(x: base.x, y: base.y - height / 2)
    }

    private var canopyColor: Color {
        switch season {
        case .fall: return Color(red: 0.85, green: 0.45, blue: 0.15)
        case .christmas: return Color(red: 0.20, green: 0.42, blue: 0.28)
        case .normal: return Color(red: 0.35, green: 0.65, blue: 0.30)
        }
    }
}
