//
//  GeneratedDoodle.swift
//  Invention Party
//
//  Renders AI-generated doodle recipes with a small, safe vocabulary of
//  hand-drawn shapes. AI picks the recipe; the app owns the drawing code.
//

import SwiftUI

struct GeneratedDoodle: View {
    let recipe: DoodleRecipe
    var size: CGFloat = 56
    var seed: UInt64 = 5

    var body: some View {
        Canvas { ctx, area in
            let s = min(area.width, area.height)
            let ox = (area.width - s) / 2
            let oy = (area.height - s) / 2
            let stroke = StrokeStyle(lineWidth: max(1.6, s * 0.062),
                                     lineCap: .round,
                                     lineJoin: .round)
            let thin = StrokeStyle(lineWidth: max(1.1, s * 0.04),
                                   lineCap: .round,
                                   lineJoin: .round)
            let accent = recipeColor(recipe.color)
            let shadow = Palette.ink.opacity(0.2)

            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: ox + x * s, y: oy + y * s)
            }

            func salted(_ value: UInt64) -> UInt64 {
                recipe.baseShape.unicodeScalars.reduce(seed &+ value) { result, scalar in
                    result &* 31 &+ UInt64(scalar.value)
                }
            }

            func draw(_ path: Path, fill: Color? = nil, color: Color = Palette.ink,
                      style: StrokeStyle? = nil) {
                if let fill { ctx.fill(path, with: .color(fill)) }
                let used = style ?? stroke
                ctx.stroke(path, with: .color(shadow),
                           style: StrokeStyle(lineWidth: used.lineWidth * 0.7,
                                              lineCap: .round,
                                              lineJoin: .round))
                ctx.stroke(path, with: .color(color), style: used)
            }

            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                      _ r: CGFloat, fill: Color? = nil, color: Color = Palette.ink,
                      salt: UInt64 = 0) {
                let frame = CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s)
                let path = SketchyRoundedRectangle(cornerRadius: r * s,
                                                   roughness: s * 0.01,
                                                   seed: salted(20 &+ salt)).path(in: frame)
                draw(path, fill: fill, color: color)
            }

            func oval(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                      fill: Color? = nil, color: Color = Palette.ink,
                      style: StrokeStyle? = nil, salt: UInt64 = 0) {
                let path = wobblyOval(center: p(x, y), rx: rx * s, ry: ry * s,
                                      seed: salted(40 &+ salt), roughness: s * 0.01, steps: 22)
                draw(path, fill: fill, color: color, style: style)
            }

            func line(_ points: [(CGFloat, CGFloat)], color: Color = Palette.ink,
                      style: StrokeStyle? = nil, salt: UInt64 = 0) {
                guard points.count >= 2 else { return }
                var path = Path()
                var last = p(points[0].0, points[0].1)
                path.move(to: last)
                for (index, point) in points.dropFirst().enumerated() {
                    let next = p(point.0, point.1)
                    path.addPath(wobblyLine(from: last, to: next,
                                            seed: salted(UInt64(index) &+ salt),
                                            roughness: s * 0.01,
                                            segments: 3))
                    last = next
                }
                draw(path, color: color, style: style ?? thin)
            }

            func triangle(_ pts: [(CGFloat, CGFloat)], fill: Color? = nil,
                          color: Color = Palette.ink, salt: UInt64 = 0) {
                var path = Path()
                path.move(to: p(pts[0].0, pts[0].1))
                for point in pts.dropFirst() { path.addLine(to: p(point.0, point.1)) }
                path.closeSubpath()
                draw(path, fill: fill, color: color)
            }

            drawShape(recipe.baseShape.normalizedObjectName, accent: accent, offsetX: 0,
                      scale: 1, salt: 1)

            if let accentShape = recipe.accentShape?.normalizedObjectName,
               !accentShape.isEmpty,
               accentShape != "none" {
                drawShape(accentShape, accent: Palette.mustard, offsetX: 0.22,
                          scale: 0.46, salt: 100)
            }

            for detail in recipe.details.map(\.normalizedObjectName).prefix(4) {
                drawDetail(detail, accent: accent)
            }

            func drawShape(_ shape: String, accent: Color, offsetX: CGFloat,
                           scale: CGFloat, salt: UInt64) {
                let cx = 0.5 + offsetX
                switch shape {
                case "circle", "ball", "round":
                    oval(cx, 0.5, 0.26 * scale, 0.26 * scale,
                         fill: accent.opacity(0.35), color: accent, salt: salt)
                case "box", "crate", "container", "machine":
                    rect(cx - 0.26 * scale, 0.3, 0.52 * scale, 0.42 * scale,
                         0.08, fill: accent.opacity(0.3), color: accent, salt: salt)
                case "bottle", "spray", "vase":
                    rect(cx - 0.14 * scale, 0.24, 0.28 * scale, 0.54 * scale,
                         0.09, fill: accent.opacity(0.28), color: accent, salt: salt)
                    rect(cx - 0.08 * scale, 0.14, 0.16 * scale, 0.14 * scale,
                         0.03, fill: accent.opacity(0.22), color: accent, salt: salt &+ 1)
                case "tool", "hammer", "wand":
                    line([(cx - 0.24 * scale, 0.72), (cx + 0.2 * scale, 0.28)],
                         color: accent, style: stroke, salt: salt)
                    rect(cx + 0.08 * scale, 0.18, 0.22 * scale, 0.12 * scale,
                         0.03, fill: accent.opacity(0.35), color: accent, salt: salt &+ 1)
                case "vehicle", "cart", "scooter":
                    rect(cx - 0.28 * scale, 0.38, 0.56 * scale, 0.2 * scale,
                         0.06, fill: accent.opacity(0.3), color: accent, salt: salt)
                    oval(cx - 0.18 * scale, 0.66, 0.07 * scale, 0.07 * scale, salt: salt &+ 1)
                    oval(cx + 0.18 * scale, 0.66, 0.07 * scale, 0.07 * scale, salt: salt &+ 2)
                case "plant", "tree":
                    line([(cx, 0.78), (cx, 0.42)], color: Palette.leaf, style: stroke, salt: salt)
                    oval(cx - 0.12 * scale, 0.45, 0.12 * scale, 0.08 * scale,
                         fill: Palette.leaf.opacity(0.3), color: Palette.leaf, salt: salt &+ 1)
                    oval(cx + 0.12 * scale, 0.35, 0.12 * scale, 0.08 * scale,
                         fill: Palette.leaf.opacity(0.3), color: Palette.leaf, salt: salt &+ 2)
                case "flower":
                    line([(cx, 0.78), (cx, 0.52)], color: Palette.leaf, style: thin, salt: salt)
                    for i in 0..<6 {
                        let angle = CGFloat(i) * .pi / 3
                        oval(cx + cos(angle) * 0.1 * scale, 0.42 + sin(angle) * 0.1 * scale,
                             0.08 * scale, 0.05 * scale,
                             fill: accent.opacity(0.35), color: accent, style: thin, salt: salt &+ UInt64(i))
                    }
                    oval(cx, 0.42, 0.055 * scale, 0.055 * scale,
                         fill: Palette.mustard, color: Palette.mustard, style: thin, salt: salt &+ 8)
                case "food", "snack":
                    oval(cx, 0.5, 0.28 * scale, 0.2 * scale,
                         fill: accent.opacity(0.35), color: accent, salt: salt)
                    line([(cx - 0.18 * scale, 0.47), (cx + 0.18 * scale, 0.53)],
                         color: Palette.tomato, style: thin, salt: salt &+ 1)
                case "device", "screen", "phone":
                    rect(cx - 0.22 * scale, 0.18, 0.44 * scale, 0.62 * scale,
                         0.08, fill: Palette.sky.opacity(0.22), color: accent, salt: salt)
                    line([(cx - 0.08 * scale, 0.25), (cx + 0.08 * scale, 0.25)],
                         style: thin, salt: salt &+ 1)
                case "door":
                    rect(cx - 0.2 * scale, 0.16, 0.4 * scale, 0.66 * scale,
                         0.04, fill: accent.opacity(0.25), color: accent, salt: salt)
                    rect(cx - 0.13 * scale, 0.25, 0.26 * scale, 0.44 * scale,
                         0.03, fill: Palette.card.opacity(0.75), color: Palette.inkSoft, salt: salt &+ 1)
                    oval(cx + 0.1 * scale, 0.49, 0.025 * scale, 0.025 * scale,
                         fill: Palette.tomato, color: Palette.tomato, salt: salt &+ 2)
                case "tent":
                    triangle([(cx - 0.32 * scale, 0.76), (cx, 0.18), (cx + 0.32 * scale, 0.76)],
                             fill: accent.opacity(0.28), color: accent, salt: salt)
                    triangle([(cx - 0.11 * scale, 0.76), (cx, 0.4), (cx + 0.11 * scale, 0.76)],
                             fill: Palette.card.opacity(0.65), color: Palette.inkSoft, salt: salt &+ 1)
                    line([(cx - 0.34 * scale, 0.78), (cx + 0.34 * scale, 0.78)], style: thin, salt: salt &+ 2)
                case "crystal":
                    triangle([(cx, 0.12), (cx + 0.24 * scale, 0.42), (cx + 0.12 * scale, 0.84),
                              (cx - 0.12 * scale, 0.84), (cx - 0.24 * scale, 0.42)],
                             fill: accent.opacity(0.32), color: accent, salt: salt)
                    line([(cx, 0.12), (cx, 0.82)], color: accent, style: thin, salt: salt &+ 1)
                    line([(cx - 0.24 * scale, 0.42), (cx + 0.24 * scale, 0.42)],
                         color: accent, style: thin, salt: salt &+ 2)
                case "wheel":
                    oval(cx, 0.5, 0.3 * scale, 0.3 * scale,
                         fill: accent.opacity(0.18), color: accent, salt: salt)
                    oval(cx, 0.5, 0.08 * scale, 0.08 * scale,
                         fill: Palette.card, color: Palette.ink, salt: salt &+ 1)
                    for i in 0..<6 {
                        let angle = CGFloat(i) * .pi / 3
                        line([(cx, 0.5),
                              (cx + cos(angle) * 0.24 * scale, 0.5 + sin(angle) * 0.24 * scale)],
                             color: Palette.inkSoft, style: thin, salt: salt &+ UInt64(i + 2))
                    }
                case "lantern":
                    rect(cx - 0.18 * scale, 0.32, 0.36 * scale, 0.38 * scale,
                         0.08, fill: Palette.mustard.opacity(0.28), color: accent, salt: salt)
                    line([(cx - 0.12 * scale, 0.32), (cx - 0.05 * scale, 0.18),
                          (cx + 0.05 * scale, 0.18), (cx + 0.12 * scale, 0.32)],
                         color: accent, style: thin, salt: salt &+ 1)
                    line([(cx - 0.14 * scale, 0.48), (cx + 0.14 * scale, 0.48)],
                         color: Palette.mustard, style: thin, salt: salt &+ 2)
                case "house", "stand", "booth":
                    rect(cx - 0.24 * scale, 0.42, 0.48 * scale, 0.34 * scale,
                         0.04, fill: accent.opacity(0.25), color: accent, salt: salt)
                    triangle([(cx - 0.3 * scale, 0.44), (cx, 0.2), (cx + 0.3 * scale, 0.44)],
                             fill: Palette.tomato.opacity(0.22), color: Palette.tomato, salt: salt &+ 1)
                case "star", "spark":
                    let path = starPath(center: p(cx, 0.48), outer: 0.27 * scale * s,
                                        inner: 0.12 * scale * s)
                    draw(path, fill: accent.opacity(0.35), color: accent)
                default:
                    rect(cx - 0.24 * scale, 0.28, 0.48 * scale, 0.44 * scale,
                         0.1, fill: accent.opacity(0.28), color: accent, salt: salt)
                }
            }

            func drawDetail(_ detail: String, accent: Color) {
                switch detail {
                case "handle":
                    line([(0.72, 0.42), (0.86, 0.48), (0.72, 0.58)], style: thin, salt: 220)
                case "wheels":
                    oval(0.34, 0.76, 0.06, 0.06, color: Palette.ink, salt: 221)
                    oval(0.66, 0.76, 0.06, 0.06, color: Palette.ink, salt: 222)
                case "stripes":
                    line([(0.28, 0.4), (0.72, 0.4)], color: Palette.tomato, style: thin, salt: 223)
                    line([(0.28, 0.52), (0.72, 0.52)], color: Palette.tomato, style: thin, salt: 224)
                    line([(0.28, 0.64), (0.72, 0.64)], color: Palette.tomato, style: thin, salt: 225)
                case "buttons":
                    oval(0.4, 0.5, 0.035, 0.035, fill: Palette.tomato, color: Palette.tomato, salt: 226)
                    oval(0.52, 0.5, 0.035, 0.035, fill: Palette.mustard, color: Palette.mustard, salt: 227)
                    oval(0.64, 0.5, 0.035, 0.035, fill: Palette.teal, color: Palette.teal, salt: 228)
                case "steam":
                    line([(0.38, 0.24), (0.34, 0.12), (0.42, 0.08)], color: Palette.inkSoft, style: thin, salt: 229)
                    line([(0.55, 0.24), (0.52, 0.12), (0.6, 0.08)], color: Palette.inkSoft, style: thin, salt: 230)
                case "legs":
                    line([(0.38, 0.66), (0.32, 0.84)], style: thin, salt: 231)
                    line([(0.62, 0.66), (0.68, 0.84)], style: thin, salt: 232)
                case "sparkles":
                    let small = StrokeStyle(lineWidth: max(1, s * 0.03), lineCap: .round, lineJoin: .round)
                    line([(0.18, 0.2), (0.18, 0.34)], color: Palette.mustard, style: small, salt: 233)
                    line([(0.11, 0.27), (0.25, 0.27)], color: Palette.mustard, style: small, salt: 234)
                    line([(0.8, 0.15), (0.8, 0.27)], color: Palette.mustard, style: small, salt: 235)
                    line([(0.74, 0.21), (0.86, 0.21)], color: Palette.mustard, style: small, salt: 236)
                case "label":
                    rect(0.34, 0.45, 0.32, 0.14, 0.03, fill: Palette.card, color: Palette.inkSoft, salt: 237)
                case "portal":
                    oval(0.5, 0.5, 0.24, 0.32, color: Palette.grape, style: thin, salt: 238)
                    oval(0.5, 0.5, 0.15, 0.23, color: Palette.sky, style: thin, salt: 239)
                default:
                    break
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func recipeColor(_ name: String) -> Color {
        switch name.normalizedObjectName {
        case "tomato", "red": return Palette.tomato
        case "mustard", "yellow": return Palette.mustard
        case "teal", "green": return Palette.teal
        case "grape", "purple": return Palette.grape
        case "leaf": return Palette.leaf
        case "sky", "blue": return Palette.sky
        case "silver", "gray", "grey": return Palette.silver
        case "ink", "black": return Palette.ink
        default: return Palette.teal
        }
    }
}
