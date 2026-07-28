//
//  HowToPlayView.swift
//  Invention Party
//
//  Ported from app/howtoplay.tsx. Sketchbook redesign.
//

import SwiftUI

struct HowToPlayView: View {
    var onClose: () -> Void = {}

    private let steps: [(number: String, title: String, text: String, accent: Color)] = [
        ("1", "Pick Your Pack", "Choose from different object packs to play with.", Palette.teal),
        ("2", "Set Up Your Game", "Add players, choose a game mode, and decide who judges first.", Palette.mustard),
        ("3", "Get Two Objects", "Each round, everyone sees the same two random objects.", Palette.tomato),
        ("4", "Invent Something!", "Everyone (except the judge) combines those two objects into an invention. Type or draw your idea!", Palette.grape),
        ("5", "Judge Ranks Them", "The judge picks 1st (3 pts), 2nd (2 pts), and 3rd place (1 pt).", Palette.sky),
        ("6", "Next Round!", "The judge role rotates. Keep playing until all rounds are done!", Palette.leaf),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("How to Play")
                    .font(.display(34))
                    .foregroundColor(Palette.ink)
                    .padding(.vertical, 10)

                ForEach(Array(steps.enumerated()), id: \.element.title) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Text(step.number)
                            .font(.display(26))
                            .foregroundColor(Palette.cream)
                            .frame(width: 46, height: 46)
                            .background(SketchyCircle(seed: UInt64(index + 2)).fill(step.accent))
                            .overlay(SketchyCircle(seed: UInt64(index + 2)).stroke(Palette.ink, lineWidth: 2))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.marker(19, bold: true))
                                .foregroundColor(Palette.ink)
                            Text(step.text)
                                .font(.marker(15))
                                .foregroundColor(Palette.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .sketchCard(fill: Palette.card, border: step.accent, lineWidth: 2.5,
                                seed: UInt64(70 + index))
                    .popIn(delay: Double(index) * 0.06)
                }

                HStack(spacing: 12) {
                    Doodle(kind: .trophy, size: 34, color: Palette.buttonInk)
                    Text("Most points wins!")
                        .font(.marker(20, bold: true))
                        .foregroundColor(Palette.buttonInk)
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .sketchCard(fill: Palette.mustard, border: Palette.ink, seed: 90)

                FilledButton(title: "Got It!", background: Palette.leaf,
                             foreground: Palette.cream, seed: 7) {
                    onClose()
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .screenBackground()
    }
}
