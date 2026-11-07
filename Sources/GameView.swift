// GameView.swift
// The field: a pitcher throws a BASEBALL, the player times a swing,
// and the hit is measured in feet. The season decorates the field
// (seasonal background scenery, Christmas lights, a few Fall pumpkins).
// The camera pans to follow the ball as it arcs through the air,
// bounces once or twice, and stops.

import SwiftUI
import UIKit

struct GameView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var gameCenter: GameCenterManager
    @EnvironmentObject var ads: AdsManager

    private enum Phase { case idle, pitching, swinging, flying, result, tookPitch }

    @State private var phase: Phase = .idle
    @State private var pitchStart = Date()
    @State private var flightStart = Date()
    @State private var finalDistance = 0
    @State private var isNewBest = false
    @State private var saying = ""
    @State private var tier: HitTier = .miss
    @State private var swingAngle: Double = 20
    @State private var showSwoosh = false
    @State private var batterRotation: Double = 0
    @State private var batterShift: CGFloat = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var impactFlash = false
    @State private var flightDistance: CGFloat = 0
    @State private var flightDuration: Double = 2.6
    @State private var shareImage: UIImage?
    @State private var coinsEarned = 0

    // Multi-pitch modes (Derby / Timing Streak / Pitch Challenge).
    @State private var pitchesLeft = 1
    @State private var derbyTotal = 0
    @State private var derbyBest = 0
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var pitchType: PitchType = .fastball
    @State private var lastPerfect = false

    // Golden Ball mode: 10 balls, points by distance, one random golden
    // ball worth double.
    @State private var pointsTotal = 0
    @State private var pointsLog: [Int] = []
    @State private var lastPoints = 0
    @State private var lastWasGolden = false
    @State private var goldenBallIndex = 1
    @State private var flyingGolden = false
    @State private var isNewPointsBest = false
    @State private var tookGoldenBall = false

    private let pitchDuration = 1.4
    private let sweetSpot = 0.85

    /// Pitch travel time: in Pitch Challenge mode each pitch type has its
    /// own speed; otherwise the standard 1.4s.
    private var currentPitchDuration: Double {
        game.playMode == .pitchChallenge ? pitchType.travelTime : pitchDuration
    }

    /// The pitch number currently being played (1-based).
    private var currentPitchNumber: Int {
        game.playMode.pitchCount - pitchesLeft + 1
    }

    /// True when the ball currently being pitched is the golden one.
    private var isGoldenBallNow: Bool {
        game.playMode == .goldenBall && currentPitchNumber == goldenBallIndex
    }

    /// Per-ball points for a finished Golden Ball game, e.g.
    /// "+2 · +5 · −5 · +16★" with ★ on the golden ball.
    private var pointsBreakdown: String {
        pointsLog.enumerated().map { i, pts in
            let sign = pts > 0 ? "+" : ""
            let star = (i + 1) == goldenBallIndex ? "★" : ""
            return "\(sign)\(pts)\(star)"
        }.joined(separator: " · ")
    }

    /// Reset the multi-pitch state for a new game. Called when the game
    /// screen appears and when the player starts a fresh game.
    private func startGame() {
        pitchesLeft = game.playMode.pitchCount
        derbyTotal = 0
        derbyBest = 0
        streak = 0
        bestStreak = 0
        lastPerfect = false
        pitchType = PitchType.allCases.randomElement() ?? .fastball
        phase = .idle
        // Golden Ball: fresh points, and one random ball (1–10) is golden.
        pointsTotal = 0
        pointsLog = []
        lastPoints = 0
        lastWasGolden = false
        goldenBallIndex = Int.random(in: 1...game.playMode.pitchCount)
        flyingGolden = false
        isNewPointsBest = false
        tookGoldenBall = false
    }

    /// True when the current game is over (all pitches used).
    private var gameOver: Bool {
        game.playMode == .classic || pitchesLeft <= 0
    }

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

                // Fireworks for a huge hit (over 450 feet) — in any mode.
                if finalDistance > 450 && (phase == .flying || phase == .result) {
                    FireworksView()
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
                        Label(game.mode == .practice ? "Practice" : (game.rankedUnlimited ? "Ranked · Unlimited" : "Ranked · \(game.rankedLeft) left"), systemImage: "bolt.fill")
                            .font(.subheadline)
                    }
                    // Mode + pitch status for the 10-pitch modes.
                    if game.playMode != .classic {
                        HStack {
                            Text(game.playMode.title)
                                .font(.subheadline).bold()
                            Spacer()
                            if game.playMode == .pitchChallenge && phase == .pitching {
                                Text(pitchType.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.orange)
                            }
                            if game.playMode == .derby {
                                Text("Total: \(derbyTotal) ft")
                                    .font(.subheadline)
                            }
                            if game.playMode == .streak {
                                Text("Streak: \(streak)")
                                    .font(.subheadline)
                            }
                            if game.playMode == .goldenBall {
                                Text("Points: \(pointsTotal)")
                                    .font(.subheadline)
                                if isGoldenBallNow && (phase == .idle || phase == .pitching) {
                                    Text("★ Golden Ball · 2x")
                                        .font(.subheadline).bold()
                                        .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.10))
                                }
                            }
                            Text("Pitch \(game.playMode.pitchCount - pitchesLeft + 1) of \(game.playMode.pitchCount)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
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
        .onAppear {
            game.resetRankedIfNeeded()
            startGame()
        }
    }

    // MARK: - Ball flight + camera

    /// Where the ball is in world coordinates at a given moment of the
    /// flight. One big arc in the air (most of the flight), then a bounce
    /// or two, then it stops — no long rolling. The first hump of the sine
    /// is stretched by squaring p, so the ball stays up for ~60% of the
    /// flight before it lands.
    private func flightPosition(elapsed: TimeInterval, geo: GeometryProxy) -> CGPoint {
        let p = CGFloat(min(max(elapsed / flightDuration, 0), 1))
        let plateX = geo.size.width - 195
        let contactY = geo.size.height - 140
        let groundY = geo.size.height - 79
        // Horizontal: cover most of the distance while airborne, then
        // decelerate hard after landing so the ball stops, not rolls.
        let ease = 1 - pow(1 - p, 4)
        let x = plateX - flightDistance * ease
        // Baseline sinks from contact height to the ground as it travels.
        let baseY = contactY + (groundY - contactY) * p * p
        // Three humps: one long arc, then two short bounces. Squaring p
        // stretches the first hump to ~58% of the flight.
        let hops: CGFloat = finalDistance > 0 ? 3 : 1
        let q = p * p
        let amp: CGFloat = finalDistance > 0 ? 60 + min(CGFloat(finalDistance), 400) * 0.30 : 10
        let hop = amp * (1 - p) * abs(sin(q * hops * .pi))
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
            BallView(kind: game.slugger.ballKind, isGolden: isGoldenBallNow)
                .position(x: 108, y: ballY)
        case .swinging:
            // Ball frozen at the plate while the batter winds up.
            BallView(kind: game.slugger.ballKind, isGolden: isGoldenBallNow)
                .position(x: plateX, y: ballY)
        case .pitching:
            let elapsed = date.timeIntervalSince(pitchStart)
            let progress = min(max(elapsed / currentPitchDuration, 0), 1)
            let x = 108 + (plateX - 108) * progress
            let y = ballY - sin(progress * .pi) * 26
            BallView(kind: game.slugger.ballKind, isGolden: isGoldenBallNow)
                .position(x: x, y: y)
            // Ball got past the batter without a swing: no swing used.
            if progress >= 1 {
                Color.clear.onAppear {
                    DispatchQueue.main.async {
                        if phase == .pitching {
                            // Capture before pitchesLeft is decremented.
                            let wasGolden = isGoldenBallNow
                            // Taking a pitch counts as a pitch used in the
                            // 10-pitch modes, and it breaks a timing streak.
                            if game.playMode != .classic {
                                pitchesLeft -= 1
                                streak = 0
                                if game.playMode == .pitchChallenge {
                                    pitchType = PitchType.allCases.randomElement() ?? .fastball
                                }
                                if game.playMode == .goldenBall {
                                    // A taken pitch scores 0 for that ball,
                                    // golden or not — the chance is gone.
                                    tookGoldenBall = wasGolden
                                    lastPoints = 0
                                    pointsLog.append(0)
                                }
                                if gameOver && game.mode == .ranked {
                                    recordModeResult()
                                }
                            }
                            phase = .tookPitch
                        }
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
                    BallView(kind: game.slugger.ballKind, isGolden: flyingGolden)
                        .opacity(lag > 0.15 ? 0.12 : lag > 0.09 ? 0.22 : 0.35)
                        .position(trail)
                }
            }
            BallView(kind: game.slugger.ballKind, isGolden: flyingGolden)
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
                    Text("Out of ranked swings for today!")
                        .bold()
                    Button {
                        Task {
                            if await store.purchaseRankedRefill() {
                                game.addRankedSwings(20)
                            }
                        }
                    } label: {
                        Text("Get 20 more ranked swings — $0.99")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(Color.white)
                            .cornerRadius(16)
                    }
                    if AdsManager.adsEnabled && !store.removeAdsUnlocked {
                        Button {
                            ads.showRewardedAd {
                                game.addRankedSwings(5)
                            }
                        } label: {
                            Label(ads.isAdReady ? "Watch an ad — +5 ranked swings" : "Ad loading…",
                                  systemImage: "play.rectangle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.teal)
                                .foregroundStyle(Color.white)
                                .cornerRadius(16)
                        }
                        .disabled(!ads.isAdReady || ads.isShowingAd)
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
        let progress = min(Date().timeIntervalSince(pitchStart) / currentPitchDuration, 1)
        // Whether the ball being swung at is the golden one — capture
        // before pitchesLeft is decremented below.
        let goldenThisBall = isGoldenBallNow
        flyingGolden = goldenThisBall
        guard progress < 1 else {
            phase = .tookPitch
            return
        }

        // Timing window widens slightly with bat speed; power scales distance.
        let window = 0.30 + Double(game.bat.speed) * 0.01
        let quality = max(0, 1 - abs(progress - sweetSpot) / window)

        // A ranked swing is consumed once per pitch in Classic, but only
        // once per GAME in the 10-pitch modes (the whole game costs 1).
        let isFirstPitch = pitchesLeft == game.playMode.pitchCount
        if game.playMode == .classic || isFirstPitch {
            game.useSwing()
        }

        phase = .swinging

        let distance: Int
        if quality <= 0.05 {
            distance = 0  // whiff
        } else {
            let factor = 0.85 + Double(game.bat.power) * 0.05
            // The bat's power boost (1%–10%) multiplies the distance.
            let boost = 1.0 + game.bat.powerBoost
            distance = Int((quality * 380 + Double.random(in: 0...40)) * factor * boost)
        }

        finalDistance = distance
        tier = HitTier.tier(for: distance, swung: true)
        saying = Sayings.random(for: tier)

        // Multi-pitch bookkeeping.
        pitchesLeft -= 1
        let perfect = distance > 0 && abs(progress - sweetSpot) <= 0.03
        lastPerfect = perfect
        switch game.playMode {
        case .derby:
            derbyTotal += distance
            derbyBest = max(derbyBest, distance)
        case .streak:
            if perfect {
                streak += 1
                bestStreak = max(bestStreak, streak)
            } else {
                streak = 0
            }
        case .pitchChallenge:
            pitchType = PitchType.allCases.randomElement() ?? .fastball
        case .goldenBall:
            derbyBest = max(derbyBest, distance)
            // A whiff scores 0 (the −5 is only for a hit under 100 feet).
            // A golden ball doubles whatever the ball is worth.
            let base = distance > 0 ? GameState.pointsFor(distance: distance) : 0
            let pts = goldenThisBall ? base * 2 : base
            lastPoints = pts
            lastWasGolden = goldenThisBall
            pointsTotal += pts
            pointsLog.append(pts)
        case .classic:
            break
        }

        // Coins are earned per hit in Ranked (practice earns nothing).
        // The leaderboard gets only the mode's final score (see
        // recordModeResult), not every pitch.
        if distance > 0 && game.mode == .ranked {
            coinsEarned = game.coinsForHit(distance: distance)
            game.earnCoins(coinsEarned)
            isNewBest = false
        } else {
            coinsEarned = 0
            isNewBest = false
        }
        // Ranked swings (hit or whiff) advance quests, Season XP, and
        // achievements. Practice does not.
        if game.mode == .ranked {
            game.advanceQuests(distance: distance)
            game.addSeasonXP(SeasonPass.xpForHit(distance: distance))
            Task {
                await gameCenter.reportAchievement(.firstHit)
                if distance >= 300 { await gameCenter.reportAchievement(.hit300) }
                if distance >= 400 { await gameCenter.reportAchievement(.hit400) }
                if game.totalRankedSwings >= 100 { await gameCenter.reportAchievement(.swings100) }
                if game.totalCoinsEarned >= 1000 { await gameCenter.reportAchievement(.coins1000) }
            }
        }
        // When the game is over, record the mode's final score.
        if gameOver && game.mode == .ranked {
            recordModeResult()
        }
        // Flight plan: bigger hits fly farther. The ball stays up in one
        // long arc, then bounces once or twice and stops.
        flightDistance = distance > 0 ? 260 + CGFloat(distance) * 3.2 : 150
        flightDuration = distance > 0 ? 3.0 : 1.3

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
                    swingAngle = 20
                    showSwoosh = false
                }
            }
        }
    }

    /// Record the mode's final score to the local leaderboard and Game
    /// Center. Classic records the single hit; Derby records the total;
    /// Streak, Pitch Challenge, and Golden Ball record the best single
    /// hit. Golden Ball also records its total points as a separate best.
    private func recordModeResult() {
        let score: Int
        switch game.playMode {
        case .classic: score = finalDistance
        case .derby: score = derbyTotal
        case .streak, .pitchChallenge, .goldenBall: score = derbyBest
        }
        if game.playMode == .goldenBall {
            isNewPointsBest = game.recordGoldenBall(points: pointsTotal)
        }
        guard score > 0 else { return }
        isNewBest = game.recordHit(distance: score)
        Task { await gameCenter.submitScore(score) }
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
                if coinsEarned > 0 {
                    Label("+\(coinsEarned) coins", systemImage: "dollarsign.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Color.yellow)
                }
                if game.bat.powerBoost > 0 {
                    Text("Power boost +\(game.bat.powerBoostPercent)% from the \(game.bat.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

            // Mode status: running totals for the 10-pitch modes.
            switch game.playMode {
            case .classic:
                EmptyView()
            case .derby:
                Text(gameOver
                     ? "Derby total: \(derbyTotal) feet · Best hit: \(derbyBest) feet"
                     : "Derby total: \(derbyTotal) feet · \(pitchesLeft) pitch\(pitchesLeft == 1 ? "" : "es") left")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            case .streak:
                Text(gameOver
                     ? "Best streak: \(bestStreak) perfect hit\(bestStreak == 1 ? "" : "s")"
                     : (lastPerfect
                        ? "Perfect! Streak: \(streak) · \(pitchesLeft) pitch\(pitchesLeft == 1 ? "" : "es") left"
                        : "Streak broken · \(pitchesLeft) pitch\(pitchesLeft == 1 ? "" : "es") left"))
                    .font(.headline)
                    .multilineTextAlignment(.center)
            case .pitchChallenge:
                Text(gameOver
                     ? "Best hit: \(derbyBest) feet"
                     : "\(pitchesLeft) pitch\(pitchesLeft == 1 ? "" : "es") left · Next: \(pitchType.title)")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            case .goldenBall:
                VStack(spacing: 4) {
                    if gameOver {
                        Text("Golden Ball total: \(pointsTotal) points")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text(pointsBreakdown)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        if isNewPointsBest {
                            Text("NEW BEST POINTS!")
                                .font(.headline)
                                .foregroundStyle(Color.orange)
                        }
                    } else {
                        Text("Points: \(pointsTotal) · \(pitchesLeft) pitch\(pitchesLeft == 1 ? "" : "es") left")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        if lastWasGolden {
                            Text("★ Golden Ball! This ball: \(lastPoints > 0 ? "+" : "")\(lastPoints) points")
                                .font(.subheadline).bold()
                                .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.10))
                        } else if finalDistance > 0 || lastPoints != 0 {
                            Text("This ball: \(lastPoints > 0 ? "+" : "")\(lastPoints) points")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Challenge a friend: share a distance card. Works for ranked
            // and practice hits — sharing is sharing.
            if finalDistance > 0 {
                if let image = shareImage {
                    ShareLink(item: Image(uiImage: image),
                              preview: SharePreview("I hit it \(finalDistance) feet!", image: Image(uiImage: image))) {
                        Label("Challenge a Friend", systemImage: "square.and.arrow.up")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundStyle(Color.white)
                            .cornerRadius(14)
                    }
                } else {
                    ShareLink(item: "I hit it \(finalDistance) feet in How Far Can You Hit It? Can you beat that?") {
                        Label("Challenge a Friend", systemImage: "square.and.arrow.up")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundStyle(Color.white)
                            .cornerRadius(14)
                    }
                }
            }

            // Buttons: mode-aware. Classic swings again (or refills);
            // the 10-pitch modes offer the next pitch until the game ends.
            if game.playMode != .classic && !gameOver {
                Button("Next Pitch (\(pitchesLeft) left)") { phase = .idle }
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .cornerRadius(14)
            } else if game.playMode != .classic && gameOver {
                Button("Play Again") { startGame() }
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .cornerRadius(14)
            } else if game.canSwing {
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
                        if await store.purchaseRankedRefill() {
                            game.addRankedSwings(20)
                            phase = .idle
                        }
                    }
                } label: {
                    Text("Get 20 more ranked swings — $0.99")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(Color.white)
                        .cornerRadius(14)
                }
                if AdsManager.adsEnabled && !store.removeAdsUnlocked {
                    Button {
                        ads.showRewardedAd {
                            game.addRankedSwings(5)
                            phase = .idle
                        }
                    } label: {
                        Label(ads.isAdReady ? "Watch an ad — +5 ranked swings" : "Ad loading…",
                              systemImage: "play.rectangle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.teal)
                            .foregroundStyle(Color.white)
                            .cornerRadius(14)
                    }
                    .disabled(!ads.isAdReady || ads.isShowingAd)
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
        .onAppear {
            // Render the share card once, so Challenge a Friend is instant.
            shareImage = renderShareCard(
                distance: finalDistance,
                sluggerName: game.slugger.name,
                seasonTitle: game.season.title)
        }
    }

    private var tookPitchCard: some View {
        VStack(spacing: 12) {
            Text("Took the pitch!")
                .font(.title2).bold()
            Text("No swing used. The \(game.slugger.ballKind.name) sailed by.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if game.playMode == .goldenBall {
                if tookGoldenBall {
                    Text("That was the golden ball — the 2x chance is gone.")
                        .font(.subheadline).bold()
                        .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.10))
                        .multilineTextAlignment(.center)
                } else {
                    Text("Points: \(pointsTotal)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if game.playMode != .classic && !gameOver {
                Text("\(pitchesLeft) pitch\(pitchesLeft == 1 ? "" : "es") left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if game.playMode != .classic && gameOver {
                Button("Back to Home") { game.screen = .home }
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .cornerRadius(14)
            } else {
                Button("Pitch Again") { phase = .idle }
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .cornerRadius(14)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 12)
        .padding(.horizontal, 24)
    }
}

/// Fireworks for a huge hit (over 450 feet) — in any mode. A few bursts
/// of sparks that expand and fade, looping while the result is up.
struct FireworksView: View {
    private let bursts: [(x: CGFloat, y: CGFloat, color: Color)] = [
        (0.25, 0.28, .red),
        (0.70, 0.20, .yellow),
        (0.50, 0.42, .blue),
        (0.85, 0.45, .green),
        (0.15, 0.55, .pink),
    ]
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(bursts.indices, id: \.self) { i in
                    let b = bursts[i]
                    ZStack {
                        ForEach(0..<12, id: \.self) { j in
                            let angle = CGFloat(j) * .pi / 6
                            Circle()
                                .fill(b.color)
                                .frame(width: 6, height: 6)
                                .offset(x: animate ? cos(angle) * 46 : 0,
                                        y: animate ? sin(angle) * 46 : 0)
                                .opacity(animate ? 0 : 1)
                        }
                    }
                    .position(x: geo.size.width * b.x, y: geo.size.height * b.y)
                    .animation(
                        .easeOut(duration: 1.0)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.25),
                        value: animate
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Field pieces

/// The ball a slugger hits, by kind. Most hit a baseball; the animals
/// and friends each hit their own thing. A golden ball (Golden Ball mode)
/// renders gold in whatever shape it is.
struct BallView: View {
    var kind: BallKind
    var isGolden: Bool = false

    var body: some View {
        switch kind {
        case .baseball: BaseballView(isGolden: isGolden)
        case .tennisBall: TennisBallView(isGolden: isGolden)
        case .yarnBall: YarnBallView(isGolden: isGolden)
        case .pumpkin: PumpkinView(isGolden: isGolden)
        case .ornament: OrnamentView(isGolden: isGolden)
        case .fish: FishView(isGolden: isGolden)
        }
    }
}

/// The pitched ball: a regular baseball — white with red seams.
/// A golden ball reads as special — used for the Golden Ball mode.
struct BaseballView: View {
    var isGolden: Bool = false

    var body: some View {
        let seamColor = isGolden ? Color(red: 0.65, green: 0.45, blue: 0.05) : Color.red
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: isGolden
                            ? [Color(red: 1.0, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.60, blue: 0.10)]
                            : [Color.white, Color(red: 0.88, green: 0.88, blue: 0.90)]),
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
            .stroke(seamColor, lineWidth: 1.6)
            Path { p in
                p.move(to: CGPoint(x: 23, y: 4))
                p.addQuadCurve(to: CGPoint(x: 23, y: 26), control: CGPoint(x: 17, y: 15))
            }
            .stroke(seamColor, lineWidth: 1.6)
            // Stitch ticks across the seams
            ForEach([9, 14, 19], id: \.self) { y in
                Path { p in
                    p.move(to: CGPoint(x: 5, y: CGFloat(y)))
                    p.addLine(to: CGPoint(x: 10, y: CGFloat(y) + 1))
                }
                .stroke(seamColor, lineWidth: 1.2)
                Path { p in
                    p.move(to: CGPoint(x: 20, y: CGFloat(y) + 1))
                    p.addLine(to: CGPoint(x: 25, y: CGFloat(y)))
                }
                .stroke(seamColor, lineWidth: 1.2)
            }
        }
        .frame(width: 30, height: 30)
    }
}

/// A tennis ball — bright yellow-green with white curved seams.
/// Big Dog's ball.
struct TennisBallView: View {
    var isGolden: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: isGolden
                            ? [Color(red: 1.0, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.60, blue: 0.10)]
                            : [Color(red: 0.85, green: 0.92, blue: 0.35), Color(red: 0.62, green: 0.76, blue: 0.18)]),
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 16
                    )
                )
            // The classic curved seams, left and right.
            Path { p in
                p.move(to: CGPoint(x: 6, y: 2))
                p.addQuadCurve(to: CGPoint(x: 6, y: 28), control: CGPoint(x: 13, y: 15))
            }
            .stroke(isGolden ? Color(red: 0.65, green: 0.45, blue: 0.05) : Color.white, lineWidth: 2)
            Path { p in
                p.move(to: CGPoint(x: 24, y: 2))
                p.addQuadCurve(to: CGPoint(x: 24, y: 28), control: CGPoint(x: 17, y: 15))
            }
            .stroke(isGolden ? Color(red: 0.65, green: 0.45, blue: 0.05) : Color.white, lineWidth: 2)
        }
        .frame(width: 30, height: 30)
    }
}

/// A ball of yarn — soft pink-red with wound wrap lines. Cat's ball.
struct YarnBallView: View {
    var isGolden: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: isGolden
                            ? [Color(red: 1.0, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.60, blue: 0.10)]
                            : [Color(red: 0.95, green: 0.55, blue: 0.60), Color(red: 0.80, green: 0.30, blue: 0.38)]),
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 16
                    )
                )
            // Wound wrap lines across the ball.
            ForEach([-6, 0, 6], id: \.self) { y in
                Path { p in
                    p.move(to: CGPoint(x: 2, y: 15 + CGFloat(y)))
                    p.addQuadCurve(to: CGPoint(x: 28, y: 15 + CGFloat(y)), control: CGPoint(x: 15, y: 8 + CGFloat(y)))
                }
                .stroke(isGolden ? Color(red: 0.65, green: 0.45, blue: 0.05) : Color(red: 0.65, green: 0.20, blue: 0.28), lineWidth: 1.5)
            }
            // A loose yarn end curling off the side.
            Path { p in
                p.move(to: CGPoint(x: 24, y: 22))
                p.addQuadCurve(to: CGPoint(x: 30, y: 28), control: CGPoint(x: 28, y: 24))
            }
            .stroke(isGolden ? Color(red: 0.65, green: 0.45, blue: 0.05) : Color(red: 0.65, green: 0.20, blue: 0.28), lineWidth: 1.5)
        }
        .frame(width: 30, height: 30)
    }
}

/// A pumpkin — orange with ridges and a stem. Scarecrow's ball.
struct PumpkinView: View {
    var isGolden: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: isGolden
                            ? [Color(red: 1.0, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.60, blue: 0.10)]
                            : [Color(red: 0.98, green: 0.60, blue: 0.15), Color(red: 0.85, green: 0.40, blue: 0.05)]),
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 16
                    )
                )
            // Ridges down the sides.
            Path { p in
                p.move(to: CGPoint(x: 10, y: 4))
                p.addQuadCurve(to: CGPoint(x: 10, y: 26), control: CGPoint(x: 6, y: 15))
            }
            .stroke(isGolden ? Color(red: 0.65, green: 0.45, blue: 0.05) : Color(red: 0.70, green: 0.30, blue: 0.02), lineWidth: 1.5)
            Path { p in
                p.move(to: CGPoint(x: 20, y: 4))
                p.addQuadCurve(to: CGPoint(x: 20, y: 26), control: CGPoint(x: 24, y: 15))
            }
            .stroke(isGolden ? Color(red: 0.65, green: 0.45, blue: 0.05) : Color(red: 0.70, green: 0.30, blue: 0.02), lineWidth: 1.5)
            // Stem on top.
            RoundedRectangle(cornerRadius: 1)
                .fill(isGolden ? Color(red: 0.65, green: 0.45, blue: 0.05) : Color(red: 0.35, green: 0.45, blue: 0.15))
                .frame(width: 4, height: 6)
                .offset(y: -14)
        }
        .frame(width: 30, height: 30)
    }
}

/// A Christmas ornament — a shiny red bauble with a gold cap.
/// Gnome's ball.
struct OrnamentView: View {
    var isGolden: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: isGolden
                            ? [Color(red: 1.0, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.60, blue: 0.10)]
                            : [Color(red: 0.90, green: 0.20, blue: 0.25), Color(red: 0.62, green: 0.08, blue: 0.12)]),
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 16
                    )
                )
            // Shiny highlight.
            Ellipse()
                .fill(Color.white.opacity(0.5))
                .frame(width: 8, height: 5)
                .offset(x: -6, y: -7)
                .rotationEffect(.degrees(-30))
            // Gold cap and hanger loop on top.
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: 0.85, green: 0.70, blue: 0.25))
                .frame(width: 8, height: 4)
                .offset(y: -14)
            Circle()
                .stroke(Color(red: 0.85, green: 0.70, blue: 0.25), lineWidth: 1.5)
                .frame(width: 4, height: 4)
                .offset(y: -18)
        }
        .frame(width: 30, height: 30)
    }
}

/// A fish — silver-blue, swimming right. Polar Bear's ball.
struct FishView: View {
    var isGolden: Bool = false

    var body: some View {
        ZStack {
            let bodyColor = isGolden
                ? Color(red: 0.95, green: 0.78, blue: 0.30)
                : Color(red: 0.72, green: 0.80, blue: 0.86)
            let darkColor = isGolden
                ? Color(red: 0.65, green: 0.45, blue: 0.05)
                : Color(red: 0.45, green: 0.55, blue: 0.65)
            // Tail fin (left).
            Path { p in
                p.move(to: CGPoint(x: -8, y: 15))
                p.addLine(to: CGPoint(x: -15, y: 9))
                p.addLine(to: CGPoint(x: -15, y: 21))
                p.closeSubpath()
            }
            .fill(bodyColor)
            // Body.
            Ellipse()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [bodyColor, darkColor]),
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 22, height: 11)
                .offset(x: 2)
            // Top fin.
            Path { p in
                p.move(to: CGPoint(x: 0, y: 10))
                p.addLine(to: CGPoint(x: 5, y: 6))
                p.addLine(to: CGPoint(x: 8, y: 10))
                p.closeSubpath()
            }
            .fill(darkColor)
            // Eye.
            Circle().fill(Color.black).frame(width: 2.5, height: 2.5).offset(x: 9, y: 14)
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
