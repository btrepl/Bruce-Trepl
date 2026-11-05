// GameView.swift
// The field: a pitcher throws a BASEBALL, the player times a swing,
// and the hit is measured in the season's unit — never feet.
// No background scenery: a plain backdrop, a flat ground strip, and the
// camera pans to follow the ball as it bounces and rolls to a stop.

import SwiftUI
import UIKit

struct GameView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var gameCenter: GameCenterManager

    private enum Phase { case idle, pitching, flying, result, tookPitch }

    @State private var phase: Phase = .idle
    @State private var pitchStart = Date()
    @State private var flightStart = Date()
    @State private var finalDistance = 0
    @State private var isNewBest = false
    @State private var saying = ""
    @State private var tier: HitTier = .miss
    @State private var swingAngle: Double = 30
    @State private var showSwoosh = false
    @State private var batterRotation: Double = 0
    @State private var batterShift: CGFloat = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var impactFlash = false
    @State private var flightDistance: CGFloat = 0
    @State private var flightDuration: Double = 2.6

    private let pitchDuration = 1.4
    private let sweetSpot = 0.85

    /// Plain backdrop color (no scenery anywhere in the game).
    private let backdrop = Color(red: 0.93, green: 0.96, blue: 1.0)
    /// Flat ground strip the ball bounces on.
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
                // Plain backdrop, fixed to the screen (it never pans).
                backdrop
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

                        // Batter + bat: the whole figure twists through the
                        // swing, so the character is seen actually swinging.
                        ZStack {
                            SluggerArtView(slugger: game.slugger)
                            BatArtView(bat: game.bat)
                                .offset(batOffset)
                                .rotationEffect(.degrees(swingAngle), anchor: .bottom)
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
                        Label("\(game.swingsLeft) left", systemImage: "bolt.fill")
                            .font(.subheadline)
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
                    Text("\(game.slugger.name) · \(game.bat.name) · \(game.season.unitPlural)")
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

        // Full-body swing: wind up (lean back, bat cocks), whip through
        // (whole figure twists, bat sweeps), then follow through and reset.
        withAnimation(.easeIn(duration: 0.12)) {
            batterRotation = -14
            batterShift = -6
            swingAngle = 52
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.10)) {
                batterRotation = 36
                batterShift = 8
                swingAngle = -72
                showSwoosh = true
            }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                withAnimation(.easeOut(duration: 0.45)) {
                    batterRotation = 0
                    batterShift = 0
                    swingAngle = 30
                    showSwoosh = false
                }
            }
        }

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
        flightStart = Date()
        phase = .flying
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
