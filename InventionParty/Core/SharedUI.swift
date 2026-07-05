//
//  SharedUI.swift
//  Invention Party
//
//  Reusable Sketchbook components: paper background, hand-drawn buttons and
//  cards, badges, tiles, and small delight helpers used across every screen.
//

import SwiftUI
import UIKit

// MARK: - Alerts

/// Lightweight identifiable alert payload for `.alert(item:)`.
struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

// MARK: - Paper background

/// The kraft-paper / chalkboard backdrop with a faint dot-grid, like a real
/// sketchbook page.
struct PaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Palette.paper
            Canvas { context, size in
                let spacing: CGFloat = 26
                let dot: CGFloat = 2.0
                // Dark dots on the kraft page in light mode; light chalk dots on
                // the chalkboard in dark mode. Stronger than before so the grid
                // actually reads.
                let dotOpacity = colorScheme == .dark ? 0.16 : 0.18
                let color = GraphicsContext.Shading.color(Palette.ink.opacity(dotOpacity))
                var y: CGFloat = spacing / 2
                while y < size.height {
                    var x: CGFloat = spacing / 2
                    while x < size.width {
                        let r = CGRect(x: x - dot / 2, y: y - dot / 2, width: dot, height: dot)
                        context.fill(Path(ellipseIn: r), with: color)
                        x += spacing
                    }
                    y += spacing
                }
            }
        }
    }
}

extension View {
    /// Applies the full-screen paper background and hides the system nav bar
    /// (screens provide their own back buttons).
    func screenBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PaperBackground().ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Sketchy card surface

extension View {
    /// Wraps the view in a hand-drawn card: wobbly ink outline, paper fill,
    /// and a hard "marker" drop shadow. Apply *after* padding the content.
    func sketchCard(fill: Color = Palette.card,
                    border: Color = Palette.ink,
                    cornerRadius: CGFloat = 20,
                    lineWidth: CGFloat = 2.5,
                    seed: UInt64 = 7,
                    shadow: Bool = true) -> some View {
        self.background(
            ZStack {
                if shadow {
                    SketchyRoundedRectangle(cornerRadius: cornerRadius, roughness: 1.5, seed: seed &+ 50)
                        .fill(Palette.ink.opacity(0.16))
                        .offset(x: 3, y: 4)
                }
                SketchyRoundedRectangle(cornerRadius: cornerRadius, roughness: 1.5, seed: seed)
                    .fill(fill)
                SketchyRoundedRectangle(cornerRadius: cornerRadius, roughness: 1.5, seed: seed)
                    .stroke(border, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
            }
        )
    }
}

// MARK: - Buttons

/// Chunky hand-drawn button: wobbly outline, hard offset shadow, and a tactile
/// "press into the page" animation.
struct SketchButtonStyle: ButtonStyle {
    var fill: Color
    var border: Color = Palette.ink
    var cornerRadius: CGFloat = 16
    var seed: UInt64 = 11

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        // The face (fill + outline) is sized to the label. The shadow is a
        // *background* of the face — so it can never grow larger than the button
        // (a bare Shape in a ZStack would greedily fill the whole proposed area).
        // The shadow's offset is cancelled on press so the face appears to press
        // down onto a fixed shadow.
        return configuration.label
            .contentShape(Rectangle())
            .background(
                SketchyRoundedRectangle(cornerRadius: cornerRadius, roughness: 1.4, seed: seed)
                    .fill(fill)
            )
            .overlay(
                SketchyRoundedRectangle(cornerRadius: cornerRadius, roughness: 1.4, seed: seed)
                    .stroke(border, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
            )
            .background(
                SketchyRoundedRectangle(cornerRadius: cornerRadius, roughness: 1.4, seed: seed &+ 50)
                    .fill(Palette.ink.opacity(0.26))
                    .offset(x: pressed ? 0 : 3.5, y: pressed ? 0 : 4.5)
            )
            .offset(x: pressed ? 3.5 : 0, y: pressed ? 4.5 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: pressed)
    }
}

/// A filled, hand-drawn pill button. Keeps the original call-site signature so
/// it can be used as a drop-in everywhere.
struct FilledButton: View {
    let title: String
    var background: Color = Palette.mustard
    var foreground: Color = Palette.ink
    var fontSize: CGFloat = 21
    var verticalPadding: CGFloat = 16
    var seed: UInt64 = 11
    /// Optional hand-drawn icon shown to the left of the title, tinted to match
    /// the foreground so it reads on any button color.
    var icon: Doodle.Kind? = nil
    let action: () -> Void

    /// Honors the Settings haptics toggle (defaults on). A light tap fires on
    /// every primary button press for a tactile, "physical paper" feel.
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    var body: some View {
        Button {
            if hapticsEnabled {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            action()
        } label: {
            HStack(spacing: 9) {
                if let icon {
                    Doodle(kind: icon, size: fontSize * 1.15, color: foreground)
                }
                Text(title)
                    .font(.marker(fontSize, bold: true))
                    .foregroundColor(foreground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, 14)
        }
        .buttonStyle(SketchButtonStyle(fill: background, seed: seed))
    }
}

// MARK: - Badges & pills

/// A small hand-drawn badge (e.g. "FREE", "LOCKED", points).
struct SketchBadge: View {
    let text: String
    var fill: Color = Palette.leaf
    var foreground: Color = Palette.cream
    var seed: UInt64 = 21

    var body: some View {
        Text(text)
            .font(.marker(13, bold: true))
            .foregroundColor(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                SketchyRoundedRectangle(cornerRadius: 9, roughness: 1.1, seed: seed).fill(fill)
            )
            .overlay(
                SketchyRoundedRectangle(cornerRadius: 9, roughness: 1.1, seed: seed)
                    .stroke(Palette.ink, lineWidth: 1.8)
            )
    }
}

// MARK: - Object tile

/// Renders a GameObject as a photo, hand-drawn object doodle, or title-only card tile.
struct ObjectTile: View {
    let object: GameObject
    var size: CGFloat = 96
    var emojiSize: CGFloat = 60
    var titleFontSize: CGFloat = 15
    var seed: UInt64 = 5

    var body: some View {
        Group {
            if let data = object.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(SketchyRoundedRectangle(cornerRadius: 14, seed: seed))
                    .overlay(
                        SketchyRoundedRectangle(cornerRadius: 14, seed: seed)
                            .stroke(Palette.ink, lineWidth: 2.5)
                    )
            } else if !object.prefersTextOnly, let kind = ObjectDoodle.Kind(object: object) {
                ObjectDoodle(kind: kind, size: min(size * 0.76, emojiSize * 1.16))
                    .frame(width: size, height: size)
                    .sketchCard(fill: Palette.cardSunken, cornerRadius: 14, seed: seed, shadow: false)
            } else if !object.prefersTextOnly, let recipe = object.doodleRecipe {
                GeneratedDoodle(recipe: recipe, size: min(size * 0.76, emojiSize * 1.16), seed: seed)
                    .frame(width: size, height: size)
                    .sketchCard(fill: Palette.cardSunken, cornerRadius: 14, seed: seed, shadow: false)
            } else {
                Text(object.name)
                    .font(.marker(titleFontSize, bold: true))
                    .foregroundColor(Palette.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.58)
                    .padding(10)
                    .frame(width: size * 1.28, height: size * 1.18)
                    .sketchCard(fill: Palette.cardSunken, cornerRadius: 14, seed: seed, shadow: false)
            }
        }
    }
}

// MARK: - Flow layout

/// A simple wrapping row layout (like flex-wrap) for chips/buttons.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                          proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Drawing preview

/// Renders a decoded drawing submission using Canvas. The preview sits on a
/// light "sketch sheet", so strokes use a fixed charcoal ink.
struct DrawingPreview: View {
    let drawing: DrawingData
    private let strokeInk = Color(hex: "#2B2B28")

    var body: some View {
        GeometryReader { geo in
            let scale = drawing.width > 0 ? geo.size.width / drawing.width : 1
            Canvas { context, _ in
                for stroke in drawing.strokes {
                    guard let first = stroke.points.first else { continue }
                    if stroke.points.count == 1 {
                        let p = CGPoint(x: first.x * scale, y: first.y * scale)
                        let dot = Path(ellipseIn: CGRect(x: p.x - 1.5, y: p.y - 1.5, width: 3, height: 3))
                        context.fill(dot, with: .color(strokeInk))
                    } else {
                        var path = Path()
                        path.move(to: CGPoint(x: first.x * scale, y: first.y * scale))
                        for point in stroke.points.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x * scale, y: point.y * scale))
                        }
                        context.stroke(path, with: .color(strokeInk),
                                       style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                }
            }
        }
        .aspectRatio(drawing.width / max(drawing.height, 1), contentMode: .fit)
    }
}

// MARK: - Page transitions

extension AnyTransition {
    /// Shuffling loose sheets across a desk. The incoming page slides straight in
    /// from one side and the outgoing slides off the same direction (so there's
    /// no gap in the middle). Paired with a springy, slightly-overshooting
    /// animation it feels like physical paper settling — a craftier cousin of a
    /// flat swipe. `forward` (push) and back (pop) shuffle opposite directions.
    static func paperShuffle(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading),
            removal: .move(edge: forward ? .leading : .trailing)
        )
    }
}

// MARK: - Delight helpers

/// Springy "pop in" entrance for cards, winners, and headlines.
struct PopIn: ViewModifier {
    var delay: Double = 0
    @State private var shown = false
    @AppStorage("playfulAnimations") private var playfulAnimations: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var enabled: Bool { playfulAnimations && !reduceMotion }

    func body(content: Content) -> some View {
        if enabled {
            content
                .scaleEffect(shown ? 1 : 0.7)
                .opacity(shown ? 1 : 0)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.62).delay(delay)) {
                        shown = true
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func popIn(delay: Double = 0) -> some View { modifier(PopIn(delay: delay)) }
}

/// Gentle continuous wobble for hero elements (the home title, the trophy).
struct Wiggle: ViewModifier {
    var angle: Double = 2.0
    @State private var on = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(on ? angle : -angle))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    on = true
                }
            }
    }
}

extension View {
    func wiggle(_ angle: Double = 2.0) -> some View { modifier(Wiggle(angle: angle)) }
}

/// Lightweight confetti burst for the podium / winner moments. Pure SwiftUI,
/// no assets — little ink-outlined paper scraps that rain down once.
struct ConfettiView: View {
    var pieceCount: Int = 60
    private let colors: [Color] = [Palette.tomato, Palette.mustard, Palette.teal, Palette.grape, Palette.leaf, Palette.sky]

    struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let size: CGFloat
        let color: Color
        let delay: Double
        let duration: Double
        let spin: Double
        let drift: CGFloat
    }

    @State private var pieces: [Piece] = []
    @State private var go = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Palette.ink.opacity(0.5), lineWidth: 1))
                        .frame(width: piece.size, height: piece.size * 1.4)
                        .rotationEffect(.degrees(go ? piece.spin : 0))
                        .position(x: piece.x + (go ? piece.drift : 0),
                                  y: go ? geo.size.height + 40 : -40)
                        .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: go)
                }
            }
            .onAppear {
                pieces = (0..<pieceCount).map { _ in
                    Piece(x: CGFloat.random(in: 0...geo.size.width),
                          size: CGFloat.random(in: 7...13),
                          color: colors.randomElement()!,
                          delay: Double.random(in: 0...0.6),
                          duration: Double.random(in: 1.6...2.8),
                          spin: Double.random(in: 180...720),
                          drift: CGFloat.random(in: -40...40))
                }
                go = true
            }
        }
        .allowsHitTesting(false)
    }
}
