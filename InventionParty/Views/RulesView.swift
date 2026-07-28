//
//  RulesView.swift
//  Invention Party
//
//  Ported from app/rules.tsx. A paged "slides" walkthrough before round 1.
//  Sketchbook redesign.
//

import SwiftUI

struct RulesView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router
    @State private var currentSlide = 0

    private var modeRules: (title: String, rules: [String]) {
        if store.mode == .speed {
            return ("Speed Round Rules", [
                "Each turn is timed",
                "You get \(turnTimeText) to create your invention",
                "When the timer hits zero, your work auto-submits",
                "Judge still ranks inventions normally",
            ])
        }
        if store.mode == .crowd {
            return ("Crowd Favorite Rules", [
                "Two random objects will be shown each round",
                "Everyone creates an invention combining those objects",
                "No judge — instead everyone votes for their favorite",
                "You can't vote for your own invention",
                "Most-voted = 3 points, runner-ups get 2 & 1",
                "Play continues for all rounds",
                "Highest score wins!",
            ])
        }
        return ("Classic Mode Rules", [
            "Two random objects will be shown each round",
            "All players (except the judge) create an invention combining those objects",
            "The judge ranks the top 3 inventions",
            "1st place = 3 points, 2nd = 2 points, 3rd = 1 point",
            "Judge rotates to next player each round",
            "Play continues for all rounds",
            "Highest score wins!",
        ])
    }

    private var turnTimeText: String {
        let secs = store.secondsPerTurn
        if secs < 60 { return "\(secs) seconds" }
        let m = secs / 60, s = secs % 60
        if s == 0 { return m == 1 ? "1 minute" : "\(m) minutes" }
        return "\(m):\(String(format: "%02d", s))"
    }

    private var slideCount: Int { 3 + modeRules.rules.count }
    private var isFirst: Bool { currentSlide == 0 }
    private var isLast: Bool { currentSlide == slideCount - 1 }

    var body: some View {
        VStack(spacing: 0) {
            slideContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)

            // Progress dots
            HStack(spacing: 7) {
                ForEach(0..<slideCount, id: \.self) { i in
                    Circle()
                        .fill(i == currentSlide ? Palette.tomato : Palette.inkFaint.opacity(0.5))
                        .frame(width: i == currentSlide ? 10 : 7, height: i == currentSlide ? 10 : 7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentSlide)
                }
            }
            .padding(.bottom, 14)

            if !isLast {
                Button {
                    withAnimation { currentSlide = slideCount - 1 }
                } label: {
                    Text("Skip →")
                        .font(.marker(15, bold: true))
                        .foregroundColor(Palette.inkSoft)
                        .underline()
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }

            HStack(spacing: 12) {
                FilledButton(title: "← Prev", background: Palette.card,
                             foreground: isFirst ? Palette.inkFaint : Palette.ink,
                             fontSize: 17, seed: 51) {
                    if !isFirst { withAnimation { currentSlide -= 1 } }
                }
                .disabled(isFirst)
                .opacity(isFirst ? 0.5 : 1)

                if isLast {
                    FilledButton(title: "Start Round 1!", background: Palette.leaf,
                                 foreground: Palette.cream, fontSize: 17, seed: 52, icon: .controller) {
                        router.push(.round)
                    }
                } else {
                    FilledButton(title: "Next →", background: Palette.mustard,
                                 foreground: Palette.buttonInk, fontSize: 17, seed: 53) {
                        withAnimation { currentSlide += 1 }
                    }
                }
            }
            .padding(.horizontal, 20)

            FilledButton(title: "← Back to Decks", background: Palette.card,
                         foreground: Palette.inkSoft, fontSize: 15, verticalPadding: 12, seed: 80) {
                router.pop()
            }
            .padding(20)
        }
        .screenBackground()
    }

    @ViewBuilder private var slideContent: some View {
        Group {
            if currentSlide == 0 {
                VStack(spacing: 14) {
                    Doodle(kind: .clipboard, size: 60, color: Palette.ink)
                    Text(modeRules.title).font(.display(34))
                        .foregroundColor(Palette.ink).multilineTextAlignment(.center)
                    Text("Let's review how to play!")
                        .font(.marker(17)).foregroundColor(Palette.inkSoft)
                }
            } else if currentSlide == 1 {
                VStack(spacing: 16) {
                    Text("Game Setup").font(.display(30)).foregroundColor(Palette.ink)
                    infoRow("Rounds", "\(store.roundsTotal)", Palette.teal)
                    if store.mode == .crowd {
                        infoRow("Judging", "Everyone votes", Palette.grape)
                    } else {
                        infoRow("First Judge", store.players[safe: store.judgeRotationIndex]?.name ?? "Auto", Palette.grape)
                    }
                    infoRow("Players", "\(store.players.count)", Palette.mustard)
                }
            } else if currentSlide == slideCount - 1 {
                VStack(spacing: 18) {
                    PaletteDoodle(size: 64).wiggle(4)
                    Text("Ready to Play?").font(.display(34)).foregroundColor(Palette.ink)
                    Text("Tap below to start your first round!")
                        .font(.marker(17)).foregroundColor(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                    Text("Good luck!").font(.marker(22, bold: true)).foregroundColor(Palette.tomato)
                }
            } else {
                let ruleIndex = currentSlide - 2
                VStack(spacing: 26) {
                    Text("\(ruleIndex + 1)")
                        .font(.display(54))
                        .foregroundColor(Palette.cream)
                        .frame(width: 110, height: 110)
                        .background(SketchyCircle(seed: UInt64(ruleIndex + 3)).fill(Palette.tomato))
                        .overlay(SketchyCircle(seed: UInt64(ruleIndex + 3)).stroke(Palette.ink, lineWidth: 3))
                    Text(modeRules.rules[ruleIndex])
                        .font(.marker(23, bold: true))
                        .foregroundColor(Palette.ink)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .id(currentSlide)
        .transition(.asymmetric(insertion: .scale(scale: 0.85).combined(with: .opacity),
                                removal: .opacity))
    }

    private func infoRow(_ label: String, _ value: String, _ accent: Color) -> some View {
        HStack {
            Text(label).font(.marker(17, bold: true)).foregroundColor(Palette.inkSoft)
            Spacer()
            Text(value).font(.marker(18, bold: true)).foregroundColor(Palette.ink)
        }
        .padding(16)
        .sketchCard(fill: Palette.card, border: accent, lineWidth: 2.5, seed: UInt64(value.count + 5))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
