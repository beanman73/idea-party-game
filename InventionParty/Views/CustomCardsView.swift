//
//  CustomCardsView.swift
//  Invention Party
//
//  Ported from app/custom-cards.tsx. Sketchbook redesign.
//

import SwiftUI
import PhotosUI

struct CustomCardsView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router

    @State private var cards: [GameObject] = []
    @State private var title: String = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var alert: AlertMessage?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Create Your Own Deck")
                    .font(.display(28))
                    .foregroundColor(Palette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
                Text("Add titles and optional photos from your library")
                    .font(.marker(15))
                    .foregroundColor(Palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 18)

                form
                summaryHeader
                cardGrid

                FilledButton(title: "Use This Deck", background: Palette.mustard,
                             foreground: Palette.ink, seed: 4) { saveCards() }
                    .padding(.top, 20)
                FilledButton(title: "← Back", background: Palette.card,
                             foreground: Palette.ink, fontSize: 18, verticalPadding: 14, seed: 80) { router.pop() }
                    .padding(.top, 12)
            }
            .padding(20)
        }
        .screenBackground()
        .onAppear { if cards.isEmpty { cards = store.customDeckObjects } }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    photoData = data
                }
            }
        }
        .alert(item: $alert) { msg in
            Alert(title: Text(msg.title), message: Text(msg.body), dismissButton: .default(Text("OK")))
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Card Title")
                .font(.marker(16, bold: true))
                .foregroundColor(Palette.ink)
                .padding(.bottom, 8)

            TextField("", text: $title, prompt: Text("Example: Grandma's Cake").foregroundColor(Palette.sheetInkFaint))
                .font(.marker(17))
                .foregroundColor(Palette.sheetInk)
                .padding(14)
                .background(SketchyRoundedRectangle(cornerRadius: 13, seed: 33).fill(Palette.drawSheet))
                .overlay(SketchyRoundedRectangle(cornerRadius: 13, seed: 33).stroke(Palette.sheetInk, lineWidth: 2))
                .padding(.bottom, 14)

            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack(spacing: 8) {
                    Doodle(kind: .camera, size: 20, color: Palette.cream)
                    Text(photoData == nil ? "Choose Photo (optional)" : "Choose a Different Photo")
                        .font(.marker(15, bold: true))
                        .foregroundColor(Palette.cream)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(SketchyRoundedRectangle(cornerRadius: 13, seed: 37).fill(Palette.teal))
                .overlay(SketchyRoundedRectangle(cornerRadius: 13, seed: 37).stroke(Palette.ink, lineWidth: 2))
            }

            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(SketchyRoundedRectangle(cornerRadius: 16, seed: 38))
                    .overlay(SketchyRoundedRectangle(cornerRadius: 16, seed: 38).stroke(Palette.ink, lineWidth: 2.5))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }

            FilledButton(title: "Add Card", background: Palette.leaf,
                         foreground: Palette.cream, fontSize: 18, verticalPadding: 14, seed: 39) { addCard() }
                .padding(.top, 16)
        }
        .padding(16)
        .sketchCard(fill: Palette.card, border: Palette.teal, lineWidth: 2.5, seed: 30)
        .padding(.bottom, 20)
    }

    private var summaryHeader: some View {
        HStack {
            Text("Custom Deck").font(.marker(20, bold: true)).foregroundColor(Palette.ink)
            Spacer()
            SketchBadge(text: "\(cards.count) cards", fill: Palette.mustard, foreground: Palette.sheetInk, seed: 35)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder private var cardGrid: some View {
        if cards.isEmpty {
            Text("Your cards will appear here.")
                .font(.marker(15, bold: true))
                .foregroundColor(Palette.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(
                    SketchyRoundedRectangle(cornerRadius: 14, seed: 36)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                        .foregroundColor(Palette.inkFaint)
                )
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    VStack(spacing: 8) {
                        if let data = card.photoData, let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFill()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .clipShape(SketchyRoundedRectangle(cornerRadius: 11, seed: UInt64(190 + index)))
                                .overlay(SketchyRoundedRectangle(cornerRadius: 11, seed: UInt64(190 + index)).stroke(Palette.ink, lineWidth: 2))
                        } else {
                            Text(card.name)
                                .font(.marker(17, bold: true))
                                .foregroundColor(Palette.ink)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fill)
                                .background(SketchyRoundedRectangle(cornerRadius: 11, seed: UInt64(190 + index)).fill(Palette.cardSunken))
                                .overlay(SketchyRoundedRectangle(cornerRadius: 11, seed: UInt64(190 + index)).stroke(Palette.ink, lineWidth: 2))
                        }
                        Text(card.name)
                            .font(.marker(15, bold: true))
                            .foregroundColor(Palette.ink)
                            .lineLimit(2)
                        Button { removeCard(card) } label: {
                            Text("Remove")
                                .font(.marker(13, bold: true))
                                .foregroundColor(Palette.cream)
                                .frame(maxWidth: .infinity)
                                .padding(7)
                                .background(SketchyRoundedRectangle(cornerRadius: 9, seed: UInt64(220 + index)).fill(Palette.danger))
                                .overlay(SketchyRoundedRectangle(cornerRadius: 9, seed: UInt64(220 + index)).stroke(Palette.ink, lineWidth: 1.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .sketchCard(fill: Palette.card, border: Palette.ink, cornerRadius: 14,
                                lineWidth: 2, seed: UInt64(200 + index), shadow: false)
                }
            }
        }
    }

    // MARK: - Actions

    private func addCard() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            alert = AlertMessage(title: "Add a Title", body: "Give this card a title before adding it.")
            return
        }
        cards.append(GameObject(id: "custom-\(Date().timeIntervalSince1970)", name: trimmed, photoData: photoData))
        title = ""
        photoData = nil
        pickerItem = nil
    }

    private func removeCard(_ card: GameObject) {
        cards.removeAll { $0.id == card.id }
    }

    private func saveCards() {
        guard cards.count >= 2 else {
            alert = AlertMessage(title: "Add More Cards", body: "Create at least two custom cards before using this deck.")
            return
        }
        store.setCustomDeck(cards)
        store.setPack("custom")
        router.push(.rules)
    }
}
