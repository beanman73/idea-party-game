//
//  DrawingCanvasView.swift
//  Invention Party
//
//  Ported from app/components/DrawingCanvas.tsx. Sketchbook redesign — the
//  canvas is a light "sketch sheet" with a hand-drawn frame.
//

import SwiftUI

struct DrawingCanvasView: View {
    let width: CGFloat
    let height: CGFloat
    /// Called whenever the drawing changes, with strokes and canvas size.
    var onChange: (DrawingData) -> Void

    @State private var strokes: [Stroke]
    @State private var currentPoints: [CGPoint] = []

    init(width: CGFloat, height: CGFloat, initialStrokes: [Stroke] = [],
         onChange: @escaping (DrawingData) -> Void) {
        self.width = width
        self.height = height
        self.onChange = onChange
        _strokes = State(initialValue: initialStrokes)
    }

    private let strokeInk = Palette.sheetInk

    var body: some View {
        VStack(spacing: 12) {
            Canvas { context, _ in
                drawStrokes(strokes, in: context)
                if !currentPoints.isEmpty {
                    drawStroke(Stroke(points: currentPoints), in: context)
                }
            }
            .frame(width: width, height: height)
            .background(SketchyRoundedRectangle(cornerRadius: 16, seed: 9).fill(Palette.drawSheet))
            .overlay(SketchyRoundedRectangle(cornerRadius: 16, seed: 9).stroke(Palette.sheetInk, lineWidth: 2.5))
            .clipShape(SketchyRoundedRectangle(cornerRadius: 16, seed: 9))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentPoints.append(value.location)
                    }
                    .onEnded { _ in
                        if !currentPoints.isEmpty {
                            strokes.append(Stroke(points: currentPoints))
                            currentPoints = []
                            emit()
                        }
                    }
            )

            HStack(spacing: 12) {
                Button { undo() } label: {
                    controlLabel("↶ Undo", fill: Palette.card, fg: Palette.ink, seed: 61)
                }
                .buttonStyle(.plain)
                Button { clear() } label: {
                    controlLabel("Clear", fill: Palette.danger, fg: Palette.cream, seed: 62, icon: .trash)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func controlLabel(_ text: String, fill: Color, fg: Color, seed: UInt64,
                              icon: Doodle.Kind? = nil) -> some View {
        HStack(spacing: 7) {
            if let icon {
                Doodle(kind: icon, size: 17, color: fg)
            }
            Text(text)
                .font(.marker(15, bold: true))
                .foregroundColor(fg)
        }
        .padding(.vertical, 10).padding(.horizontal, 22)
        .background(SketchyRoundedRectangle(cornerRadius: 11, seed: seed).fill(fill))
        .overlay(SketchyRoundedRectangle(cornerRadius: 11, seed: seed).stroke(Palette.ink, lineWidth: 2))
    }

    private func drawStrokes(_ strokes: [Stroke], in context: GraphicsContext) {
        for stroke in strokes { drawStroke(stroke, in: context) }
    }

    private func drawStroke(_ stroke: Stroke, in context: GraphicsContext) {
        guard let first = stroke.points.first else { return }
        if stroke.points.count == 1 {
            let dot = Path(ellipseIn: CGRect(x: first.x - 1.5, y: first.y - 1.5, width: 3, height: 3))
            context.fill(dot, with: .color(strokeInk))
        } else {
            var path = Path()
            path.move(to: first)
            for point in stroke.points.dropFirst() { path.addLine(to: point) }
            context.stroke(path, with: .color(strokeInk),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }

    private func undo() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        emit()
    }

    private func clear() {
        strokes = []
        currentPoints = []
        onChange(DrawingData(strokes: [], width: width, height: height))
    }

    private func emit() {
        onChange(DrawingData(strokes: strokes, width: width, height: height))
    }
}
