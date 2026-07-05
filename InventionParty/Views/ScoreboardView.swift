//
//  ScoreboardView.swift
//  Invention Party
//
//  Ported from app/scoreboard.tsx. Sketchbook redesign.
//

import SwiftUI

struct ScoreboardView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router

    private var sortedPlayers: [Player] { store.players.sorted { $0.score > $1.score } }
    private var lastResult: RoundResult? { store.roundResults.last }
    private var isGameOver: Bool { store.currentRound >= store.roundsTotal }

    private func player(_ id: String?) -> Player? {
        guard let id else { return nil }
        return store.players.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Round \(store.currentRound) Results")
                    .font(.display(30)).foregroundColor(Palette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 28)

                VStack(spacing: 12) {
                    Text("This Round's Winners")
                        .font(.marker(20, bold: true)).foregroundColor(Palette.ink)
                        .padding(.bottom, 2)
                    if let p = player(lastResult?.first) {
                        winnerCard(1, p.name, "+3", accent: Palette.gold, big: true).popIn(delay: 0.05)
                    }
                    if let p = player(lastResult?.second) {
                        winnerCard(2, p.name, "+2", accent: Palette.silver, big: false).popIn(delay: 0.18)
                    }
                    if let p = player(lastResult?.third) {
                        winnerCard(3, p.name, "+1", accent: Palette.bronze, big: false).popIn(delay: 0.31)
                    }
                }
                .padding(.bottom, 30)

                VStack(spacing: 10) {
                    Text("Overall Scores")
                        .font(.marker(20, bold: true)).foregroundColor(Palette.ink)
                        .padding(.bottom, 4)
                    ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, p in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.display(20)).foregroundColor(Palette.cream)
                                .frame(width: 38, height: 38)
                                .background(SketchyCircle(seed: UInt64(index + 1)).fill(rankColor(index)))
                                .overlay(SketchyCircle(seed: UInt64(index + 1)).stroke(Palette.ink, lineWidth: 2))
                            Text(p.name).font(.marker(17, bold: true)).foregroundColor(Palette.ink)
                            Spacer()
                            Text("\(p.score) pts").font(.marker(18, bold: true)).foregroundColor(Palette.tomato)
                        }
                        .padding(14)
                        .sketchCard(fill: Palette.card, border: Palette.ink, lineWidth: 2,
                                    seed: UInt64(160 + index))
                    }
                }
                .padding(.bottom, 22)

                FilledButton(title: isGameOver ? "View Final Results"
                                                : "Next Round (\(store.currentRound + 1)/\(store.roundsTotal))",
                             background: Palette.leaf, foreground: Palette.cream, seed: 5,
                             icon: isGameOver ? .trophy : nil) {
                    nextAction()
                }
            }
            .padding(20)
        }
        .screenBackground()
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return Palette.gold
        case 1: return Palette.silver
        case 2: return Palette.bronze
        default: return Palette.inkFaint
        }
    }

    private func winnerCard(_ place: Int, _ name: String, _ points: String, accent: Color, big: Bool) -> some View {
        HStack {
            MedalDoodle(place: place, size: big ? 44 : 34)
            Text(name).font(.marker(big ? 22 : 19, bold: true)).foregroundColor(Palette.ink)
                .padding(.leading, 14)
            Spacer()
            Text(points).font(.display(big ? 26 : 22)).foregroundColor(Palette.ink)
        }
        .padding(big ? 20 : 16)
        .sketchCard(fill: accent, border: Palette.ink, cornerRadius: big ? 18 : 14,
                    lineWidth: big ? 3 : 2.5, seed: big ? 81 : UInt64(82 + name.count))
    }

    private func nextAction() {
        if isGameOver {
            router.push(.podium)
        } else {
            store.nextRound()
            router.push(.round)
        }
    }
}
