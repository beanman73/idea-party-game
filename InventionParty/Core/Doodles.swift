//
//  Doodles.swift
//  Invention Party
//
//  Hand-drawn replacements for emoji. Each doodle is sketched with the same
//  seeded "wobble" the rest of the UI uses (see SketchyRoundedRectangle), so
//  the strokes look like they were inked by hand with a marker. Drawn in a
//  Canvas and scaled to whatever frame they're given.
//

import SwiftUI

// MARK: - Doodle primitives

/// A near-circle (or oval) with a hand-jittered outline. Deterministic per seed.
func wobblyOval(center: CGPoint, rx: CGFloat, ry: CGFloat,
                seed: UInt64, roughness: CGFloat = 1.2, steps: Int = 24) -> Path {
    var rng = SeededGenerator(seed: seed)
    var path = Path()
    for i in 0...steps {
        let a = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let wob = (i == steps) ? 0 : CGFloat.random(in: -roughness...roughness, using: &rng)
        let p = CGPoint(x: center.x + cos(a) * (rx + wob),
                        y: center.y + sin(a) * (ry + wob))
        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
    }
    path.closeSubpath()
    return path
}

/// A straight stroke that wavers slightly off its axis, like a hand-drawn line.
func wobblyLine(from a: CGPoint, to b: CGPoint,
                seed: UInt64, roughness: CGFloat = 1.0, segments: Int = 4) -> Path {
    var rng = SeededGenerator(seed: seed)
    var path = Path()
    path.move(to: a)
    let dx = b.x - a.x, dy = b.y - a.y
    let len = max(hypot(dx, dy), 0.0001)
    let nx = -dy / len, ny = dx / len
    let count = max(2, segments)
    for i in 1...count {
        let t = CGFloat(i) / CGFloat(count)
        let off = (i == count) ? 0 : CGFloat.random(in: -roughness...roughness, using: &rng)
        path.addLine(to: CGPoint(x: a.x + dx * t + nx * off,
                                 y: a.y + dy * t + ny * off))
    }
    return path
}

// MARK: - Lightbulb ("idea")

struct LightbulbDoodle: View {
    var size: CGFloat = 56

    var body: some View {
        Canvas { ctx, area in
            let s = min(area.width, area.height)
            let cx = area.width / 2
            let lw = s * 0.05
            let stroke = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
            let thin = StrokeStyle(lineWidth: lw * 0.7, lineCap: .round, lineJoin: .round)

            // Glass bulb.
            let bulbCenter = CGPoint(x: cx, y: s * 0.44)
            let bulbR = s * 0.25
            let bulb = wobblyOval(center: bulbCenter, rx: bulbR * 0.96, ry: bulbR * 1.04,
                                  seed: 11, roughness: s * 0.024, steps: 28)
            ctx.fill(bulb, with: .color(Palette.mustard.opacity(0.5)))
            for i in 0..<7 {
                let y = bulbCenter.y - bulbR * 0.48 + CGFloat(i) * bulbR * 0.16
                let inset = abs(CGFloat(i) - 3) * bulbR * 0.055
                ctx.stroke(wobblyLine(from: CGPoint(x: cx - bulbR * 0.46 + inset, y: y),
                                      to: CGPoint(x: cx + bulbR * 0.38 - inset, y: y + bulbR * 0.04),
                                      seed: UInt64(210 + i), roughness: s * 0.01, segments: 3),
                           with: .color(Palette.mustard.opacity(0.34)),
                           style: StrokeStyle(lineWidth: lw * 0.42, lineCap: .round))
            }
            ctx.stroke(wobblyOval(center: CGPoint(x: bulbCenter.x + s * 0.008, y: bulbCenter.y - s * 0.006),
                                  rx: bulbR * 0.98, ry: bulbR, seed: 111, roughness: s * 0.018, steps: 24),
                       with: .color(Palette.ink.opacity(0.35)),
                       style: StrokeStyle(lineWidth: lw * 0.5, lineCap: .round, lineJoin: .round))
            ctx.stroke(bulb, with: .color(Palette.ink), style: stroke)

            // Filament squiggle inside the bulb.
            var fil = Path()
            fil.move(to: CGPoint(x: cx - bulbR * 0.45, y: bulbCenter.y + bulbR * 0.1))
            fil.addLine(to: CGPoint(x: cx - bulbR * 0.15, y: bulbCenter.y + bulbR * 0.4))
            fil.addLine(to: CGPoint(x: cx + bulbR * 0.12, y: bulbCenter.y - bulbR * 0.05))
            fil.addLine(to: CGPoint(x: cx + bulbR * 0.42, y: bulbCenter.y + bulbR * 0.3))
            ctx.stroke(fil, with: .color(Palette.ink), style: thin)

            // Screw base.
            let baseTop = bulbCenter.y + bulbR * 0.92
            let baseW = bulbR * 1.0
            let baseRect = CGRect(x: cx - baseW / 2, y: baseTop, width: baseW, height: s * 0.18)
            let base = SketchyRoundedRectangle(cornerRadius: s * 0.03, roughness: 0.9, seed: 5)
                .path(in: baseRect)
            ctx.fill(base, with: .color(Palette.silver))
            for i in 0..<4 {
                let y = baseRect.minY + baseRect.height * (0.24 + CGFloat(i) * 0.16)
                ctx.stroke(wobblyLine(from: CGPoint(x: baseRect.minX + s * 0.03, y: y),
                                      to: CGPoint(x: baseRect.maxX - s * 0.03, y: y + s * 0.008),
                                      seed: UInt64(230 + i), roughness: s * 0.006, segments: 2),
                           with: .color(Palette.ink.opacity(0.18)),
                           style: StrokeStyle(lineWidth: lw * 0.32, lineCap: .round))
            }
            ctx.stroke(base, with: .color(Palette.ink), style: stroke)

            // Thread lines on the base.
            let y1 = baseTop + s * 0.06
            let y2 = baseTop + s * 0.12
            ctx.stroke(wobblyLine(from: CGPoint(x: cx - baseW * 0.4, y: y1),
                                  to: CGPoint(x: cx + baseW * 0.4, y: y1), seed: 7),
                       with: .color(Palette.ink), style: thin)
            ctx.stroke(wobblyLine(from: CGPoint(x: cx - baseW * 0.4, y: y2),
                                  to: CGPoint(x: cx + baseW * 0.4, y: y2), seed: 8),
                       with: .color(Palette.ink), style: thin)

            // Idea rays shooting off the top.
            let rays: [(CGFloat, CGFloat)] = [(-0.85, -0.55), (0, -1), (0.85, -0.55)]
            for (idx, dir) in rays.enumerated() {
                let len = hypot(dir.0, dir.1)
                let ux = dir.0 / len, uy = dir.1 / len
                let start = CGPoint(x: bulbCenter.x + ux * bulbR * 1.18,
                                    y: bulbCenter.y + uy * bulbR * 1.18)
                let end = CGPoint(x: bulbCenter.x + ux * bulbR * 1.5,
                                  y: bulbCenter.y + uy * bulbR * 1.5)
                ctx.stroke(wobblyLine(from: start, to: end, seed: UInt64(20 + idx),
                                      roughness: s * 0.012, segments: 2),
                           with: .color(Palette.tomato), style: stroke)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Paint palette ("art")

struct PaletteDoodle: View {
    var size: CGFloat = 56

    var body: some View {
        Canvas { ctx, area in
            let s = min(area.width, area.height)
            let cx = area.width / 2
            let cy = area.height * 0.52
            let lw = s * 0.05
            let stroke = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
            let thin = StrokeStyle(lineWidth: lw * 0.55, lineCap: .round, lineJoin: .round)

            let rx = s * 0.44, ry = s * 0.36

            // Palette blob.
            let blob = wobblyOval(center: CGPoint(x: cx - s * 0.01, y: cy + s * 0.006),
                                  rx: rx, ry: ry * 0.96, seed: 31, roughness: s * 0.022, steps: 30)
            ctx.fill(blob, with: .color(Palette.card))
            for i in 0..<9 {
                let y = cy - ry * 0.54 + CGFloat(i) * ry * 0.13
                let inset = abs(CGFloat(i) - 4) * rx * 0.035
                ctx.stroke(wobblyLine(from: CGPoint(x: cx - rx * 0.52 + inset, y: y),
                                      to: CGPoint(x: cx + rx * 0.42 - inset, y: y + s * 0.012),
                                      seed: UInt64(260 + i), roughness: s * 0.008, segments: 4),
                           with: .color(Palette.ink.opacity(0.08)),
                           style: StrokeStyle(lineWidth: lw * 0.36, lineCap: .round))
            }
            ctx.stroke(wobblyOval(center: CGPoint(x: cx + s * 0.008, y: cy - s * 0.004),
                                  rx: rx * 0.98, ry: ry * 0.95, seed: 131, roughness: s * 0.016, steps: 25),
                       with: .color(Palette.ink.opacity(0.32)),
                       style: StrokeStyle(lineWidth: lw * 0.52, lineCap: .round, lineJoin: .round))
            ctx.stroke(blob, with: .color(Palette.ink), style: stroke)

            // Thumb hole (cut-out: filled with the page color).
            let hole = wobblyOval(center: CGPoint(x: cx + rx * 0.34, y: cy + ry * 0.42),
                                  rx: s * 0.075, ry: s * 0.075, seed: 32, roughness: 0.7)
            ctx.fill(hole, with: .color(Palette.paper))
            ctx.stroke(hole, with: .color(Palette.ink), style: thin)

            // Dabs of paint.
            let dabs: [(CGFloat, CGFloat, Color)] = [
                (-0.52, -0.42, Palette.tomato),
                (-0.12, -0.6,  Palette.mustard),
                ( 0.32, -0.5,  Palette.teal),
                ( 0.6,  -0.12, Palette.grape),
                (-0.62,  0.08, Palette.leaf),
            ]
            for (idx, dab) in dabs.enumerated() {
                let center = CGPoint(x: cx + dab.0 * rx, y: cy + dab.1 * ry)
                let dot = wobblyOval(center: center, rx: s * 0.075, ry: s * 0.07,
                                     seed: UInt64(40 + idx), roughness: 0.9)
                ctx.fill(dot, with: .color(dab.2))
                ctx.stroke(wobblyLine(from: CGPoint(x: center.x - s * 0.04, y: center.y - s * 0.006),
                                      to: CGPoint(x: center.x + s * 0.035, y: center.y + s * 0.01),
                                      seed: UInt64(280 + idx), roughness: s * 0.004, segments: 2),
                           with: .color(Palette.cream.opacity(0.28)),
                           style: StrokeStyle(lineWidth: lw * 0.32, lineCap: .round))
                ctx.stroke(dot, with: .color(Palette.ink), style: thin)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - More primitives

/// A partial wobbly circle, from `start` to `end` radians (0 = +x, clockwise
/// because y grows downward). Endpoints are pinned (no wobble) so arcs join
/// cleanly to adjoining strokes.
func wobblyArc(center: CGPoint, radius: CGFloat, start: CGFloat, end: CGFloat,
               seed: UInt64, roughness: CGFloat = 0.8, steps: Int = 16) -> Path {
    var rng = SeededGenerator(seed: seed)
    var path = Path()
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let a = start + (end - start) * t
        let wob = (i == 0 || i == steps) ? 0 : CGFloat.random(in: -roughness...roughness, using: &rng)
        let p = CGPoint(x: center.x + cos(a) * (radius + wob),
                        y: center.y + sin(a) * (radius + wob))
        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
    }
    return path
}

/// A regular star polygon (used on medals). Top point is up.
func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat, points: Int = 5) -> Path {
    var path = Path()
    let total = points * 2
    for i in 0..<total {
        let r = (i % 2 == 0) ? outer : inner
        let a = -CGFloat.pi / 2 + CGFloat(i) / CGFloat(total) * 2 * .pi
        let p = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
    }
    path.closeSubpath()
    return path
}

// MARK: - Generic line-art doodle

/// A single hand-drawn icon. Monochrome line art tinted by `color`, so the same
/// glyph works on a paper card (ink) or on a colored button (cream). Coordinates
/// inside each case are normalized 0...1 over a square that's centered in the
/// view's frame.
struct Doodle: View {
    enum Kind {
        case sparkle, camera, trash, trophy, pencil, warning, stopwatch, scales
        case clipboard, party, controller, house, crown, lock, box, dice
        case puzzle, target, tent, face, gear
    }

    var kind: Kind
    var size: CGFloat = 28
    var color: Color = Palette.ink

    var body: some View {
        Canvas { ctx, area in
            let s = min(area.width, area.height)
            let ox = (area.width - s) / 2
            let oy = (area.height - s) / 2
            let lw = max(1, s * 0.08)
            let stroke = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
            let thin = StrokeStyle(lineWidth: lw * 0.7, lineCap: .round, lineJoin: .round)

            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
            func lineSeed(_ a: CGPoint, _ b: CGPoint, _ salt: UInt64) -> UInt64 {
                let ax = UInt64(max(0, Int((a.x - ox) / max(s, 1) * 997)))
                let ay = UInt64(max(0, Int((a.y - oy) / max(s, 1) * 991)))
                let bx = UInt64(max(0, Int((b.x - ox) / max(s, 1) * 983)))
                let by = UInt64(max(0, Int((b.y - oy) / max(s, 1) * 977)))
                return salt &+ ax &* 31 &+ ay &* 37 &+ bx &* 41 &+ by &* 43
            }
            func line(_ pts: [(CGFloat, CGFloat)], closed: Bool = false, style: StrokeStyle? = nil) {
                guard !pts.isEmpty else { return }
                let points = pts.map { P($0.0, $0.1) }
                var drawn = Path()
                drawn.move(to: points[0])
                var current = points[0]
                for (idx, next) in points.dropFirst().enumerated() {
                    let segment = wobblyLine(from: current, to: next,
                                             seed: lineSeed(current, next, UInt64(idx + 101)),
                                             roughness: s * 0.012,
                                             segments: 3)
                    drawn.addPath(segment)
                    current = next
                }
                if closed {
                    let segment = wobblyLine(from: current, to: points[0],
                                             seed: lineSeed(current, points[0], 199),
                                             roughness: s * 0.012,
                                             segments: 3)
                    drawn.addPath(segment)
                    drawn.closeSubpath()
                }
                ctx.stroke(drawn, with: .color(color.opacity(0.26)),
                           style: StrokeStyle(lineWidth: (style ?? stroke).lineWidth * 0.72,
                                              lineCap: .round, lineJoin: .round))
                ctx.stroke(drawn, with: .color(color), style: style ?? stroke)
            }
            func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, seed: UInt64 = 1) {
                ctx.fill(wobblyOval(center: P(x + 0.006, y - 0.004), rx: r * s, ry: r * s,
                                     seed: seed &+ 400, roughness: s * 0.004, steps: 10),
                         with: .color(color.opacity(0.24)))
                ctx.fill(wobblyOval(center: P(x, y), rx: r * s, ry: r * s, seed: seed, roughness: s * 0.006, steps: 12),
                         with: .color(color))
            }
            func oval(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, seed: UInt64 = 1,
                      style: StrokeStyle? = nil) {
                ctx.stroke(wobblyOval(center: P(x + 0.006, y - 0.004), rx: r * s, ry: r * s,
                                      seed: seed &+ 400, roughness: s * 0.009, steps: 20),
                           with: .color(color.opacity(0.28)),
                           style: StrokeStyle(lineWidth: (style ?? stroke).lineWidth * 0.65,
                                              lineCap: .round, lineJoin: .round))
                ctx.stroke(wobblyOval(center: P(x, y), rx: r * s, ry: r * s, seed: seed, roughness: s * 0.009),
                           with: .color(color), style: style ?? stroke)
            }
            func arc(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ a0: CGFloat, _ a1: CGFloat,
                     seed: UInt64 = 1, style: StrokeStyle? = nil) {
                ctx.stroke(wobblyArc(center: P(x, y), radius: r * s, start: a0, end: a1, seed: seed),
                           with: .color(color), style: style ?? stroke)
            }
            func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                       corner: CGFloat, seed: UInt64 = 1, style: StrokeStyle? = nil) {
                let r = CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s)
                let ghost = CGRect(x: r.minX + s * 0.006, y: r.minY - s * 0.004, width: r.width, height: r.height)
                ctx.stroke(SketchyRoundedRectangle(cornerRadius: corner * s, roughness: s * 0.012, seed: seed &+ 400).path(in: ghost),
                           with: .color(color.opacity(0.25)),
                           style: StrokeStyle(lineWidth: (style ?? stroke).lineWidth * 0.65,
                                              lineCap: .round, lineJoin: .round))
                ctx.stroke(SketchyRoundedRectangle(cornerRadius: corner * s, roughness: 0.9, seed: seed).path(in: r),
                           with: .color(color), style: style ?? stroke)
            }
            let pi = CGFloat.pi

            switch kind {
            case .sparkle:
                var star = Path()
                let pts: [(CGFloat, CGFloat)] = [
                    (0.5, 0.08), (0.59, 0.41), (0.92, 0.5), (0.59, 0.59),
                    (0.5, 0.92), (0.41, 0.59), (0.08, 0.5), (0.41, 0.41),
                ]
                star.move(to: P(pts[0].0, pts[0].1))
                for q in pts.dropFirst() { star.addLine(to: P(q.0, q.1)) }
                star.closeSubpath()
                ctx.fill(star, with: .color(color))
                dot(0.82, 0.2, 0.035, seed: 2)

            case .camera:
                rrect(0.1, 0.32, 0.8, 0.5, corner: 0.08, seed: 71)
                line([(0.36, 0.32), (0.4, 0.24), (0.54, 0.24), (0.58, 0.32)])
                oval(0.5, 0.58, 0.15, seed: 72)
                oval(0.5, 0.58, 0.07, seed: 73, style: thin)
                dot(0.76, 0.42, 0.03, seed: 74)

            case .trash:
                line([(0.18, 0.3), (0.82, 0.3)])
                line([(0.42, 0.3), (0.44, 0.22), (0.56, 0.22), (0.58, 0.3)])
                line([(0.26, 0.3), (0.31, 0.84), (0.69, 0.84), (0.74, 0.3)])
                line([(0.4, 0.4), (0.41, 0.76)], style: thin)
                line([(0.5, 0.4), (0.5, 0.76)], style: thin)
                line([(0.6, 0.4), (0.59, 0.76)], style: thin)

            case .trophy:
                line([(0.3, 0.2), (0.7, 0.2)])
                line([(0.32, 0.2), (0.4, 0.5), (0.6, 0.5), (0.68, 0.2)])
                line([(0.31, 0.22), (0.2, 0.26), (0.24, 0.4), (0.35, 0.44)], style: thin)
                line([(0.69, 0.22), (0.8, 0.26), (0.76, 0.4), (0.65, 0.44)], style: thin)
                line([(0.5, 0.5), (0.5, 0.66)])
                line([(0.38, 0.8), (0.4, 0.66), (0.6, 0.66), (0.62, 0.8)], closed: true)
                line([(0.34, 0.84), (0.66, 0.84)])

            case .pencil:
                line([(0.223, 0.663), (0.18, 0.82), (0.337, 0.777)])
                line([(0.337, 0.777), (0.797, 0.317)])
                line([(0.223, 0.663), (0.683, 0.203)])
                line([(0.683, 0.203), (0.797, 0.317)])
                line([(0.223, 0.663), (0.337, 0.777)], style: thin)
                line([(0.598, 0.288), (0.712, 0.402)], style: thin)

            case .warning:
                line([(0.5, 0.16), (0.86, 0.8), (0.14, 0.8)], closed: true)
                line([(0.5, 0.4), (0.5, 0.62)])
                dot(0.5, 0.72, 0.03, seed: 2)

            case .stopwatch:
                line([(0.44, 0.1), (0.56, 0.1)])
                line([(0.5, 0.1), (0.5, 0.2)])
                oval(0.5, 0.58, 0.34, seed: 81)
                line([(0.5, 0.58), (0.5, 0.36)], style: thin)
                line([(0.5, 0.58), (0.64, 0.64)], style: thin)
                dot(0.5, 0.58, 0.03, seed: 2)

            case .scales:
                line([(0.5, 0.2), (0.5, 0.82)])
                line([(0.4, 0.84), (0.6, 0.84)])
                line([(0.22, 0.28), (0.78, 0.28)])
                dot(0.5, 0.2, 0.035, seed: 2)
                line([(0.22, 0.28), (0.15, 0.48)], style: thin)
                line([(0.22, 0.28), (0.29, 0.48)], style: thin)
                arc(0.22, 0.48, 0.1, 0, pi, seed: 82)
                line([(0.78, 0.28), (0.71, 0.48)], style: thin)
                line([(0.78, 0.28), (0.85, 0.48)], style: thin)
                arc(0.78, 0.48, 0.1, 0, pi, seed: 83)

            case .clipboard:
                rrect(0.2, 0.18, 0.6, 0.7, corner: 0.06, seed: 84)
                line([(0.42, 0.18), (0.42, 0.14), (0.58, 0.14), (0.58, 0.18)])
                line([(0.44, 0.12), (0.56, 0.12)])
                line([(0.32, 0.42), (0.68, 0.42)], style: thin)
                line([(0.32, 0.56), (0.68, 0.56)], style: thin)
                line([(0.32, 0.7), (0.68, 0.7)], style: thin)

            case .party:
                line([(0.28, 0.78), (0.46, 0.46)])
                line([(0.28, 0.78), (0.74, 0.66)])
                line([(0.46, 0.46), (0.74, 0.66)])
                line([(0.6, 0.42), (0.7, 0.32)], style: thin)
                line([(0.72, 0.5), (0.84, 0.46)], style: thin)
                line([(0.55, 0.34), (0.6, 0.22)], style: thin)
                dot(0.8, 0.34, 0.03, seed: 2)
                dot(0.68, 0.2, 0.025, seed: 3)
                dot(0.86, 0.58, 0.025, seed: 4)

            case .controller:
                rrect(0.12, 0.36, 0.76, 0.32, corner: 0.14, seed: 85)
                line([(0.3, 0.44), (0.3, 0.6)])
                line([(0.22, 0.52), (0.38, 0.52)])
                dot(0.66, 0.48, 0.04, seed: 2)
                dot(0.74, 0.58, 0.04, seed: 3)

            case .house:
                line([(0.26, 0.5), (0.26, 0.84), (0.74, 0.84), (0.74, 0.5)])
                line([(0.18, 0.52), (0.5, 0.24), (0.82, 0.52)])
                line([(0.44, 0.84), (0.44, 0.64), (0.56, 0.64), (0.56, 0.84)])

            case .crown:
                line([(0.18, 0.7), (0.24, 0.34), (0.38, 0.56), (0.5, 0.3),
                      (0.62, 0.56), (0.76, 0.34), (0.82, 0.7)], closed: true)
                line([(0.2, 0.62), (0.8, 0.62)], style: thin)
                dot(0.24, 0.34, 0.03, seed: 2)
                dot(0.5, 0.3, 0.03, seed: 3)
                dot(0.76, 0.34, 0.03, seed: 4)

            case .lock:
                rrect(0.24, 0.44, 0.52, 0.42, corner: 0.06, seed: 86)
                arc(0.5, 0.44, 0.16, pi, 2 * pi, seed: 87)
                line([(0.34, 0.44), (0.34, 0.38)], style: thin)
                line([(0.66, 0.44), (0.66, 0.38)], style: thin)
                dot(0.5, 0.6, 0.04, seed: 2)
                line([(0.5, 0.62), (0.5, 0.72)])

            case .box:
                // Front, top and right faces of a little 3D cube + packing tape.
                line([(0.2, 0.44), (0.62, 0.44), (0.62, 0.84), (0.2, 0.84)], closed: true)
                line([(0.2, 0.44), (0.36, 0.3), (0.78, 0.3), (0.62, 0.44)], closed: true)
                line([(0.62, 0.44), (0.78, 0.3), (0.78, 0.7), (0.62, 0.84)], closed: true)
                line([(0.41, 0.44), (0.41, 0.84)], style: thin)
                line([(0.41, 0.44), (0.57, 0.3)], style: thin)

            case .dice:
                rrect(0.22, 0.22, 0.56, 0.56, corner: 0.1, seed: 88)
                dot(0.36, 0.36, 0.05, seed: 2)
                dot(0.64, 0.36, 0.05, seed: 3)
                dot(0.5, 0.5, 0.05, seed: 4)
                dot(0.36, 0.64, 0.05, seed: 5)
                dot(0.64, 0.64, 0.05, seed: 6)

            case .puzzle:
                line([(0.28, 0.34), (0.72, 0.34), (0.72, 0.78), (0.28, 0.78)], closed: true)
                oval(0.5, 0.3, 0.08, seed: 89)
                oval(0.76, 0.56, 0.08, seed: 90)

            case .target:
                oval(0.5, 0.5, 0.36, seed: 91)
                oval(0.5, 0.5, 0.24, seed: 92)
                oval(0.5, 0.5, 0.12, seed: 93)
                dot(0.5, 0.5, 0.045, seed: 2)

            case .gear:
                for i in 0..<8 {
                    let a = CGFloat(i) / 8 * 2 * pi
                    let x0 = 0.5 + cos(a) * 0.31
                    let y0 = 0.5 + sin(a) * 0.31
                    let x1 = 0.5 + cos(a) * 0.43
                    let y1 = 0.5 + sin(a) * 0.43
                    line([(x0, y0), (x1, y1)], style: thin)
                }
                oval(0.5, 0.5, 0.31, seed: 96)
                oval(0.5, 0.5, 0.14, seed: 97, style: thin)

            case .tent:
                line([(0.16, 0.5), (0.5, 0.18), (0.84, 0.5)])
                line([(0.5, 0.18), (0.5, 0.1)])
                line([(0.5, 0.1), (0.6, 0.13), (0.5, 0.16)], closed: true)
                line([(0.16, 0.5), (0.2, 0.82), (0.8, 0.82), (0.84, 0.5)])
                line([(0.42, 0.82), (0.5, 0.6), (0.58, 0.82)])
                line([(0.5, 0.6), (0.5, 0.5)], style: thin)
                line([(0.5, 0.18), (0.34, 0.82)], style: thin)
                line([(0.5, 0.18), (0.66, 0.82)], style: thin)

            case .face:
                oval(0.5, 0.5, 0.38, seed: 94)
                dot(0.38, 0.44, 0.04, seed: 2)
                dot(0.62, 0.44, 0.04, seed: 3)
                arc(0.5, 0.5, 0.2, 0.15 * pi, 0.85 * pi, seed: 95)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Object doodles

/// Hand-drawn stand-ins for the starter deck emoji. The deck can keep its
/// emoji labels for data compatibility, while cards render these sketched marks.
struct ObjectDoodle: View {
    enum Kind: String {
        case banana, clock, umbrella, lightbulb, key, book, phone, camera, scissors, magnet
        case ball, balloon, guitar, dice, telescope, microphone, crown, gem, rainbow, fire
        case snowflake, star, moon, sun, cloud, lightning, rocket, robot, alien, ghost
        case clown, glasses, hat, backpack, compass, trophy, medal, flag, bomb, hammer
        // Codex's "everyday specifics" expansion (s41–s120).
        case lunchbox, bikeBell, gardenHose, elevatorButton, mailbox, shoppingCart, flashlight, suitcase, thermos, paintRoller
        case doorbell, dogLeash, birdhouse, trafficCone, windChime, pillow, skateboard, fishingRod, vendingMachine, pizzaBox
        case beachChair, toolbox, sprayBottle, remoteControl, sunglasses, popcornBucket, wateringCan, cookieJar, laundryBasket, walkieTalkie
        case sleepingBag, soapDispenser, parkingMeter, fireHydrant, bubbleWand, snowGlobe, pencilSharpener, cerealBox, campingLantern, doorMat
        case kiteString, scooter, coffeeMug, trainTicket, picnicBlanket, deskFan, magnifyingGlass, showerCurtain, toyCar, rainBarrel
        case stickyNote, safetyPin, marshmallow, hulaHoop, fryingPan, museumMap, hotelKeycard, snowShovel, iceTray, recordPlayer
        case gardenGnome, tacoShell, poolNoodle, handMirror, electricKettle, receipt, firstAidKit, chalkboard, mopBucket, boardGame
        case picnicCooler, carabiner, musicBox, breadToaster, dogBowl, windowBlinds, gardenTrowel, nameTag, bentoTray, rubberStamp
        // Space deck.
        case airlockDoor, moonRock, roverWheel, alienFlower, starMap, cometScoop, gravityBoots, plasmaLantern, meteorJar, rocketSeat
        case spaceHelmet, orbitRing, satelliteDish, planetFlag, vacuumTent, asteroidNet, nebulaBottle, solarPanel, zeroGSnack, portalButton
        // Kitchen deck.
        case spatula, mixingBowl, rollingPin, measuringCup, whisk, saucepan, cuttingBoard, apronPocket, saltShaker, ovenMitt
        case lemonSqueezer, cupcakeTray, soupLadle, dishSponge, recipeCard, pepperGrinder, cookieCutter, pastaStrainer, waffleIron, jamJar
        // Sports deck.
        case whistle, goalNet, baseballGlove, tennisRacket, scoreboard, waterBottle, kneePad, soccerCleat, basketballHoop, hockeyPuck
        case bikeHelmet, refereeFlag, battingTee, foamFinger, stopwatchStrap, skateRamp, dumbbell, teamJersey, swimGoggles, medalRibbon
        // School deck.
        case glueStick, ruler, lockerDoor, whiteboardEraser, cafeteriaTray, hallPass, pencilCase, binderClip, notebookSpiral, indexCard
        case crayonBox, lunchTray, libraryStamp, deskBell, protractor, scienceGoggles, chalkHolder, gymWhistle, bookCart, stickyBookmark
        // Household Items deck additions.
        case extensionCord, tapeRoll, battery, trashCan, coatHanger, pictureFrame, doorknob, storageBin, vacuumHose, curtainRod
        case lampShade, wallHook, broom, rug
        // Space deck additions.
        case marsShovel, cosmicCompass, galaxyGoggles, rocketToolbox, starlightUmbrella, alienLunchbox, moonBoots, orbitScooter, spaceRadio, craterBucket
        // Kitchen deck additions.
        case pizzaCutter, teaKettle, butterDish, iceCreamScoop, cupcakeLiner, dishTowel, canOpener, kitchenTimer, spiceRack, sinkPlug
        // Sports deck additions.
        case jumpRope, conesSet, golfTee, boxingGlove, yogaMat, skiPole, racingBib, bowlingPin, pingPongPaddle, climbingGrip
        // School deck additions.
        case markerCap, paperTray, mathCube, backpackCharm, classroomTimer, stapleRemover, readingLamp, paintSmock, reportFolder, busPass
        // Smart-home additions (Household Items).
        case smartSpeaker, robotVacuum, securityCamera, thermostat, wifiRouter, leakSensor, doorSensor, motionSensor, smartPlug
        // Tech & Gadgets deck.
        case smartButton, qrCodeSticker, gpsTag, smartCamera, voiceRemote, wifiHotspot, robotArm, handScanner, alertBell, weatherApp
        case votingApp, batteryPack, trackerTag, touchScreen, miniDrone, smartLock, dataRecorder, alertBadge, aiCoach, timerButton
        case mapMarker, bluetoothTag, chargingDock, cameraLens, deliveryTracker, barcodeScanner, callButton, wifiBooster, smartWatch
        // Kitchen additions.
        case groceryScanner, fridgeCamera, recipeScanner, foodThermometer, kitchenScale, smartPan, smartFaucet, foodSealer, compostBin
        // Sports additions.
        case replayCamera, stopwatch, heartMonitor, fitnessTracker, speedSensor, raceTimer, trainingApp
        // School additions.
        case tabletCart, attendanceScanner, flashcardApp, projectorRemote, dueDateStamp, chalkTray, smartPen, classPollApp, smartWorksheet, noiseMeter, homeworkApp

        init?(object: GameObject) {
            let key = object.name.lowercased()
            switch key {
            case "banana": self = .banana
            case "clock": self = .clock
            case "umbrella": self = .umbrella
            case "light bulb": self = .lightbulb
            case "key": self = .key
            case "book": self = .book
            case "phone": self = .phone
            case "camera": self = .camera
            case "scissors": self = .scissors
            case "magnet": self = .magnet
            case "ball": self = .ball
            case "balloon": self = .balloon
            case "guitar": self = .guitar
            case "dice": self = .dice
            case "telescope": self = .telescope
            case "microphone": self = .microphone
            case "crown": self = .crown
            case "gem": self = .gem
            case "rainbow": self = .rainbow
            case "fire": self = .fire
            case "snowflake": self = .snowflake
            case "star": self = .star
            case "moon": self = .moon
            case "sun": self = .sun
            case "cloud": self = .cloud
            case "lightning": self = .lightning
            case "rocket": self = .rocket
            case "robot": self = .robot
            case "alien": self = .alien
            case "ghost": self = .ghost
            case "clown": self = .clown
            case "glasses": self = .glasses
            case "hat": self = .hat
            case "backpack": self = .backpack
            case "compass": self = .compass
            case "trophy": self = .trophy
            case "medal": self = .medal
            case "flag": self = .flag
            case "bomb": self = .bomb
            case "hammer": self = .hammer
            case "lunchbox": self = .lunchbox
            case "bike bell": self = .bikeBell
            case "garden hose": self = .gardenHose
            case "elevator button": self = .elevatorButton
            case "mailbox": self = .mailbox
            case "shopping cart": self = .shoppingCart
            case "flashlight": self = .flashlight
            case "suitcase": self = .suitcase
            case "thermos": self = .thermos
            case "paint roller": self = .paintRoller
            case "doorbell": self = .doorbell
            case "dog leash": self = .dogLeash
            case "birdhouse": self = .birdhouse
            case "traffic cone": self = .trafficCone
            case "wind chime": self = .windChime
            case "pillow": self = .pillow
            case "skateboard": self = .skateboard
            case "fishing rod": self = .fishingRod
            case "vending machine": self = .vendingMachine
            case "pizza box": self = .pizzaBox
            case "beach chair": self = .beachChair
            case "toolbox": self = .toolbox
            case "spray bottle": self = .sprayBottle
            case "remote control": self = .remoteControl
            case "sunglasses": self = .sunglasses
            case "popcorn bucket": self = .popcornBucket
            case "watering can": self = .wateringCan
            case "cookie jar": self = .cookieJar
            case "laundry basket": self = .laundryBasket
            case "walkie talkie": self = .walkieTalkie
            case "sleeping bag": self = .sleepingBag
            case "soap dispenser": self = .soapDispenser
            case "parking meter": self = .parkingMeter
            case "fire hydrant": self = .fireHydrant
            case "bubble wand": self = .bubbleWand
            case "snow globe": self = .snowGlobe
            case "pencil sharpener": self = .pencilSharpener
            case "cereal box": self = .cerealBox
            case "camping lantern": self = .campingLantern
            case "door mat": self = .doorMat
            case "kite string": self = .kiteString
            case "scooter": self = .scooter
            case "coffee mug": self = .coffeeMug
            case "train ticket": self = .trainTicket
            case "picnic blanket": self = .picnicBlanket
            case "desk fan": self = .deskFan
            case "magnifying glass": self = .magnifyingGlass
            case "shower curtain": self = .showerCurtain
            case "toy car": self = .toyCar
            case "rain barrel": self = .rainBarrel
            case "sticky note": self = .stickyNote
            case "safety pin": self = .safetyPin
            case "marshmallow": self = .marshmallow
            case "hula hoop": self = .hulaHoop
            case "frying pan": self = .fryingPan
            case "museum map": self = .museumMap
            case "hotel keycard": self = .hotelKeycard
            case "snow shovel": self = .snowShovel
            case "ice tray": self = .iceTray
            case "record player": self = .recordPlayer
            case "garden gnome": self = .gardenGnome
            case "taco shell": self = .tacoShell
            case "pool noodle": self = .poolNoodle
            case "hand mirror": self = .handMirror
            case "electric kettle": self = .electricKettle
            case "receipt": self = .receipt
            case "first aid kit": self = .firstAidKit
            case "chalkboard": self = .chalkboard
            case "mop bucket": self = .mopBucket
            case "board game": self = .boardGame
            case "picnic cooler": self = .picnicCooler
            case "carabiner": self = .carabiner
            case "music box": self = .musicBox
            case "bread toaster": self = .breadToaster
            case "dog bowl": self = .dogBowl
            case "window blinds": self = .windowBlinds
            case "garden trowel": self = .gardenTrowel
            case "name tag": self = .nameTag
            case "bento tray": self = .bentoTray
            case "rubber stamp": self = .rubberStamp
            // Space deck.
            case "airlock door": self = .airlockDoor
            case "moon rock": self = .moonRock
            case "rover wheel": self = .roverWheel
            case "alien flower": self = .alienFlower
            case "star map": self = .starMap
            case "comet scoop": self = .cometScoop
            case "gravity boots": self = .gravityBoots
            case "plasma lantern": self = .plasmaLantern
            case "meteor jar": self = .meteorJar
            case "rocket seat": self = .rocketSeat
            case "space helmet": self = .spaceHelmet
            case "orbit ring": self = .orbitRing
            case "satellite dish": self = .satelliteDish
            case "planet flag": self = .planetFlag
            case "vacuum tent": self = .vacuumTent
            case "asteroid net": self = .asteroidNet
            case "nebula bottle": self = .nebulaBottle
            case "solar panel": self = .solarPanel
            case "zero-g snack": self = .zeroGSnack
            case "portal button": self = .portalButton
            // Kitchen deck.
            case "spatula": self = .spatula
            case "mixing bowl": self = .mixingBowl
            case "rolling pin": self = .rollingPin
            case "measuring cup": self = .measuringCup
            case "whisk": self = .whisk
            case "saucepan": self = .saucepan
            case "cutting board": self = .cuttingBoard
            case "apron pocket": self = .apronPocket
            case "salt shaker": self = .saltShaker
            case "oven mitt": self = .ovenMitt
            case "lemon squeezer": self = .lemonSqueezer
            case "cupcake tray": self = .cupcakeTray
            case "soup ladle": self = .soupLadle
            case "dish sponge": self = .dishSponge
            case "recipe card": self = .recipeCard
            case "pepper grinder": self = .pepperGrinder
            case "cookie cutter": self = .cookieCutter
            case "pasta strainer": self = .pastaStrainer
            case "waffle iron": self = .waffleIron
            case "jam jar": self = .jamJar
            // Sports deck.
            case "whistle": self = .whistle
            case "goal net": self = .goalNet
            case "baseball glove": self = .baseballGlove
            case "tennis racket": self = .tennisRacket
            case "scoreboard": self = .scoreboard
            case "water bottle": self = .waterBottle
            case "knee pad": self = .kneePad
            case "soccer cleat": self = .soccerCleat
            case "basketball hoop": self = .basketballHoop
            case "hockey puck": self = .hockeyPuck
            case "bike helmet": self = .bikeHelmet
            case "referee flag": self = .refereeFlag
            case "batting tee": self = .battingTee
            case "foam finger": self = .foamFinger
            case "stopwatch strap": self = .stopwatchStrap
            case "skate ramp": self = .skateRamp
            case "dumbbell": self = .dumbbell
            case "team jersey": self = .teamJersey
            case "swim goggles": self = .swimGoggles
            case "medal ribbon": self = .medalRibbon
            // School deck.
            case "glue stick": self = .glueStick
            case "ruler": self = .ruler
            case "locker door": self = .lockerDoor
            case "whiteboard eraser": self = .whiteboardEraser
            case "cafeteria tray": self = .cafeteriaTray
            case "hall pass": self = .hallPass
            case "pencil case": self = .pencilCase
            case "binder clip": self = .binderClip
            case "notebook spiral": self = .notebookSpiral
            case "index card": self = .indexCard
            case "crayon box": self = .crayonBox
            case "lunch tray": self = .lunchTray
            case "library stamp": self = .libraryStamp
            case "desk bell": self = .deskBell
            case "protractor": self = .protractor
            case "science goggles": self = .scienceGoggles
            case "chalk holder": self = .chalkHolder
            case "gym whistle": self = .gymWhistle
            case "book cart": self = .bookCart
            case "sticky bookmark": self = .stickyBookmark
            // Household Items deck additions.
            case "extension cord": self = .extensionCord
            case "tape roll": self = .tapeRoll
            case "battery": self = .battery
            case "trash can": self = .trashCan
            case "coat hanger": self = .coatHanger
            case "picture frame": self = .pictureFrame
            case "doorknob": self = .doorknob
            case "storage bin": self = .storageBin
            case "vacuum hose": self = .vacuumHose
            case "curtain rod": self = .curtainRod
            case "lamp shade": self = .lampShade
            case "wall hook": self = .wallHook
            case "broom": self = .broom
            case "rug": self = .rug
            // Space deck additions.
            case "mars shovel": self = .marsShovel
            case "cosmic compass": self = .cosmicCompass
            case "galaxy goggles": self = .galaxyGoggles
            case "rocket toolbox": self = .rocketToolbox
            case "starlight umbrella": self = .starlightUmbrella
            case "alien lunchbox": self = .alienLunchbox
            case "moon boots": self = .moonBoots
            case "orbit scooter": self = .orbitScooter
            case "space radio": self = .spaceRadio
            case "crater bucket": self = .craterBucket
            // Kitchen deck additions.
            case "pizza cutter": self = .pizzaCutter
            case "tea kettle": self = .teaKettle
            case "butter dish": self = .butterDish
            case "ice cream scoop": self = .iceCreamScoop
            case "cupcake liner": self = .cupcakeLiner
            case "dish towel": self = .dishTowel
            case "can opener": self = .canOpener
            case "kitchen timer": self = .kitchenTimer
            case "spice rack": self = .spiceRack
            case "sink plug": self = .sinkPlug
            // Sports deck additions.
            case "jump rope": self = .jumpRope
            case "cones set": self = .conesSet
            case "golf tee": self = .golfTee
            case "boxing glove": self = .boxingGlove
            case "yoga mat": self = .yogaMat
            case "ski pole": self = .skiPole
            case "racing bib": self = .racingBib
            case "bowling pin": self = .bowlingPin
            case "ping pong paddle": self = .pingPongPaddle
            case "climbing grip": self = .climbingGrip
            // School deck additions.
            case "marker cap": self = .markerCap
            case "paper tray": self = .paperTray
            case "math cube": self = .mathCube
            case "backpack charm": self = .backpackCharm
            case "classroom timer": self = .classroomTimer
            case "staple remover": self = .stapleRemover
            case "reading lamp": self = .readingLamp
            case "paint smock": self = .paintSmock
            case "report folder": self = .reportFolder
            case "bus pass": self = .busPass
            // Reuse existing doodles for renamed / equivalent objects.
            case "spiral notebook": self = .notebookSpiral
            case "baseball tee": self = .battingTee
            case "practice cones": self = .conesSet
            case "climbing hold": self = .climbingGrip
            case "counting cube": self = .mathCube
            case "library cart": self = .bookCart
            case "school folder": self = .reportFolder
            // Smart-home additions (Household Items).
            case "smart speaker": self = .smartSpeaker
            case "robot vacuum": self = .robotVacuum
            case "security camera": self = .securityCamera
            case "thermostat": self = .thermostat
            case "wi-fi router": self = .wifiRouter
            case "leak sensor": self = .leakSensor
            case "door sensor": self = .doorSensor
            case "motion sensor": self = .motionSensor
            case "smart plug": self = .smartPlug
            // Tech & Gadgets deck.
            case "smart button": self = .smartButton
            case "qr code sticker": self = .qrCodeSticker
            case "gps tag": self = .gpsTag
            case "smart camera": self = .smartCamera
            case "voice remote": self = .voiceRemote
            case "wi-fi hotspot": self = .wifiHotspot
            case "robot arm": self = .robotArm
            case "hand scanner": self = .handScanner
            case "alert bell": self = .alertBell
            case "weather app": self = .weatherApp
            case "voting app": self = .votingApp
            case "battery pack": self = .batteryPack
            case "tracker tag": self = .trackerTag
            case "touch screen": self = .touchScreen
            case "mini drone": self = .miniDrone
            case "smart lock": self = .smartLock
            case "data recorder": self = .dataRecorder
            case "alert badge": self = .alertBadge
            case "ai coach": self = .aiCoach
            case "timer button": self = .timerButton
            case "map marker": self = .mapMarker
            case "bluetooth tag": self = .bluetoothTag
            case "charging dock": self = .chargingDock
            case "camera lens": self = .cameraLens
            case "delivery tracker": self = .deliveryTracker
            case "barcode scanner": self = .barcodeScanner
            case "call button": self = .callButton
            case "wi-fi booster": self = .wifiBooster
            case "smart watch": self = .smartWatch
            // Kitchen additions.
            case "grocery scanner": self = .groceryScanner
            case "fridge camera": self = .fridgeCamera
            case "recipe scanner": self = .recipeScanner
            case "food thermometer": self = .foodThermometer
            case "kitchen scale": self = .kitchenScale
            case "smart pan": self = .smartPan
            case "smart faucet": self = .smartFaucet
            case "food sealer": self = .foodSealer
            case "compost bin": self = .compostBin
            // Sports additions.
            case "replay camera": self = .replayCamera
            case "stopwatch": self = .stopwatch
            case "heart monitor": self = .heartMonitor
            case "fitness tracker": self = .fitnessTracker
            case "speed sensor": self = .speedSensor
            case "race timer": self = .raceTimer
            case "training app": self = .trainingApp
            // School additions.
            case "tablet cart": self = .tabletCart
            case "attendance scanner": self = .attendanceScanner
            case "flashcard app": self = .flashcardApp
            case "projector remote": self = .projectorRemote
            case "due date stamp": self = .dueDateStamp
            case "chalk tray": self = .chalkTray
            case "smart pen": self = .smartPen
            case "class poll app": self = .classPollApp
            case "smart worksheet": self = .smartWorksheet
            case "noise meter": self = .noiseMeter
            case "homework app": self = .homeworkApp
            default: return nil
            }
        }
    }

    var kind: Kind
    var size: CGFloat = 56

    var body: some View {
        Canvas { ctx, area in
            let s = min(area.width, area.height)
            let ox = (area.width - s) / 2
            let oy = (area.height - s) / 2
            let lw = max(1.6, s * 0.064)
            let stroke = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
            let thin = StrokeStyle(lineWidth: lw * 0.62, lineCap: .round, lineJoin: .round)
            let ink = Palette.ink
            let shadow = ink.opacity(0.22)
            let pi = CGFloat.pi

            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
            func seed(_ n: UInt64) -> UInt64 {
                kind.rawValue.unicodeScalars.reduce(n) { partial, scalar in
                    partial &* 33 &+ UInt64(scalar.value)
                }
            }
            func wobble(_ points: [CGPoint], closed: Bool = false, salt: UInt64 = 0) -> Path {
                var path = Path()
                guard let first = points.first else { return path }
                path.move(to: first)
                var current = first
                for (idx, next) in points.dropFirst().enumerated() {
                    path.addPath(wobblyLine(from: current, to: next, seed: seed(UInt64(idx) &+ salt),
                                            roughness: s * 0.01, segments: 3))
                    current = next
                }
                if closed {
                    path.addPath(wobblyLine(from: current, to: first, seed: seed(99 &+ salt),
                                            roughness: s * 0.01, segments: 3))
                    path.closeSubpath()
                }
                return path
            }
            func line(_ pts: [(CGFloat, CGFloat)], color: Color = Palette.ink,
                      style: StrokeStyle? = nil, closed: Bool = false,
                      fill: Color? = nil, salt: UInt64 = 0) {
                let points = pts.map { P($0.0, $0.1) }
                let path = wobble(points, closed: closed, salt: salt)
                if let fill { ctx.fill(path, with: .color(fill)) }
                let used = style ?? stroke
                ctx.stroke(path, with: .color(shadow), style: StrokeStyle(lineWidth: used.lineWidth * 0.7, lineCap: .round, lineJoin: .round))
                ctx.stroke(path, with: .color(color), style: used)
            }
            /// A closed/open path drawn through the points as a smooth Catmull-Rom
            /// spline (with a touch of jitter), so rounded objects read as round
            /// instead of as sharp-cornered polygons.
            func smooth(_ pts: [(CGFloat, CGFloat)], closed: Bool = false,
                        fill: Color? = nil, color: Color = Palette.ink,
                        style: StrokeStyle? = nil, salt: UInt64 = 0) {
                var rng = SeededGenerator(seed: seed(700 &+ salt))
                let jit = s * 0.006
                let ps = pts.map { CGPoint(x: ox + $0.0 * s + CGFloat.random(in: -jit...jit, using: &rng),
                                           y: oy + $0.1 * s + CGFloat.random(in: -jit...jit, using: &rng)) }
                guard ps.count >= 2 else { return }
                func node(_ i: Int) -> CGPoint {
                    if closed { return ps[((i % ps.count) + ps.count) % ps.count] }
                    return ps[min(max(i, 0), ps.count - 1)]
                }
                var path = Path()
                path.move(to: ps[0])
                let segs = closed ? ps.count : ps.count - 1
                for i in 0..<segs {
                    let p0 = node(i - 1), p1 = node(i), p2 = node(i + 1), p3 = node(i + 2)
                    let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
                    let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
                    path.addCurve(to: p2, control1: c1, control2: c2)
                }
                if closed { path.closeSubpath() }
                if let fill { ctx.fill(path, with: .color(fill)) }
                let used = style ?? stroke
                ctx.stroke(path, with: .color(shadow), style: StrokeStyle(lineWidth: used.lineWidth * 0.7, lineCap: .round, lineJoin: .round))
                ctx.stroke(path, with: .color(color), style: used)
            }
            func oval(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                      fill: Color? = nil, color: Color = Palette.ink, style: StrokeStyle? = nil, salt: UInt64 = 0) {
                let path = wobblyOval(center: P(x, y), rx: rx * s, ry: ry * s,
                                      seed: seed(200 &+ salt), roughness: s * 0.01, steps: 24)
                if let fill { ctx.fill(path, with: .color(fill)) }
                let used = style ?? stroke
                ctx.stroke(path, with: .color(shadow), style: StrokeStyle(lineWidth: used.lineWidth * 0.65, lineCap: .round, lineJoin: .round))
                ctx.stroke(path, with: .color(color), style: used)
            }
            func arc(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ a0: CGFloat, _ a1: CGFloat,
                     color: Color = Palette.ink, style: StrokeStyle? = nil, salt: UInt64 = 0) {
                ctx.stroke(wobblyArc(center: P(x, y), radius: r * s, start: a0, end: a1,
                                     seed: seed(300 &+ salt), roughness: s * 0.01, steps: 18),
                           with: .color(color), style: style ?? stroke)
            }
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat,
                      fill: Color? = nil, color: Color = Palette.ink, style: StrokeStyle? = nil, salt: UInt64 = 0) {
                let frame = CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s)
                let path = SketchyRoundedRectangle(cornerRadius: radius * s, roughness: s * 0.01, seed: seed(400 &+ salt)).path(in: frame)
                if let fill { ctx.fill(path, with: .color(fill)) }
                ctx.stroke(path, with: .color(color), style: style ?? stroke)
            }
            func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, color: Color = Palette.ink, salt: UInt64 = 0) {
                ctx.fill(wobblyOval(center: P(x, y), rx: r * s, ry: r * s,
                                    seed: seed(500 &+ salt), roughness: s * 0.005, steps: 12),
                         with: .color(color))
            }
            func star(_ cx: CGFloat, _ cy: CGFloat, _ outer: CGFloat, _ inner: CGFloat,
                      fill: Color? = nil, color: Color = Palette.ink, salt: UInt64 = 0) {
                let path = starPath(center: P(cx, cy), outer: outer * s, inner: inner * s)
                if let fill { ctx.fill(path, with: .color(fill)) }
                ctx.stroke(path, with: .color(color), style: thin)
            }

            switch kind {
            case .banana:
                smooth([(0.27, 0.24), (0.2, 0.46), (0.3, 0.7), (0.56, 0.82), (0.8, 0.74),
                        (0.72, 0.64), (0.52, 0.66), (0.37, 0.52), (0.35, 0.3)],
                       closed: true, fill: Palette.mustard, color: Palette.mustard)
                dot(0.28, 0.23, 0.035, color: Palette.leaf)
                dot(0.8, 0.73, 0.03, color: Palette.ink)
            case .clock:
                oval(0.5, 0.54, 0.34, 0.34, fill: Palette.card)
                line([(0.3, 0.2), (0.24, 0.3)], style: thin)
                line([(0.7, 0.2), (0.76, 0.3)], style: thin)
                line([(0.5, 0.54), (0.5, 0.33)])
                line([(0.5, 0.54), (0.65, 0.62)], color: Palette.tomato)
                dot(0.5, 0.54, 0.028, color: Palette.tomato)
            case .umbrella:
                smooth([(0.12, 0.52), (0.5, 0.16), (0.88, 0.52)],
                       fill: Palette.tomato, color: Palette.tomato)
                smooth([(0.12, 0.52), (0.26, 0.6), (0.4, 0.52), (0.5, 0.6),
                        (0.6, 0.52), (0.74, 0.6), (0.88, 0.52)])
                line([(0.5, 0.18), (0.5, 0.78)])
                arc(0.41, 0.76, 0.09, 0, pi, style: thin)
            case .lightbulb:
                oval(0.5, 0.42, 0.24, 0.27, fill: Palette.mustard.opacity(0.55), color: Palette.mustard)
                rect(0.4, 0.66, 0.2, 0.14, 0.03, fill: Palette.silver.opacity(0.5))
                line([(0.42, 0.72), (0.58, 0.72)], style: thin)
                smooth([(0.42, 0.46), (0.47, 0.54), (0.53, 0.46), (0.58, 0.54)], style: thin)
                line([(0.5, 0.08), (0.5, 0.16)], color: Palette.tomato, style: thin)
                line([(0.25, 0.18), (0.31, 0.24)], color: Palette.tomato, style: thin)
                line([(0.75, 0.18), (0.69, 0.24)], color: Palette.tomato, style: thin)
            case .key:
                oval(0.32, 0.42, 0.16, 0.16, fill: Palette.mustard.opacity(0.4), color: Palette.mustard)
                oval(0.32, 0.42, 0.07, 0.07, color: Palette.mustard, style: thin)
                line([(0.44, 0.5), (0.8, 0.74)], color: Palette.mustard)
                line([(0.66, 0.64), (0.62, 0.74)], color: Palette.mustard, style: thin)
                line([(0.74, 0.69), (0.7, 0.8)], color: Palette.mustard, style: thin)
            case .book:
                smooth([(0.5, 0.3), (0.32, 0.24), (0.18, 0.28), (0.18, 0.74), (0.32, 0.7), (0.5, 0.78)],
                       closed: true, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                smooth([(0.5, 0.3), (0.68, 0.24), (0.82, 0.28), (0.82, 0.74), (0.68, 0.7), (0.5, 0.78)],
                       closed: true, fill: Palette.tomato.opacity(0.25), color: Palette.tomato)
                line([(0.5, 0.3), (0.5, 0.78)])
                line([(0.28, 0.4), (0.42, 0.44)], style: thin)
                line([(0.58, 0.44), (0.72, 0.4)], style: thin)
            case .phone:
                rect(0.32, 0.12, 0.36, 0.76, 0.09, fill: Palette.sky.opacity(0.2))
                line([(0.44, 0.19), (0.56, 0.19)], style: thin)
                dot(0.5, 0.81, 0.028)
            case .camera:
                rect(0.12, 0.32, 0.76, 0.46, 0.09, fill: Palette.silver.opacity(0.3))
                smooth([(0.34, 0.32), (0.4, 0.22), (0.56, 0.22), (0.62, 0.32)])
                oval(0.5, 0.56, 0.15, 0.15, fill: Palette.sky.opacity(0.3))
                oval(0.5, 0.56, 0.07, 0.07, color: Palette.sky, style: thin)
                dot(0.76, 0.42, 0.03, color: Palette.tomato)
            case .scissors:
                oval(0.3, 0.7, 0.11, 0.11, color: Palette.tomato)
                oval(0.54, 0.7, 0.11, 0.11, color: Palette.tomato)
                line([(0.38, 0.62), (0.8, 0.22)], color: Palette.silver)
                line([(0.46, 0.62), (0.82, 0.46)], color: Palette.silver)
                dot(0.42, 0.62, 0.018)
            case .magnet:
                arc(0.5, 0.42, 0.28, pi, 2 * pi, color: Palette.tomato)
                arc(0.5, 0.42, 0.16, pi, 2 * pi, color: Palette.tomato)
                line([(0.22, 0.42), (0.22, 0.7)], color: Palette.tomato)
                line([(0.34, 0.42), (0.34, 0.7)], color: Palette.tomato)
                line([(0.78, 0.42), (0.78, 0.7)], color: Palette.tomato)
                line([(0.66, 0.42), (0.66, 0.7)], color: Palette.tomato)
                rect(0.2, 0.68, 0.16, 0.07, 0.01, fill: Palette.silver.opacity(0.6))
                rect(0.64, 0.68, 0.16, 0.07, 0.01, fill: Palette.silver.opacity(0.6))
            case .ball:
                oval(0.5, 0.5, 0.33, 0.33, fill: Palette.card)
                smooth([(0.5, 0.4), (0.61, 0.48), (0.57, 0.6), (0.43, 0.6), (0.39, 0.48)],
                       closed: true, fill: Palette.ink.opacity(0.8), color: Palette.ink)
                line([(0.5, 0.4), (0.5, 0.27)], style: thin)
                line([(0.61, 0.48), (0.74, 0.44)], style: thin)
                line([(0.57, 0.6), (0.66, 0.71)], style: thin)
                line([(0.43, 0.6), (0.34, 0.71)], style: thin)
                line([(0.39, 0.48), (0.26, 0.44)], style: thin)
            case .balloon:
                oval(0.5, 0.36, 0.24, 0.29, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                smooth([(0.46, 0.64), (0.54, 0.64), (0.5, 0.71)],
                       closed: true, fill: Palette.tomato, color: Palette.tomato)
                smooth([(0.5, 0.71), (0.43, 0.8), (0.57, 0.88), (0.5, 0.96)], style: thin)
            case .guitar:
                oval(0.4, 0.68, 0.18, 0.2, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                oval(0.5, 0.5, 0.13, 0.15, fill: Palette.mustard.opacity(0.45), color: Palette.mustard)
                line([(0.56, 0.42), (0.84, 0.14)])
                rect(0.79, 0.07, 0.13, 0.11, 0.02, fill: Palette.ink.opacity(0.18))
                dot(0.42, 0.64, 0.05, color: Palette.ink)
                line([(0.34, 0.58), (0.82, 0.13)], style: thin)
            case .dice:
                rect(0.24, 0.24, 0.52, 0.52, 0.12, fill: Palette.card)
                dot(0.37, 0.37, 0.045)
                dot(0.63, 0.37, 0.045)
                dot(0.5, 0.5, 0.045)
                dot(0.37, 0.63, 0.045)
                dot(0.63, 0.63, 0.045)
            case .telescope:
                smooth([(0.2, 0.5), (0.62, 0.34), (0.68, 0.46), (0.26, 0.62)],
                       closed: true, fill: Palette.grape.opacity(0.3), color: Palette.grape)
                smooth([(0.62, 0.32), (0.84, 0.24), (0.9, 0.4), (0.68, 0.48)],
                       closed: true, fill: Palette.grape.opacity(0.45), color: Palette.grape)
                line([(0.44, 0.58), (0.36, 0.86)], style: thin)
                line([(0.44, 0.58), (0.6, 0.84)], style: thin)
            case .microphone:
                rect(0.37, 0.14, 0.26, 0.4, 0.13, fill: Palette.grape.opacity(0.4))
                line([(0.42, 0.24), (0.58, 0.24)], style: thin)
                line([(0.42, 0.34), (0.58, 0.34)], style: thin)
                arc(0.5, 0.46, 0.26, 0, pi)
                line([(0.5, 0.72), (0.5, 0.86)])
                line([(0.36, 0.86), (0.64, 0.86)])
            case .crown:
                smooth([(0.18, 0.7), (0.22, 0.36), (0.36, 0.54), (0.5, 0.3),
                        (0.64, 0.54), (0.78, 0.36), (0.82, 0.7)],
                       closed: true, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                line([(0.2, 0.64), (0.8, 0.64)], color: Palette.mustard, style: thin)
                dot(0.22, 0.37, 0.03, color: Palette.tomato)
                dot(0.5, 0.31, 0.032, color: Palette.tomato)
                dot(0.78, 0.37, 0.03, color: Palette.tomato)
            case .gem:
                line([(0.28, 0.26), (0.72, 0.26), (0.86, 0.46), (0.5, 0.84), (0.14, 0.46)],
                     color: Palette.sky, closed: true, fill: Palette.sky.opacity(0.4))
                line([(0.28, 0.26), (0.4, 0.46), (0.5, 0.84)], color: Palette.sky, style: thin)
                line([(0.72, 0.26), (0.6, 0.46), (0.5, 0.84)], color: Palette.sky, style: thin)
                line([(0.14, 0.46), (0.86, 0.46)], color: Palette.sky, style: thin)
            case .rainbow:
                arc(0.5, 0.78, 0.46, pi, 2 * pi, color: Palette.tomato)
                arc(0.5, 0.78, 0.37, pi, 2 * pi, color: Palette.mustard)
                arc(0.5, 0.78, 0.28, pi, 2 * pi, color: Palette.teal)
                oval(0.2, 0.78, 0.12, 0.08, fill: Palette.card)
                oval(0.8, 0.78, 0.12, 0.08, fill: Palette.card)
            case .fire:
                smooth([(0.5, 0.88), (0.3, 0.7), (0.38, 0.5), (0.46, 0.58), (0.46, 0.16),
                        (0.6, 0.42), (0.7, 0.42), (0.7, 0.64)],
                       closed: true, fill: Palette.tomato.opacity(0.55), color: Palette.tomato)
                smooth([(0.5, 0.8), (0.42, 0.66), (0.5, 0.5), (0.58, 0.66)],
                       closed: true, fill: Palette.mustard, color: Palette.mustard)
            case .snowflake:
                for a in stride(from: CGFloat(0), to: 2 * pi, by: pi / 3) {
                    let x = cos(a), y = sin(a)
                    line([(0.5, 0.5), (0.5 + x * 0.34, 0.5 + y * 0.34)], color: Palette.sky, style: thin)
                    let bx = cos(a + 0.5), by = sin(a + 0.5)
                    let dx = cos(a - 0.5), dy = sin(a - 0.5)
                    line([(0.5 + x * 0.22, 0.5 + y * 0.22),
                          (0.5 + x * 0.22 + bx * 0.08, 0.5 + y * 0.22 + by * 0.08)],
                         color: Palette.sky, style: thin)
                    line([(0.5 + x * 0.22, 0.5 + y * 0.22),
                          (0.5 + x * 0.22 + dx * 0.08, 0.5 + y * 0.22 + dy * 0.08)],
                         color: Palette.sky, style: thin)
                }
                dot(0.5, 0.5, 0.03, color: Palette.sky)
            case .star:
                star(0.5, 0.5, 0.38, 0.17, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
            case .moon:
                smooth([(0.52, 0.14), (0.3, 0.32), (0.3, 0.68), (0.52, 0.86),
                        (0.44, 0.66), (0.42, 0.5), (0.44, 0.34)],
                       closed: true, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                dot(0.4, 0.36, 0.022, color: Palette.mustard)
                dot(0.37, 0.56, 0.018, color: Palette.mustard)
            case .sun:
                oval(0.5, 0.5, 0.22, 0.22, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                for a in stride(from: CGFloat(0), to: 2 * pi, by: pi / 4) {
                    line([(0.5 + cos(a) * 0.3, 0.5 + sin(a) * 0.3),
                          (0.5 + cos(a) * 0.44, 0.5 + sin(a) * 0.44)], color: Palette.mustard, style: thin)
                }
            case .cloud:
                smooth([(0.2, 0.62), (0.18, 0.5), (0.3, 0.44), (0.4, 0.36), (0.56, 0.36),
                        (0.68, 0.44), (0.8, 0.48), (0.84, 0.6), (0.78, 0.66), (0.5, 0.66), (0.28, 0.66)],
                       closed: true, fill: Palette.sky.opacity(0.25), color: Palette.sky)
            case .lightning:
                line([(0.56, 0.1), (0.3, 0.52), (0.48, 0.52), (0.4, 0.9), (0.72, 0.42), (0.54, 0.42)],
                     color: Palette.mustard, closed: true, fill: Palette.mustard)
            case .rocket:
                smooth([(0.5, 0.1), (0.66, 0.4), (0.66, 0.66), (0.34, 0.66), (0.34, 0.4)],
                       closed: true, fill: Palette.card, color: Palette.ink)
                oval(0.5, 0.4, 0.09, 0.09, fill: Palette.sky.opacity(0.4), color: Palette.sky)
                smooth([(0.34, 0.54), (0.18, 0.7), (0.34, 0.66)],
                       closed: true, fill: Palette.tomato.opacity(0.6), color: Palette.tomato)
                smooth([(0.66, 0.54), (0.82, 0.7), (0.66, 0.66)],
                       closed: true, fill: Palette.tomato.opacity(0.6), color: Palette.tomato)
                smooth([(0.42, 0.66), (0.5, 0.92), (0.58, 0.66)],
                       closed: true, fill: Palette.mustard, color: Palette.mustard)
            case .robot:
                rect(0.24, 0.3, 0.52, 0.44, 0.1, fill: Palette.silver.opacity(0.3))
                line([(0.5, 0.3), (0.5, 0.18)], style: thin)
                dot(0.5, 0.16, 0.035, color: Palette.tomato)
                dot(0.39, 0.46, 0.045, color: Palette.sky)
                dot(0.61, 0.46, 0.045, color: Palette.sky)
                smooth([(0.4, 0.6), (0.5, 0.64), (0.6, 0.6)], style: thin)
            case .alien:
                oval(0.5, 0.46, 0.28, 0.34, fill: Palette.leaf.opacity(0.4), color: Palette.leaf)
                smooth([(0.32, 0.4), (0.4, 0.36), (0.44, 0.46), (0.36, 0.5)],
                       closed: true, fill: ink, color: ink)
                smooth([(0.68, 0.4), (0.6, 0.36), (0.56, 0.46), (0.64, 0.5)],
                       closed: true, fill: ink, color: ink)
                arc(0.5, 0.56, 0.12, 0.1 * pi, 0.9 * pi, style: thin)
            case .ghost:
                smooth([(0.25, 0.8), (0.25, 0.46), (0.34, 0.28), (0.5, 0.24), (0.66, 0.28),
                        (0.75, 0.46), (0.75, 0.8), (0.65, 0.72), (0.55, 0.82), (0.45, 0.72), (0.35, 0.82)],
                       closed: true, fill: Palette.card, color: Palette.ink)
                dot(0.42, 0.48, 0.035, color: Palette.ink)
                dot(0.58, 0.48, 0.035, color: Palette.ink)
                arc(0.5, 0.58, 0.07, 0, pi, style: thin)
            case .clown:
                oval(0.5, 0.52, 0.3, 0.3, fill: Palette.card)
                arc(0.3, 0.34, 0.1, pi, 2 * pi, color: Palette.tomato)
                arc(0.7, 0.34, 0.1, pi, 2 * pi, color: Palette.tomato)
                dot(0.5, 0.55, 0.06, color: Palette.tomato)
                dot(0.39, 0.46, 0.03, color: Palette.ink)
                dot(0.61, 0.46, 0.03, color: Palette.ink)
                arc(0.5, 0.58, 0.16, 0.12 * pi, 0.88 * pi, color: Palette.tomato, style: thin)
            case .glasses:
                oval(0.33, 0.5, 0.16, 0.13, fill: Palette.sky.opacity(0.18))
                oval(0.67, 0.5, 0.16, 0.13, fill: Palette.sky.opacity(0.18))
                smooth([(0.48, 0.48), (0.5, 0.44), (0.52, 0.48)], style: thin)
                line([(0.17, 0.46), (0.07, 0.4)], style: thin)
                line([(0.83, 0.46), (0.93, 0.4)], style: thin)
            case .hat:
                oval(0.5, 0.7, 0.34, 0.08, fill: Palette.ink.opacity(0.15))
                rect(0.35, 0.24, 0.3, 0.46, 0.04, fill: Palette.grape.opacity(0.35))
                line([(0.33, 0.62), (0.67, 0.62)], color: Palette.tomato)
            case .backpack:
                rect(0.28, 0.3, 0.44, 0.56, 0.12, fill: Palette.tomato.opacity(0.4))
                arc(0.5, 0.3, 0.16, pi, 2 * pi, style: thin)
                rect(0.37, 0.56, 0.26, 0.22, 0.06, fill: Palette.tomato.opacity(0.25))
            case .compass:
                oval(0.5, 0.5, 0.33, 0.33, fill: Palette.card)
                line([(0.56, 0.26), (0.46, 0.54), (0.44, 0.74), (0.54, 0.46)],
                     color: Palette.tomato, closed: true, fill: Palette.tomato.opacity(0.7))
                dot(0.5, 0.5, 0.025)
            case .trophy:
                smooth([(0.34, 0.2), (0.66, 0.2), (0.64, 0.44), (0.5, 0.54), (0.36, 0.44)],
                       closed: true, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                arc(0.3, 0.3, 0.08, 0.5 * pi, 1.5 * pi, color: Palette.mustard, style: thin)
                arc(0.7, 0.3, 0.08, -0.5 * pi, 0.5 * pi, color: Palette.mustard, style: thin)
                line([(0.5, 0.54), (0.5, 0.66)], color: Palette.mustard)
                smooth([(0.38, 0.82), (0.4, 0.66), (0.6, 0.66), (0.62, 0.82)],
                       closed: true, fill: Palette.mustard.opacity(0.4), color: Palette.mustard)
            case .medal:
                line([(0.38, 0.1), (0.5, 0.44), (0.62, 0.1)], color: Palette.tomato)
                oval(0.5, 0.64, 0.24, 0.24, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                star(0.5, 0.64, 0.12, 0.05, fill: Palette.mustard, color: Palette.mustard)
            case .flag:
                line([(0.28, 0.14), (0.28, 0.88)])
                smooth([(0.28, 0.18), (0.5, 0.24), (0.62, 0.18), (0.78, 0.26),
                        (0.78, 0.48), (0.6, 0.42), (0.46, 0.48), (0.28, 0.44)],
                       closed: true, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                dot(0.28, 0.13, 0.03, color: Palette.mustard)
            case .bomb:
                oval(0.46, 0.6, 0.26, 0.26, fill: Palette.ink.opacity(0.85), color: Palette.ink)
                rect(0.54, 0.32, 0.1, 0.08, 0.02, fill: Palette.ink.opacity(0.6))
                smooth([(0.6, 0.34), (0.72, 0.26), (0.78, 0.16)], style: thin)
                star(0.8, 0.13, 0.1, 0.04, fill: Palette.tomato, color: Palette.tomato)
            case .hammer:
                rect(0.32, 0.18, 0.4, 0.17, 0.06, fill: Palette.silver.opacity(0.45))
                smooth([(0.34, 0.35), (0.3, 0.46), (0.36, 0.4), (0.4, 0.46), (0.42, 0.35)],
                       color: Palette.ink, style: thin)
                line([(0.52, 0.35), (0.62, 0.84)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.8, lineCap: .round, lineJoin: .round))

            // MARK: everyday specifics (s41–s120)

            case .lunchbox:
                let thick = StrokeStyle(lineWidth: lw * 1.6, lineCap: .round, lineJoin: .round)
                rect(0.2, 0.42, 0.6, 0.42, 0.08, fill: Palette.tomato.opacity(0.4))
                arc(0.5, 0.42, 0.15, pi, 2 * pi, color: Palette.ink, style: thick)
                line([(0.2, 0.54), (0.8, 0.54)], style: thin)
                rect(0.44, 0.5, 0.12, 0.08, 0.02, fill: Palette.silver.opacity(0.6))
            case .bikeBell:
                smooth([(0.24, 0.62), (0.28, 0.38), (0.5, 0.3), (0.72, 0.38), (0.76, 0.62)],
                       closed: true, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                rect(0.2, 0.62, 0.6, 0.1, 0.02, fill: Palette.silver.opacity(0.5))
                dot(0.5, 0.28, 0.03, color: Palette.tomato)
                line([(0.76, 0.5), (0.88, 0.55)], style: thin)
            case .gardenHose:
                oval(0.42, 0.54, 0.28, 0.28, color: Palette.leaf)
                oval(0.42, 0.54, 0.17, 0.17, color: Palette.leaf, style: thin)
                oval(0.42, 0.54, 0.07, 0.07, color: Palette.leaf, style: thin)
                line([(0.66, 0.4), (0.86, 0.26)], color: Palette.silver,
                     style: StrokeStyle(lineWidth: lw * 1.4, lineCap: .round, lineJoin: .round))
                dot(0.86, 0.25, 0.03, color: Palette.silver)
            case .elevatorButton:
                rect(0.34, 0.2, 0.32, 0.6, 0.1, fill: Palette.silver.opacity(0.3))
                oval(0.5, 0.36, 0.1, 0.1, fill: Palette.card)
                line([(0.44, 0.39), (0.5, 0.31), (0.56, 0.39)], color: Palette.leaf, style: thin)
                oval(0.5, 0.62, 0.1, 0.1, fill: Palette.card)
                line([(0.44, 0.59), (0.5, 0.67), (0.56, 0.59)], color: Palette.tomato, style: thin)
            case .mailbox:
                smooth([(0.24, 0.66), (0.24, 0.46), (0.34, 0.36), (0.5, 0.34),
                        (0.66, 0.36), (0.76, 0.46), (0.76, 0.66)],
                       closed: true, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                line([(0.4, 0.66), (0.4, 0.86)])
                line([(0.34, 0.5), (0.34, 0.64)], style: thin)
                rect(0.76, 0.4, 0.08, 0.12, 0.01, fill: Palette.tomato, color: Palette.tomato)
            case .shoppingCart:
                line([(0.28, 0.36), (0.72, 0.36), (0.66, 0.62), (0.34, 0.62)], closed: true,
                     fill: Palette.silver.opacity(0.2))
                line([(0.28, 0.36), (0.2, 0.28), (0.13, 0.28)])
                line([(0.31, 0.49), (0.69, 0.49)], style: thin)
                line([(0.44, 0.36), (0.42, 0.62)], style: thin)
                line([(0.56, 0.36), (0.58, 0.62)], style: thin)
                dot(0.4, 0.72, 0.05, color: Palette.ink)
                dot(0.62, 0.72, 0.05, color: Palette.ink)
            case .flashlight:
                rect(0.18, 0.42, 0.42, 0.16, 0.05, fill: Palette.grape.opacity(0.4))
                line([(0.6, 0.4), (0.74, 0.34), (0.74, 0.66), (0.6, 0.6)], closed: true,
                     fill: Palette.silver.opacity(0.5))
                dot(0.32, 0.42, 0.025, color: Palette.tomato)
                line([(0.78, 0.4), (0.9, 0.32)], color: Palette.mustard, style: thin)
                line([(0.8, 0.5), (0.94, 0.5)], color: Palette.mustard, style: thin)
                line([(0.78, 0.6), (0.9, 0.68)], color: Palette.mustard, style: thin)
            case .suitcase:
                rect(0.22, 0.34, 0.56, 0.5, 0.08, fill: Palette.tomato.opacity(0.35))
                arc(0.5, 0.34, 0.13, pi, 2 * pi)
                line([(0.36, 0.34), (0.36, 0.84)], style: thin)
                line([(0.64, 0.34), (0.64, 0.84)], style: thin)
                rect(0.44, 0.52, 0.12, 0.06, 0.01, fill: Palette.silver.opacity(0.6))
            case .thermos:
                rect(0.36, 0.28, 0.28, 0.54, 0.07, fill: Palette.teal.opacity(0.35))
                rect(0.38, 0.16, 0.24, 0.14, 0.04, fill: Palette.silver.opacity(0.5))
                line([(0.36, 0.5), (0.64, 0.5)], style: thin)
                line([(0.42, 0.34), (0.42, 0.46)], style: thin)
            case .paintRoller:
                rect(0.26, 0.22, 0.46, 0.16, 0.05, fill: Palette.sky.opacity(0.4))
                line([(0.49, 0.38), (0.49, 0.56), (0.4, 0.56)])
                rect(0.32, 0.56, 0.16, 0.28, 0.05, fill: Palette.mustard.opacity(0.4))
                dot(0.6, 0.44, 0.02, color: Palette.sky)

            case .doorbell:
                rect(0.34, 0.22, 0.32, 0.56, 0.1, fill: Palette.silver.opacity(0.3))
                oval(0.5, 0.4, 0.1, 0.1, fill: Palette.tomato.opacity(0.6), color: Palette.tomato)
                dot(0.5, 0.4, 0.03, color: Palette.tomato)
                line([(0.44, 0.6), (0.56, 0.6)], style: thin)
                line([(0.44, 0.68), (0.56, 0.68)], style: thin)
            case .dogLeash:
                oval(0.28, 0.3, 0.07, 0.09, color: Palette.silver)
                smooth([(0.32, 0.36), (0.5, 0.5), (0.4, 0.68), (0.62, 0.74), (0.76, 0.58)],
                       color: Palette.tomato)
                oval(0.78, 0.52, 0.09, 0.08, color: Palette.tomato)
            case .birdhouse:
                rect(0.3, 0.5, 0.4, 0.34, 0.03, fill: Palette.leaf.opacity(0.3))
                line([(0.22, 0.52), (0.5, 0.28), (0.78, 0.52)])
                line([(0.5, 0.28), (0.5, 0.16)], style: thin)
                dot(0.5, 0.6, 0.07, color: Palette.ink)
                line([(0.5, 0.67), (0.5, 0.78)], style: thin)
            case .trafficCone:
                smooth([(0.5, 0.2), (0.66, 0.72), (0.34, 0.72)], closed: true,
                       fill: Palette.tomato.opacity(0.55), color: Palette.tomato)
                rect(0.26, 0.72, 0.48, 0.12, 0.03, fill: Palette.tomato.opacity(0.4))
                line([(0.42, 0.46), (0.58, 0.46)], color: Palette.cream,
                     style: StrokeStyle(lineWidth: lw * 1.6, lineCap: .round, lineJoin: .round))
            case .windChime:
                oval(0.5, 0.28, 0.2, 0.05, fill: Palette.mustard.opacity(0.4), color: Palette.mustard)
                line([(0.35, 0.3), (0.35, 0.66)], color: Palette.silver, style: thin)
                line([(0.45, 0.3), (0.45, 0.72)], color: Palette.silver, style: thin)
                line([(0.55, 0.3), (0.55, 0.68)], color: Palette.silver, style: thin)
                line([(0.65, 0.3), (0.65, 0.62)], color: Palette.silver, style: thin)
                line([(0.5, 0.32), (0.5, 0.78)], style: thin)
                dot(0.5, 0.8, 0.04, color: Palette.mustard)
            case .pillow:
                smooth([(0.24, 0.36), (0.5, 0.3), (0.76, 0.36), (0.8, 0.6),
                        (0.72, 0.72), (0.5, 0.74), (0.28, 0.72), (0.2, 0.6)],
                       closed: true, fill: Palette.grape.opacity(0.25), color: Palette.grape)
                line([(0.28, 0.4), (0.34, 0.46)], style: thin)
                line([(0.72, 0.4), (0.66, 0.46)], style: thin)
            case .skateboard:
                smooth([(0.14, 0.5), (0.3, 0.44), (0.7, 0.44), (0.86, 0.5),
                        (0.7, 0.56), (0.3, 0.56)],
                       closed: true, fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                line([(0.32, 0.56), (0.32, 0.62)], style: thin)
                line([(0.68, 0.56), (0.68, 0.62)], style: thin)
                dot(0.32, 0.66, 0.05, color: Palette.ink)
                dot(0.68, 0.66, 0.05, color: Palette.ink)
            case .fishingRod:
                line([(0.18, 0.82), (0.8, 0.2)])
                line([(0.18, 0.82), (0.3, 0.74)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.7, lineCap: .round, lineJoin: .round))
                oval(0.34, 0.72, 0.05, 0.05, color: Palette.silver, style: thin)
                line([(0.8, 0.2), (0.83, 0.58)], style: thin)
                arc(0.8, 0.62, 0.05, -0.4 * pi, 0.8 * pi, style: thin)
            case .vendingMachine:
                rect(0.28, 0.16, 0.44, 0.68, 0.06, fill: Palette.tomato.opacity(0.3))
                rect(0.33, 0.22, 0.24, 0.38, 0.03, fill: Palette.sky.opacity(0.25))
                line([(0.33, 0.35), (0.57, 0.35)], style: thin)
                line([(0.33, 0.47), (0.57, 0.47)], style: thin)
                dot(0.64, 0.28, 0.02, color: Palette.mustard)
                dot(0.64, 0.36, 0.02, color: Palette.mustard)
                rect(0.34, 0.66, 0.32, 0.1, 0.02, fill: Palette.ink.opacity(0.2))
            case .pizzaBox:
                rect(0.2, 0.36, 0.6, 0.44, 0.04, fill: Palette.mustard.opacity(0.3))
                line([(0.2, 0.48), (0.8, 0.48)], style: thin)
                smooth([(0.5, 0.54), (0.4, 0.72), (0.6, 0.72)], closed: true,
                       fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                dot(0.47, 0.62, 0.02, color: Palette.tomato)
                dot(0.53, 0.66, 0.02, color: Palette.tomato)

            case .beachChair:
                line([(0.28, 0.6), (0.56, 0.6), (0.74, 0.36)], color: Palette.teal)
                line([(0.28, 0.6), (0.24, 0.8)])
                line([(0.56, 0.6), (0.6, 0.8)])
                line([(0.74, 0.36), (0.7, 0.6)], style: thin)
                line([(0.6, 0.52), (0.66, 0.44)], color: Palette.teal, style: thin)
                line([(0.5, 0.58), (0.56, 0.5)], color: Palette.teal, style: thin)
            case .toolbox:
                rect(0.2, 0.44, 0.6, 0.36, 0.04, fill: Palette.tomato.opacity(0.4))
                line([(0.2, 0.44), (0.3, 0.34), (0.7, 0.34), (0.8, 0.44)])
                arc(0.5, 0.34, 0.12, pi, 2 * pi)
                rect(0.44, 0.5, 0.12, 0.06, 0.01, fill: Palette.silver.opacity(0.6))
            case .sprayBottle:
                rect(0.34, 0.44, 0.28, 0.4, 0.06, fill: Palette.sky.opacity(0.3))
                rect(0.4, 0.34, 0.16, 0.12, 0.02, fill: Palette.sky.opacity(0.4))
                line([(0.4, 0.36), (0.26, 0.3), (0.26, 0.4)], closed: true, fill: Palette.grape.opacity(0.4))
                dot(0.18, 0.28, 0.014, color: Palette.sky)
                dot(0.15, 0.33, 0.014, color: Palette.sky)
                line([(0.4, 0.62), (0.56, 0.62)], style: thin)
            case .remoteControl:
                rect(0.38, 0.16, 0.24, 0.68, 0.08, fill: Palette.ink.opacity(0.15))
                dot(0.5, 0.27, 0.035, color: Palette.tomato)
                dot(0.44, 0.42, 0.025)
                dot(0.56, 0.42, 0.025)
                dot(0.44, 0.54, 0.025)
                dot(0.56, 0.54, 0.025)
                line([(0.44, 0.68), (0.56, 0.68)], style: thin)
            case .sunglasses:
                oval(0.32, 0.5, 0.16, 0.13, fill: Palette.ink.opacity(0.7), color: Palette.ink)
                oval(0.68, 0.5, 0.16, 0.13, fill: Palette.ink.opacity(0.7), color: Palette.ink)
                smooth([(0.48, 0.48), (0.5, 0.43), (0.52, 0.48)])
                line([(0.17, 0.44), (0.07, 0.4)], style: thin)
                line([(0.83, 0.44), (0.93, 0.4)], style: thin)
            case .popcornBucket:
                line([(0.32, 0.44), (0.68, 0.44), (0.74, 0.82), (0.26, 0.82)], closed: true,
                     fill: Palette.card)
                line([(0.42, 0.44), (0.4, 0.82)], color: Palette.tomato, style: thin)
                line([(0.52, 0.44), (0.52, 0.82)], color: Palette.tomato, style: thin)
                line([(0.62, 0.44), (0.64, 0.82)], color: Palette.tomato, style: thin)
                dot(0.4, 0.4, 0.045, color: Palette.mustard)
                dot(0.52, 0.36, 0.05, color: Palette.mustard)
                dot(0.63, 0.4, 0.045, color: Palette.mustard)
            case .wateringCan:
                rect(0.3, 0.44, 0.34, 0.34, 0.06, fill: Palette.leaf.opacity(0.35))
                line([(0.3, 0.5), (0.14, 0.34)], color: Palette.leaf,
                     style: StrokeStyle(lineWidth: lw * 1.3, lineCap: .round, lineJoin: .round))
                oval(0.13, 0.32, 0.05, 0.05, color: Palette.leaf)
                arc(0.5, 0.44, 0.13, pi, 2 * pi, color: Palette.leaf)
                dot(0.11, 0.44, 0.013, color: Palette.sky)
                dot(0.15, 0.48, 0.013, color: Palette.sky)
            case .cookieJar:
                rect(0.3, 0.4, 0.4, 0.42, 0.1, fill: Palette.sky.opacity(0.2))
                rect(0.32, 0.3, 0.36, 0.12, 0.05, fill: Palette.tomato.opacity(0.4))
                dot(0.5, 0.28, 0.03)
                oval(0.5, 0.6, 0.11, 0.11, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                dot(0.46, 0.57, 0.02, color: Palette.ink)
                dot(0.54, 0.62, 0.02, color: Palette.ink)
                dot(0.5, 0.64, 0.02, color: Palette.ink)
            case .laundryBasket:
                line([(0.28, 0.46), (0.72, 0.46), (0.66, 0.82), (0.34, 0.82)], closed: true,
                     fill: Palette.grape.opacity(0.2))
                smooth([(0.34, 0.46), (0.44, 0.38), (0.56, 0.4), (0.66, 0.46)],
                       fill: Palette.cream, color: Palette.inkSoft)
                line([(0.31, 0.6), (0.69, 0.6)], style: thin)
                line([(0.45, 0.48), (0.43, 0.82)], style: thin)
                line([(0.57, 0.48), (0.59, 0.82)], style: thin)
            case .walkieTalkie:
                rect(0.36, 0.28, 0.28, 0.54, 0.06, fill: Palette.ink.opacity(0.18))
                line([(0.44, 0.28), (0.4, 0.12)])
                rect(0.4, 0.36, 0.2, 0.12, 0.02, fill: Palette.sky.opacity(0.3))
                line([(0.42, 0.56), (0.58, 0.56)], style: thin)
                line([(0.42, 0.62), (0.58, 0.62)], style: thin)
                line([(0.42, 0.68), (0.58, 0.68)], style: thin)

            case .sleepingBag:
                oval(0.46, 0.5, 0.32, 0.2, fill: Palette.tomato.opacity(0.3), color: Palette.tomato)
                oval(0.72, 0.5, 0.11, 0.18, color: Palette.tomato)
                oval(0.72, 0.5, 0.045, 0.08, color: Palette.tomato, style: thin)
                line([(0.36, 0.32), (0.36, 0.68)], style: thin)
                line([(0.52, 0.32), (0.52, 0.68)], style: thin)
            case .soapDispenser:
                rect(0.36, 0.42, 0.28, 0.42, 0.06, fill: Palette.teal.opacity(0.3))
                line([(0.5, 0.42), (0.5, 0.3), (0.64, 0.3)])
                rect(0.44, 0.24, 0.12, 0.08, 0.02, fill: Palette.silver.opacity(0.4))
                dot(0.66, 0.36, 0.02, color: Palette.sky)
                line([(0.4, 0.6), (0.6, 0.6)], style: thin)
            case .parkingMeter:
                line([(0.5, 0.52), (0.5, 0.84)])
                line([(0.4, 0.84), (0.6, 0.84)])
                rect(0.34, 0.22, 0.32, 0.32, 0.06, fill: Palette.silver.opacity(0.4))
                rect(0.4, 0.28, 0.2, 0.1, 0.02, fill: Palette.sky.opacity(0.3))
                line([(0.5, 0.44), (0.5, 0.48)], style: thin)
                dot(0.5, 0.2, 0.02)
            case .fireHydrant:
                smooth([(0.38, 0.82), (0.36, 0.5), (0.4, 0.4), (0.6, 0.4), (0.64, 0.5), (0.62, 0.82)],
                       closed: true, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                arc(0.5, 0.4, 0.12, pi, 2 * pi, color: Palette.tomato)
                dot(0.5, 0.28, 0.03, color: Palette.tomato)
                oval(0.32, 0.56, 0.05, 0.06, color: Palette.tomato)
                oval(0.68, 0.56, 0.05, 0.06, color: Palette.tomato)
                rect(0.34, 0.8, 0.32, 0.06, 0.02, fill: Palette.tomato.opacity(0.4))
            case .bubbleWand:
                line([(0.3, 0.84), (0.44, 0.56)], color: Palette.grape,
                     style: StrokeStyle(lineWidth: lw * 1.4, lineCap: .round, lineJoin: .round))
                oval(0.48, 0.46, 0.12, 0.14, color: Palette.grape)
                oval(0.68, 0.3, 0.08, 0.08, color: Palette.sky, style: thin)
                oval(0.82, 0.44, 0.05, 0.05, color: Palette.sky, style: thin)
                dot(0.74, 0.5, 0.02, color: Palette.sky)
            case .snowGlobe:
                oval(0.5, 0.44, 0.3, 0.3, fill: Palette.sky.opacity(0.15), color: Palette.sky)
                line([(0.3, 0.7), (0.7, 0.7), (0.64, 0.84), (0.36, 0.84)], closed: true,
                     fill: Palette.grape.opacity(0.4))
                smooth([(0.5, 0.32), (0.6, 0.56), (0.4, 0.56)], closed: true,
                       fill: Palette.leaf.opacity(0.5), color: Palette.leaf)
                dot(0.38, 0.36, 0.014, color: Palette.sky)
                dot(0.62, 0.4, 0.014, color: Palette.sky)
                dot(0.45, 0.5, 0.014, color: Palette.sky)
            case .pencilSharpener:
                rect(0.3, 0.48, 0.4, 0.28, 0.06, fill: Palette.sky.opacity(0.3))
                line([(0.5, 0.48), (0.5, 0.26)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.6, lineCap: .round, lineJoin: .round))
                smooth([(0.46, 0.48), (0.5, 0.54), (0.54, 0.48)], closed: true,
                       fill: Palette.ink, color: Palette.ink)
                line([(0.7, 0.58), (0.82, 0.52)])
                dot(0.84, 0.5, 0.03, color: Palette.grape)
            case .cerealBox:
                rect(0.32, 0.24, 0.36, 0.56, 0.04, fill: Palette.tomato.opacity(0.35))
                line([(0.32, 0.24), (0.4, 0.18), (0.6, 0.18), (0.68, 0.24)])
                oval(0.5, 0.42, 0.11, 0.1, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                line([(0.4, 0.6), (0.6, 0.6)], style: thin)
                line([(0.4, 0.68), (0.6, 0.68)], style: thin)
            case .campingLantern:
                arc(0.5, 0.24, 0.14, pi, 2 * pi)
                rect(0.38, 0.24, 0.24, 0.1, 0.03, fill: Palette.silver.opacity(0.5))
                rect(0.36, 0.34, 0.28, 0.34, 0.04, fill: Palette.mustard.opacity(0.35))
                smooth([(0.5, 0.62), (0.44, 0.52), (0.5, 0.42), (0.56, 0.52)], closed: true,
                       fill: Palette.mustard, color: Palette.mustard)
                rect(0.38, 0.68, 0.24, 0.1, 0.02, fill: Palette.silver.opacity(0.5))
            case .doorMat:
                line([(0.16, 0.42), (0.84, 0.42), (0.76, 0.74), (0.24, 0.74)], closed: true,
                     fill: Palette.leaf.opacity(0.3))
                line([(0.22, 0.48), (0.78, 0.48)], style: thin)
                line([(0.24, 0.68), (0.76, 0.68)], style: thin)
                line([(0.38, 0.58), (0.62, 0.58)])

            case .kiteString:
                line([(0.5, 0.18), (0.68, 0.42), (0.5, 0.68), (0.32, 0.42)], color: Palette.tomato, closed: true,
                     fill: Palette.tomato.opacity(0.4))
                line([(0.5, 0.18), (0.5, 0.68)], style: thin)
                line([(0.32, 0.42), (0.68, 0.42)], style: thin)
                smooth([(0.5, 0.68), (0.44, 0.78), (0.56, 0.84), (0.48, 0.94)], style: thin)
                dot(0.45, 0.8, 0.02, color: Palette.mustard)
                dot(0.53, 0.87, 0.02, color: Palette.sky)
            case .scooter:
                line([(0.28, 0.7), (0.6, 0.7)], color: Palette.grape,
                     style: StrokeStyle(lineWidth: lw * 1.6, lineCap: .round, lineJoin: .round))
                line([(0.62, 0.7), (0.7, 0.28)], color: Palette.grape)
                line([(0.58, 0.28), (0.82, 0.28)], color: Palette.grape)
                oval(0.28, 0.78, 0.07, 0.07, color: Palette.ink)
                oval(0.66, 0.78, 0.07, 0.07, color: Palette.ink)
            case .coffeeMug:
                rect(0.32, 0.42, 0.34, 0.38, 0.08, fill: Palette.card)
                arc(0.66, 0.58, 0.1, -0.5 * pi, 0.5 * pi)
                line([(0.32, 0.48), (0.66, 0.48)], style: thin)
                smooth([(0.44, 0.36), (0.48, 0.3), (0.44, 0.24)], color: Palette.inkFaint, style: thin)
                smooth([(0.56, 0.36), (0.52, 0.3), (0.56, 0.24)], color: Palette.inkFaint, style: thin)
            case .trainTicket:
                rect(0.16, 0.4, 0.68, 0.28, 0.03, fill: Palette.mustard.opacity(0.3))
                dot(0.62, 0.44, 0.008)
                dot(0.62, 0.5, 0.008)
                dot(0.62, 0.56, 0.008)
                dot(0.62, 0.62, 0.008)
                line([(0.24, 0.5), (0.5, 0.5)], style: thin)
                line([(0.24, 0.58), (0.44, 0.58)], style: thin)
                oval(0.72, 0.54, 0.04, 0.05, color: Palette.ink, style: thin)
            case .picnicBlanket:
                line([(0.16, 0.44), (0.84, 0.44), (0.74, 0.8), (0.26, 0.8)], closed: true,
                     fill: Palette.tomato.opacity(0.2))
                line([(0.4, 0.44), (0.36, 0.8)], color: Palette.tomato, style: thin)
                line([(0.6, 0.44), (0.64, 0.8)], color: Palette.tomato, style: thin)
                line([(0.2, 0.56), (0.8, 0.56)], color: Palette.tomato, style: thin)
                line([(0.18, 0.68), (0.82, 0.68)], color: Palette.tomato, style: thin)
            case .deskFan:
                oval(0.5, 0.42, 0.28, 0.28, color: Palette.sky)
                smooth([(0.5, 0.42), (0.4, 0.24), (0.56, 0.3)], closed: true,
                       fill: Palette.sky.opacity(0.3), color: Palette.sky)
                smooth([(0.5, 0.42), (0.7, 0.36), (0.62, 0.52)], closed: true,
                       fill: Palette.sky.opacity(0.3), color: Palette.sky)
                smooth([(0.5, 0.42), (0.42, 0.62), (0.36, 0.46)], closed: true,
                       fill: Palette.sky.opacity(0.3), color: Palette.sky)
                dot(0.5, 0.42, 0.035)
                line([(0.5, 0.7), (0.5, 0.82)])
                line([(0.38, 0.84), (0.62, 0.84)])
            case .magnifyingGlass:
                oval(0.44, 0.42, 0.22, 0.22, fill: Palette.sky.opacity(0.15), color: Palette.sky)
                line([(0.6, 0.58), (0.82, 0.82)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.7, lineCap: .round, lineJoin: .round))
                line([(0.36, 0.34), (0.4, 0.44)], style: thin)
            case .showerCurtain:
                line([(0.14, 0.24), (0.86, 0.24)])
                dot(0.26, 0.24, 0.018)
                dot(0.42, 0.24, 0.018)
                dot(0.58, 0.24, 0.018)
                dot(0.74, 0.24, 0.018)
                line([(0.24, 0.28), (0.24, 0.76)], color: Palette.sky, style: thin)
                line([(0.42, 0.28), (0.42, 0.78)], color: Palette.sky, style: thin)
                line([(0.6, 0.28), (0.6, 0.78)], color: Palette.sky, style: thin)
                smooth([(0.18, 0.78), (0.32, 0.82), (0.46, 0.78), (0.6, 0.82), (0.74, 0.78), (0.82, 0.8)],
                       color: Palette.sky)
            case .toyCar:
                smooth([(0.16, 0.6), (0.2, 0.5), (0.34, 0.5), (0.42, 0.4),
                        (0.6, 0.4), (0.68, 0.5), (0.82, 0.52), (0.84, 0.6)],
                       closed: true, fill: Palette.tomato.opacity(0.45), color: Palette.tomato)
                line([(0.44, 0.42), (0.42, 0.5), (0.56, 0.5), (0.58, 0.42)], closed: true,
                     fill: Palette.sky.opacity(0.3))
                dot(0.32, 0.64, 0.07, color: Palette.ink)
                dot(0.66, 0.64, 0.07, color: Palette.ink)
                dot(0.82, 0.55, 0.02, color: Palette.mustard)
            case .rainBarrel:
                rect(0.32, 0.4, 0.36, 0.44, 0.06, fill: Palette.sky.opacity(0.2))
                oval(0.5, 0.4, 0.18, 0.05, fill: Palette.sky.opacity(0.3))
                line([(0.32, 0.56), (0.68, 0.56)], style: thin)
                line([(0.32, 0.7), (0.68, 0.7)], style: thin)
                line([(0.4, 0.2), (0.38, 0.32)], color: Palette.sky, style: thin)
                line([(0.5, 0.16), (0.48, 0.3)], color: Palette.sky, style: thin)
                line([(0.6, 0.2), (0.58, 0.32)], color: Palette.sky, style: thin)

            case .stickyNote:
                rect(0.24, 0.26, 0.52, 0.52, 0.02, fill: Palette.mustard.opacity(0.4))
                smooth([(0.6, 0.78), (0.76, 0.62), (0.76, 0.78)], closed: true,
                       fill: Palette.mustard.opacity(0.65), color: Palette.mustard)
                line([(0.34, 0.4), (0.66, 0.4)], style: thin)
                line([(0.34, 0.5), (0.62, 0.5)], style: thin)
                line([(0.34, 0.6), (0.5, 0.6)], style: thin)
            case .safetyPin:
                line([(0.28, 0.42), (0.74, 0.42)], color: Palette.silver)
                smooth([(0.7, 0.36), (0.8, 0.42), (0.7, 0.48)], color: Palette.silver)
                smooth([(0.72, 0.46), (0.5, 0.6), (0.34, 0.6)], color: Palette.silver)
                oval(0.28, 0.56, 0.07, 0.07, color: Palette.silver)
            case .marshmallow:
                line([(0.16, 0.82), (0.56, 0.5)], color: Palette.bronze,
                     style: StrokeStyle(lineWidth: lw * 0.8, lineCap: .round, lineJoin: .round))
                rect(0.52, 0.4, 0.24, 0.22, 0.1, fill: Palette.cream, color: Palette.inkSoft)
                dot(0.6, 0.46, 0.02, color: Palette.bronze)
                dot(0.68, 0.53, 0.02, color: Palette.bronze)
            case .hulaHoop:
                oval(0.5, 0.5, 0.2, 0.38, color: Palette.tomato)
                oval(0.5, 0.5, 0.15, 0.33, color: Palette.mustard, style: thin)
            case .fryingPan:
                oval(0.42, 0.52, 0.26, 0.26, fill: Palette.ink.opacity(0.12), color: Palette.ink)
                line([(0.66, 0.44), (0.92, 0.3)], color: Palette.ink,
                     style: StrokeStyle(lineWidth: lw * 1.7, lineCap: .round, lineJoin: .round))
                oval(0.42, 0.52, 0.13, 0.12, fill: Palette.card, color: Palette.mustard)
                dot(0.42, 0.52, 0.05, color: Palette.mustard)
            case .museumMap:
                line([(0.16, 0.34), (0.4, 0.28), (0.6, 0.34), (0.84, 0.28),
                      (0.84, 0.7), (0.6, 0.76), (0.4, 0.7), (0.16, 0.76)], closed: true,
                     fill: Palette.leaf.opacity(0.2))
                line([(0.4, 0.28), (0.4, 0.7)], style: thin)
                line([(0.6, 0.34), (0.6, 0.76)], style: thin)
                smooth([(0.26, 0.5), (0.46, 0.44), (0.54, 0.58), (0.72, 0.5)],
                       color: Palette.tomato, style: thin)
                dot(0.72, 0.5, 0.03, color: Palette.tomato)
            case .hotelKeycard:
                rect(0.2, 0.34, 0.6, 0.4, 0.05, fill: Palette.sky.opacity(0.3))
                rect(0.2, 0.4, 0.6, 0.07, 0.005, fill: Palette.ink.opacity(0.5))
                rect(0.3, 0.56, 0.12, 0.1, 0.02, fill: Palette.mustard.opacity(0.6))
                arc(0.66, 0.61, 0.05, -0.55 * pi, 0.05 * pi, color: Palette.sky, style: thin)
                arc(0.66, 0.61, 0.09, -0.55 * pi, 0.05 * pi, color: Palette.sky, style: thin)
            case .snowShovel:
                line([(0.6, 0.18), (0.42, 0.62)], color: Palette.sky)
                arc(0.6, 0.18, 0.06, pi, 2 * pi, color: Palette.sky, style: thin)
                line([(0.24, 0.6), (0.52, 0.56), (0.58, 0.74), (0.3, 0.82)], color: Palette.sky,
                     closed: true, fill: Palette.sky.opacity(0.3))
                dot(0.4, 0.68, 0.014, color: Palette.sky)
            case .iceTray:
                rect(0.16, 0.36, 0.68, 0.32, 0.04, fill: Palette.sky.opacity(0.2))
                line([(0.33, 0.36), (0.33, 0.68)], style: thin)
                line([(0.5, 0.36), (0.5, 0.68)], style: thin)
                line([(0.67, 0.36), (0.67, 0.68)], style: thin)
                line([(0.16, 0.52), (0.84, 0.52)], style: thin)
                rect(0.2, 0.4, 0.09, 0.09, 0.01, fill: Palette.sky.opacity(0.35))
            case .recordPlayer:
                rect(0.18, 0.4, 0.64, 0.4, 0.06, fill: Palette.ink.opacity(0.15))
                oval(0.44, 0.6, 0.2, 0.2, fill: Palette.ink.opacity(0.4), color: Palette.ink)
                oval(0.44, 0.6, 0.06, 0.06, fill: Palette.tomato.opacity(0.6), color: Palette.tomato)
                dot(0.44, 0.6, 0.012, color: Palette.cream)
                line([(0.72, 0.46), (0.56, 0.58)], color: Palette.silver)
                dot(0.73, 0.45, 0.03, color: Palette.silver)

            case .gardenGnome:
                smooth([(0.5, 0.18), (0.66, 0.5), (0.34, 0.5)], closed: true,
                       fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                oval(0.5, 0.56, 0.12, 0.1, fill: Palette.card)
                smooth([(0.38, 0.56), (0.5, 0.82), (0.62, 0.56)], closed: true,
                       fill: Palette.cream, color: Palette.inkSoft)
                dot(0.5, 0.58, 0.03, color: Palette.tomato)
                dot(0.45, 0.53, 0.015)
                dot(0.55, 0.53, 0.015)
            case .tacoShell:
                smooth([(0.2, 0.66), (0.3, 0.44), (0.5, 0.36), (0.7, 0.44), (0.8, 0.66)],
                       closed: true, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                smooth([(0.24, 0.62), (0.5, 0.5), (0.76, 0.62)], color: Palette.leaf)
                dot(0.4, 0.58, 0.025, color: Palette.tomato)
                dot(0.58, 0.58, 0.025, color: Palette.tomato)
            case .poolNoodle:
                line([(0.18, 0.4), (0.5, 0.32), (0.78, 0.4)], color: Palette.sky,
                     style: StrokeStyle(lineWidth: lw * 2.2, lineCap: .round, lineJoin: .round))
                oval(0.79, 0.4, 0.05, 0.06, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                line([(0.36, 0.35), (0.34, 0.46)], style: thin)
                line([(0.52, 0.33), (0.5, 0.44)], style: thin)
            case .handMirror:
                oval(0.5, 0.38, 0.24, 0.26, fill: Palette.sky.opacity(0.2), color: Palette.grape)
                line([(0.42, 0.3), (0.5, 0.46)], style: thin)
                rect(0.44, 0.62, 0.12, 0.24, 0.05, fill: Palette.grape.opacity(0.4))
                line([(0.42, 0.62), (0.58, 0.62)])
            case .electricKettle:
                smooth([(0.32, 0.78), (0.3, 0.5), (0.4, 0.4), (0.62, 0.4), (0.7, 0.5), (0.68, 0.78)],
                       closed: true, fill: Palette.silver.opacity(0.35), color: Palette.ink)
                line([(0.7, 0.5), (0.84, 0.42)])
                arc(0.5, 0.4, 0.14, 1.05 * pi, 1.95 * pi)
                dot(0.5, 0.36, 0.03)
                rect(0.3, 0.78, 0.4, 0.06, 0.02, fill: Palette.ink.opacity(0.2))
                dot(0.4, 0.68, 0.02, color: Palette.tomato)
            case .receipt:
                rect(0.34, 0.16, 0.32, 0.58, 0.01, fill: Palette.card)
                line([(0.4, 0.28), (0.6, 0.28)], style: thin)
                line([(0.4, 0.36), (0.6, 0.36)], style: thin)
                line([(0.4, 0.48), (0.6, 0.48)], style: thin)
                line([(0.42, 0.58), (0.44, 0.68)], style: thin)
                line([(0.48, 0.58), (0.5, 0.68)], style: thin)
                line([(0.54, 0.58), (0.56, 0.68)], style: thin)
                line([(0.34, 0.74), (0.4, 0.8), (0.46, 0.74), (0.52, 0.8), (0.58, 0.74), (0.64, 0.8), (0.66, 0.74)])
            case .firstAidKit:
                rect(0.2, 0.34, 0.6, 0.46, 0.06, fill: Palette.cream)
                arc(0.5, 0.34, 0.1, pi, 2 * pi)
                rect(0.46, 0.44, 0.08, 0.26, 0.01, fill: Palette.tomato, color: Palette.tomato)
                rect(0.37, 0.53, 0.26, 0.08, 0.01, fill: Palette.tomato, color: Palette.tomato)
            case .chalkboard:
                rect(0.16, 0.24, 0.68, 0.5, 0.03, fill: Palette.mustard.opacity(0.3))
                rect(0.2, 0.28, 0.6, 0.42, 0.02, fill: Palette.ink.opacity(0.72), color: Palette.ink)
                line([(0.28, 0.4), (0.5, 0.4)], color: Palette.cream, style: thin)
                line([(0.28, 0.5), (0.6, 0.5)], color: Palette.cream, style: thin)
                line([(0.28, 0.6), (0.44, 0.6)], color: Palette.cream, style: thin)
                line([(0.2, 0.72), (0.8, 0.72)])
                line([(0.58, 0.74), (0.68, 0.74)], color: Palette.cream,
                     style: StrokeStyle(lineWidth: lw * 1.3, lineCap: .round, lineJoin: .round))
            case .mopBucket:
                line([(0.28, 0.44), (0.72, 0.44), (0.66, 0.82), (0.34, 0.82)], closed: true,
                     fill: Palette.sky.opacity(0.2))
                oval(0.5, 0.44, 0.22, 0.05, fill: Palette.sky.opacity(0.3))
                rect(0.52, 0.3, 0.24, 0.14, 0.03, fill: Palette.silver.opacity(0.4))
                line([(0.34, 0.6), (0.66, 0.6)], color: Palette.sky, style: thin)
                dot(0.38, 0.84, 0.03)
                dot(0.62, 0.84, 0.03)
            case .boardGame:
                rect(0.22, 0.32, 0.56, 0.52, 0.04, fill: Palette.leaf.opacity(0.2))
                line([(0.4, 0.32), (0.4, 0.84)], style: thin)
                line([(0.6, 0.32), (0.6, 0.84)], style: thin)
                line([(0.22, 0.49), (0.78, 0.49)], style: thin)
                line([(0.22, 0.66), (0.78, 0.66)], style: thin)
                dot(0.31, 0.41, 0.04, color: Palette.tomato)
                dot(0.69, 0.75, 0.04, color: Palette.sky)

            case .picnicCooler:
                rect(0.22, 0.46, 0.56, 0.34, 0.05, fill: Palette.sky.opacity(0.25))
                rect(0.2, 0.38, 0.6, 0.12, 0.04, fill: Palette.sky.opacity(0.4))
                line([(0.36, 0.38), (0.36, 0.32), (0.64, 0.32), (0.64, 0.38)])
                rect(0.44, 0.48, 0.12, 0.06, 0.01, fill: Palette.silver.opacity(0.6))
                line([(0.3, 0.64), (0.44, 0.64)], style: thin)
                line([(0.56, 0.64), (0.7, 0.64)], style: thin)
            case .carabiner:
                oval(0.5, 0.5, 0.18, 0.3, color: Palette.silver,
                     style: StrokeStyle(lineWidth: lw * 1.2, lineCap: .round, lineJoin: .round))
                line([(0.36, 0.42), (0.42, 0.58)], color: Palette.silver, style: thin)
                dot(0.4, 0.6, 0.02, color: Palette.silver)
            case .musicBox:
                rect(0.28, 0.44, 0.44, 0.34, 0.05, fill: Palette.grape.opacity(0.3))
                rect(0.28, 0.38, 0.44, 0.08, 0.03, fill: Palette.grape.opacity(0.45))
                line([(0.72, 0.6), (0.82, 0.6)])
                line([(0.82, 0.6), (0.82, 0.68)])
                dot(0.82, 0.7, 0.025)
                dot(0.44, 0.28, 0.035, color: Palette.ink)
                line([(0.475, 0.28), (0.475, 0.16)])
                dot(0.58, 0.22, 0.03, color: Palette.ink)
                line([(0.61, 0.22), (0.61, 0.12)])
            case .breadToaster:
                smooth([(0.24, 0.8), (0.24, 0.54), (0.3, 0.46), (0.7, 0.46), (0.76, 0.54), (0.76, 0.8)],
                       closed: true, fill: Palette.silver.opacity(0.35), color: Palette.ink)
                line([(0.36, 0.48), (0.64, 0.48)], style: thin)
                smooth([(0.4, 0.48), (0.4, 0.3), (0.46, 0.24), (0.54, 0.24), (0.6, 0.3), (0.6, 0.48)],
                       closed: true, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                line([(0.76, 0.6), (0.84, 0.6)])
                dot(0.86, 0.6, 0.025)
            case .dogBowl:
                line([(0.26, 0.56), (0.74, 0.56), (0.66, 0.76), (0.34, 0.76)], closed: true,
                     fill: Palette.tomato.opacity(0.35))
                oval(0.5, 0.56, 0.24, 0.06, fill: Palette.tomato.opacity(0.5))
                dot(0.42, 0.53, 0.03, color: Palette.mustard)
                dot(0.5, 0.51, 0.03, color: Palette.mustard)
                dot(0.58, 0.53, 0.03, color: Palette.mustard)
            case .windowBlinds:
                rect(0.24, 0.2, 0.52, 0.6, 0.03, fill: Palette.card)
                rect(0.22, 0.18, 0.56, 0.08, 0.02, fill: Palette.sky.opacity(0.3))
                line([(0.26, 0.34), (0.74, 0.34)], color: Palette.inkSoft, style: thin)
                line([(0.26, 0.44), (0.74, 0.44)], color: Palette.inkSoft, style: thin)
                line([(0.26, 0.54), (0.74, 0.54)], color: Palette.inkSoft, style: thin)
                line([(0.26, 0.64), (0.74, 0.64)], color: Palette.inkSoft, style: thin)
                line([(0.72, 0.26), (0.72, 0.62)], style: thin)
                dot(0.72, 0.64, 0.02)
            case .gardenTrowel:
                rect(0.6, 0.18, 0.14, 0.22, 0.05, fill: Palette.mustard.opacity(0.4))
                line([(0.6, 0.4), (0.5, 0.5)], color: Palette.silver)
                smooth([(0.5, 0.46), (0.36, 0.62), (0.44, 0.82), (0.56, 0.78), (0.6, 0.56)],
                       closed: true, fill: Palette.silver.opacity(0.4), color: Palette.ink)
                line([(0.5, 0.52), (0.48, 0.76)], style: thin)
            case .nameTag:
                rect(0.18, 0.3, 0.64, 0.44, 0.04, fill: Palette.card)
                rect(0.18, 0.3, 0.64, 0.14, 0.04, fill: Palette.tomato.opacity(0.6), color: Palette.tomato)
                line([(0.3, 0.37), (0.7, 0.37)], color: Palette.cream, style: thin)
                line([(0.3, 0.58), (0.7, 0.58)], color: Palette.sky, style: thin)
                dot(0.5, 0.3, 0.025)
            case .bentoTray:
                rect(0.2, 0.32, 0.6, 0.44, 0.06, fill: Palette.leaf.opacity(0.2))
                line([(0.5, 0.32), (0.5, 0.76)], style: thin)
                line([(0.5, 0.54), (0.8, 0.54)], style: thin)
                oval(0.35, 0.54, 0.08, 0.08, fill: Palette.card)
                dot(0.35, 0.54, 0.03, color: Palette.tomato)
                dot(0.65, 0.43, 0.03, color: Palette.leaf)
                dot(0.65, 0.65, 0.03, color: Palette.mustard)
            case .rubberStamp:
                rect(0.4, 0.2, 0.2, 0.16, 0.06, fill: Palette.grape.opacity(0.4))
                arc(0.5, 0.2, 0.1, pi, 2 * pi, color: Palette.grape)
                rect(0.44, 0.36, 0.12, 0.08, 0.02, fill: Palette.silver.opacity(0.4))
                rect(0.32, 0.44, 0.36, 0.12, 0.03, fill: Palette.ink.opacity(0.55), color: Palette.ink)
                star(0.5, 0.72, 0.09, 0.04, fill: Palette.tomato, color: Palette.tomato)

            // MARK: Space deck

            case .airlockDoor:
                rect(0.24, 0.16, 0.52, 0.68, 0.1, fill: Palette.silver.opacity(0.3))
                oval(0.5, 0.42, 0.16, 0.16, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                dot(0.46, 0.38, 0.012, color: Palette.cream)
                dot(0.54, 0.46, 0.012, color: Palette.cream)
                dot(0.3, 0.22, 0.02); dot(0.7, 0.22, 0.02)
                dot(0.3, 0.78, 0.02); dot(0.7, 0.78, 0.02)
                oval(0.5, 0.66, 0.08, 0.08, color: Palette.silver)
                line([(0.5, 0.58), (0.5, 0.74)], style: thin)
                line([(0.42, 0.66), (0.58, 0.66)], style: thin)
            case .moonRock:
                smooth([(0.24, 0.6), (0.22, 0.44), (0.36, 0.34), (0.56, 0.32), (0.74, 0.4),
                        (0.78, 0.58), (0.66, 0.72), (0.42, 0.74), (0.28, 0.7)],
                       closed: true, fill: Palette.silver.opacity(0.4), color: Palette.ink)
                oval(0.4, 0.5, 0.06, 0.05, color: Palette.inkSoft, style: thin)
                oval(0.6, 0.56, 0.05, 0.04, color: Palette.inkSoft, style: thin)
                oval(0.52, 0.42, 0.035, 0.03, color: Palette.inkSoft, style: thin)
            case .roverWheel:
                oval(0.5, 0.5, 0.3, 0.3, fill: Palette.teal.opacity(0.18), color: Palette.ink)
                for i in 0..<10 {
                    let a = CGFloat(i) / 10 * 2 * pi
                    line([(0.5 + cos(a) * 0.3, 0.5 + sin(a) * 0.3),
                          (0.5 + cos(a) * 0.37, 0.5 + sin(a) * 0.37)], style: thin)
                }
                oval(0.5, 0.5, 0.12, 0.12, fill: Palette.silver.opacity(0.5), color: Palette.ink)
                dot(0.5, 0.5, 0.025)
            case .alienFlower:
                line([(0.5, 0.84), (0.5, 0.5)], color: Palette.leaf)
                smooth([(0.5, 0.66), (0.4, 0.62), (0.44, 0.72)], closed: true,
                       fill: Palette.leaf.opacity(0.4), color: Palette.leaf)
                for i in 0..<5 {
                    let a = -pi / 2 + CGFloat(i) / 5 * 2 * pi
                    oval(0.5 + cos(a) * 0.16, 0.42 + sin(a) * 0.16, 0.08, 0.06,
                         fill: Palette.grape.opacity(0.4), color: Palette.grape, style: thin)
                }
                oval(0.5, 0.42, 0.08, 0.08, fill: Palette.leaf.opacity(0.5), color: Palette.leaf)
                dot(0.5, 0.42, 0.03, color: Palette.ink)
                dot(0.52, 0.4, 0.012, color: Palette.cream)
            case .starMap:
                rect(0.18, 0.24, 0.64, 0.52, 0.03, fill: Palette.grape.opacity(0.22))
                line([(0.5, 0.24), (0.5, 0.76)], style: thin)
                line([(0.32, 0.4), (0.46, 0.34), (0.6, 0.46), (0.7, 0.6)], color: Palette.mustard, style: thin)
                dot(0.32, 0.4, 0.02, color: Palette.mustard)
                dot(0.46, 0.34, 0.02, color: Palette.mustard)
                dot(0.6, 0.46, 0.02, color: Palette.mustard)
                dot(0.7, 0.6, 0.02, color: Palette.mustard)
                dot(0.28, 0.62, 0.014, color: Palette.cream)
            case .cometScoop:
                line([(0.2, 0.82), (0.5, 0.52)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.6, lineCap: .round, lineJoin: .round))
                arc(0.56, 0.46, 0.16, 0, pi, color: Palette.silver)
                line([(0.4, 0.46), (0.72, 0.46)], color: Palette.silver, style: thin)
                dot(0.68, 0.3, 0.05, color: Palette.sky)
                line([(0.68, 0.3), (0.82, 0.16)], color: Palette.sky, style: thin)
                line([(0.68, 0.3), (0.84, 0.24)], color: Palette.sky, style: thin)
            case .gravityBoots:
                smooth([(0.3, 0.3), (0.48, 0.28), (0.5, 0.5), (0.68, 0.56), (0.68, 0.7), (0.28, 0.7)],
                       closed: true, fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                rect(0.26, 0.7, 0.44, 0.08, 0.02, fill: Palette.ink.opacity(0.45))
                line([(0.36, 0.38), (0.46, 0.42)], style: thin)
                line([(0.34, 0.8), (0.34, 0.9)], color: Palette.mustard, style: thin)
                line([(0.5, 0.8), (0.5, 0.92)], color: Palette.mustard, style: thin)
                line([(0.62, 0.8), (0.62, 0.9)], color: Palette.mustard, style: thin)
            case .plasmaLantern:
                arc(0.5, 0.24, 0.12, pi, 2 * pi)
                rect(0.4, 0.24, 0.2, 0.08, 0.03, fill: Palette.silver.opacity(0.5))
                oval(0.5, 0.52, 0.2, 0.24, fill: Palette.grape.opacity(0.28), color: Palette.grape)
                line([(0.44, 0.44), (0.52, 0.54), (0.46, 0.6), (0.56, 0.66)], color: Palette.sky, style: thin)
                dot(0.5, 0.52, 0.045, color: Palette.grape)
                rect(0.4, 0.72, 0.2, 0.08, 0.02, fill: Palette.silver.opacity(0.5))
            case .meteorJar:
                rect(0.32, 0.34, 0.36, 0.44, 0.08, fill: Palette.sky.opacity(0.18))
                rect(0.34, 0.28, 0.32, 0.08, 0.03, fill: Palette.silver.opacity(0.5))
                smooth([(0.42, 0.58), (0.5, 0.5), (0.6, 0.56), (0.58, 0.66), (0.46, 0.68)],
                       closed: true, fill: Palette.mustard.opacity(0.6), color: Palette.bronze)
                line([(0.44, 0.44), (0.44, 0.5)], color: Palette.mustard, style: thin)
                line([(0.41, 0.47), (0.47, 0.47)], color: Palette.mustard, style: thin)
            case .rocketSeat:
                smooth([(0.3, 0.7), (0.3, 0.4), (0.4, 0.3), (0.5, 0.38), (0.5, 0.7)],
                       closed: true, fill: Palette.tomato.opacity(0.35), color: Palette.tomato)
                rect(0.28, 0.66, 0.42, 0.12, 0.04, fill: Palette.tomato.opacity(0.3))
                line([(0.36, 0.4), (0.46, 0.66)], color: Palette.cream, style: thin)
                line([(0.4, 0.34), (0.34, 0.5)], color: Palette.cream, style: thin)
            case .spaceHelmet:
                oval(0.5, 0.5, 0.28, 0.28, fill: Palette.silver.opacity(0.22), color: Palette.ink)
                smooth([(0.3, 0.5), (0.36, 0.4), (0.64, 0.4), (0.7, 0.5), (0.64, 0.6), (0.36, 0.6)],
                       closed: true, fill: Palette.sky.opacity(0.35), color: Palette.sky)
                line([(0.4, 0.46), (0.5, 0.44)], color: Palette.cream, style: thin)
                rect(0.36, 0.72, 0.28, 0.08, 0.02, fill: Palette.silver.opacity(0.5))
                line([(0.68, 0.28), (0.74, 0.2)], style: thin)
                dot(0.75, 0.19, 0.02, color: Palette.tomato)
            case .orbitRing:
                oval(0.5, 0.5, 0.34, 0.12, color: Palette.grape)
                oval(0.5, 0.5, 0.17, 0.17, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                dot(0.84, 0.5, 0.03, color: Palette.sky)
            case .satelliteDish:
                oval(0.44, 0.4, 0.2, 0.14, fill: Palette.silver.opacity(0.3), color: Palette.teal)
                line([(0.44, 0.4), (0.58, 0.28)], style: thin)
                dot(0.59, 0.27, 0.022, color: Palette.tomato)
                line([(0.44, 0.5), (0.5, 0.78)])
                line([(0.4, 0.8), (0.6, 0.8)])
            case .planetFlag:
                arc(0.5, 1.0, 0.44, pi, 2 * pi, color: Palette.leaf)
                line([(0.44, 0.74), (0.44, 0.3)])
                smooth([(0.44, 0.32), (0.66, 0.28), (0.7, 0.42), (0.44, 0.46)], closed: true,
                       fill: Palette.sky.opacity(0.4), color: Palette.sky)
                dot(0.55, 0.37, 0.02, color: Palette.mustard)
            case .vacuumTent:
                smooth([(0.18, 0.74), (0.24, 0.44), (0.5, 0.3), (0.76, 0.44), (0.82, 0.74)],
                       closed: true, fill: Palette.sky.opacity(0.2), color: Palette.sky)
                line([(0.16, 0.74), (0.84, 0.74)])
                oval(0.5, 0.62, 0.1, 0.14, fill: Palette.grape.opacity(0.3), color: Palette.grape)
                line([(0.5, 0.3), (0.5, 0.48)], style: thin)
            case .asteroidNet:
                smooth([(0.32, 0.34), (0.68, 0.34), (0.74, 0.62), (0.5, 0.76), (0.26, 0.62)],
                       closed: true, color: Palette.inkSoft)
                line([(0.4, 0.36), (0.44, 0.74)], color: Palette.inkFaint, style: thin)
                line([(0.6, 0.36), (0.56, 0.74)], color: Palette.inkFaint, style: thin)
                line([(0.3, 0.5), (0.7, 0.5)], color: Palette.inkFaint, style: thin)
                smooth([(0.42, 0.46), (0.58, 0.46), (0.6, 0.6), (0.4, 0.6)], closed: true,
                       fill: Palette.silver.opacity(0.4), color: Palette.ink)
                line([(0.32, 0.34), (0.24, 0.24)], style: thin)
                line([(0.68, 0.34), (0.76, 0.24)], style: thin)
            case .nebulaBottle:
                rect(0.34, 0.3, 0.32, 0.5, 0.1, fill: Palette.grape.opacity(0.28))
                rect(0.42, 0.2, 0.16, 0.12, 0.03, fill: Palette.mustard.opacity(0.5), color: Palette.bronze)
                arc(0.5, 0.56, 0.12, 0.2 * pi, 1.7 * pi, color: Palette.grape, style: thin)
                arc(0.5, 0.56, 0.06, 0.6 * pi, 2.0 * pi, color: Palette.sky, style: thin)
                dot(0.42, 0.44, 0.013, color: Palette.cream)
                dot(0.6, 0.66, 0.013, color: Palette.cream)
            case .solarPanel:
                line([(0.24, 0.4), (0.7, 0.28), (0.78, 0.5), (0.32, 0.62)],
                     color: Palette.sky, closed: true, fill: Palette.sky.opacity(0.3))
                line([(0.4, 0.36), (0.48, 0.58)], style: thin)
                line([(0.56, 0.32), (0.64, 0.54)], style: thin)
                line([(0.28, 0.51), (0.74, 0.39)], style: thin)
                line([(0.52, 0.55), (0.54, 0.8)])
                line([(0.44, 0.8), (0.64, 0.8)])
            case .zeroGSnack:
                rect(0.34, 0.34, 0.32, 0.4, 0.05, fill: Palette.mustard.opacity(0.35))
                line([(0.34, 0.34), (0.4, 0.28), (0.46, 0.34), (0.52, 0.28), (0.58, 0.34), (0.66, 0.3)])
                rect(0.4, 0.48, 0.2, 0.12, 0.02, fill: Palette.card)
                dot(0.24, 0.28, 0.02, color: Palette.bronze)
                dot(0.76, 0.4, 0.018, color: Palette.bronze)
                dot(0.72, 0.7, 0.015, color: Palette.bronze)
            case .portalButton:
                oval(0.5, 0.5, 0.3, 0.3, color: Palette.grape)
                oval(0.5, 0.5, 0.2, 0.2, fill: Palette.grape.opacity(0.28), color: Palette.sky)
                oval(0.5, 0.5, 0.1, 0.1, fill: Palette.tomato.opacity(0.6), color: Palette.tomato)
                dot(0.5, 0.16, 0.02, color: Palette.mustard)
                dot(0.84, 0.5, 0.02, color: Palette.mustard)
                dot(0.5, 0.84, 0.02, color: Palette.mustard)

            // MARK: Kitchen deck

            case .spatula:
                line([(0.5, 0.86), (0.5, 0.52)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.6, lineCap: .round, lineJoin: .round))
                rect(0.36, 0.26, 0.28, 0.26, 0.05, fill: Palette.silver.opacity(0.4))
                line([(0.44, 0.32), (0.44, 0.46)], style: thin)
                line([(0.5, 0.32), (0.5, 0.46)], style: thin)
                line([(0.56, 0.32), (0.56, 0.46)], style: thin)
            case .mixingBowl:
                smooth([(0.24, 0.46), (0.76, 0.46), (0.68, 0.76), (0.32, 0.76)], closed: true,
                       fill: Palette.teal.opacity(0.3), color: Palette.teal)
                oval(0.5, 0.46, 0.26, 0.06, fill: Palette.teal.opacity(0.4))
                line([(0.62, 0.5), (0.72, 0.24)], color: Palette.mustard)
                oval(0.72, 0.22, 0.06, 0.05, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
            case .rollingPin:
                rect(0.28, 0.42, 0.44, 0.16, 0.08, fill: Palette.mustard.opacity(0.4))
                rect(0.15, 0.46, 0.13, 0.08, 0.03, fill: Palette.mustard.opacity(0.55), color: Palette.bronze)
                rect(0.72, 0.46, 0.13, 0.08, 0.03, fill: Palette.mustard.opacity(0.55), color: Palette.bronze)
                line([(0.34, 0.5), (0.66, 0.5)], color: Palette.bronze, style: thin)
            case .measuringCup:
                line([(0.32, 0.34), (0.66, 0.34), (0.7, 0.78), (0.36, 0.78)], closed: true,
                     fill: Palette.sky.opacity(0.2))
                line([(0.66, 0.36), (0.78, 0.3)])
                arc(0.7, 0.56, 0.1, -0.5 * pi, 0.5 * pi)
                line([(0.4, 0.5), (0.5, 0.5)], style: thin)
                line([(0.4, 0.6), (0.48, 0.6)], style: thin)
                line([(0.4, 0.7), (0.5, 0.7)], style: thin)
            case .whisk:
                rect(0.44, 0.62, 0.12, 0.24, 0.05, fill: Palette.silver.opacity(0.4))
                smooth([(0.5, 0.62), (0.32, 0.42), (0.5, 0.18)], color: Palette.silver, style: thin)
                smooth([(0.5, 0.62), (0.68, 0.42), (0.5, 0.18)], color: Palette.silver, style: thin)
                line([(0.5, 0.62), (0.5, 0.18)], color: Palette.silver, style: thin)
                smooth([(0.5, 0.6), (0.42, 0.42), (0.5, 0.2)], color: Palette.silver, style: thin)
                smooth([(0.5, 0.6), (0.58, 0.42), (0.5, 0.2)], color: Palette.silver, style: thin)
            case .saucepan:
                rect(0.28, 0.46, 0.42, 0.3, 0.06, fill: Palette.tomato.opacity(0.4))
                oval(0.49, 0.46, 0.21, 0.05, fill: Palette.tomato.opacity(0.5))
                rect(0.7, 0.5, 0.22, 0.08, 0.04, fill: Palette.ink.opacity(0.3))
                smooth([(0.4, 0.4), (0.44, 0.32), (0.4, 0.24)], color: Palette.inkFaint, style: thin)
                smooth([(0.56, 0.4), (0.52, 0.32), (0.56, 0.24)], color: Palette.inkFaint, style: thin)
            case .cuttingBoard:
                rect(0.24, 0.34, 0.44, 0.5, 0.06, fill: Palette.mustard.opacity(0.35))
                oval(0.46, 0.42, 0.03, 0.03, color: Palette.inkSoft, style: thin)
                line([(0.3, 0.6), (0.62, 0.6)], color: Palette.bronze, style: thin)
                line([(0.6, 0.4), (0.82, 0.62)], color: Palette.silver)
                rect(0.74, 0.56, 0.12, 0.08, 0.02, fill: Palette.ink.opacity(0.3))
            case .apronPocket:
                smooth([(0.36, 0.24), (0.64, 0.24), (0.68, 0.32), (0.72, 0.78),
                        (0.28, 0.78), (0.32, 0.32)], closed: true,
                       fill: Palette.leaf.opacity(0.3), color: Palette.leaf)
                arc(0.5, 0.24, 0.1, pi, 2 * pi, style: thin)
                line([(0.34, 0.42), (0.2, 0.38)], style: thin)
                line([(0.66, 0.42), (0.8, 0.38)], style: thin)
                rect(0.4, 0.5, 0.2, 0.16, 0.02, fill: Palette.leaf.opacity(0.2))
                line([(0.5, 0.5), (0.5, 0.66)], style: thin)
            case .saltShaker:
                smooth([(0.38, 0.8), (0.36, 0.44), (0.42, 0.36), (0.58, 0.36), (0.64, 0.44), (0.62, 0.8)],
                       closed: true, fill: Palette.silver.opacity(0.25), color: Palette.ink)
                rect(0.4, 0.3, 0.2, 0.1, 0.04, fill: Palette.silver.opacity(0.5))
                dot(0.46, 0.34, 0.012); dot(0.5, 0.32, 0.012); dot(0.54, 0.34, 0.012)
                line([(0.38, 0.62), (0.62, 0.62)], style: thin)
            case .ovenMitt:
                smooth([(0.34, 0.3), (0.5, 0.26), (0.62, 0.32), (0.62, 0.48), (0.72, 0.54),
                        (0.7, 0.68), (0.34, 0.68)], closed: true,
                       fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                rect(0.32, 0.68, 0.4, 0.1, 0.03, fill: Palette.tomato.opacity(0.5))
                smooth([(0.4, 0.36), (0.4, 0.6)], color: Palette.cream, style: thin)
            case .lemonSqueezer:
                line([(0.28, 0.62), (0.72, 0.62), (0.66, 0.76), (0.34, 0.76)], closed: true,
                     fill: Palette.mustard.opacity(0.2))
                smooth([(0.5, 0.28), (0.62, 0.6), (0.38, 0.6)], closed: true,
                       fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                line([(0.5, 0.3), (0.5, 0.58)], style: thin)
                line([(0.44, 0.36), (0.44, 0.58)], style: thin)
                line([(0.56, 0.36), (0.56, 0.58)], style: thin)
            case .cupcakeTray:
                rect(0.18, 0.42, 0.64, 0.28, 0.05, fill: Palette.grape.opacity(0.2))
                oval(0.32, 0.5, 0.08, 0.06, color: Palette.grape)
                oval(0.5, 0.5, 0.08, 0.06, color: Palette.grape)
                oval(0.68, 0.5, 0.08, 0.06, color: Palette.grape)
                line([(0.18, 0.6), (0.82, 0.6)], style: thin)
            case .soupLadle:
                line([(0.56, 0.2), (0.46, 0.56)], color: Palette.teal,
                     style: StrokeStyle(lineWidth: lw * 1.4, lineCap: .round, lineJoin: .round))
                arc(0.57, 0.2, 0.04, 0.5 * pi, 1.6 * pi, color: Palette.teal, style: thin)
                smooth([(0.3, 0.56), (0.62, 0.56), (0.54, 0.78), (0.38, 0.78)], closed: true,
                       fill: Palette.teal.opacity(0.3), color: Palette.teal)
            case .dishSponge:
                rect(0.26, 0.4, 0.48, 0.12, 0.03, fill: Palette.leaf.opacity(0.5), color: Palette.leaf)
                rect(0.26, 0.5, 0.48, 0.22, 0.03, fill: Palette.mustard.opacity(0.35), color: Palette.mustard)
                dot(0.36, 0.6, 0.014, color: Palette.inkFaint)
                dot(0.5, 0.64, 0.014, color: Palette.inkFaint)
                dot(0.62, 0.58, 0.014, color: Palette.inkFaint)
                dot(0.34, 0.46, 0.018, color: Palette.sky)
            case .recipeCard:
                rect(0.2, 0.3, 0.6, 0.44, 0.03, fill: Palette.sky.opacity(0.15))
                line([(0.24, 0.42), (0.76, 0.42)], color: Palette.tomato, style: thin)
                line([(0.3, 0.37), (0.5, 0.37)])
                line([(0.28, 0.52), (0.72, 0.52)], style: thin)
                line([(0.28, 0.6), (0.66, 0.6)], style: thin)
                line([(0.28, 0.68), (0.7, 0.68)], style: thin)
            case .pepperGrinder:
                smooth([(0.38, 0.8), (0.38, 0.44), (0.42, 0.4), (0.58, 0.4), (0.62, 0.44), (0.62, 0.8)],
                       closed: true, fill: Palette.grape.opacity(0.3), color: Palette.grape)
                oval(0.5, 0.36, 0.09, 0.07, fill: Palette.grape.opacity(0.45), color: Palette.grape)
                line([(0.38, 0.56), (0.62, 0.56)], style: thin)
                line([(0.38, 0.66), (0.62, 0.66)], style: thin)
                dot(0.46, 0.87, 0.012); dot(0.54, 0.87, 0.012)
            case .cookieCutter:
                star(0.5, 0.5, 0.3, 0.14, color: Palette.tomato)
                star(0.5, 0.5, 0.25, 0.115, color: Palette.tomato)
            case .pastaStrainer:
                smooth([(0.24, 0.46), (0.76, 0.46), (0.66, 0.74), (0.34, 0.74)], closed: true,
                       fill: Palette.silver.opacity(0.3), color: Palette.ink)
                oval(0.5, 0.46, 0.26, 0.06, fill: Palette.silver.opacity(0.4))
                dot(0.42, 0.56, 0.014, color: Palette.inkFaint)
                dot(0.5, 0.6, 0.014, color: Palette.inkFaint)
                dot(0.58, 0.56, 0.014, color: Palette.inkFaint)
                dot(0.5, 0.5, 0.014, color: Palette.inkFaint)
                line([(0.24, 0.48), (0.16, 0.44)], style: thin)
                line([(0.76, 0.48), (0.84, 0.44)], style: thin)
            case .waffleIron:
                oval(0.5, 0.46, 0.28, 0.18, fill: Palette.mustard.opacity(0.3), color: Palette.ink)
                line([(0.34, 0.42), (0.66, 0.5)], style: thin)
                line([(0.34, 0.5), (0.66, 0.42)], style: thin)
                line([(0.4, 0.36), (0.44, 0.56)], style: thin)
                line([(0.6, 0.36), (0.56, 0.56)], style: thin)
                rect(0.4, 0.3, 0.2, 0.08, 0.03, fill: Palette.ink.opacity(0.3))
                dot(0.8, 0.5, 0.02)
            case .jamJar:
                rect(0.32, 0.36, 0.36, 0.44, 0.06, fill: Palette.tomato.opacity(0.3))
                rect(0.34, 0.28, 0.32, 0.1, 0.03, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                rect(0.4, 0.5, 0.2, 0.16, 0.02, fill: Palette.card)
                dot(0.5, 0.58, 0.03, color: Palette.tomato)

            // MARK: Sports deck

            case .whistle:
                smooth([(0.3, 0.44), (0.62, 0.42), (0.66, 0.56), (0.5, 0.64), (0.32, 0.6)],
                       closed: true, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                rect(0.26, 0.44, 0.08, 0.08, 0.02, fill: Palette.mustard.opacity(0.6))
                dot(0.5, 0.52, 0.03, color: Palette.ink)
                oval(0.68, 0.44, 0.04, 0.04, color: Palette.mustard)
                arc(0.74, 0.4, 0.05, -0.4 * pi, 0.4 * pi, color: Palette.mustard, style: thin)
            case .goalNet:
                line([(0.24, 0.7), (0.24, 0.34), (0.76, 0.34), (0.76, 0.7)])
                line([(0.2, 0.7), (0.8, 0.7)])
                line([(0.36, 0.34), (0.36, 0.7)], color: Palette.inkFaint, style: thin)
                line([(0.5, 0.34), (0.5, 0.7)], color: Palette.inkFaint, style: thin)
                line([(0.64, 0.34), (0.64, 0.7)], color: Palette.inkFaint, style: thin)
                line([(0.24, 0.46), (0.76, 0.46)], color: Palette.inkFaint, style: thin)
                line([(0.24, 0.58), (0.76, 0.58)], color: Palette.inkFaint, style: thin)
                dot(0.5, 0.64, 0.045, color: Palette.card)
            case .baseballGlove:
                smooth([(0.32, 0.34), (0.5, 0.28), (0.66, 0.34), (0.72, 0.5), (0.7, 0.68),
                        (0.4, 0.72), (0.28, 0.6), (0.28, 0.44)], closed: true,
                       fill: Palette.mustard.opacity(0.4), color: Palette.bronze)
                line([(0.44, 0.3), (0.44, 0.44)], style: thin)
                line([(0.54, 0.29), (0.54, 0.44)], style: thin)
                line([(0.64, 0.34), (0.62, 0.46)], style: thin)
                dot(0.5, 0.56, 0.06, color: Palette.card)
            case .tennisRacket:
                oval(0.5, 0.38, 0.2, 0.24, fill: Palette.leaf.opacity(0.18), color: Palette.leaf)
                line([(0.4, 0.3), (0.6, 0.46)], color: Palette.inkFaint, style: thin)
                line([(0.4, 0.46), (0.6, 0.3)], color: Palette.inkFaint, style: thin)
                line([(0.5, 0.2), (0.5, 0.56)], color: Palette.inkFaint, style: thin)
                line([(0.42, 0.58), (0.46, 0.68)], color: Palette.leaf)
                line([(0.58, 0.58), (0.54, 0.68)], color: Palette.leaf)
                rect(0.46, 0.68, 0.08, 0.18, 0.02, fill: Palette.leaf.opacity(0.4))
            case .scoreboard:
                rect(0.2, 0.28, 0.6, 0.4, 0.05, fill: Palette.grape.opacity(0.3))
                rect(0.26, 0.34, 0.48, 0.22, 0.02, fill: Palette.ink.opacity(0.6), color: Palette.ink)
                line([(0.34, 0.4), (0.34, 0.5)], color: Palette.cream, style: thin)
                line([(0.4, 0.4), (0.4, 0.5)], color: Palette.cream, style: thin)
                dot(0.5, 0.42, 0.012, color: Palette.cream)
                dot(0.5, 0.48, 0.012, color: Palette.cream)
                line([(0.6, 0.4), (0.6, 0.5)], color: Palette.cream, style: thin)
                line([(0.66, 0.4), (0.66, 0.5)], color: Palette.cream, style: thin)
                line([(0.34, 0.68), (0.32, 0.76)]); line([(0.66, 0.68), (0.68, 0.76)])
            case .waterBottle:
                rect(0.36, 0.34, 0.28, 0.46, 0.1, fill: Palette.sky.opacity(0.25))
                rect(0.44, 0.24, 0.12, 0.1, 0.03, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                rect(0.47, 0.18, 0.06, 0.06, 0.02, fill: Palette.tomato.opacity(0.6), color: Palette.tomato)
                rect(0.36, 0.5, 0.28, 0.14, 0.02, fill: Palette.card)
                line([(0.38, 0.6), (0.62, 0.6)], color: Palette.sky, style: thin)
            case .kneePad:
                smooth([(0.32, 0.3), (0.68, 0.3), (0.72, 0.5), (0.66, 0.72), (0.34, 0.72), (0.28, 0.5)],
                       closed: true, fill: Palette.tomato.opacity(0.35), color: Palette.tomato)
                oval(0.5, 0.5, 0.14, 0.14, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                rect(0.24, 0.4, 0.08, 0.2, 0.02, fill: Palette.ink.opacity(0.25))
                rect(0.68, 0.4, 0.08, 0.2, 0.02, fill: Palette.ink.opacity(0.25))
            case .soccerCleat:
                smooth([(0.2, 0.56), (0.26, 0.44), (0.44, 0.42), (0.66, 0.46), (0.8, 0.56),
                        (0.8, 0.64), (0.2, 0.64)], closed: true,
                       fill: Palette.silver.opacity(0.3), color: Palette.ink)
                line([(0.4, 0.48), (0.5, 0.46)], style: thin)
                line([(0.42, 0.52), (0.52, 0.5)], style: thin)
                dot(0.3, 0.68, 0.02); dot(0.45, 0.7, 0.02); dot(0.6, 0.7, 0.02); dot(0.74, 0.68, 0.02)
            case .basketballHoop:
                rect(0.3, 0.24, 0.4, 0.28, 0.03, fill: Palette.card)
                rect(0.42, 0.32, 0.16, 0.12, 0.01, color: Palette.tomato, style: thin)
                arc(0.5, 0.54, 0.12, 0, pi, color: Palette.tomato)
                line([(0.4, 0.56), (0.44, 0.7)], color: Palette.inkFaint, style: thin)
                line([(0.5, 0.56), (0.5, 0.72)], color: Palette.inkFaint, style: thin)
                line([(0.6, 0.56), (0.56, 0.7)], color: Palette.inkFaint, style: thin)
                line([(0.7, 0.38), (0.7, 0.78)], style: thin)
            case .hockeyPuck:
                oval(0.5, 0.6, 0.24, 0.09, fill: Palette.ink.opacity(0.8), color: Palette.ink)
                line([(0.26, 0.44), (0.26, 0.6)], color: Palette.ink)
                line([(0.74, 0.44), (0.74, 0.6)], color: Palette.ink)
                oval(0.5, 0.44, 0.24, 0.09, fill: Palette.ink.opacity(0.55), color: Palette.ink)
                line([(0.4, 0.44), (0.5, 0.44)], color: Palette.cream, style: thin)
            case .bikeHelmet:
                smooth([(0.2, 0.6), (0.28, 0.4), (0.5, 0.32), (0.72, 0.4), (0.8, 0.6)],
                       closed: true, fill: Palette.teal.opacity(0.35), color: Palette.teal)
                line([(0.38, 0.44), (0.4, 0.58)], style: thin)
                line([(0.5, 0.4), (0.5, 0.58)], style: thin)
                line([(0.62, 0.44), (0.6, 0.58)], style: thin)
                line([(0.2, 0.6), (0.8, 0.6)])
            case .refereeFlag:
                line([(0.34, 0.16), (0.34, 0.84)])
                rect(0.34, 0.2, 0.34, 0.26, 0.01, fill: Palette.mustard.opacity(0.4), color: Palette.mustard)
                rect(0.34, 0.2, 0.17, 0.13, 0.0, fill: Palette.mustard.opacity(0.55))
                rect(0.51, 0.33, 0.17, 0.13, 0.0, fill: Palette.mustard.opacity(0.55))
                line([(0.3, 0.8), (0.38, 0.8)],
                     style: StrokeStyle(lineWidth: lw * 1.6, lineCap: .round, lineJoin: .round))
            case .battingTee:
                oval(0.5, 0.8, 0.14, 0.04, fill: Palette.leaf.opacity(0.3))
                line([(0.32, 0.8), (0.68, 0.8)])
                rect(0.46, 0.4, 0.08, 0.42, 0.03, fill: Palette.leaf.opacity(0.4))
                arc(0.5, 0.4, 0.08, pi, 2 * pi, color: Palette.leaf)
                dot(0.5, 0.32, 0.08, color: Palette.card)
                line([(0.46, 0.3), (0.5, 0.34)], color: Palette.tomato, style: thin)
            case .foamFinger:
                smooth([(0.4, 0.8), (0.4, 0.44), (0.36, 0.36), (0.44, 0.32), (0.5, 0.4),
                        (0.5, 0.5), (0.58, 0.5), (0.58, 0.56), (0.62, 0.8)], closed: true,
                       fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                line([(0.45, 0.6), (0.45, 0.74)], color: Palette.cream,
                     style: StrokeStyle(lineWidth: lw * 1.1, lineCap: .round, lineJoin: .round))
            case .stopwatchStrap:
                rect(0.42, 0.24, 0.16, 0.12, 0.03, fill: Palette.sky.opacity(0.3))
                rect(0.42, 0.62, 0.16, 0.16, 0.03, fill: Palette.sky.opacity(0.3))
                oval(0.5, 0.48, 0.2, 0.2, fill: Palette.card, color: Palette.sky)
                line([(0.5, 0.24), (0.5, 0.18)]); dot(0.5, 0.17, 0.02)
                line([(0.5, 0.48), (0.5, 0.36)], style: thin)
                line([(0.5, 0.48), (0.6, 0.52)], color: Palette.tomato, style: thin)
                dot(0.5, 0.48, 0.02, color: Palette.tomato)
            case .skateRamp:
                smooth([(0.2, 0.74), (0.42, 0.72), (0.62, 0.6), (0.72, 0.36), (0.72, 0.74)],
                       closed: true, fill: Palette.grape.opacity(0.25), color: Palette.grape)
                line([(0.16, 0.74), (0.84, 0.74)])
                line([(0.72, 0.36), (0.84, 0.36)], color: Palette.grape)
                dot(0.72, 0.36, 0.025, color: Palette.tomato)
            case .dumbbell:
                rect(0.36, 0.46, 0.28, 0.08, 0.02, fill: Palette.ink.opacity(0.3))
                rect(0.22, 0.38, 0.09, 0.24, 0.03, fill: Palette.silver.opacity(0.5), color: Palette.ink)
                rect(0.31, 0.41, 0.06, 0.18, 0.02, fill: Palette.silver.opacity(0.4), color: Palette.ink)
                rect(0.69, 0.38, 0.09, 0.24, 0.03, fill: Palette.silver.opacity(0.5), color: Palette.ink)
                rect(0.63, 0.41, 0.06, 0.18, 0.02, fill: Palette.silver.opacity(0.4), color: Palette.ink)
            case .teamJersey:
                smooth([(0.32, 0.36), (0.42, 0.28), (0.58, 0.28), (0.68, 0.36), (0.78, 0.46),
                        (0.68, 0.52), (0.64, 0.46), (0.64, 0.78), (0.36, 0.78), (0.36, 0.46),
                        (0.32, 0.52), (0.22, 0.46)], closed: true,
                       fill: Palette.leaf.opacity(0.35), color: Palette.leaf)
                smooth([(0.44, 0.3), (0.5, 0.36), (0.56, 0.3)], style: thin)
                line([(0.44, 0.52), (0.58, 0.52), (0.5, 0.7)], color: Palette.cream)
            case .swimGoggles:
                oval(0.36, 0.48, 0.13, 0.11, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                oval(0.64, 0.48, 0.13, 0.11, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                line([(0.49, 0.48), (0.51, 0.48)])
                line([(0.23, 0.46), (0.12, 0.42)], color: Palette.tomato, style: thin)
                line([(0.77, 0.46), (0.88, 0.42)], color: Palette.tomato, style: thin)
            case .medalRibbon:
                line([(0.4, 0.2), (0.44, 0.46)], color: Palette.sky)
                line([(0.6, 0.2), (0.56, 0.46)], color: Palette.tomato)
                line([(0.4, 0.2), (0.6, 0.2)])
                oval(0.5, 0.62, 0.18, 0.18, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                star(0.5, 0.62, 0.1, 0.045, fill: Palette.mustard, color: Palette.mustard)

            // MARK: School deck

            case .glueStick:
                rect(0.4, 0.36, 0.2, 0.44, 0.04, fill: Palette.tomato.opacity(0.35))
                rect(0.4, 0.24, 0.2, 0.14, 0.04, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                oval(0.5, 0.34, 0.08, 0.04, fill: Palette.cream, color: Palette.inkSoft)
                rect(0.42, 0.5, 0.16, 0.2, 0.02, fill: Palette.card)
            case .ruler:
                rect(0.14, 0.42, 0.72, 0.16, 0.02, fill: Palette.mustard.opacity(0.4))
                for i in 0..<8 {
                    let x = 0.2 + CGFloat(i) * 0.08
                    line([(x, 0.42), (x, 0.48)], style: thin)
                }
                line([(0.14, 0.52), (0.86, 0.52)], color: Palette.bronze, style: thin)
            case .lockerDoor:
                rect(0.32, 0.16, 0.36, 0.68, 0.03, fill: Palette.teal.opacity(0.3))
                line([(0.38, 0.26), (0.62, 0.26)], style: thin)
                line([(0.38, 0.3), (0.62, 0.3)], style: thin)
                line([(0.38, 0.34), (0.62, 0.34)], style: thin)
                oval(0.5, 0.52, 0.06, 0.06, fill: Palette.silver.opacity(0.5), color: Palette.ink)
                rect(0.37, 0.58, 0.05, 0.12, 0.02, fill: Palette.ink.opacity(0.3))
            case .whiteboardEraser:
                rect(0.26, 0.4, 0.48, 0.14, 0.04, fill: Palette.sky.opacity(0.3), color: Palette.ink)
                rect(0.24, 0.52, 0.52, 0.12, 0.02, fill: Palette.silver.opacity(0.3), color: Palette.inkSoft)
                line([(0.3, 0.66), (0.44, 0.7)], color: Palette.inkFaint, style: thin)
                line([(0.5, 0.68), (0.64, 0.66)], color: Palette.inkFaint, style: thin)
            case .cafeteriaTray:
                rect(0.18, 0.34, 0.64, 0.4, 0.05, fill: Palette.leaf.opacity(0.2))
                line([(0.5, 0.34), (0.5, 0.74)], style: thin)
                line([(0.5, 0.54), (0.82, 0.54)], style: thin)
                rect(0.6, 0.4, 0.12, 0.12, 0.01, fill: Palette.sky.opacity(0.3))
                dot(0.34, 0.54, 0.05, color: Palette.mustard)
            case .hallPass:
                line([(0.38, 0.14), (0.5, 0.34)], color: Palette.sky, style: thin)
                line([(0.62, 0.14), (0.5, 0.34)], color: Palette.sky, style: thin)
                rect(0.34, 0.34, 0.32, 0.44, 0.03, fill: Palette.sky.opacity(0.25))
                rect(0.46, 0.3, 0.08, 0.06, 0.01, fill: Palette.silver.opacity(0.5))
                line([(0.4, 0.46), (0.6, 0.46)], color: Palette.sky)
                rect(0.4, 0.54, 0.14, 0.16, 0.02, fill: Palette.card)
                line([(0.58, 0.56), (0.64, 0.56)], style: thin)
                line([(0.58, 0.64), (0.64, 0.64)], style: thin)
            case .pencilCase:
                rect(0.2, 0.4, 0.6, 0.3, 0.12, fill: Palette.grape.opacity(0.3))
                line([(0.22, 0.46), (0.78, 0.46)], style: thin)
                dot(0.72, 0.46, 0.02)
                line([(0.6, 0.46), (0.72, 0.34)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.4, lineCap: .round, lineJoin: .round))
                smooth([(0.7, 0.36), (0.74, 0.32), (0.74, 0.37)], closed: true,
                       fill: Palette.ink, color: Palette.ink)
            case .binderClip:
                line([(0.34, 0.5), (0.66, 0.5), (0.6, 0.74), (0.4, 0.74)], color: Palette.ink,
                     closed: true, fill: Palette.ink.opacity(0.5))
                line([(0.4, 0.5), (0.34, 0.34), (0.42, 0.34)], color: Palette.silver, style: thin)
                line([(0.6, 0.5), (0.66, 0.34), (0.58, 0.34)], color: Palette.silver, style: thin)
            case .notebookSpiral:
                rect(0.3, 0.24, 0.44, 0.56, 0.03, fill: Palette.tomato.opacity(0.3))
                for i in 0..<6 {
                    let y = 0.3 + CGFloat(i) * 0.09
                    oval(0.3, y, 0.03, 0.02, color: Palette.silver, style: thin)
                }
                line([(0.42, 0.4), (0.66, 0.4)], style: thin)
                line([(0.42, 0.52), (0.66, 0.52)], style: thin)
                line([(0.42, 0.64), (0.6, 0.64)], style: thin)
            case .indexCard:
                rect(0.2, 0.3, 0.6, 0.44, 0.02, fill: Palette.card)
                line([(0.24, 0.42), (0.76, 0.42)], color: Palette.tomato, style: thin)
                line([(0.32, 0.44), (0.32, 0.72)], color: Palette.tomato, style: thin)
                line([(0.36, 0.52), (0.72, 0.52)], color: Palette.sky, style: thin)
                line([(0.36, 0.6), (0.72, 0.6)], color: Palette.sky, style: thin)
                line([(0.36, 0.68), (0.66, 0.68)], color: Palette.sky, style: thin)
            case .crayonBox:
                rect(0.24, 0.42, 0.52, 0.36, 0.03, fill: Palette.sky.opacity(0.25))
                rect(0.3, 0.26, 0.06, 0.18, 0.01, fill: Palette.tomato.opacity(0.6), color: Palette.tomato)
                rect(0.4, 0.24, 0.06, 0.2, 0.01, fill: Palette.mustard.opacity(0.6), color: Palette.mustard)
                rect(0.5, 0.26, 0.06, 0.18, 0.01, fill: Palette.leaf.opacity(0.6), color: Palette.leaf)
                rect(0.6, 0.24, 0.06, 0.2, 0.01, fill: Palette.grape.opacity(0.6), color: Palette.grape)
                line([(0.3, 0.6), (0.7, 0.6)], style: thin)
            case .lunchTray:
                rect(0.2, 0.36, 0.6, 0.36, 0.05, fill: Palette.teal.opacity(0.2))
                line([(0.4, 0.36), (0.4, 0.72)], style: thin)
                line([(0.6, 0.36), (0.6, 0.72)], style: thin)
                oval(0.3, 0.52, 0.07, 0.05, color: Palette.sky)
                line([(0.66, 0.52), (0.7, 0.46), (0.74, 0.52)], color: Palette.mustard, style: thin)
                dot(0.5, 0.54, 0.04, color: Palette.tomato)
            case .libraryStamp:
                rect(0.42, 0.2, 0.16, 0.14, 0.05, fill: Palette.grape.opacity(0.4))
                arc(0.5, 0.2, 0.09, pi, 2 * pi, color: Palette.grape)
                line([(0.34, 0.34), (0.66, 0.34), (0.72, 0.58), (0.28, 0.58)],
                     color: Palette.ink, closed: true, fill: Palette.ink.opacity(0.18))
                rect(0.3, 0.58, 0.4, 0.06, 0.02, fill: Palette.ink.opacity(0.5))
                rect(0.4, 0.7, 0.2, 0.08, 0.02, color: Palette.tomato, style: thin)
                line([(0.44, 0.74), (0.56, 0.74)], color: Palette.tomato, style: thin)
            case .deskBell:
                smooth([(0.28, 0.6), (0.32, 0.4), (0.5, 0.32), (0.68, 0.4), (0.72, 0.6)],
                       closed: true, fill: Palette.mustard.opacity(0.45), color: Palette.mustard)
                line([(0.5, 0.32), (0.5, 0.28)])
                dot(0.5, 0.27, 0.035, color: Palette.tomato)
                rect(0.24, 0.6, 0.52, 0.1, 0.03, fill: Palette.mustard.opacity(0.5))
                line([(0.4, 0.46), (0.44, 0.54)], color: Palette.cream, style: thin)
            case .protractor:
                arc(0.5, 0.66, 0.34, pi, 2 * pi, color: Palette.leaf)
                line([(0.16, 0.66), (0.84, 0.66)], color: Palette.leaf)
                arc(0.5, 0.66, 0.2, pi, 2 * pi, color: Palette.leaf, style: thin)
                line([(0.5, 0.32), (0.5, 0.4)], style: thin)
                line([(0.29, 0.42), (0.34, 0.48)], style: thin)
                line([(0.71, 0.42), (0.66, 0.48)], style: thin)
                dot(0.5, 0.66, 0.02, color: Palette.inkSoft)
            case .scienceGoggles:
                smooth([(0.24, 0.5), (0.3, 0.4), (0.7, 0.4), (0.76, 0.5), (0.7, 0.62), (0.3, 0.62)],
                       closed: true, fill: Palette.sky.opacity(0.2), color: Palette.ink)
                oval(0.4, 0.51, 0.08, 0.07, color: Palette.sky)
                oval(0.6, 0.51, 0.08, 0.07, color: Palette.sky)
                dot(0.26, 0.46, 0.012); dot(0.74, 0.46, 0.012)
                line([(0.24, 0.52), (0.12, 0.48)], color: Palette.tomato, style: thin)
                line([(0.76, 0.52), (0.88, 0.48)], color: Palette.tomato, style: thin)
            case .chalkHolder:
                rect(0.44, 0.3, 0.12, 0.28, 0.03, fill: Palette.silver.opacity(0.4))
                line([(0.44, 0.4), (0.56, 0.4)], style: thin)
                line([(0.44, 0.46), (0.56, 0.46)], style: thin)
                rect(0.46, 0.56, 0.08, 0.24, 0.01, fill: Palette.cream, color: Palette.inkSoft)
                dot(0.5, 0.85, 0.012, color: Palette.inkFaint)
            case .gymWhistle:
                smooth([(0.3, 0.16), (0.4, 0.34), (0.5, 0.4), (0.6, 0.34), (0.7, 0.16)],
                       color: Palette.tomato, style: thin)
                smooth([(0.34, 0.46), (0.62, 0.44), (0.66, 0.58), (0.5, 0.66), (0.32, 0.62)],
                       closed: true, fill: Palette.silver.opacity(0.4), color: Palette.ink)
                dot(0.5, 0.54, 0.03, color: Palette.ink)
                oval(0.64, 0.46, 0.035, 0.035, color: Palette.silver)
            case .bookCart:
                rect(0.24, 0.3, 0.5, 0.44, 0.03, fill: Palette.teal.opacity(0.2))
                line([(0.24, 0.46), (0.74, 0.46)], style: thin)
                line([(0.24, 0.6), (0.74, 0.6)], style: thin)
                rect(0.3, 0.34, 0.05, 0.1, 0.01, fill: Palette.tomato.opacity(0.7), color: Palette.tomato)
                rect(0.36, 0.34, 0.05, 0.1, 0.01, fill: Palette.mustard.opacity(0.7), color: Palette.mustard)
                rect(0.42, 0.34, 0.05, 0.1, 0.01, fill: Palette.sky.opacity(0.7), color: Palette.sky)
                line([(0.74, 0.3), (0.82, 0.3), (0.82, 0.5)], style: thin)
                dot(0.32, 0.78, 0.05, color: Palette.ink)
                dot(0.66, 0.78, 0.05, color: Palette.ink)
            case .stickyBookmark:
                rect(0.28, 0.22, 0.4, 0.56, 0.02, fill: Palette.card)
                line([(0.34, 0.36), (0.6, 0.36)], style: thin)
                line([(0.34, 0.44), (0.6, 0.44)], style: thin)
                line([(0.34, 0.52), (0.56, 0.52)], style: thin)
                rect(0.66, 0.3, 0.1, 0.06, 0.01, fill: Palette.tomato.opacity(0.7), color: Palette.tomato)
                rect(0.66, 0.42, 0.1, 0.06, 0.01, fill: Palette.leaf.opacity(0.7), color: Palette.leaf)
                rect(0.66, 0.54, 0.1, 0.06, 0.01, fill: Palette.mustard.opacity(0.7), color: Palette.mustard)

            // MARK: Household Items deck additions

            case .extensionCord:
                rect(0.14, 0.28, 0.12, 0.14, 0.03, fill: Palette.teal.opacity(0.4), color: Palette.teal)
                line([(0.18, 0.28), (0.18, 0.22)]); line([(0.22, 0.28), (0.22, 0.22)])
                smooth([(0.2, 0.42), (0.4, 0.5), (0.3, 0.66), (0.5, 0.74), (0.64, 0.64)], color: Palette.teal)
                rect(0.62, 0.56, 0.16, 0.16, 0.03, fill: Palette.teal.opacity(0.4), color: Palette.teal)
                dot(0.67, 0.63, 0.014); dot(0.73, 0.63, 0.014)
            case .tapeRoll:
                oval(0.46, 0.52, 0.24, 0.24, fill: Palette.sky.opacity(0.25), color: Palette.sky)
                oval(0.46, 0.52, 0.1, 0.1, fill: Palette.paper, color: Palette.sky)
                line([(0.7, 0.44), (0.86, 0.36), (0.84, 0.48), (0.68, 0.56)], color: Palette.sky,
                     closed: true, fill: Palette.sky.opacity(0.15))
            case .battery:
                rect(0.28, 0.36, 0.44, 0.28, 0.04, fill: Palette.leaf.opacity(0.35))
                rect(0.72, 0.44, 0.06, 0.12, 0.02, fill: Palette.silver.opacity(0.5), color: Palette.ink)
                line([(0.5, 0.36), (0.5, 0.64)], style: thin)
                line([(0.36, 0.5), (0.44, 0.5)], color: Palette.cream, style: thin)
                line([(0.4, 0.46), (0.4, 0.54)], color: Palette.cream, style: thin)
                line([(0.58, 0.5), (0.66, 0.5)], color: Palette.cream, style: thin)
            case .trashCan:
                line([(0.3, 0.34), (0.7, 0.34), (0.66, 0.82), (0.34, 0.82)], closed: true,
                     fill: Palette.silver.opacity(0.3))
                rect(0.26, 0.26, 0.48, 0.1, 0.03, fill: Palette.silver.opacity(0.5), color: Palette.ink)
                arc(0.5, 0.26, 0.06, pi, 2 * pi)
                line([(0.42, 0.4), (0.4, 0.78)], style: thin)
                line([(0.5, 0.4), (0.5, 0.78)], style: thin)
                line([(0.58, 0.4), (0.6, 0.78)], style: thin)
            case .coatHanger:
                arc(0.5, 0.26, 0.06, 0.5 * pi, 2 * pi, color: Palette.grape)
                line([(0.5, 0.32), (0.5, 0.4)], color: Palette.grape)
                line([(0.5, 0.4), (0.24, 0.62)], color: Palette.grape)
                line([(0.5, 0.4), (0.76, 0.62)], color: Palette.grape)
                line([(0.24, 0.62), (0.76, 0.62)], color: Palette.grape)
            case .pictureFrame:
                rect(0.24, 0.24, 0.52, 0.52, 0.04, fill: Palette.tomato.opacity(0.3), color: Palette.tomato)
                rect(0.3, 0.3, 0.4, 0.4, 0.02, fill: Palette.card)
                line([(0.34, 0.6), (0.44, 0.46), (0.5, 0.54), (0.58, 0.42), (0.66, 0.6)],
                     color: Palette.teal, style: thin)
                dot(0.6, 0.4, 0.03, color: Palette.mustard)
            case .doorknob:
                oval(0.5, 0.5, 0.2, 0.2, fill: Palette.mustard.opacity(0.18), color: Palette.inkSoft)
                oval(0.5, 0.5, 0.13, 0.13, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                line([(0.44, 0.44), (0.48, 0.48)], color: Palette.cream, style: thin)
                dot(0.5, 0.52, 0.02, color: Palette.ink)
            case .storageBin:
                line([(0.26, 0.4), (0.74, 0.4), (0.68, 0.8), (0.32, 0.8)], closed: true,
                     fill: Palette.sky.opacity(0.25))
                rect(0.24, 0.32, 0.52, 0.1, 0.03, fill: Palette.sky.opacity(0.4), color: Palette.sky)
                rect(0.29, 0.5, 0.08, 0.1, 0.02, fill: Palette.sky.opacity(0.3))
                rect(0.63, 0.5, 0.08, 0.1, 0.02, fill: Palette.sky.opacity(0.3))
                rect(0.42, 0.54, 0.16, 0.14, 0.02, fill: Palette.card)
            case .vacuumHose:
                smooth([(0.2, 0.36), (0.4, 0.5), (0.28, 0.66), (0.52, 0.74), (0.7, 0.62)],
                       color: Palette.teal,
                       style: StrokeStyle(lineWidth: lw * 1.9, lineCap: .round, lineJoin: .round))
                smooth([(0.2, 0.36), (0.4, 0.5), (0.28, 0.66), (0.52, 0.74), (0.7, 0.62)],
                       color: Palette.ink.opacity(0.25), style: thin)
                line([(0.7, 0.62), (0.84, 0.5)], color: Palette.silver,
                     style: StrokeStyle(lineWidth: lw * 1.3, lineCap: .round, lineJoin: .round))
            case .curtainRod:
                line([(0.16, 0.5), (0.84, 0.5)], color: Palette.silver,
                     style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round, lineJoin: .round))
                dot(0.13, 0.5, 0.04, color: Palette.silver)
                dot(0.87, 0.5, 0.04, color: Palette.silver)
                oval(0.34, 0.48, 0.03, 0.05, color: Palette.inkSoft, style: thin)
                oval(0.5, 0.48, 0.03, 0.05, color: Palette.inkSoft, style: thin)
                oval(0.66, 0.48, 0.03, 0.05, color: Palette.inkSoft, style: thin)
            case .lampShade:
                line([(0.34, 0.36), (0.66, 0.36), (0.76, 0.66), (0.24, 0.66)],
                     color: Palette.grape, closed: true, fill: Palette.grape.opacity(0.3))
                line([(0.34, 0.36), (0.66, 0.36)], style: thin)
                line([(0.44, 0.36), (0.4, 0.66)], style: thin)
                line([(0.56, 0.36), (0.6, 0.66)], style: thin)
                line([(0.42, 0.74), (0.58, 0.74)], color: Palette.mustard, style: thin)
                dot(0.68, 0.76, 0.014, color: Palette.mustard)
            case .wallHook:
                rect(0.4, 0.2, 0.2, 0.14, 0.05, fill: Palette.silver.opacity(0.3))
                dot(0.46, 0.27, 0.015); dot(0.54, 0.27, 0.015)
                line([(0.5, 0.34), (0.5, 0.58)], color: Palette.silver)
                arc(0.56, 0.58, 0.06, pi, 2.5 * pi, color: Palette.silver)
            case .broom:
                line([(0.64, 0.16), (0.44, 0.6)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.4, lineCap: .round, lineJoin: .round))
                smooth([(0.34, 0.6), (0.54, 0.6), (0.6, 0.84), (0.28, 0.84)], closed: true,
                       fill: Palette.leaf.opacity(0.4), color: Palette.leaf)
                line([(0.34, 0.64), (0.58, 0.62)], color: Palette.mustard, style: thin)
                line([(0.38, 0.66), (0.34, 0.82)], style: thin)
                line([(0.46, 0.64), (0.44, 0.82)], style: thin)
                line([(0.54, 0.64), (0.56, 0.82)], style: thin)
            case .rug:
                line([(0.18, 0.4), (0.82, 0.4), (0.72, 0.72), (0.28, 0.72)], closed: true,
                     fill: Palette.mustard.opacity(0.35))
                line([(0.26, 0.48), (0.74, 0.48)], color: Palette.tomato, style: thin)
                line([(0.24, 0.62), (0.76, 0.62)], color: Palette.tomato, style: thin)
                line([(0.2, 0.4), (0.18, 0.36)], style: thin)
                line([(0.4, 0.4), (0.39, 0.36)], style: thin)
                line([(0.6, 0.4), (0.61, 0.36)], style: thin)
                line([(0.8, 0.4), (0.82, 0.36)], style: thin)

            // MARK: Space deck additions

            case .marsShovel:
                line([(0.6, 0.16), (0.44, 0.6)], color: Palette.tomato)
                arc(0.6, 0.16, 0.06, 0, pi, color: Palette.tomato)
                smooth([(0.26, 0.6), (0.54, 0.56), (0.6, 0.76), (0.3, 0.82)], closed: true,
                       fill: Palette.tomato.opacity(0.35), color: Palette.tomato)
                dot(0.4, 0.7, 0.014, color: Palette.tomato)
            case .cosmicCompass:
                oval(0.5, 0.5, 0.32, 0.32, fill: Palette.grape.opacity(0.15), color: Palette.grape)
                line([(0.56, 0.28), (0.46, 0.54), (0.44, 0.72), (0.54, 0.46)], color: Palette.tomato,
                     closed: true, fill: Palette.tomato.opacity(0.6))
                dot(0.5, 0.22, 0.015, color: Palette.mustard)
                dot(0.78, 0.5, 0.015, color: Palette.mustard)
                dot(0.5, 0.78, 0.015, color: Palette.mustard)
                dot(0.22, 0.5, 0.015, color: Palette.mustard)
                dot(0.5, 0.5, 0.022)
            case .galaxyGoggles:
                oval(0.36, 0.5, 0.14, 0.12, fill: Palette.grape.opacity(0.3), color: Palette.grape)
                oval(0.64, 0.5, 0.14, 0.12, fill: Palette.grape.opacity(0.3), color: Palette.grape)
                line([(0.49, 0.48), (0.51, 0.48)])
                dot(0.34, 0.48, 0.012, color: Palette.cream)
                dot(0.66, 0.52, 0.012, color: Palette.cream)
                dot(0.4, 0.53, 0.01, color: Palette.mustard)
                line([(0.22, 0.48), (0.12, 0.44)], color: Palette.tomato, style: thin)
                line([(0.78, 0.48), (0.88, 0.44)], color: Palette.tomato, style: thin)
            case .rocketToolbox:
                rect(0.2, 0.44, 0.6, 0.36, 0.04, fill: Palette.sky.opacity(0.3))
                line([(0.2, 0.44), (0.3, 0.34), (0.7, 0.34), (0.8, 0.44)])
                arc(0.5, 0.34, 0.12, pi, 2 * pi)
                smooth([(0.5, 0.5), (0.56, 0.6), (0.44, 0.6)], closed: true,
                       fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                dot(0.5, 0.66, 0.02, color: Palette.mustard)
            case .starlightUmbrella:
                smooth([(0.12, 0.52), (0.5, 0.2), (0.88, 0.52)],
                       fill: Palette.grape.opacity(0.4), color: Palette.grape)
                smooth([(0.12, 0.52), (0.26, 0.6), (0.4, 0.52), (0.5, 0.6),
                        (0.6, 0.52), (0.74, 0.6), (0.88, 0.52)])
                line([(0.5, 0.22), (0.5, 0.78)])
                arc(0.41, 0.76, 0.09, 0, pi, style: thin)
                star(0.5, 0.16, 0.06, 0.025, fill: Palette.mustard, color: Palette.mustard)
                dot(0.3, 0.42, 0.012, color: Palette.cream)
                dot(0.7, 0.42, 0.012, color: Palette.cream)
            case .alienLunchbox:
                rect(0.22, 0.4, 0.56, 0.42, 0.08, fill: Palette.leaf.opacity(0.4))
                arc(0.5, 0.4, 0.15, pi, 2 * pi)
                line([(0.22, 0.52), (0.78, 0.52)], style: thin)
                dot(0.4, 0.64, 0.03, color: Palette.ink)
                dot(0.6, 0.64, 0.03, color: Palette.ink)
                smooth([(0.44, 0.72), (0.5, 0.75), (0.56, 0.72)], style: thin)
            case .moonBoots:
                smooth([(0.32, 0.28), (0.5, 0.26), (0.52, 0.5), (0.7, 0.56), (0.7, 0.7), (0.3, 0.7)],
                       closed: true, fill: Palette.silver.opacity(0.35), color: Palette.ink)
                rect(0.28, 0.7, 0.44, 0.08, 0.03, fill: Palette.ink.opacity(0.4))
                line([(0.34, 0.78), (0.34, 0.82)], style: thin)
                line([(0.44, 0.78), (0.44, 0.82)], style: thin)
                line([(0.54, 0.78), (0.54, 0.82)], style: thin)
                line([(0.64, 0.78), (0.64, 0.82)], style: thin)
                line([(0.36, 0.4), (0.5, 0.44)], color: Palette.tomato, style: thin)
                dot(0.42, 0.34, 0.014, color: Palette.mustard)
            case .orbitScooter:
                line([(0.28, 0.7), (0.6, 0.7)], color: Palette.grape,
                     style: StrokeStyle(lineWidth: lw * 1.6, lineCap: .round, lineJoin: .round))
                line([(0.62, 0.7), (0.7, 0.28)], color: Palette.grape)
                line([(0.58, 0.28), (0.82, 0.28)], color: Palette.grape)
                oval(0.28, 0.78, 0.12, 0.06, color: Palette.sky, style: thin)
                oval(0.28, 0.78, 0.07, 0.07, color: Palette.ink)
                oval(0.66, 0.78, 0.07, 0.07, color: Palette.ink)
                dot(0.74, 0.22, 0.014, color: Palette.mustard)
            case .spaceRadio:
                rect(0.34, 0.3, 0.32, 0.5, 0.06, fill: Palette.ink.opacity(0.18))
                line([(0.42, 0.3), (0.38, 0.14)])
                dot(0.37, 0.13, 0.02, color: Palette.tomato)
                rect(0.38, 0.36, 0.24, 0.14, 0.02, fill: Palette.sky.opacity(0.3))
                line([(0.4, 0.58), (0.6, 0.58)], style: thin)
                line([(0.4, 0.64), (0.6, 0.64)], style: thin)
                line([(0.4, 0.7), (0.6, 0.7)], style: thin)
                dot(0.5, 0.24, 0.02)
            case .craterBucket:
                line([(0.3, 0.42), (0.7, 0.42), (0.64, 0.82), (0.36, 0.82)], closed: true,
                     fill: Palette.silver.opacity(0.3))
                arc(0.5, 0.42, 0.2, pi, 2 * pi, color: Palette.silver)
                oval(0.5, 0.42, 0.2, 0.05, fill: Palette.silver.opacity(0.4))
                oval(0.44, 0.6, 0.05, 0.04, color: Palette.inkSoft, style: thin)
                oval(0.58, 0.68, 0.04, 0.03, color: Palette.inkSoft, style: thin)

            // MARK: Kitchen deck additions

            case .pizzaCutter:
                oval(0.36, 0.6, 0.16, 0.16, fill: Palette.silver.opacity(0.4), color: Palette.ink)
                dot(0.36, 0.6, 0.03)
                arc(0.36, 0.6, 0.2, 1.15 * pi, 1.85 * pi, color: Palette.silver, style: thin)
                line([(0.44, 0.5), (0.74, 0.24)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round, lineJoin: .round))
                rect(0.7, 0.18, 0.1, 0.1, 0.03, fill: Palette.mustard.opacity(0.5))
            case .teaKettle:
                smooth([(0.3, 0.76), (0.28, 0.5), (0.38, 0.4), (0.62, 0.4), (0.72, 0.5), (0.7, 0.76)],
                       closed: true, fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                line([(0.3, 0.5), (0.16, 0.42), (0.2, 0.52)], color: Palette.tomato,
                     closed: true, fill: Palette.tomato.opacity(0.4))
                arc(0.5, 0.36, 0.16, 1.05 * pi, 1.95 * pi)
                dot(0.5, 0.36, 0.03)
                smooth([(0.16, 0.36), (0.12, 0.28), (0.18, 0.22)], color: Palette.inkFaint, style: thin)
                rect(0.3, 0.76, 0.4, 0.05, 0.02, fill: Palette.ink.opacity(0.2))
            case .butterDish:
                line([(0.24, 0.6), (0.76, 0.6), (0.72, 0.72), (0.28, 0.72)], closed: true,
                     fill: Palette.mustard.opacity(0.2))
                smooth([(0.28, 0.6), (0.3, 0.44), (0.7, 0.44), (0.72, 0.6)], closed: true,
                       fill: Palette.sky.opacity(0.2), color: Palette.sky)
                dot(0.5, 0.42, 0.025)
                rect(0.4, 0.54, 0.2, 0.06, 0.01, fill: Palette.mustard.opacity(0.5))
            case .iceCreamScoop:
                oval(0.5, 0.44, 0.16, 0.16, fill: Palette.tomato.opacity(0.3), color: Palette.tomato)
                arc(0.5, 0.44, 0.16, 0, pi, color: Palette.silver)
                line([(0.5, 0.6), (0.5, 0.84)], color: Palette.silver,
                     style: StrokeStyle(lineWidth: lw * 1.4, lineCap: .round, lineJoin: .round))
                rect(0.44, 0.78, 0.12, 0.08, 0.03, fill: Palette.silver.opacity(0.5))
            case .cupcakeLiner:
                line([(0.32, 0.44), (0.68, 0.44), (0.62, 0.74), (0.38, 0.74)], closed: true,
                     fill: Palette.grape.opacity(0.25))
                smooth([(0.32, 0.44), (0.4, 0.4), (0.5, 0.44), (0.6, 0.4), (0.68, 0.44)])
                line([(0.42, 0.46), (0.44, 0.74)], style: thin)
                line([(0.5, 0.46), (0.5, 0.74)], style: thin)
                line([(0.58, 0.46), (0.56, 0.74)], style: thin)
            case .dishTowel:
                line([(0.28, 0.28), (0.72, 0.28)])
                rect(0.32, 0.28, 0.36, 0.5, 0.03, fill: Palette.teal.opacity(0.3))
                line([(0.32, 0.4), (0.68, 0.4)], color: Palette.tomato, style: thin)
                line([(0.32, 0.46), (0.68, 0.46)], color: Palette.tomato, style: thin)
                smooth([(0.32, 0.78), (0.42, 0.82), (0.5, 0.78), (0.58, 0.82), (0.68, 0.78)])
            case .canOpener:
                line([(0.28, 0.4), (0.6, 0.34)], color: Palette.tomato,
                     style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round, lineJoin: .round))
                line([(0.28, 0.5), (0.6, 0.56)], color: Palette.tomato,
                     style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round, lineJoin: .round))
                dot(0.6, 0.45, 0.03)
                oval(0.67, 0.44, 0.06, 0.06, color: Palette.silver)
                line([(0.67, 0.44), (0.76, 0.6)], style: thin)
                oval(0.77, 0.62, 0.05, 0.05, color: Palette.silver)
            case .kitchenTimer:
                oval(0.5, 0.54, 0.26, 0.26, fill: Palette.tomato.opacity(0.3), color: Palette.tomato)
                oval(0.5, 0.54, 0.18, 0.18, fill: Palette.card, color: Palette.ink)
                dot(0.5, 0.4, 0.012); dot(0.64, 0.54, 0.012); dot(0.5, 0.68, 0.012); dot(0.36, 0.54, 0.012)
                line([(0.5, 0.54), (0.58, 0.44)], color: Palette.tomato, style: thin)
                rect(0.44, 0.24, 0.12, 0.08, 0.03, fill: Palette.tomato.opacity(0.4))
            case .spiceRack:
                line([(0.2, 0.66), (0.8, 0.66)])
                line([(0.2, 0.66), (0.24, 0.74)]); line([(0.8, 0.66), (0.76, 0.74)])
                line([(0.2, 0.66), (0.2, 0.36)], style: thin)
                line([(0.8, 0.66), (0.8, 0.36)], style: thin)
                rect(0.28, 0.44, 0.1, 0.22, 0.03, fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                rect(0.45, 0.44, 0.1, 0.22, 0.03, fill: Palette.mustard.opacity(0.4), color: Palette.mustard)
                rect(0.62, 0.44, 0.1, 0.22, 0.03, fill: Palette.leaf.opacity(0.4), color: Palette.leaf)
            case .sinkPlug:
                line([(0.36, 0.5), (0.64, 0.5), (0.6, 0.66), (0.4, 0.66)],
                     color: Palette.ink, closed: true, fill: Palette.ink.opacity(0.3))
                oval(0.5, 0.48, 0.06, 0.03, color: Palette.ink)
                line([(0.5, 0.46), (0.62, 0.36), (0.72, 0.4), (0.82, 0.32)], color: Palette.silver, style: thin)
                dot(0.62, 0.36, 0.012, color: Palette.silver)
                dot(0.72, 0.4, 0.012, color: Palette.silver)

            // MARK: Sports deck additions

            case .jumpRope:
                smooth([(0.24, 0.34), (0.14, 0.6), (0.5, 0.78), (0.86, 0.6), (0.76, 0.34)],
                       color: Palette.tomato)
                rect(0.2, 0.28, 0.08, 0.14, 0.03, fill: Palette.sky.opacity(0.4), color: Palette.sky)
                rect(0.72, 0.28, 0.08, 0.14, 0.03, fill: Palette.sky.opacity(0.4), color: Palette.sky)
            case .conesSet:
                smooth([(0.34, 0.34), (0.44, 0.66), (0.24, 0.66)], closed: true,
                       fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                rect(0.22, 0.66, 0.24, 0.06, 0.02, fill: Palette.mustard.opacity(0.4))
                smooth([(0.64, 0.42), (0.72, 0.66), (0.56, 0.66)], closed: true,
                       fill: Palette.mustard.opacity(0.4), color: Palette.mustard)
                rect(0.54, 0.66, 0.2, 0.05, 0.02, fill: Palette.mustard.opacity(0.35))
            case .golfTee:
                oval(0.5, 0.36, 0.12, 0.12, fill: Palette.card, color: Palette.ink)
                dot(0.46, 0.34, 0.01, color: Palette.inkFaint)
                dot(0.52, 0.38, 0.01, color: Palette.inkFaint)
                smooth([(0.42, 0.46), (0.58, 0.46), (0.54, 0.54), (0.46, 0.54)], closed: true,
                       fill: Palette.leaf.opacity(0.4), color: Palette.leaf)
                line([(0.5, 0.54), (0.5, 0.82)], color: Palette.leaf,
                     style: StrokeStyle(lineWidth: lw * 1.4, lineCap: .round, lineJoin: .round))
            case .boxingGlove:
                smooth([(0.32, 0.4), (0.5, 0.32), (0.66, 0.38), (0.7, 0.56), (0.62, 0.7),
                        (0.4, 0.72), (0.3, 0.6), (0.3, 0.48)], closed: true,
                       fill: Palette.tomato.opacity(0.45), color: Palette.tomato)
                smooth([(0.32, 0.5), (0.24, 0.5), (0.28, 0.6), (0.34, 0.58)], closed: true,
                       fill: Palette.tomato.opacity(0.45), color: Palette.tomato)
                rect(0.4, 0.7, 0.24, 0.1, 0.03, fill: Palette.tomato.opacity(0.55), color: Palette.tomato)
                line([(0.5, 0.38), (0.5, 0.62)], style: thin)
            case .yogaMat:
                oval(0.5, 0.5, 0.16, 0.28, fill: Palette.teal.opacity(0.3), color: Palette.teal)
                oval(0.5, 0.5, 0.08, 0.16, color: Palette.teal, style: thin)
                oval(0.5, 0.5, 0.03, 0.06, color: Palette.teal, style: thin)
                line([(0.34, 0.4), (0.66, 0.4)], color: Palette.mustard, style: thin)
                line([(0.34, 0.6), (0.66, 0.6)], color: Palette.mustard, style: thin)
            case .skiPole:
                line([(0.56, 0.16), (0.44, 0.8)], color: Palette.sky)
                rect(0.54, 0.14, 0.08, 0.1, 0.03, fill: Palette.ink.opacity(0.3))
                arc(0.6, 0.2, 0.06, 0.5 * pi, 1.6 * pi, style: thin)
                oval(0.45, 0.72, 0.1, 0.04, color: Palette.sky)
                line([(0.44, 0.8), (0.43, 0.87)], style: thin)
            case .racingBib:
                rect(0.28, 0.28, 0.44, 0.5, 0.03, fill: Palette.card)
                dot(0.32, 0.32, 0.015, color: Palette.tomato)
                dot(0.68, 0.32, 0.015, color: Palette.tomato)
                dot(0.32, 0.74, 0.015, color: Palette.tomato)
                dot(0.68, 0.74, 0.015, color: Palette.tomato)
                line([(0.28, 0.4), (0.72, 0.4)], color: Palette.tomato, style: thin)
                line([(0.42, 0.46), (0.58, 0.46), (0.5, 0.68)], color: Palette.ink)
            case .bowlingPin:
                smooth([(0.5, 0.2), (0.44, 0.3), (0.43, 0.44), (0.4, 0.64), (0.42, 0.78),
                        (0.58, 0.78), (0.6, 0.64), (0.57, 0.44), (0.56, 0.3)], closed: true,
                       fill: Palette.card, color: Palette.ink)
                line([(0.44, 0.36), (0.56, 0.36)], color: Palette.tomato, style: thin)
                line([(0.43, 0.42), (0.57, 0.42)], color: Palette.tomato, style: thin)
            case .pingPongPaddle:
                oval(0.44, 0.44, 0.2, 0.22, fill: Palette.tomato.opacity(0.45), color: Palette.tomato)
                rect(0.4, 0.62, 0.08, 0.2, 0.03, fill: Palette.mustard.opacity(0.4), color: Palette.bronze)
                dot(0.74, 0.34, 0.06, color: Palette.card)
            case .climbingGrip:
                smooth([(0.3, 0.42), (0.52, 0.34), (0.68, 0.44), (0.66, 0.6), (0.5, 0.68), (0.34, 0.62)],
                       closed: true, fill: Palette.grape.opacity(0.4), color: Palette.grape)
                dot(0.5, 0.5, 0.03, color: Palette.ink)
                dot(0.42, 0.46, 0.012, color: Palette.grape)
                dot(0.58, 0.52, 0.012, color: Palette.grape)

            // MARK: School deck additions

            case .markerCap:
                rect(0.4, 0.4, 0.2, 0.42, 0.04, fill: Palette.sky.opacity(0.35))
                rect(0.44, 0.32, 0.12, 0.1, 0.02, fill: Palette.ink.opacity(0.4))
                rect(0.62, 0.5, 0.12, 0.28, 0.04, fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                line([(0.7, 0.52), (0.7, 0.72)], style: thin)
            case .paperTray:
                line([(0.22, 0.5), (0.78, 0.5), (0.72, 0.66), (0.28, 0.66)], closed: true,
                     fill: Palette.silver.opacity(0.3))
                line([(0.22, 0.5), (0.2, 0.42)], style: thin)
                line([(0.78, 0.5), (0.8, 0.42)], style: thin)
                rect(0.32, 0.4, 0.36, 0.12, 0.01, fill: Palette.card)
                line([(0.36, 0.44), (0.62, 0.44)], style: thin)
                line([(0.36, 0.48), (0.58, 0.48)], style: thin)
            case .mathCube:
                line([(0.3, 0.44), (0.6, 0.44), (0.6, 0.74), (0.3, 0.74)], closed: true,
                     fill: Palette.leaf.opacity(0.3))
                line([(0.3, 0.44), (0.42, 0.34), (0.72, 0.34), (0.6, 0.44)], closed: true,
                     fill: Palette.leaf.opacity(0.4))
                line([(0.6, 0.44), (0.72, 0.34), (0.72, 0.64), (0.6, 0.74)], closed: true,
                     fill: Palette.leaf.opacity(0.2))
                line([(0.45, 0.54), (0.45, 0.64)], color: Palette.ink, style: thin)
                line([(0.4, 0.59), (0.5, 0.59)], color: Palette.ink, style: thin)
            case .backpackCharm:
                oval(0.5, 0.26, 0.08, 0.08, color: Palette.silver, style: thin)
                line([(0.5, 0.34), (0.5, 0.42)], color: Palette.silver)
                star(0.5, 0.58, 0.16, 0.08, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                dot(0.66, 0.44, 0.014, color: Palette.mustard)
            case .classroomTimer:
                rect(0.26, 0.36, 0.48, 0.32, 0.05, fill: Palette.grape.opacity(0.3))
                rect(0.32, 0.42, 0.36, 0.2, 0.02, fill: Palette.ink.opacity(0.6), color: Palette.ink)
                line([(0.4, 0.48), (0.4, 0.56)], color: Palette.cream, style: thin)
                dot(0.5, 0.48, 0.01, color: Palette.cream)
                dot(0.5, 0.56, 0.01, color: Palette.cream)
                line([(0.6, 0.48), (0.6, 0.56)], color: Palette.cream, style: thin)
                line([(0.36, 0.68), (0.34, 0.74)]); line([(0.64, 0.68), (0.66, 0.74)])
            case .stapleRemover:
                line([(0.24, 0.36), (0.5, 0.46), (0.26, 0.44)], color: Palette.tomato,
                     closed: true, fill: Palette.tomato.opacity(0.4))
                line([(0.24, 0.58), (0.5, 0.46), (0.26, 0.5)], color: Palette.tomato,
                     closed: true, fill: Palette.tomato.opacity(0.5))
                dot(0.52, 0.47, 0.03, color: Palette.ink)
                line([(0.52, 0.47), (0.72, 0.42)], color: Palette.ink)
            case .readingLamp:
                line([(0.34, 0.8), (0.62, 0.8)])
                oval(0.48, 0.8, 0.12, 0.03, fill: Palette.ink.opacity(0.2))
                line([(0.48, 0.8), (0.44, 0.5), (0.6, 0.36)], color: Palette.mustard)
                dot(0.44, 0.5, 0.025)
                smooth([(0.5, 0.32), (0.74, 0.34), (0.66, 0.5), (0.5, 0.44)], closed: true,
                       fill: Palette.mustard.opacity(0.4), color: Palette.mustard)
                dot(0.6, 0.56, 0.012, color: Palette.mustard)
            case .paintSmock:
                smooth([(0.34, 0.26), (0.5, 0.24), (0.66, 0.26), (0.7, 0.34), (0.72, 0.78),
                        (0.28, 0.78), (0.3, 0.34)], closed: true,
                       fill: Palette.sky.opacity(0.25), color: Palette.sky)
                smooth([(0.44, 0.26), (0.5, 0.32), (0.56, 0.26)], style: thin)
                line([(0.3, 0.34), (0.22, 0.46)], style: thin)
                line([(0.7, 0.34), (0.78, 0.46)], style: thin)
                dot(0.44, 0.5, 0.03, color: Palette.tomato)
                dot(0.58, 0.6, 0.025, color: Palette.mustard)
                dot(0.5, 0.68, 0.02, color: Palette.leaf)
            case .reportFolder:
                rect(0.24, 0.32, 0.52, 0.44, 0.03, fill: Palette.tomato.opacity(0.35))
                rect(0.24, 0.28, 0.2, 0.08, 0.02, fill: Palette.tomato.opacity(0.45), color: Palette.tomato)
                rect(0.3, 0.36, 0.36, 0.12, 0.01, fill: Palette.card)
                line([(0.34, 0.4), (0.6, 0.4)], style: thin)
                line([(0.34, 0.44), (0.56, 0.44)], style: thin)
                line([(0.3, 0.62), (0.7, 0.62)], style: thin)
            case .busPass:
                rect(0.2, 0.34, 0.6, 0.4, 0.04, fill: Palette.mustard.opacity(0.35))
                rect(0.28, 0.42, 0.24, 0.14, 0.03, fill: Palette.sky.opacity(0.4), color: Palette.sky)
                line([(0.34, 0.46), (0.34, 0.5)], style: thin)
                line([(0.4, 0.46), (0.4, 0.5)], style: thin)
                line([(0.46, 0.46), (0.46, 0.5)], style: thin)
                dot(0.34, 0.57, 0.02, color: Palette.ink)
                dot(0.46, 0.57, 0.02, color: Palette.ink)
                line([(0.58, 0.46), (0.72, 0.46)], style: thin)
                line([(0.58, 0.52), (0.7, 0.52)], style: thin)

            // MARK: Smart-home additions (Household Items)

            case .smartSpeaker:
                rect(0.36, 0.3, 0.28, 0.5, 0.12, fill: Palette.teal.opacity(0.3))
                oval(0.5, 0.32, 0.14, 0.05, fill: Palette.teal.opacity(0.45))
                oval(0.5, 0.32, 0.1, 0.035, color: Palette.sky, style: thin)
                dot(0.44, 0.5, 0.012); dot(0.5, 0.5, 0.012); dot(0.56, 0.5, 0.012)
                dot(0.44, 0.58, 0.012); dot(0.5, 0.58, 0.012); dot(0.56, 0.58, 0.012)
            case .robotVacuum:
                oval(0.5, 0.54, 0.3, 0.3, fill: Palette.silver.opacity(0.3), color: Palette.ink)
                oval(0.5, 0.44, 0.08, 0.08, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                dot(0.5, 0.44, 0.025)
                line([(0.5, 0.54), (0.5, 0.62)], style: thin)
                dot(0.3, 0.54, 0.02); dot(0.7, 0.54, 0.02)
            case .securityCamera:
                rect(0.3, 0.4, 0.36, 0.18, 0.08, fill: Palette.silver.opacity(0.35), color: Palette.ink)
                oval(0.66, 0.49, 0.06, 0.06, fill: Palette.ink.opacity(0.6), color: Palette.ink)
                dot(0.68, 0.47, 0.012, color: Palette.cream)
                dot(0.4, 0.46, 0.015, color: Palette.tomato)
                line([(0.34, 0.5), (0.24, 0.66)], color: Palette.ink)
                line([(0.18, 0.68), (0.3, 0.68)])
            case .thermostat:
                oval(0.5, 0.5, 0.3, 0.3, fill: Palette.silver.opacity(0.3), color: Palette.ink)
                oval(0.5, 0.5, 0.2, 0.2, fill: Palette.sky.opacity(0.25), color: Palette.sky)
                line([(0.5, 0.5), (0.5, 0.36)], color: Palette.sky, style: thin)
                dot(0.5, 0.5, 0.02)
                dot(0.64, 0.5, 0.012); dot(0.36, 0.5, 0.012); dot(0.5, 0.64, 0.012)
            case .wifiRouter:
                rect(0.26, 0.5, 0.48, 0.26, 0.05, fill: Palette.ink.opacity(0.18))
                line([(0.36, 0.5), (0.32, 0.28)]); line([(0.64, 0.5), (0.68, 0.28)])
                dot(0.32, 0.27, 0.02); dot(0.68, 0.27, 0.02)
                dot(0.34, 0.62, 0.015, color: Palette.leaf)
                dot(0.42, 0.62, 0.015, color: Palette.leaf)
                dot(0.5, 0.62, 0.015, color: Palette.mustard)
                arc(0.5, 0.5, 0.1, pi, 2 * pi, color: Palette.sky, style: thin)
            case .leakSensor:
                rect(0.34, 0.4, 0.32, 0.24, 0.08, fill: Palette.sky.opacity(0.25), color: Palette.sky)
                dot(0.5, 0.48, 0.02, color: Palette.tomato)
                smooth([(0.5, 0.66), (0.44, 0.76), (0.5, 0.82), (0.56, 0.76)], closed: true,
                       fill: Palette.sky.opacity(0.4), color: Palette.sky)
                line([(0.42, 0.64), (0.42, 0.72)], color: Palette.silver, style: thin)
                line([(0.58, 0.64), (0.58, 0.72)], color: Palette.silver, style: thin)
            case .doorSensor:
                rect(0.3, 0.34, 0.18, 0.34, 0.03, fill: Palette.silver.opacity(0.3))
                rect(0.52, 0.34, 0.14, 0.34, 0.03, fill: Palette.silver.opacity(0.4))
                line([(0.5, 0.34), (0.5, 0.68)], style: thin)
                dot(0.39, 0.42, 0.015, color: Palette.leaf)
            case .motionSensor:
                smooth([(0.36, 0.6), (0.36, 0.44), (0.5, 0.34), (0.64, 0.44), (0.64, 0.6)],
                       closed: true, fill: Palette.card, color: Palette.ink)
                oval(0.5, 0.58, 0.13, 0.1, fill: Palette.sky.opacity(0.2), color: Palette.sky)
                dot(0.5, 0.5, 0.014, color: Palette.tomato)
                arc(0.68, 0.4, 0.08, 1.2 * pi, 1.7 * pi, color: Palette.tomato, style: thin)
                arc(0.68, 0.4, 0.14, 1.2 * pi, 1.7 * pi, color: Palette.tomato, style: thin)
            case .smartPlug:
                rect(0.36, 0.34, 0.28, 0.32, 0.08, fill: Palette.card, color: Palette.ink)
                dot(0.46, 0.46, 0.014); dot(0.54, 0.46, 0.014); dot(0.5, 0.54, 0.014)
                line([(0.44, 0.34), (0.44, 0.26)], color: Palette.silver)
                line([(0.56, 0.34), (0.56, 0.26)], color: Palette.silver)
                dot(0.5, 0.61, 0.02, color: Palette.leaf)

            // MARK: Tech & Gadgets deck

            case .smartButton:
                oval(0.5, 0.5, 0.26, 0.26, fill: Palette.tomato.opacity(0.3), color: Palette.tomato)
                oval(0.5, 0.5, 0.15, 0.15, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                arc(0.5, 0.5, 0.15, 1.1 * pi, 1.7 * pi, color: Palette.cream, style: thin)
                dot(0.5, 0.5, 0.03, color: Palette.cream)
            case .qrCodeSticker:
                rect(0.28, 0.28, 0.44, 0.44, 0.03, fill: Palette.card, color: Palette.ink)
                rect(0.32, 0.32, 0.1, 0.1, 0.01, color: Palette.ink)
                rect(0.58, 0.32, 0.1, 0.1, 0.01, color: Palette.ink)
                rect(0.32, 0.58, 0.1, 0.1, 0.01, color: Palette.ink)
                dot(0.37, 0.37, 0.018); dot(0.63, 0.37, 0.018); dot(0.37, 0.63, 0.018)
                dot(0.58, 0.58, 0.016); dot(0.64, 0.63, 0.013); dot(0.66, 0.56, 0.013)
            case .gpsTag:
                smooth([(0.5, 0.8), (0.34, 0.5), (0.4, 0.34), (0.5, 0.28), (0.6, 0.34), (0.66, 0.5)],
                       closed: true, fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                oval(0.5, 0.44, 0.07, 0.07, fill: Palette.card, color: Palette.tomato)
            case .smartCamera:
                rect(0.32, 0.36, 0.36, 0.36, 0.08, fill: Palette.sky.opacity(0.25), color: Palette.ink)
                oval(0.5, 0.54, 0.11, 0.11, fill: Palette.ink.opacity(0.5), color: Palette.ink)
                dot(0.52, 0.52, 0.02, color: Palette.cream)
                dot(0.4, 0.44, 0.015, color: Palette.tomato)
                line([(0.5, 0.72), (0.5, 0.8)]); line([(0.42, 0.8), (0.58, 0.8)])
            case .voiceRemote:
                rect(0.4, 0.16, 0.2, 0.68, 0.08, fill: Palette.ink.opacity(0.18))
                dot(0.5, 0.26, 0.03, color: Palette.tomato)
                oval(0.5, 0.44, 0.09, 0.09, color: Palette.silver)
                dot(0.5, 0.44, 0.02)
                dot(0.45, 0.62, 0.018); dot(0.55, 0.62, 0.018); dot(0.5, 0.72, 0.018)
            case .wifiHotspot:
                rect(0.34, 0.5, 0.32, 0.2, 0.06, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                line([(0.4, 0.62), (0.6, 0.62)], style: thin)
                dot(0.5, 0.44, 0.02, color: Palette.sky)
                arc(0.5, 0.44, 0.08, pi, 2 * pi, color: Palette.sky, style: thin)
                arc(0.5, 0.44, 0.14, pi, 2 * pi, color: Palette.sky, style: thin)
            case .robotArm:
                rect(0.36, 0.74, 0.28, 0.08, 0.02, fill: Palette.ink.opacity(0.3))
                line([(0.5, 0.74), (0.4, 0.5)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round, lineJoin: .round))
                dot(0.4, 0.5, 0.03)
                line([(0.4, 0.5), (0.62, 0.38)], color: Palette.mustard,
                     style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round, lineJoin: .round))
                line([(0.62, 0.38), (0.76, 0.26)], color: Palette.ink, style: thin)
                line([(0.62, 0.38), (0.72, 0.42)], color: Palette.ink, style: thin)
            case .handScanner:
                rect(0.32, 0.28, 0.36, 0.44, 0.06, fill: Palette.sky.opacity(0.2), color: Palette.sky)
                arc(0.5, 0.52, 0.11, 0, pi, color: Palette.ink, style: thin)
                arc(0.5, 0.52, 0.075, 0, pi, color: Palette.ink, style: thin)
                arc(0.5, 0.52, 0.04, 0, pi, color: Palette.ink, style: thin)
                line([(0.36, 0.42), (0.64, 0.42)], color: Palette.tomato, style: thin)
            case .alertBell:
                smooth([(0.32, 0.62), (0.34, 0.44), (0.5, 0.32), (0.66, 0.44), (0.68, 0.62)],
                       closed: true, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                line([(0.3, 0.62), (0.7, 0.62)], style: thin)
                dot(0.5, 0.68, 0.035, color: Palette.mustard)
                dot(0.5, 0.3, 0.02)
                dot(0.68, 0.36, 0.04, color: Palette.tomato)
            case .weatherApp:
                rect(0.28, 0.28, 0.44, 0.44, 0.12, fill: Palette.sky.opacity(0.25), color: Palette.sky)
                oval(0.42, 0.42, 0.08, 0.08, fill: Palette.mustard.opacity(0.6), color: Palette.mustard)
                smooth([(0.44, 0.62), (0.44, 0.52), (0.52, 0.48), (0.62, 0.5), (0.66, 0.58), (0.6, 0.62)],
                       closed: true, fill: Palette.card, color: Palette.inkSoft)
            case .votingApp:
                rect(0.28, 0.28, 0.44, 0.44, 0.12, fill: Palette.grape.opacity(0.25), color: Palette.grape)
                rect(0.38, 0.44, 0.24, 0.2, 0.03, fill: Palette.card, color: Palette.inkSoft)
                line([(0.44, 0.44), (0.56, 0.44)], style: thin)
                line([(0.44, 0.54), (0.48, 0.6), (0.58, 0.48)], color: Palette.leaf)
            case .batteryPack:
                rect(0.32, 0.3, 0.36, 0.5, 0.06, fill: Palette.leaf.opacity(0.3))
                rect(0.46, 0.27, 0.08, 0.05, 0.01, fill: Palette.ink.opacity(0.3))
                dot(0.42, 0.4, 0.014, color: Palette.leaf)
                dot(0.5, 0.4, 0.014, color: Palette.leaf)
                dot(0.58, 0.4, 0.014, color: Palette.inkFaint)
                line([(0.53, 0.5), (0.47, 0.58), (0.53, 0.58), (0.47, 0.66)], color: Palette.mustard, style: thin)
            case .trackerTag:
                oval(0.5, 0.5, 0.24, 0.24, fill: Palette.card, color: Palette.ink)
                oval(0.5, 0.5, 0.16, 0.16, color: Palette.inkSoft, style: thin)
                dot(0.5, 0.5, 0.03, color: Palette.sky)
                arc(0.5, 0.5, 0.2, 1.2 * pi, 1.55 * pi, color: Palette.sky, style: thin)
            case .touchScreen:
                rect(0.28, 0.22, 0.44, 0.56, 0.05, fill: Palette.ink.opacity(0.15))
                rect(0.32, 0.28, 0.36, 0.4, 0.02, fill: Palette.sky.opacity(0.2))
                oval(0.5, 0.48, 0.06, 0.06, color: Palette.sky, style: thin)
                oval(0.5, 0.48, 0.1, 0.1, color: Palette.sky, style: thin)
                dot(0.5, 0.48, 0.025, color: Palette.sky)
                dot(0.5, 0.73, 0.02)
            case .miniDrone:
                line([(0.5, 0.5), (0.3, 0.38)]); line([(0.5, 0.5), (0.7, 0.38)])
                line([(0.5, 0.5), (0.3, 0.62)]); line([(0.5, 0.5), (0.7, 0.62)])
                oval(0.3, 0.38, 0.08, 0.03, color: Palette.sky)
                oval(0.7, 0.38, 0.08, 0.03, color: Palette.sky)
                oval(0.3, 0.62, 0.08, 0.03, color: Palette.sky)
                oval(0.7, 0.62, 0.08, 0.03, color: Palette.sky)
                oval(0.5, 0.5, 0.08, 0.06, fill: Palette.ink.opacity(0.3), color: Palette.ink)
                dot(0.5, 0.56, 0.02, color: Palette.tomato)
            case .smartLock:
                rect(0.36, 0.3, 0.28, 0.44, 0.08, fill: Palette.silver.opacity(0.35), color: Palette.ink)
                dot(0.44, 0.4, 0.015); dot(0.5, 0.4, 0.015); dot(0.56, 0.4, 0.015)
                dot(0.44, 0.48, 0.015); dot(0.5, 0.48, 0.015); dot(0.56, 0.48, 0.015)
                oval(0.5, 0.62, 0.06, 0.06, fill: Palette.mustard.opacity(0.5), color: Palette.mustard)
                dot(0.5, 0.62, 0.014, color: Palette.ink)
            case .dataRecorder:
                rect(0.28, 0.34, 0.44, 0.34, 0.05, fill: Palette.grape.opacity(0.28))
                rect(0.33, 0.4, 0.34, 0.14, 0.02, fill: Palette.ink.opacity(0.5), color: Palette.ink)
                line([(0.36, 0.47), (0.4, 0.43), (0.44, 0.5), (0.48, 0.42), (0.52, 0.5), (0.56, 0.44), (0.64, 0.47)],
                     color: Palette.leaf, style: thin)
                dot(0.4, 0.6, 0.02, color: Palette.tomato)
                dot(0.55, 0.6, 0.018); dot(0.62, 0.6, 0.018)
            case .alertBadge:
                smooth([(0.5, 0.28), (0.7, 0.36), (0.68, 0.58), (0.5, 0.74), (0.32, 0.58), (0.3, 0.36)],
                       closed: true, fill: Palette.tomato.opacity(0.35), color: Palette.tomato)
                line([(0.5, 0.42), (0.5, 0.56)], color: Palette.tomato)
                dot(0.5, 0.64, 0.02, color: Palette.tomato)
            case .aiCoach:
                rect(0.34, 0.34, 0.32, 0.3, 0.08, fill: Palette.sky.opacity(0.25), color: Palette.ink)
                line([(0.5, 0.34), (0.5, 0.26)]); dot(0.5, 0.25, 0.02, color: Palette.tomato)
                dot(0.44, 0.46, 0.025, color: Palette.sky)
                dot(0.56, 0.46, 0.025, color: Palette.sky)
                smooth([(0.44, 0.55), (0.5, 0.59), (0.56, 0.55)], style: thin)
                line([(0.72, 0.3), (0.72, 0.4)], color: Palette.mustard, style: thin)
                line([(0.67, 0.35), (0.77, 0.35)], color: Palette.mustard, style: thin)
            case .timerButton:
                oval(0.5, 0.5, 0.26, 0.26, fill: Palette.sky.opacity(0.25), color: Palette.sky)
                oval(0.5, 0.5, 0.16, 0.16, fill: Palette.card, color: Palette.ink)
                line([(0.5, 0.5), (0.5, 0.4)], style: thin)
                line([(0.5, 0.5), (0.58, 0.54)], color: Palette.tomato, style: thin)
                dot(0.5, 0.5, 0.02)
            case .mapMarker:
                rect(0.24, 0.4, 0.52, 0.36, 0.02, fill: Palette.leaf.opacity(0.15))
                line([(0.24, 0.55), (0.76, 0.55)], style: thin)
                line([(0.5, 0.4), (0.5, 0.76)], style: thin)
                smooth([(0.56, 0.62), (0.48, 0.42), (0.52, 0.32), (0.6, 0.3), (0.66, 0.4), (0.6, 0.5)],
                       closed: true, fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                dot(0.57, 0.4, 0.02, color: Palette.card)
            case .bluetoothTag:
                rect(0.34, 0.28, 0.32, 0.44, 0.06, fill: Palette.sky.opacity(0.25), color: Palette.sky)
                line([(0.5, 0.34), (0.5, 0.66)], color: Palette.sky, style: thin)
                line([(0.5, 0.34), (0.6, 0.42), (0.42, 0.5)], color: Palette.sky, style: thin)
                line([(0.5, 0.66), (0.6, 0.58), (0.42, 0.5)], color: Palette.sky, style: thin)
            case .chargingDock:
                smooth([(0.34, 0.7), (0.66, 0.7), (0.62, 0.82), (0.38, 0.82)], closed: true,
                       fill: Palette.ink.opacity(0.25))
                rect(0.42, 0.3, 0.2, 0.4, 0.04, fill: Palette.sky.opacity(0.25), color: Palette.sky)
                line([(0.53, 0.44), (0.48, 0.52), (0.53, 0.52), (0.48, 0.6)], color: Palette.mustard, style: thin)
                line([(0.5, 0.7), (0.5, 0.66)], style: thin)
            case .cameraLens:
                oval(0.5, 0.5, 0.28, 0.28, fill: Palette.ink.opacity(0.2), color: Palette.ink)
                oval(0.5, 0.5, 0.2, 0.2, color: Palette.silver)
                oval(0.5, 0.5, 0.13, 0.13, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                line([(0.44, 0.44), (0.5, 0.52)], color: Palette.cream, style: thin)
                dot(0.5, 0.28, 0.012); dot(0.72, 0.5, 0.012)
            case .deliveryTracker:
                line([(0.3, 0.48), (0.7, 0.48), (0.66, 0.78), (0.34, 0.78)], closed: true,
                     fill: Palette.mustard.opacity(0.3))
                line([(0.3, 0.48), (0.4, 0.4), (0.8, 0.4), (0.7, 0.48)], closed: true,
                     fill: Palette.mustard.opacity(0.4))
                line([(0.5, 0.4), (0.5, 0.78)], style: thin)
                smooth([(0.5, 0.4), (0.42, 0.24), (0.5, 0.16), (0.58, 0.24)], closed: true,
                       fill: Palette.tomato.opacity(0.5), color: Palette.tomato)
                dot(0.5, 0.24, 0.016, color: Palette.card)
            case .barcodeScanner:
                rect(0.42, 0.5, 0.14, 0.3, 0.04, fill: Palette.ink.opacity(0.25))
                smooth([(0.42, 0.5), (0.42, 0.34), (0.66, 0.34), (0.66, 0.44), (0.56, 0.5)],
                       closed: true, fill: Palette.tomato.opacity(0.4), color: Palette.tomato)
                line([(0.66, 0.39), (0.82, 0.39)], color: Palette.tomato, style: thin)
                line([(0.78, 0.32), (0.78, 0.46)], style: thin)
                line([(0.82, 0.32), (0.82, 0.46)], style: thin)
                line([(0.86, 0.34), (0.86, 0.44)], style: thin)
            case .callButton:
                oval(0.5, 0.5, 0.26, 0.26, fill: Palette.leaf.opacity(0.4), color: Palette.leaf)
                smooth([(0.42, 0.4), (0.38, 0.46), (0.44, 0.52), (0.5, 0.58), (0.56, 0.62),
                        (0.62, 0.58), (0.58, 0.52), (0.52, 0.5), (0.46, 0.44)], closed: true,
                       fill: Palette.cream, color: Palette.ink)
            case .wifiBooster:
                rect(0.38, 0.36, 0.24, 0.34, 0.06, fill: Palette.sky.opacity(0.3), color: Palette.sky)
                line([(0.46, 0.36), (0.46, 0.28)], color: Palette.silver)
                line([(0.54, 0.36), (0.54, 0.28)], color: Palette.silver)
                dot(0.5, 0.62, 0.015, color: Palette.leaf)
                arc(0.5, 0.5, 0.09, pi, 2 * pi, color: Palette.sky, style: thin)
                arc(0.5, 0.5, 0.15, pi, 2 * pi, color: Palette.sky, style: thin)
            case .smartWatch:
                rect(0.42, 0.16, 0.16, 0.16, 0.04, fill: Palette.ink.opacity(0.2))
                rect(0.42, 0.68, 0.16, 0.16, 0.04, fill: Palette.ink.opacity(0.2))
                rect(0.34, 0.32, 0.32, 0.36, 0.09, fill: Palette.ink.opacity(0.25), color: Palette.ink)
                rect(0.38, 0.36, 0.24, 0.28, 0.06, fill: Palette.sky.opacity(0.3))
                line([(0.5, 0.5), (0.5, 0.42)], color: Palette.cream, style: thin)
                line([(0.5, 0.5), (0.56, 0.52)], color: Palette.cream, style: thin)
                dot(0.67, 0.5, 0.018)

            // MARK: Kitchen additions

            case .groceryScanner:
                smooth([(0.34, 0.5), (0.34, 0.36), (0.56, 0.36), (0.56, 0.5), (0.46, 0.56)],
                       closed: true, fill: Palette.teal.opacity(0.4), color: Palette.teal)
                rect(0.4, 0.54, 0.12, 0.26, 0.03, fill: Palette.ink.opacity(0.25))
                line([(0.56, 0.42), (0.74, 0.42)], color: Palette.tomato, style: thin)
                line([(0.7, 0.34), (0.7, 0.5)], style: thin)
                line([(0.74, 0.34), (0.74, 0.5)], style: thin)
                line([(0.78, 0.36), (0.78, 0.48)], style: thin)
            case .fridgeCamera:
                rect(0.34, 0.24, 0.32, 0.56, 0.05, fill: Palette.sky.opacity(0.2))
                line([(0.34, 0.44), (0.66, 0.44)], style: thin)
                line([(0.62, 0.3), (0.62, 0.4)], style: thin)
                oval(0.5, 0.58, 0.07, 0.07, fill: Palette.ink.opacity(0.5), color: Palette.ink)
                dot(0.52, 0.56, 0.014, color: Palette.cream)
                dot(0.42, 0.52, 0.012, color: Palette.tomato)
            case .recipeScanner:
                rect(0.24, 0.3, 0.36, 0.44, 0.03, fill: Palette.sky.opacity(0.15))
                line([(0.3, 0.42), (0.54, 0.42)], style: thin)
                line([(0.3, 0.5), (0.54, 0.5)], style: thin)
                line([(0.3, 0.58), (0.5, 0.58)], style: thin)
                rect(0.62, 0.36, 0.14, 0.3, 0.03, fill: Palette.ink.opacity(0.2))
                dot(0.69, 0.44, 0.02, color: Palette.tomato)
                line([(0.24, 0.68), (0.6, 0.68)], color: Palette.tomato, style: thin)
            case .foodThermometer:
                oval(0.5, 0.36, 0.14, 0.14, fill: Palette.card, color: Palette.ink)
                line([(0.5, 0.36), (0.58, 0.3)], color: Palette.tomato, style: thin)
                dot(0.5, 0.36, 0.015)
                line([(0.5, 0.5), (0.5, 0.82)], color: Palette.silver,
                     style: StrokeStyle(lineWidth: lw * 1.4, lineCap: .round, lineJoin: .round))
            case .kitchenScale:
                rect(0.28, 0.5, 0.44, 0.24, 0.05, fill: Palette.silver.opacity(0.3))
                rect(0.34, 0.4, 0.32, 0.12, 0.03, fill: Palette.silver.opacity(0.4), color: Palette.ink)
                rect(0.4, 0.6, 0.2, 0.08, 0.02, fill: Palette.ink.opacity(0.5), color: Palette.ink)
                line([(0.46, 0.62), (0.46, 0.66)], color: Palette.cream, style: thin)
                line([(0.52, 0.62), (0.52, 0.66)], color: Palette.cream, style: thin)
            case .smartPan:
                oval(0.42, 0.54, 0.24, 0.24, fill: Palette.ink.opacity(0.12), color: Palette.ink)
                line([(0.64, 0.46), (0.9, 0.34)], color: Palette.ink,
                     style: StrokeStyle(lineWidth: lw * 1.6, lineCap: .round, lineJoin: .round))
                rect(0.72, 0.36, 0.1, 0.08, 0.02, fill: Palette.sky.opacity(0.4), color: Palette.sky)
                dot(0.42, 0.54, 0.03, color: Palette.tomato)
                line([(0.36, 0.44), (0.36, 0.38)], color: Palette.tomato, style: thin)
                line([(0.48, 0.44), (0.48, 0.38)], color: Palette.tomato, style: thin)
            case .smartFaucet:
                smooth([(0.36, 0.7), (0.36, 0.44), (0.46, 0.32), (0.6, 0.32)], color: Palette.silver,
                       style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round, lineJoin: .round))
                rect(0.3, 0.7, 0.16, 0.08, 0.02, fill: Palette.silver.opacity(0.4))
                dot(0.58, 0.36, 0.015, color: Palette.sky)
                line([(0.6, 0.36), (0.6, 0.56)], color: Palette.sky, style: thin)
                dot(0.6, 0.6, 0.012, color: Palette.sky)
            case .foodSealer:
                rect(0.3, 0.32, 0.4, 0.44, 0.03, fill: Palette.sky.opacity(0.15), color: Palette.inkSoft)
                line([(0.3, 0.36), (0.7, 0.36)], style: thin)
                line([(0.3, 0.4), (0.7, 0.4)], color: Palette.ink, style: thin)
                oval(0.5, 0.56, 0.12, 0.1, fill: Palette.tomato.opacity(0.3), color: Palette.tomato)
                line([(0.36, 0.5), (0.4, 0.66)], style: thin)
                line([(0.64, 0.5), (0.6, 0.66)], style: thin)
            case .compostBin:
                line([(0.32, 0.36), (0.68, 0.36), (0.64, 0.82), (0.36, 0.82)], closed: true,
                     fill: Palette.leaf.opacity(0.3))
                rect(0.28, 0.28, 0.44, 0.1, 0.03, fill: Palette.leaf.opacity(0.45), color: Palette.leaf)
                arc(0.5, 0.28, 0.06, pi, 2 * pi)
                smooth([(0.5, 0.48), (0.58, 0.54), (0.5, 0.66), (0.42, 0.54)], closed: true,
                       fill: Palette.leaf.opacity(0.5), color: Palette.leaf)
                line([(0.5, 0.5), (0.5, 0.64)], style: thin)

            // MARK: Sports additions

            case .replayCamera:
                rect(0.3, 0.36, 0.34, 0.2, 0.05, fill: Palette.ink.opacity(0.25), color: Palette.ink)
                oval(0.64, 0.46, 0.06, 0.06, fill: Palette.sky.opacity(0.4), color: Palette.sky)
                oval(0.4, 0.34, 0.06, 0.06, color: Palette.ink)
                oval(0.52, 0.34, 0.06, 0.06, color: Palette.ink)
                dot(0.36, 0.42, 0.015, color: Palette.tomato)
                line([(0.42, 0.56), (0.34, 0.8)]); line([(0.5, 0.56), (0.5, 0.8)]); line([(0.56, 0.56), (0.64, 0.8)])
            case .stopwatch:
                oval(0.5, 0.56, 0.24, 0.24, fill: Palette.card, color: Palette.ink)
                rect(0.44, 0.26, 0.12, 0.08, 0.03, fill: Palette.silver.opacity(0.5))
                line([(0.5, 0.34), (0.5, 0.32)])
                line([(0.34, 0.38), (0.3, 0.34)], style: thin)
                line([(0.66, 0.38), (0.7, 0.34)], style: thin)
                dot(0.5, 0.38, 0.012); dot(0.68, 0.56, 0.012); dot(0.5, 0.74, 0.012); dot(0.32, 0.56, 0.012)
                line([(0.5, 0.56), (0.5, 0.44)], style: thin)
                line([(0.5, 0.56), (0.6, 0.6)], color: Palette.tomato, style: thin)
                dot(0.5, 0.56, 0.02)
            case .heartMonitor:
                rect(0.28, 0.36, 0.44, 0.32, 0.06, fill: Palette.tomato.opacity(0.25))
                rect(0.33, 0.42, 0.34, 0.2, 0.02, fill: Palette.card, color: Palette.inkSoft)
                line([(0.35, 0.52), (0.42, 0.52), (0.46, 0.44), (0.5, 0.6), (0.54, 0.5), (0.65, 0.5)],
                     color: Palette.tomato, style: thin)
            case .fitnessTracker:
                rect(0.4, 0.18, 0.2, 0.64, 0.09, fill: Palette.grape.opacity(0.3))
                rect(0.42, 0.4, 0.16, 0.24, 0.05, fill: Palette.ink.opacity(0.4), color: Palette.ink)
                line([(0.44, 0.52), (0.48, 0.52), (0.5, 0.48), (0.52, 0.56), (0.56, 0.52)],
                     color: Palette.leaf, style: thin)
            case .speedSensor:
                rect(0.34, 0.42, 0.28, 0.16, 0.04, fill: Palette.mustard.opacity(0.4), color: Palette.ink)
                rect(0.4, 0.56, 0.12, 0.22, 0.03, fill: Palette.ink.opacity(0.25))
                rect(0.37, 0.45, 0.1, 0.08, 0.02, fill: Palette.tomato.opacity(0.5))
                oval(0.62, 0.5, 0.05, 0.08, color: Palette.ink)
                arc(0.68, 0.5, 0.07, 1.6 * pi, 2.4 * pi, color: Palette.sky, style: thin)
                arc(0.68, 0.5, 0.12, 1.6 * pi, 2.4 * pi, color: Palette.sky, style: thin)
            case .raceTimer:
                rect(0.24, 0.34, 0.52, 0.28, 0.05, fill: Palette.ink.opacity(0.2))
                rect(0.3, 0.4, 0.4, 0.16, 0.02, fill: Palette.ink.opacity(0.6), color: Palette.ink)
                line([(0.38, 0.44), (0.38, 0.52)], color: Palette.mustard, style: thin)
                dot(0.47, 0.44, 0.01, color: Palette.mustard)
                dot(0.47, 0.52, 0.01, color: Palette.mustard)
                line([(0.55, 0.44), (0.55, 0.52)], color: Palette.mustard, style: thin)
                line([(0.62, 0.44), (0.62, 0.52)], color: Palette.mustard, style: thin)
                line([(0.36, 0.62), (0.34, 0.72)]); line([(0.64, 0.62), (0.66, 0.72)])
            case .trainingApp:
                rect(0.28, 0.28, 0.44, 0.44, 0.12, fill: Palette.leaf.opacity(0.25), color: Palette.leaf)
                rect(0.42, 0.47, 0.16, 0.06, 0.02, fill: Palette.ink.opacity(0.4))
                rect(0.36, 0.43, 0.06, 0.14, 0.02, fill: Palette.ink.opacity(0.5), color: Palette.ink)
                rect(0.58, 0.43, 0.06, 0.14, 0.02, fill: Palette.ink.opacity(0.5), color: Palette.ink)

            // MARK: School additions

            case .tabletCart:
                rect(0.26, 0.3, 0.48, 0.44, 0.03, fill: Palette.teal.opacity(0.2))
                line([(0.26, 0.46), (0.74, 0.46)], style: thin)
                line([(0.26, 0.6), (0.74, 0.6)], style: thin)
                rect(0.32, 0.34, 0.08, 0.1, 0.01, fill: Palette.sky.opacity(0.4), color: Palette.sky)
                rect(0.44, 0.34, 0.08, 0.1, 0.01, fill: Palette.sky.opacity(0.4), color: Palette.sky)
                rect(0.56, 0.34, 0.08, 0.1, 0.01, fill: Palette.sky.opacity(0.4), color: Palette.sky)
                line([(0.74, 0.3), (0.82, 0.3), (0.82, 0.5)], style: thin)
                dot(0.34, 0.78, 0.05, color: Palette.ink)
                dot(0.66, 0.78, 0.05, color: Palette.ink)
            case .attendanceScanner:
                rect(0.36, 0.3, 0.28, 0.4, 0.05, fill: Palette.sky.opacity(0.25), color: Palette.sky)
                rect(0.4, 0.36, 0.2, 0.05, 0.01, fill: Palette.ink.opacity(0.4))
                dot(0.5, 0.46, 0.015, color: Palette.leaf)
                line([(0.44, 0.56), (0.48, 0.62), (0.58, 0.52)], color: Palette.leaf)
            case .flashcardApp:
                rect(0.28, 0.28, 0.44, 0.44, 0.12, fill: Palette.mustard.opacity(0.25), color: Palette.mustard)
                rect(0.38, 0.4, 0.24, 0.24, 0.03, fill: Palette.card, color: Palette.inkSoft)
                rect(0.34, 0.44, 0.24, 0.22, 0.03, fill: Palette.card, color: Palette.ink)
                line([(0.42, 0.62), (0.46, 0.5), (0.5, 0.62)], color: Palette.ink, style: thin)
                line([(0.44, 0.57), (0.48, 0.57)], color: Palette.ink, style: thin)
            case .projectorRemote:
                rect(0.42, 0.3, 0.16, 0.44, 0.06, fill: Palette.ink.opacity(0.2))
                dot(0.5, 0.38, 0.02, color: Palette.tomato)
                dot(0.46, 0.5, 0.015); dot(0.54, 0.5, 0.015); dot(0.5, 0.58, 0.015)
                line([(0.5, 0.3), (0.5, 0.2)], color: Palette.tomato, style: thin)
                dot(0.5, 0.18, 0.015, color: Palette.tomato)
            case .dueDateStamp:
                rect(0.42, 0.2, 0.16, 0.14, 0.05, fill: Palette.tomato.opacity(0.4))
                arc(0.5, 0.2, 0.09, pi, 2 * pi, color: Palette.tomato)
                line([(0.34, 0.34), (0.66, 0.34), (0.72, 0.56), (0.28, 0.56)],
                     color: Palette.ink, closed: true, fill: Palette.ink.opacity(0.18))
                rect(0.3, 0.56, 0.4, 0.06, 0.02, fill: Palette.ink.opacity(0.5))
                rect(0.4, 0.68, 0.2, 0.1, 0.02, color: Palette.tomato, style: thin)
                line([(0.44, 0.73), (0.56, 0.73)], color: Palette.tomato, style: thin)
            case .chalkTray:
                rect(0.22, 0.24, 0.56, 0.26, 0.02, fill: Palette.leaf.opacity(0.5), color: Palette.ink)
                rect(0.2, 0.5, 0.6, 0.1, 0.02, fill: Palette.mustard.opacity(0.3), color: Palette.bronze)
                rect(0.3, 0.46, 0.12, 0.05, 0.02, fill: Palette.cream, color: Palette.inkSoft)
                rect(0.46, 0.46, 0.1, 0.05, 0.02, fill: Palette.tomato.opacity(0.4), color: Palette.inkSoft)
                rect(0.6, 0.43, 0.12, 0.07, 0.02, fill: Palette.sky.opacity(0.3), color: Palette.ink)
            case .smartPen:
                rect(0.44, 0.2, 0.12, 0.5, 0.05, fill: Palette.grape.opacity(0.35))
                smooth([(0.44, 0.7), (0.5, 0.82), (0.56, 0.7)], closed: true,
                       fill: Palette.ink.opacity(0.5), color: Palette.ink)
                line([(0.53, 0.24), (0.53, 0.4)], style: thin)
                dot(0.5, 0.3, 0.02, color: Palette.sky)
                dot(0.5, 0.86, 0.012, color: Palette.sky)
            case .classPollApp:
                rect(0.28, 0.28, 0.44, 0.44, 0.12, fill: Palette.sky.opacity(0.25), color: Palette.sky)
                line([(0.34, 0.62), (0.66, 0.62)], style: thin)
                rect(0.36, 0.5, 0.07, 0.12, 0.01, fill: Palette.tomato.opacity(0.6), color: Palette.tomato)
                rect(0.46, 0.42, 0.07, 0.2, 0.01, fill: Palette.mustard.opacity(0.7), color: Palette.mustard)
                rect(0.56, 0.46, 0.07, 0.16, 0.01, fill: Palette.leaf.opacity(0.6), color: Palette.leaf)
            case .smartWorksheet:
                rect(0.28, 0.24, 0.44, 0.56, 0.03, fill: Palette.card)
                line([(0.34, 0.36), (0.66, 0.36)], style: thin)
                line([(0.34, 0.44), (0.66, 0.44)], style: thin)
                line([(0.34, 0.52), (0.6, 0.52)], style: thin)
                line([(0.34, 0.62), (0.38, 0.66), (0.44, 0.58)], color: Palette.leaf, style: thin)
                line([(0.6, 0.62), (0.6, 0.72)], color: Palette.sky, style: thin)
                line([(0.55, 0.67), (0.65, 0.67)], color: Palette.sky, style: thin)
            case .noiseMeter:
                rect(0.28, 0.36, 0.44, 0.32, 0.05, fill: Palette.grape.opacity(0.28))
                rect(0.34, 0.56, 0.05, 0.08, 0.01, fill: Palette.leaf, color: Palette.leaf)
                rect(0.42, 0.5, 0.05, 0.14, 0.01, fill: Palette.leaf, color: Palette.leaf)
                rect(0.5, 0.46, 0.05, 0.18, 0.01, fill: Palette.mustard, color: Palette.mustard)
                rect(0.58, 0.42, 0.05, 0.22, 0.01, fill: Palette.tomato, color: Palette.tomato)
            case .homeworkApp:
                rect(0.28, 0.28, 0.44, 0.44, 0.12, fill: Palette.tomato.opacity(0.22), color: Palette.tomato)
                rect(0.36, 0.38, 0.2, 0.26, 0.02, fill: Palette.card, color: Palette.inkSoft)
                line([(0.4, 0.44), (0.52, 0.44)], style: thin)
                line([(0.4, 0.5), (0.52, 0.5)], style: thin)
                line([(0.56, 0.6), (0.66, 0.42)], color: Palette.mustard, style: thin)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Medal (colored)

/// A hand-drawn award medal: ribbon + disc + star, colored gold/silver/bronze by
/// `place` (1/2/3). Replaces the 🥇🥈🥉 emoji on the scoreboard, judge and podium.
struct MedalDoodle: View {
    var place: Int
    var size: CGFloat = 34

    private var medalColor: Color {
        switch place {
        case 1: return Palette.gold
        case 2: return Palette.silver
        default: return Palette.bronze
        }
    }

    var body: some View {
        Canvas { ctx, area in
            let s = min(area.width, area.height)
            let ox = (area.width - s) / 2
            let oy = (area.height - s) / 2
            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
            let lw = max(1, s * 0.06)
            let stroke = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)

            // Ribbons (two crossed tails behind the disc).
            var rib = Path()
            rib.move(to: P(0.34, 0.06)); rib.addLine(to: P(0.44, 0.5))
            rib.addLine(to: P(0.56, 0.5)); rib.addLine(to: P(0.5, 0.06)); rib.closeSubpath()
            ctx.fill(rib, with: .color(Palette.tomato))
            ctx.stroke(rib, with: .color(Palette.ink), style: stroke)

            var rib2 = Path()
            rib2.move(to: P(0.66, 0.06)); rib2.addLine(to: P(0.56, 0.5))
            rib2.addLine(to: P(0.44, 0.5)); rib2.addLine(to: P(0.5, 0.06)); rib2.closeSubpath()
            ctx.fill(rib2, with: .color(Palette.sky))
            ctx.stroke(rib2, with: .color(Palette.ink), style: stroke)

            // Disc.
            let disc = wobblyOval(center: P(0.5, 0.66), rx: s * 0.27, ry: s * 0.27, seed: 61, roughness: 0.8)
            ctx.fill(disc, with: .color(medalColor))
            ctx.stroke(disc, with: .color(Palette.ink), style: stroke)

            // Inner ring.
            let ring = wobblyOval(center: P(0.5, 0.66), rx: s * 0.19, ry: s * 0.19, seed: 62, roughness: 0.5)
            ctx.stroke(ring, with: .color(Palette.ink.opacity(0.45)),
                       style: StrokeStyle(lineWidth: lw * 0.55))

            // Star.
            let star = starPath(center: P(0.5, 0.66), outer: s * 0.13, inner: s * 0.055)
            ctx.fill(star, with: .color(Palette.cream))
            ctx.stroke(star, with: .color(Palette.ink), style: StrokeStyle(lineWidth: lw * 0.5, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}
