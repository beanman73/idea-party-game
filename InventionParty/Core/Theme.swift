//
//  Theme.swift
//  Invention Party
//
//  "Sketchbook" design system — warm kraft-paper light mode, chalkboard dark
//  mode, charcoal ink outlines, and a playful hand-drawn aesthetic.
//
//  This file owns the design *tokens*: colors, fonts, and the sketchy shape
//  primitives. Reusable components live in SharedUI.swift.
//

import SwiftUI
import UIKit

// MARK: - Color helpers

extension Color {
    /// Create a Color from a hex string like "#E5533C" or "E5533C".
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: Double
        switch cleaned.count {
        case 8: // RRGGBBAA
            r = Double((value & 0xFF00_0000) >> 24) / 255
            g = Double((value & 0x00FF_0000) >> 16) / 255
            b = Double((value & 0x0000_FF00) >> 8) / 255
            a = Double(value & 0x0000_00FF) / 255
        default: // RRGGBB
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Create a Color that automatically adapts to light / dark appearance.
    init(light: String, dark: String) {
        self = Color(uiColor: UIColor { trait in
            UIColor(Color(hex: trait.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

// MARK: - Palette

/// The Sketchbook palette. Surfaces and ink adapt between kraft-paper (light)
/// and chalkboard (dark); the accent crayons stay vivid in both.
enum Palette {
    // Surfaces
    static let paper      = Color(light: "#F4E9D4", dark: "#1C1A16") // app background
    static let card       = Color(light: "#FBF4E4", dark: "#2A2620") // raised card
    static let cardSunken = Color(light: "#FFFDF7", dark: "#211E18") // inputs / wells
    static let drawSheet  = Color(hex: "#FFFDF7")                    // always-light "paper" to draw on

    // Ink for content sitting on the always-light drawSheet. Fixed (non-adaptive)
    // so text/outlines stay dark and legible even in dark mode, where the regular
    // `ink` token flips to light cream and would vanish on the white sheet.
    static let sheetInk      = Color(hex: "#2B2B28")
    static let sheetInkFaint = Color(hex: "#A89E88")

    // Ink (text + outlines)
    static let ink      = Color(light: "#2B2B28", dark: "#F1E7D3") // primary
    static let inkSoft  = Color(light: "#6B6453", dark: "#C7BCA4") // secondary
    static let inkFaint = Color(light: "#A89E88", dark: "#8B8067") // tertiary / placeholder
    static let cream    = Color(hex: "#FFF8EC")                     // text/lines on dark accents

    // Accent crayons
    static let tomato  = Color(light: "#E5533C", dark: "#F26B54")
    static let mustard = Color(light: "#F2A516", dark: "#FFB733")
    static let teal    = Color(light: "#2B9C8A", dark: "#36BBA4")
    static let grape   = Color(light: "#7A5CC2", dark: "#9C7DE6")
    static let leaf    = Color(light: "#4FA05A", dark: "#5FC06C")
    static let sky     = Color(light: "#3E8BC9", dark: "#52A5E0")
    static let danger  = Color(light: "#D6453E", dark: "#F0635B")

    // Medals
    static let gold   = Color(light: "#F2A516", dark: "#FFB733")
    static let silver = Color(light: "#B6AC95", dark: "#CDC3AB")
    static let bronze = Color(light: "#C77B3A", dark: "#DB9554")
}

// MARK: - Fonts

extension Font {
    /// Big, wide marker font for screen titles and hero text.
    static func display(_ size: CGFloat) -> Font {
        .custom("MarkerFelt-Wide", size: size)
    }

    /// Readable hand-printed font for body, labels, and buttons.
    static func marker(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "ChalkboardSE-Bold" : "ChalkboardSE-Regular", size: size)
    }
}

// MARK: - Seeded randomness (stable per-shape jitter)

/// Tiny deterministic xorshift64 generator so each sketchy shape keeps the
/// same "hand-drawn" wobble across re-renders instead of jittering every frame.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Sketchy shape

/// A rounded rectangle whose straight edges wobble slightly, like it was drawn
/// by hand with a marker. Corners stay clean so fills/strokes line up. The
/// wobble is deterministic per `seed`.
struct SketchyRoundedRectangle: Shape {
    var cornerRadius: CGFloat = 18
    var roughness: CGFloat = 1.6
    var seed: UInt64 = 42
    /// Number of little segments per edge — more = wavier.
    var segments: Int = 4

    func path(in rect: CGRect) -> Path {
        var rng = SeededGenerator(seed: seed)
        let r = max(0, min(cornerRadius, min(rect.width, rect.height) / 2))
        var path = Path()

        // Anchors where straight edges meet the corner arcs (kept un-jittered
        // so the path always closes cleanly).
        let topStart    = CGPoint(x: rect.minX + r, y: rect.minY)
        let topEnd      = CGPoint(x: rect.maxX - r, y: rect.minY)
        let rightStart  = CGPoint(x: rect.maxX, y: rect.minY + r)
        let rightEnd    = CGPoint(x: rect.maxX, y: rect.maxY - r)
        let bottomEnd   = CGPoint(x: rect.maxX - r, y: rect.maxY)
        let bottomStart = CGPoint(x: rect.minX + r, y: rect.maxY)
        let leftEnd     = CGPoint(x: rect.minX, y: rect.maxY - r)
        let leftStart   = CGPoint(x: rect.minX, y: rect.minY + r)

        path.move(to: topStart)
        addWavyLine(&path, from: topStart, to: topEnd, rng: &rng)
        path.addQuadCurve(to: rightStart, control: CGPoint(x: rect.maxX, y: rect.minY))
        addWavyLine(&path, from: rightStart, to: rightEnd, rng: &rng)
        path.addQuadCurve(to: bottomEnd, control: CGPoint(x: rect.maxX, y: rect.maxY))
        addWavyLine(&path, from: bottomEnd, to: bottomStart, rng: &rng)
        path.addQuadCurve(to: leftEnd, control: CGPoint(x: rect.minX, y: rect.maxY))
        addWavyLine(&path, from: leftEnd, to: leftStart, rng: &rng)
        path.addQuadCurve(to: topStart, control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }

    private func addWavyLine(_ path: inout Path, from a: CGPoint, to b: CGPoint,
                             rng: inout SeededGenerator) {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = max(hypot(dx, dy), 0.0001)
        let nx = -dy / len // perpendicular unit vector
        let ny = dx / len
        let count = max(2, segments)
        for i in 1...count {
            let t = CGFloat(i) / CGFloat(count)
            // No offset on the final point so it lands exactly on anchor `b`.
            let off = (i == count) ? 0 : CGFloat.random(in: -roughness...roughness, using: &rng)
            path.addLine(to: CGPoint(x: a.x + dx * t + nx * off,
                                     y: a.y + dy * t + ny * off))
        }
    }
}

/// A hand-drawn circle/blob — a near-circle with a wobbly outline. Used for
/// rank badges and judge chips.
struct SketchyCircle: Shape {
    var roughness: CGFloat = 1.4
    var seed: UInt64 = 7

    func path(in rect: CGRect) -> Path {
        var rng = SeededGenerator(seed: seed)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        let steps = 22
        for i in 0...steps {
            let angle = (CGFloat(i) / CGFloat(steps)) * 2 * .pi
            let wob = (i == steps) ? 0 : CGFloat.random(in: -roughness...roughness, using: &rng)
            let rr = radius + wob
            let p = CGPoint(x: center.x + cos(angle) * rr,
                            y: center.y + sin(angle) * rr)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}
