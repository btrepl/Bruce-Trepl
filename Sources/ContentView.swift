// ContentView.swift
// Screen router plus Home, Character Select, Season Picker, Leaderboard.

import SwiftUI
import UIKit
import GameKit

struct ContentView: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        ZStack {
            switch game.screen {
            case .home: HomeView()
            case .characters: CharacterSelectView()
            case .seasons: SeasonPickerView()
            case .buildSlugger: BuildSluggerView()
            case .buildBat: BuildBatView()
            case .game: GameView()
            case .leaderboard: LeaderboardView()
            case .seasonPass: SeasonPassView()
            }
        }
        .onAppear {
            game.resetRankedIfNeeded()
            game.refreshDailyReward()
            game.resetQuestsIfNeeded()
        }
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var ads: AdsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("How Far Can You Hit It?")
                    .font(.system(size: 30, weight: .black))
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                Text("A baseball is coming. How far can you hit it?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Current slugger + bat
                HStack(spacing: 16) {
                    SluggerPortraitView(slugger: game.slugger)
                        .scaleEffect(0.85)
                        .frame(width: 130, height: 165)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(game.slugger.name)
                            .font(.title3).bold()
                        Text("Swings a \(game.bat.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Power \(game.bat.power) · Speed \(game.bat.speed)\(game.bat.powerBoost > 0 ? " · +\(game.bat.powerBoostPercent)% power" : "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Season: \(game.season.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)

                // Ranked swings left today + coins
                HStack {
                    Label(game.rankedUnlimited ? "Unlimited ranked swings" : "\(game.rankedLeft) ranked swings left today", systemImage: "bolt.fill")
                        .font(.headline)
                    Spacer()
                    Label("\(game.coins)", systemImage: "dollarsign.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Color.yellow)
                    if game.lifetimeBest > 0 {
                        Text("Best: \(game.lifetimeBest) \(game.season.unitName(for: game.lifetimeBest))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Testing: unlimited ranked swings, never consumes the daily 10.
                Toggle("Unlimited ranked (testing)", isOn: Binding(
                    get: { game.unlimitedSwings },
                    set: { game.setUnlimitedSwings($0) }
                ))
                .font(.subheadline)

                // Mode picker: Classic, Derby, Timing Streak, Pitch Challenge.
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mode").bold()
                    Picker("Mode", selection: Binding(
                        get: { game.playMode },
                        set: { game.setPlayMode($0) }
                    )) {
                        ForEach(PlayMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(game.playMode.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Practice: unlimited, never counts. Ranked: 10/day, counts
                // for the leaderboard. Energy gates rewards, not play.
                Button {
                    game.mode = .practice
                    game.screen = .game
                } label: {
                    Text("PRACTICE — unlimited")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(Color.white)
                        .cornerRadius(16)
                }

                Button {
                    if game.rankedUnlimited || game.rankedLeft > 0 {
                        game.mode = .ranked
                        game.screen = .game
                    }
                } label: {
                    Text(game.rankedUnlimited || game.rankedLeft > 0 ? "RANKED — \(game.rankedLeft) left" : "RANKED — out for today")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(game.rankedUnlimited || game.rankedLeft > 0 ? Color.blue : Color.gray)
                        .foregroundStyle(Color.white)
                        .cornerRadius(16)
                }
                .disabled(!game.rankedUnlimited && game.rankedLeft <= 0)

                if !game.rankedUnlimited && game.rankedLeft <= 0 {
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
                    // Rewarded ad: watch once for +5 ranked swings. Hidden
                    // when Remove Ads is owned (ads are off for that player).
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

                VStack(spacing: 10) {
                    MenuButton(title: "Sluggers", systemImage: "person.3.fill") {
                        game.screen = .characters
                    }
                    MenuButton(title: "Pick Your Season", systemImage: "leaf.fill") {
                        game.screen = .seasons
                    }
                    MenuButton(title: "Season Pass", systemImage: "ticket.fill") {
                        game.screen = .seasonPass
                    }
                    MenuButton(title: "Leaderboard", systemImage: "trophy.fill") {
                        game.screen = .leaderboard
                    }
                }

                // Daily reward: claim once a day, streak climbs.
                if game.dailyRewardAvailable {
                    Button {
                        _ = game.claimDailyReward()
                    } label: {
                        Label("Claim daily reward — Day \(game.dailyStreak + 1) · \(DailyReward.coins(for: game.dailyStreak + 1)) coins\(DailyReward.rankedSwings(for: game.dailyStreak + 1) > 0 ? " + \(DailyReward.rankedSwings(for: game.dailyStreak + 1)) ranked swings" : "")", systemImage: "gift.fill")
                            .font(.subheadline).bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(Color.white)
                            .cornerRadius(12)
                    }
                } else {
                    Label("Daily reward claimed — streak: \(game.dailyStreak) day\(game.dailyStreak == 1 ? "" : "s")", systemImage: "gift.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Today's quests
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Quests").bold()
                    ForEach(game.quests) { quest in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(quest.title).bold()
                                    .font(.subheadline)
                                Text("\(quest.detail) — \(min(quest.progress, quest.target))/\(quest.target)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if quest.claimed {
                                Text("Claimed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if quest.isComplete {
                                Button {
                                    _ = game.claimQuest(quest)
                                } label: {
                                    Text("Claim \(quest.coinReward) coins")
                                        .font(.caption).bold()
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.green)
                                        .foregroundStyle(Color.white)
                                        .cornerRadius(8)
                                }
                            } else {
                                Text("\(quest.coinReward) coins")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }

                // Remove Ads + Unlimited Ranked ($4.99, one-time).
                if store.removeAdsUnlocked {
                    Label("Ads removed · Ranked unlimited", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        Task {
                            if await store.purchaseRemoveAds() {
                                game.setRemoveAdsUnlocked(true)
                            }
                        }
                    } label: {
                        Text(store.isPurchasing ? "Working…" : "Remove Ads + Unlimited Ranked — $4.99")
                            .font(.subheadline).bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundStyle(Color.white)
                            .cornerRadius(12)
                    }
                    .disabled(store.isPurchasing)
                }

                // Coin bundles — coins upgrade custom bats (+2% power each).
                HStack(spacing: 10) {
                    Button {
                        Task {
                            if await store.purchaseCoins1000() {
                                game.earnCoins(1000)
                            }
                        }
                    } label: {
                        Text("1,000 coins — $0.99")
                            .font(.subheadline).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.yellow.opacity(0.25))
                            .cornerRadius(10)
                    }
                    .disabled(store.isPurchasing)
                    Button {
                        Task {
                            if await store.purchaseCoins5000() {
                                game.earnCoins(5000)
                            }
                        }
                    } label: {
                        Text("5,000 coins — $2.99")
                            .font(.subheadline).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.yellow.opacity(0.25))
                            .cornerRadius(10)
                    }
                    .disabled(store.isPurchasing)
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
    }
}

struct MenuButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Character select

struct CharacterSelectView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var gameCenter: GameCenterManager

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HeaderBar(title: "Pick Your Slugger") { game.screen = .home }

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(PresetID.allCases) { preset in
                        let slugger = Slugger.presetSlugger(preset)
                        let bat = Bat.signatureBat(for: preset)
                        let selected = game.slugger.id == slugger.id
                        Button {
                            game.selectPreset(preset)
                            game.screen = .home
                        } label: {
                            VStack(spacing: 6) {
                                SluggerPortraitView(slugger: slugger)
                                    .scaleEffect(0.8)
                                    .frame(width: 120, height: 150)
                                Text(slugger.name).bold()
                                Text("Swings a \(bat.name)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("FREE")
                                    .font(.caption2).bold()
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding(8)
                            .background(selected ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selected ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Custom slugger card
                    VStack(spacing: 6) {
                        if store.customSluggerUnlocked {
                            Button {
                                game.selectCustomSlugger()
                                game.screen = .home
                            } label: {
                                VStack(spacing: 6) {
                                    SluggerPortraitView(slugger: game.customSlugger)
                                        .scaleEffect(0.8)
                                        .frame(width: 120, height: 150)
                                    Text(game.customSlugger.name).bold()
                                    Text("Your custom slugger")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            Button("Edit My Slugger") { game.screen = .buildSlugger }
                                .font(.caption)
                        } else {
                            SluggerPortraitView(slugger: game.customSlugger)
                                .scaleEffect(0.8)
                                .frame(width: 120, height: 150)
                                .opacity(0.5)
                            Text("Build-a-Slugger").bold()
                            Text("Make your own character")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button {
                                Task {
                                    if await store.purchaseCustomSlugger() {
                                        game.screen = .buildSlugger
                                    }
                                }
                            } label: {
                                Text(store.isPurchasing ? "Working…" : "Unlock — $0.99")
                                    .font(.caption).bold()
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange)
                                    .foregroundStyle(Color.white)
                                    .cornerRadius(8)
                            }
                            .disabled(store.isPurchasing)
                        }
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }

                // Custom bats shortcut
                MenuButton(title: "Build-a-Bat", systemImage: "hammer.fill") {
                    if store.customBatUnlocked {
                        game.screen = .buildBat
                    } else {
                        Task {
                            if await store.purchaseCustomBat() {
                                game.screen = .buildBat
                            }
                        }
                    }
                }
                if !store.customBatUnlocked {
                    Text("Build-a-Bat is a $0.99 unlock. Tap above to unlock.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !game.customBats.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Bats").bold()
                        ForEach(game.customBats) { bat in
                            VStack(alignment: .leading, spacing: 6) {
                                Button {
                                    game.selectCustomBat(bat)
                                    game.screen = .home
                                } label: {
                                    HStack {
                                        BatArtView(bat: bat)
                                            .scaleEffect(0.5)
                                            .frame(width: 20, height: 60)
                                        Text(bat.name)
                                        Spacer()
                                        Text("P\(bat.power) · S\(bat.speed)\(bat.powerBoost > 0 ? " · +\(bat.powerBoostPercent)%" : "")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if game.bat.id == bat.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.blue)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                // Upgrade: +2% power boost per level, up to +10%.
                                if bat.upgradeLevel < Bat.maxUpgradeLevel {
                                    let cost = Bat.upgradeCost(for: bat.upgradeLevel)
                                    Button {
                                        if game.upgradeBat(bat) {
                                            // Maxed-out achievement (Game Center).
                                            if let upgraded = game.customBats.first(where: { $0.id == bat.id }),
                                               upgraded.upgradeLevel >= Bat.maxUpgradeLevel {
                                                Task { await gameCenter.reportAchievement(.maxBat) }
                                            }
                                        }
                                    } label: {
                                        Text("Upgrade to +\(bat.powerBoostPercent + 2)% — \(cost) coins")
                                            .font(.caption).bold()
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(game.coins >= cost ? Color.yellow : Color.gray.opacity(0.3))
                                            .foregroundStyle(game.coins >= cost ? Color.black : Color.secondary)
                                            .cornerRadius(8)
                                    }
                                    .disabled(game.coins < cost)
                                } else {
                                    Text("Maxed out at +10% power")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                }
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Season picker

struct SeasonPickerView: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HeaderBar(title: "Pick Your Season") { game.screen = .home }
                Text("Pick a season — it decorates the field. Distance is always in feet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ForEach(Season.allCases) { season in
                    let selected = game.season == season
                    Button {
                        game.season = season
                        game.persistSeason()
                        game.screen = .home
                    } label: {
                        HStack(spacing: 16) {
                            SeasonIcon(season: season)
                                .frame(width: 56, height: 56)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(season.title).bold()
                                Text(season.decoration)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.blue)
                            }
                        }
                        .padding()
                        .background(selected ? Color.blue.opacity(0.12) : Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selected ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

/// Small original-shape icon for each season's unit.
struct SeasonIcon: View {
    let season: Season

    var body: some View {
        ZStack {
            switch season {
            case .fall:
                // Pumpkin
                Circle().fill(Color.orange).frame(width: 44, height: 44)
                Ellipse().fill(Color(red: 0.85, green: 0.45, blue: 0.10))
                    .frame(width: 12, height: 40)
                Ellipse().fill(Color(red: 0.85, green: 0.45, blue: 0.10))
                    .frame(width: 12, height: 40)
                    .rotationEffect(.degrees(60))
                Rectangle().fill(Color.green).frame(width: 6, height: 12).offset(y: -24)
            case .christmas:
                // Christmas tree
                Triangle().fill(Color.green).frame(width: 44, height: 22).offset(y: -8)
                Triangle().fill(Color.green).frame(width: 36, height: 20).offset(y: 6)
                Triangle().fill(Color.green).frame(width: 28, height: 18).offset(y: 18)
                Rectangle().fill(Color.brown).frame(width: 8, height: 12).offset(y: 30)
            case .normal:
                // Baseball (plain field)
                Circle().fill(Color.white).frame(width: 40, height: 40)
                    .shadow(radius: 2)
                Ellipse().fill(Color.red).frame(width: 4, height: 30)
                    .rotationEffect(.degrees(30))
                Ellipse().fill(Color.red).frame(width: 4, height: 30)
                    .rotationEffect(.degrees(-30))
            }
        }
    }
}

// MARK: - Leaderboard

/// Three boards in one: Friends (Game Center friends-only), Everyone
/// (Game Center global), and Local (on-device top 20). The friends board
/// is the one to watch — it is the only board where you know the names.
/// A dashboard button opens Game Center's own leaderboard, where the
/// player can use the system's challenge UI (including iOS 26 Challenges).
struct LeaderboardView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var gameCenter: GameCenterManager

    private enum BoardTab: String, CaseIterable {
        case friends = "Friends"
        case everyone = "Everyone"
        case local = "Local"
    }

    @State private var tab: BoardTab = .friends
    @State private var showDashboard = false
    @State private var localWeekOnly = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HeaderBar(title: "Leaderboard") { game.screen = .home }

                Picker("Board", selection: $tab) {
                    ForEach(BoardTab.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)

                switch tab {
                case .friends:
                    friendsBoard
                case .everyone:
                    globalBoard
                case .local:
                    localBoard
                }

                Button {
                    showDashboard = true
                } label: {
                    Label("Open in Game Center", systemImage: "gamecontroller.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal)
        }
        .task { await gameCenter.loadLeaderboards() }
        .sheet(isPresented: $showDashboard) {
            GameCenterDashboardView()
        }
    }

    // MARK: - Friends board (Game Center, friends-only)

    @ViewBuilder
    private var friendsBoard: some View {
        if !gameCenter.isAuthenticated {
            Text("Sign in to Game Center to see your friends' scores.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
        } else if gameCenter.isLoadingBoards {
            ProgressView("Loading the friends board…")
                .padding(.top, 40)
        } else if let error = gameCenter.boardsError {
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
        } else if gameCenter.friendsEntries.isEmpty {
            VStack(spacing: 8) {
                Text("No friends on the board yet.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
                Text("Hit a big one, tap Challenge a Friend, and get them playing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        } else {
            ForEach(gameCenter.friendsEntries, id: \.player.gamePlayerID) { entry in
                boardRow(rank: entry.rank,
                         name: entry.player.displayName,
                         distance: entry.score,
                         isYou: entry.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID)
            }
        }
    }

    // MARK: - Global board (Game Center, everyone)

    @ViewBuilder
    private var globalBoard: some View {
        if !gameCenter.isAuthenticated {
            Text("Sign in to Game Center to see the global board.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
        } else if gameCenter.isLoadingBoards {
            ProgressView("Loading the global board…")
                .padding(.top, 40)
        } else if let error = gameCenter.boardsError {
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
        } else if gameCenter.globalEntries.isEmpty {
            Text("No scores on the global board yet. Be the first!")
                .foregroundStyle(.secondary)
                .padding(.top, 40)
        } else {
            ForEach(gameCenter.globalEntries, id: \.player.gamePlayerID) { entry in
                boardRow(rank: entry.rank,
                         name: entry.player.displayName,
                         distance: entry.score,
                         isYou: entry.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID)
            }
        }
    }

    // MARK: - Local board (on-device top 20)

    @ViewBuilder
    private var localBoard: some View {
        Text("Your best hits on this device.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

        // Weekly board: only hits from the current calendar week
        // (Monday–Sunday). The board resets every Monday.
        Picker("Local range", selection: $localWeekOnly) {
            Text("All Time").tag(false)
            Text("This Week").tag(true)
        }
        .pickerStyle(.segmented)

        let shown = localWeekOnly
            ? game.leaderboard.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            : game.leaderboard

        if shown.isEmpty {
            Text(localWeekOnly ? "No hits this week yet. Take a swing!" : "No hits yet. Take a swing and set the first score!")
                .foregroundStyle(.secondary)
                .padding(.top, 40)
        } else {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, entry in
                HStack {
                    Text("#\(index + 1)").bold().frame(width: 40, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.distanceText).bold()
                        Text("\(entry.characterName) · \(entry.season.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if index == 0 {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.yellow)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Shared Game Center row

    private func boardRow(rank: Int, name: String, distance: Int, isYou: Bool) -> some View {
        HStack {
            Text("#\(rank)").bold().frame(width: 40, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(distance) feet").bold()
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isYou {
                Text("YOU")
                    .font(.caption2).bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Color.yellow)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Season pass

/// The season pass: 10 levels, 150 XP each, earned from ranked hits.
/// Free track pays coins; the premium track ($4.99) pays more coins plus
/// a Golden Bat at level 10. Themed to the player's selected season.
struct SeasonPassView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var store: StoreManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HeaderBar(title: "Season Pass — \(game.season.title)") { game.screen = .home }

                // Progress header
                VStack(spacing: 6) {
                    Text("Level \(game.passLevel) of \(SeasonPass.levels.count)")
                        .font(.title3).bold()
                    ProgressView(value: Double(game.passXPIntoLevel), total: Double(SeasonPass.xpPerLevel))
                    Text("\(game.passXPIntoLevel) / \(SeasonPass.xpPerLevel) XP to the next level · \(game.seasonXP) total XP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Earn XP from ranked hits: 10 per swing + 1 per 10 feet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)

                // Premium unlock
                if game.premiumPassOwned {
                    Label("Premium pass owned", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        Task {
                            if await store.purchaseSeasonPass() {
                                game.setPremiumPassOwned(true)
                            }
                        }
                    } label: {
                        Text(store.isPurchasing ? "Working…" : "Unlock Premium Pass — $4.99")
                            .font(.subheadline).bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundStyle(Color.white)
                            .cornerRadius(12)
                    }
                    .disabled(store.isPurchasing)
                }

                // The 10 levels
                ForEach(SeasonPass.levels) { row in
                    let reached = row.level <= game.passLevel
                    let freeClaimed = game.claimedFreeRewards.contains(row.level)
                    let premiumClaimed = game.claimedPremiumRewards.contains(row.level)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Level \(row.level)")
                            .bold()
                        HStack(spacing: 10) {
                            // Free track
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FREE")
                                    .font(.caption2).bold()
                                    .foregroundStyle(.secondary)
                                Text("\(row.freeCoins) coins")
                                    .font(.subheadline)
                                Button {
                                    _ = game.claimFreeReward(level: row.level)
                                } label: {
                                    Text(freeClaimed ? "Claimed" : "Claim")
                                        .font(.caption).bold()
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(reached && !freeClaimed ? Color.green : Color.gray.opacity(0.3))
                                        .foregroundStyle(reached && !freeClaimed ? Color.white : Color.secondary)
                                        .cornerRadius(8)
                                }
                                .disabled(!reached || freeClaimed)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            // Premium track
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PREMIUM")
                                    .font(.caption2).bold()
                                    .foregroundStyle(Color.purple)
                                Text("\(row.premiumCoins) coins\(row.premiumBonus.map { " + \($0)" } ?? "")")
                                    .font(.subheadline)
                                Button {
                                    _ = game.claimPremiumReward(level: row.level)
                                } label: {
                                    Text(premiumClaimed ? "Claimed" : (game.premiumPassOwned ? "Claim" : "Premium"))
                                        .font(.caption).bold()
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(reached && game.premiumPassOwned && !premiumClaimed ? Color.purple : Color.gray.opacity(0.3))
                                        .foregroundStyle(reached && game.premiumPassOwned && !premiumClaimed ? Color.white : Color.secondary)
                                        .cornerRadius(8)
                                }
                                .disabled(!reached || !game.premiumPassOwned || premiumClaimed)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(reached ? Color.blue.opacity(0.08) : Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Shared header

struct HeaderBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            Spacer()
            Text(title).bold()
            Spacer()
            // Balance the back button
            Image(systemName: "chevron.left").opacity(0)
            Text("Back").opacity(0)
        }
        .padding(.top, 12)
    }
}
