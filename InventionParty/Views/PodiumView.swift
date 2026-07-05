//
//  PodiumView.swift
//  Invention Party
//
//  Ported from app/podium.tsx. Sketchbook redesign with a confetti finale.
//

import SwiftUI

struct PodiumView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router

    private var sortedPlayers: [Player] { store.players.sorted { $0.score > $1.score } }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Game Over!")
                    .font(.display(40)).foregroundColor(Palette.ink)
                    .padding(.bottom, 6)
                    .popIn()
                Doodle(kind: .party, size: 44, color: Palette.tomato)
                    .padding(.bottom, 28)
                    .wiggle(6)

                podium.padding(.bottom, 36)

                VStack(spacing: 12) {
                    Text("Final Scores").font(.marker(20, bold: true)).foregroundColor(Palette.ink)
                    ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, p in
                        HStack(spacing: 12) {
                            Text("#\(index + 1)").font(.display(18))
                                .foregroundColor(Palette.tomato).frame(width: 42, alignment: .leading)
                            Text(p.name).font(.marker(17, bold: true)).foregroundColor(Palette.ink)
                            Spacer()
                            Text("\(p.score) pts").font(.marker(18, bold: true)).foregroundColor(Palette.ink)
                        }
                        .padding(13)
                        .sketchCard(fill: Palette.cardSunken, border: Palette.ink, lineWidth: 1.8,
                                    seed: UInt64(170 + index))
                    }
                }
                .padding(18)
                .sketchCard(fill: Palette.card, border: Palette.mustard, lineWidth: 2.5, seed: 91)
                .padding(.bottom, 22)

                FilledButton(title: "Play Again", background: Palette.leaf,
                             foreground: Palette.cream, seed: 5, icon: .controller) {
                    store.resetGame()
                    router.reset(to: .setup)
                }
                .padding(.bottom, 12)
                FilledButton(title: "Home", background: Palette.card,
                             foreground: Palette.ink, fontSize: 18, verticalPadding: 14, seed: 80,
                             icon: .house) {
                    store.resetGame()
                    router.popToRoot()
                }
            }
            .padding(20)
        }
        .screenBackground()
        .overlay(ConfettiView().ignoresSafeArea())
    }

    private var podium: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if let second = sortedPlayers[safe: 1] {
                podiumSlot(player: second, place: 2, rank: "2nd", height: 92,
                           block: Palette.silver, crown: false, delay: 0.25)
            }
            if let first = sortedPlayers[safe: 0] {
                podiumSlot(player: first, place: 1, rank: "1st", height: 128,
                           block: Palette.gold, crown: true, delay: 0.1)
                    .padding(.bottom, 28)
            }
            if let third = sortedPlayers[safe: 2] {
                podiumSlot(player: third, place: 3, rank: "3rd", height: 72,
                           block: Palette.bronze, crown: false, delay: 0.4)
            }
        }
    }

    private func podiumSlot(player: Player, place: Int, rank: String,
                            height: CGFloat, block: Color, crown: Bool, delay: Double) -> some View {
        VStack(spacing: 8) {
            if crown { Doodle(kind: .crown, size: 38, color: Palette.gold).wiggle(5) }
            MedalDoodle(place: place, size: crown ? 50 : 38)
            Text(player.name)
                .font(.marker(crown ? 19 : 16, bold: true))
                .foregroundColor(Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.bottom, 2)
            VStack(spacing: 4) {
                Text(rank).font(.marker(17, bold: true)).foregroundColor(Palette.ink)
                Text("\(player.score)").font(.display(26)).foregroundColor(Palette.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding(.top, 16)
            .background(
                SketchyRoundedRectangle(cornerRadius: 12, seed: UInt64(rank.count + 30))
                    .fill(block)
            )
            .overlay(
                SketchyRoundedRectangle(cornerRadius: 12, seed: UInt64(rank.count + 30))
                    .stroke(Palette.ink, lineWidth: 2.5)
            )
        }
        .frame(maxWidth: .infinity)
        .popIn(delay: delay)
    }
}
