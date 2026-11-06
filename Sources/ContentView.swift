// ContentView.swift
// Screen router plus Home, Character Select, Season Picker, Leaderboard.

import SwiftUI
import UIKit

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
            }
        }
        .onAppear { game.resetSwingsIfNeeded() }
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var store: StoreManager

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
                        Text("Power \(game.bat.power) · Speed \(game.bat.speed)")
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

                // Swings
                HStack {
                    Label(game.unlimitedSwings ? "Unlimited swings" : "\(game.swingsLeft) swings left today", systemImage: "bolt.fill")
                        .font(.headline)
                    Spacer()
                    if game.lifetimeBest > 0 {
                        Text("Best: \(game.lifetimeBest) \(game.season.unitName(for: game.lifetimeBest))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Testing: unlimited swings, never consumes the daily 10.
                Toggle("Unlimited swings (testing)", isOn: Binding(
                    get: { game.unlimitedSwings },
                    set: { game.setUnlimitedSwings($0) }
                ))
                .font(.subheadline)

                Button {
                    if game.canSwing {
                        game.screen = .game
                    }
                } label: {
                    Text(game.canSwing ? "PLAY" : "OUT OF SWINGS")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(game.canSwing ? Color.blue : Color.gray)
                        .foregroundStyle(Color.white)
                        .cornerRadius(16)
                }
                .disabled(!game.canSwing)

                if !game.canSwing {
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

                VStack(spacing: 10) {
                    MenuButton(title: "Sluggers", systemImage: "person.3.fill") {
                        game.screen = .characters
                    }
                    MenuButton(title: "Pick Your Season", systemImage: "leaf.fill") {
                        game.screen = .seasons
                    }
                    MenuButton(title: "Leaderboard", systemImage: "trophy.fill") {
                        game.screen = .leaderboard
                    }
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
                                    Text("P\(bat.power) · S\(bat.speed)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if game.bat.id == bat.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.blue)
                                    }
                                }
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
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

struct LeaderboardView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var gameCenter: GameCenterManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HeaderBar(title: "Leaderboard") { game.screen = .home }
                Text("Local bests. The global Game Center board connects once it is configured in App Store Connect.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if game.leaderboard.isEmpty {
                    Text("No hits yet. Take a swing and set the first score!")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(Array(game.leaderboard.enumerated()), id: \.element.id) { index, entry in
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
                Spacer()
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
