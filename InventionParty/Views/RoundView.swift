//
//  RoundView.swift
//  Invention Party
//
//  Ported from app/round.tsx. Sketchbook redesign.
//

import SwiftUI

struct RoundView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router

    var body: some View {
        Group {
            if let obj1 = store.currentRoundObjects[safe: 0],
               let obj2 = store.currentRoundObjects[safe: 1] {
                content(obj1: obj1, obj2: obj2)
            } else {
                Text("Loading…")
                    .font(.display(28))
                    .foregroundColor(Palette.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .screenBackground()
        .onAppear(perform: generateIfNeeded)
    }

    private func content(obj1: GameObject, obj2: GameObject) -> some View {
        VStack(spacing: 0) {
            Text("Round \(store.currentRound) of \(store.roundsTotal)")
                .font(.marker(15, bold: true))
                .foregroundColor(Palette.cream)
                .padding(.horizontal, 16).padding(.vertical, 7)
                .background(SketchyRoundedRectangle(cornerRadius: 11, seed: 2).fill(Palette.tomato))
                .overlay(SketchyRoundedRectangle(cornerRadius: 11, seed: 2).stroke(Palette.ink, lineWidth: 2))
                .padding(.bottom, 16)

            if store.mode == .crowd {
                HStack(spacing: 8) {
                    Doodle(kind: .face, size: 20, color: Palette.grape)
                    Text("Everyone votes!").font(.marker(17, bold: true)).foregroundColor(Palette.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .sketchCard(fill: Palette.card, border: Palette.grape, lineWidth: 2.5, seed: 6)
                .padding(.bottom, 30)
            } else {
                HStack(spacing: 8) {
                    Doodle(kind: .scales, size: 20, color: Palette.grape)
                    Text("Judge:").font(.marker(16)).foregroundColor(Palette.inkSoft)
                    Text(store.players[safe: store.judgeRotationIndex]?.name ?? "Auto")
                        .font(.marker(18, bold: true)).foregroundColor(Palette.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .sketchCard(fill: Palette.card, border: Palette.grape, lineWidth: 2.5, seed: 6)
                .padding(.bottom, 30)
            }

            Text("Your Objects")
                .font(.display(32)).foregroundColor(Palette.ink)
            Text("Combine these to create something amazing!")
                .font(.marker(15)).foregroundColor(Palette.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.bottom, 34)

            HStack(spacing: 16) {
                objectCard(obj1, seed: 21).popIn(delay: 0.05)
                Text("+").font(.display(42)).foregroundColor(Palette.tomato).popIn(delay: 0.2)
                objectCard(obj2, seed: 22).popIn(delay: 0.35)
            }
            .padding(.bottom, store.currentRoundModifier == nil ? 44 : 24)

            if let modifier = store.currentRoundModifier {
                modifierCard(modifier)
                    .popIn(delay: 0.5)
                    .padding(.bottom, 34)
            }

            FilledButton(title: "Continue to Idea Pad", background: Palette.mustard,
                         foreground: Palette.buttonInk, fontSize: 20, verticalPadding: 18, seed: 4) {
                router.push(.ideaPad)
            }
        }
    }

    private func objectCard(_ object: GameObject, seed: UInt64) -> some View {
        VStack(spacing: 12) {
            ObjectTile(object: object, seed: seed)
            if !object.prefersTextOnly {
                Text(object.name)
                    .font(.marker(17, bold: true))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .multilineTextAlignment(.center)
                    .frame(width: 108)
            }
        }
        .padding(18)
        .sketchCard(fill: Palette.card, border: Palette.ink, cornerRadius: 18, seed: seed &+ 40)
    }

    private func modifierCard(_ modifier: InventionModifier) -> some View {
        HStack(spacing: 10) {
            Doodle(kind: .sparkle, size: 22, color: Palette.grape)
            VStack(alignment: .leading, spacing: 2) {
                Text("Twist")
                    .font(.marker(13, bold: true))
                    .foregroundColor(Palette.inkSoft)
                Text(modifier.text)
                    .font(.marker(19, bold: true))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .sketchCard(fill: Palette.card, border: Palette.grape, lineWidth: 2.5, seed: 51)
    }

    private func generateIfNeeded() {
        guard store.currentRoundObjects.isEmpty, let pack = store.activePack() else { return }
        let objects = ObjectPacks.randomObjects(from: pack, count: 2,
                                                avoidingRecentIds: store.recentObjectIds)
        let modifier = store.modifiersEnabled ? InventionModifiers.randomModifier(for: objects) : nil
        store.startRound(objects: objects, modifier: modifier)
    }
}
