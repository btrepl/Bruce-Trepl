// GameView.swift
// The field: a pitcher throws a YELLOW SNOWBALL, the player times a swing,
// and the hit is measured in the season's unit — never feet.
// Background is static mountains only (no forest, nothing scrolls).

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

    private let pitchDuration = 1.4
    private let sweetSpot = 0.85

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sky
                LinearGradient(
                    colors: [game.season.skyTop, game.season.skyBottom],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // Static mountains + ground strip (never moves)
                VStack(spacing: 0) {
                    Spacer()
                    MountainsView().frame(height: 190)
                    Rectangle()
                        .fill(Color(red: 0.45, green: 0.70, blue: 0.40))
                        .frame(height: 64)
                }
                .ignoresSafeArea(edges: .bottom)

                // Pitcher machine (left)
                PitchMachineView()
                    .position(x: 74, y: geo.size.height - 119)

                // Batter + bat (right)
                ZStack {
                    SluggerArtView(slugger: game.slugger)
                        .scaleEffect(0.9)
                    BatArtView(bat: game.bat)
                        .scaleEffect(0.9)
                        .offset(x: -28, y: -84)
                        .rotationEffect(.degrees(swingAngle), anchor: .bottom)
                    if showSwoosh {
                        SwooshArc()
                            .offset(x: -70, y: -120)
                    }
                }
                .position(x: geo.size.width - 108, y: geo.size.height - 150)

                // Ball, driven by the animation clock
                TimelineView(.animation) { timeline in
                    ballLayer(date: timeline.date, geo: geo)
                }

                // HUD + controls
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

    // MARK: - Ball

    @ViewBuilder
    private func ballLayer(date: Date, geo: GeometryProxy) -> some View {
        let ballY = geo.size.height - 140
        let plateX = geo.size.width - 195
        switch phase {
        case .idle:
            // Ball resting in the pitcher's hand
            YellowSnowballView()
                .position(x: 108, y: ballY)
        case .pitching:
            let elapsed = date.timeIntervalSince(pitchStart)
            let progress = min(max(elapsed / pitchDuration, 0), 1)
            let x = 108 + (plateX - 108) * progress
            let y = ballY - sin(progress * .pi) * 26
            YellowSnowballView()
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
            let t = min(elapsed / 1.3, 1)
            let x = plateX - t * max(plateX - 30, 0)
            let y = ballY - sin(t * .pi) * 170
            YellowSnowballView()
                .position(x: x, y: y)
            if elapsed >= 1.6 {
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
                    Text("Purchases are simulated in this build (stub mode). No real charge.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

        // Visible swing animation: wind-up is the rest pose, then swoosh.
        withAnimation(.easeOut(duration: 0.14)) {
            swingAngle = -55
            showSwoosh = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.25)) {
                swingAngle = 30
                showSwoosh = false
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
            Text("No swing used. The yellow snowball sailed by.")
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

/// The pitched ball: a yellow snowball (yellow gradient + speckles).
struct YellowSnowballView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.yellow, Color(red: 0.95, green: 0.75, blue: 0.15)]),
                        center: .center,
                        startRadius: 4,
                        endRadius: 16
                    )
                )
                .frame(width: 28, height: 28)
            Circle().fill(Color(red: 0.85, green: 0.65, blue: 0.10))
                .frame(width: 4, height: 4).offset(x: -6, y: -4)
            Circle().fill(Color(red: 0.85, green: 0.65, blue: 0.10))
                .frame(width: 3, height: 3).offset(x: 6, y: 5)
            Circle().fill(Color(red: 0.85, green: 0.65, blue: 0.10))
                .frame(width: 3, height: 3).offset(x: 2, y: -7)
        }
    }
}

/// Static mountains with snow caps. No forest, nothing animates.
struct MountainsView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h))
                    p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w * 0.36, y: h))
                    p.addLine(to: CGPoint(x: w * 0.52, y: h * 0.40))
                    p.addLine(to: CGPoint(x: w * 0.68, y: h))
                    p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.18))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.closeSubpath()
                }
                .fill(Color(red: 0.35, green: 0.45, blue: 0.65))
                // Snow caps on the three peaks
                Path { p in
                    let peak = CGPoint(x: w * 0.18, y: h * 0.25)
                    p.move(to: CGPoint(x: peak.x - 24, y: peak.y + 26))
                    p.addLine(to: peak)
                    p.addLine(to: CGPoint(x: peak.x + 24, y: peak.y + 26))
                    p.addLine(to: CGPoint(x: peak.x + 10, y: peak.y + 18))
                    p.addLine(to: CGPoint(x: peak.x - 8, y: peak.y + 24))
                    p.closeSubpath()
                }
                .fill(Color.white)
                Path { p in
                    let peak = CGPoint(x: w * 0.52, y: h * 0.40)
                    p.move(to: CGPoint(x: peak.x - 20, y: peak.y + 22))
                    p.addLine(to: peak)
                    p.addLine(to: CGPoint(x: peak.x + 20, y: peak.y + 22))
                    p.addLine(to: CGPoint(x: peak.x + 8, y: peak.y + 15))
                    p.addLine(to: CGPoint(x: peak.x - 6, y: peak.y + 20))
                    p.closeSubpath()
                }
                .fill(Color.white)
                Path { p in
                    let peak = CGPoint(x: w * 0.84, y: h * 0.18)
                    p.move(to: CGPoint(x: peak.x - 24, y: peak.y + 26))
                    p.addLine(to: peak)
                    p.addLine(to: CGPoint(x: peak.x + 24, y: peak.y + 26))
                    p.addLine(to: CGPoint(x: peak.x + 10, y: peak.y + 18))
                    p.addLine(to: CGPoint(x: peak.x - 8, y: peak.y + 24))
                    p.closeSubpath()
                }
                .fill(Color.white)
            }
        }
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
            p.addArc(center: .zero, radius: 55,
                     startAngle: .degrees(-160), endAngle: .degrees(-20),
                     clockwise: false)
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        .opacity(0.9)
        .frame(width: 120, height: 120)
    }
}
