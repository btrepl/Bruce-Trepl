// BuilderViews.swift
// Build-a-Slugger and Build-a-Bat workshops.
// Both are $0.99 unlocks in the full app (see StoreManager); the views
// themselves assume the unlock already happened.

import SwiftUI
import UIKit

// MARK: - Build-a-Slugger

/// Pick a head, a torso, and legs from the 20-entry sprite catalog.
/// The preview composes the three parts into one character, exactly as
/// the game renders it.
struct BuildSluggerView: View {
    @EnvironmentObject var game: GameState

    @State private var name: String = ""
    @State private var headAsset: String = "santa"
    @State private var torsoAsset: String = "santa"
    @State private var legsAsset: String = "santa"
    @State private var didInit = false

    private var preview: Slugger {
        Slugger(id: "slugger-custom", name: name.isEmpty ? "My Slugger" : name,
                preset: nil, face: .swoop, hat: .cap, jerseyColor: .blue,
                expression: .grin, isCustom: true,
                headAsset: headAsset, torsoAsset: torsoAsset, legsAsset: legsAsset)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HeaderBar(title: "Build-a-Slugger") { game.screen = .characters }

                // Live preview: the three parts composed, as in the game.
                SluggerArtView(slugger: preview)
                    .frame(height: 190)

                TextField("Name your slugger", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                PartPickerRow(title: "Head", selection: $headAsset, part: .head)
                PartPickerRow(title: "Torso", selection: $torsoAsset, part: .torso)
                PartPickerRow(title: "Legs", selection: $legsAsset, part: .legs)

                Button {
                    game.saveCustomSlugger(preview)
                    game.selectCustomSlugger()
                    game.screen = .characters
                } label: {
                    Text("Save My Slugger")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
        }
        .onAppear {
            // Seed the form from the saved custom slugger exactly once.
            if !didInit {
                didInit = true
                name = game.customSlugger.name
                headAsset = game.customSlugger.headAsset
                torsoAsset = game.customSlugger.torsoAsset
                legsAsset = game.customSlugger.legsAsset
            }
        }
    }
}

/// A labeled horizontal picker of sprite parts (heads, torsos, or legs).
struct PartPickerRow: View {
    let title: String
    @Binding var selection: String
    let part: SpriteRenderer.Part

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).bold().padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SpriteCatalog.all) { spec in
                        let selected = selection == spec.id
                        Button { selection = spec.id } label: {
                            VStack(spacing: 2) {
                                if let img = SpriteRenderer.partImage(asset: spec.id, part: part) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 52, height: 52)
                                }
                                Text(spec.displayName)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 64)
                            }
                            .padding(6)
                            .background(selected ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selected ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Build-a-Bat

struct BuildBatView: View {
    @EnvironmentObject var game: GameState

    @State private var name: String = ""
    @State private var object: BatObject = .classicBat
    @State private var power: Double = 4  // speed = 8 - power

    private var speed: Int { 8 - Int(power) }

    private var preview: Bat {
        Bat(id: UUID().uuidString,
            name: name.isEmpty ? object.displayName : name,
            object: object, power: Int(power), speed: speed, isCustom: true)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HeaderBar(title: "Build-a-Bat") { game.screen = .characters }

                // Preview + stats
                HStack(spacing: 20) {
                    BatArtView(bat: preview)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(preview.name).bold()
                        Text("Power \(preview.power) · Speed \(preview.speed)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Power + speed always add up to 8.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                TextField("Name your bat", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pick an object").bold().padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                        GridItem(.flexible()), GridItem(.flexible())],
                              spacing: 12) {
                        ForEach(BatObject.allCases) { obj in
                            let selected = object == obj
                            Button { object = obj } label: {
                                VStack(spacing: 4) {
                                    BatArtView(bat: Bat(id: obj.rawValue, name: obj.displayName,
                                                        object: obj, power: 4, speed: 4,
                                                        isCustom: true))
                                        .scaleEffect(0.55)
                                        .frame(width: 22, height: 66)
                                    Text(obj.displayName)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(6)
                                .background(selected ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selected ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Power: \(Int(power)) · Speed: \(speed)").bold()
                        .padding(.horizontal)
                    Slider(value: $power, in: 1...7, step: 1)
                        .padding(.horizontal)
                    HStack {
                        Text("Fast").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("Powerful").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                Button {
                    game.addCustomBat(preview)
                    game.screen = .characters
                } label: {
                    Text("Save My Bat & Use It")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
        }
    }
}
