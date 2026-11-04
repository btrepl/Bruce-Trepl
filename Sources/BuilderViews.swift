// BuilderViews.swift
// Build-a-Slugger and Build-a-Bat workshops.
// Both are $0.99 unlocks in the full app (see StoreManager); the views
// themselves assume the unlock already happened.

import SwiftUI
import UIKit

// MARK: - Build-a-Slugger

struct BuildSluggerView: View {
    @EnvironmentObject var game: GameState

    @State private var name: String = ""
    @State private var face: FaceStyle = .swoop
    @State private var expression: ExpressionStyle = .grin
    @State private var hat: HatStyle = .cap
    @State private var jerseyColor: ColorChoice = .blue
    @State private var didInit = false

    private var preview: Slugger {
        Slugger(id: "slugger-custom", name: name.isEmpty ? "My Slugger" : name,
                preset: nil, face: face, hat: hat, jerseyColor: jerseyColor,
                expression: expression, isCustom: true)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HeaderBar(title: "Build-a-Slugger") { game.screen = .characters }

                // Live preview: smaller body, larger goofy head, cartoonish.
                CustomSluggerArt(slugger: preview, expression: expression)
                    .frame(height: 190)

                TextField("Name your slugger", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                PickerRow(title: "Face", selection: $face, cases: FaceStyle.allCases) {
                    $0.displayName
                }
                PickerRow(title: "Expression", selection: $expression, cases: ExpressionStyle.allCases) {
                    $0.displayName
                }
                PickerRow(title: "Hat", selection: $hat, cases: HatStyle.allCases) {
                    $0.displayName
                }
                PickerRow(title: "Jersey", selection: $jerseyColor, cases: ColorChoice.allCases) {
                    $0.displayName
                }

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
                face = game.customSlugger.face
                expression = game.customSlugger.expression
                hat = game.customSlugger.hat
                jerseyColor = game.customSlugger.jerseyColor
            }
        }
    }
}

/// A labeled chip picker row for an enum case list.
struct PickerRow<T: Hashable & Identifiable>: View {
    let title: String
    @Binding var selection: T
    let cases: [T]
    let label: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).bold().padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(cases) { item in
                        Button { selection = item } label: {
                            Text(label(item))
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selection == item ? Color.blue : Color(.secondarySystemBackground))
                                .foregroundStyle(selection == item ? Color.white : Color.primary)
                                .cornerRadius(20)
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
