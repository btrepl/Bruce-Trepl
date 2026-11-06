// CharacterArt.swift
// Illustrated sprite characters: single cohesive drawings, no bat baked in.
// Presets render their full sprite; Build-a-Slugger composes a character
// from a head, a torso, and legs part cropped from three sprites at runtime.
// The snowman is a generic funny snowman, drawn from scratch.

import SwiftUI
import UIKit

/// Renders any slugger (preset or custom) in a 150 x 190 frame.
struct SluggerArtView: View {
    let slugger: Slugger

    var body: some View {
        ZStack {
            // Soft ground shadow so the character sits on the field.
            Ellipse()
                .fill(Color.black.opacity(0.16))
                .frame(width: 112, height: 16)
                .offset(y: 96)
            if let image = SpriteRenderer.image(for: slugger) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 150, height: 190)
    }
}

/// Renders a slugger's front-facing portrait in a 150 x 190 frame — the
/// fun pose shown on the Home screen and in the character picker. Presets
/// have a portrait (Santa in his backwards YARD cap, Bigfoot's peace sign,
/// the Snowman's coffee, Trump's thumbs-up, the Ballplayer tipping his
/// cap); customs fall back to the back-view batter sprite.
struct SluggerPortraitView: View {
    let slugger: Slugger

    var body: some View {
        ZStack {
            // Soft ground shadow so the character sits on the field.
            Ellipse()
                .fill(Color.black.opacity(0.16))
                .frame(width: 112, height: 16)
                .offset(y: 96)
            if let preset = slugger.preset,
               let image = UIImage(named: preset.portraitAsset) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if let image = SpriteRenderer.image(for: slugger) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 150, height: 190)
    }
}

// MARK: - Sprite rendering

/// Loads illustrated sprites from the asset catalog and crops/composes them.
/// Sprites are 560 px wide, 1030 px tall, 1x images decoded into the asset
/// catalog at build time (see codemagic.yaml "Decode sprite assets").
enum SpriteRenderer {
    enum Part { case head, torso, legs }

    /// The image for a slugger: full sprite for presets, composed parts for customs.
    static func image(for slugger: Slugger) -> UIImage? {
        if let preset = slugger.preset {
            return UIImage(named: preset.rawValue)
        }
        return composedImage(head: slugger.headAsset,
                             torso: slugger.torsoAsset,
                             legs: slugger.legsAsset)
    }

    /// One part (head, torso, or legs) cropped from a sprite, for the builder thumbnails.
    /// Cropped parts are cached so the builder's 60 thumbnails stay cheap.
    private static var partCache: [String: UIImage] = [:]

    static func partImage(asset: String, part: Part) -> UIImage? {
        let key = "\(asset)-\(part)"
        if let cached = partCache[key] { return cached }
        guard let image = UIImage(named: asset),
              let cg = image.cgImage else { return nil }
        let spec = SpriteCatalog.spec(for: asset)
        let w = CGFloat(cg.width)
        let h = CGFloat(cg.height)
        let rect: CGRect
        switch part {
        case .head:
            rect = CGRect(x: 0, y: 0, width: w, height: h * spec.headEnd)
        case .torso:
            rect = CGRect(x: 0, y: h * spec.headEnd,
                          width: w, height: h * (spec.torsoEnd - spec.headEnd))
        case .legs:
            rect = CGRect(x: 0, y: h * spec.torsoEnd,
                          width: w, height: h * (1 - spec.torsoEnd))
        }
        guard let cropped = cg.cropping(to: rect) else { return nil }
        let partImage = UIImage(cgImage: cropped, scale: image.scale,
                                orientation: image.imageOrientation)
        partCache[key] = partImage
        return partImage
    }

    /// Compose a custom character from three parts, stacked with a small
    /// overlap so the seams hide under the chin and the belt line.
    static func composedImage(head: String, torso: String, legs: String) -> UIImage? {
        guard let headImg = partImage(asset: head, part: .head),
              let torsoImg = partImage(asset: torso, part: .torso),
              let legsImg = partImage(asset: legs, part: .legs),
              let headCG = headImg.cgImage,
              let torsoCG = torsoImg.cgImage,
              let legsCG = legsImg.cgImage else { return nil }
        let overlap = SpriteSpec.overlap
        let width = CGFloat(headCG.width)
        let height = CGFloat(headCG.height + torsoCG.height + legsCG.height)
            - 2 * overlap
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height),
                                               format: format)
        return renderer.image { _ in
            legsImg.draw(at: CGPoint(x: 0, y: CGFloat(headCG.height + torsoCG.height) - 2 * overlap))
            torsoImg.draw(at: CGPoint(x: 0, y: CGFloat(headCG.height) - overlap))
            headImg.draw(at: CGPoint(x: 0, y: 0))
        }
    }

    /// Where the hands grip the bat, as a fraction of the DISPLAYED image
    /// (full sprite for presets, composed image for customs). Presets use
    /// their own grip; customs use the torso's grip, mapped into the
    /// composed image's coordinates.
    static func gripPoint(for slugger: Slugger) -> CGPoint {
        if let preset = slugger.preset {
            return SpriteCatalog.spec(for: preset.rawValue).grip
        }
        let torsoSpec = SpriteCatalog.spec(for: slugger.torsoAsset)
        let headSpec = SpriteCatalog.spec(for: slugger.headAsset)
        let legsSpec = SpriteCatalog.spec(for: slugger.legsAsset)
        // Part heights in the composed image, as fractions of a sprite height.
        let headH = headSpec.headEnd
        let torsoH = torsoSpec.torsoEnd - torsoSpec.headEnd
        let legsH = 1 - legsSpec.torsoEnd
        let overlapFrac = SpriteSpec.overlap / 1030
        let composedH = headH + torsoH + legsH - 2 * overlapFrac
        // Grip y inside the torso, measured from the torso band's top.
        let gripYInTorso = torsoSpec.grip.y - torsoSpec.headEnd
        let gripY = (headH - overlapFrac + gripYInTorso) / composedH
        return CGPoint(x: torsoSpec.grip.x, y: gripY)
    }
}

// MARK: - Helpers

/// Simple triangle path, used for hats, noses, ties, and season icons.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Expression options for custom sluggers (kept for saved-data compatibility).
enum ExpressionStyle: String, CaseIterable, Identifiable, Codable {
    case grin, tongue, shades, wow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grin: return "Big Grin"
        case .tongue: return "Tongue Out"
        case .shades: return "Shades Smirk"
        case .wow: return "Wide-Eyed Wow"
        }
    }
}
