//
//  AIDeckView.swift
//  Invention Party
//
//  Ported from app/ai-deck.tsx. Sketchbook redesign.
//

import SwiftUI

struct AIDeckView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var purchases: PurchaseStore

    @State private var deckTitle: String = ""
    @State private var prompt: String = ""
    @State private var cards: [GameObject] = []
    @State private var generateCardArt = false
    @State private var isGenerating = false
    @State private var generationStatus: String = ""
    @State private var alert: AlertMessage?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    private var aiCreditCountText: String {
        "\(purchases.aiCredits) \(purchases.aiCredits == 1 ? "credit" : "credits")"
    }

    private var aiCreditAvailableText: String {
        "\(purchases.aiCredits) AI \(purchases.aiCredits == 1 ? "credit" : "credits") available"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("AI Deck Generator")
                    .font(.display(30))
                    .foregroundColor(Palette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
                Text("Describe a theme and conjure a full deck of cards")
                    .font(.marker(15))
                    .foregroundColor(Palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 18)

                form
                summaryHeader
                cardGrid

                FilledButton(title: "Use This Deck", background: Palette.mustard,
                             foreground: Palette.buttonInk, seed: 4) { useDeck() }
                    .padding(.top, 20)
                FilledButton(title: "← Back", background: Palette.card,
                             foreground: Palette.ink, fontSize: 18, verticalPadding: 14, seed: 80) { router.pop() }
                    .padding(.top, 12)
            }
            .padding(20)
        }
        .screenBackground()
        .onAppear {
            if prompt.isEmpty { prompt = store.aiDeckPrompt }
            if cards.isEmpty { cards = store.aiDeckObjects }
        }
        .task {
            await purchases.refreshProductsAndEntitlements()
        }
        .alert(item: $alert) { msg in
            Alert(title: Text(msg.title), message: Text(msg.body), dismissButton: .default(Text("OK")))
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Deck Prompt")
                .font(.marker(16, bold: true))
                .foregroundColor(Palette.ink)
                .padding(.bottom, 8)

            TextField("", text: $deckTitle,
                      prompt: Text("Deck title, like Tech Gadgets").foregroundColor(Palette.sheetInkFaint))
                .font(.marker(17))
                .foregroundColor(Palette.sheetInk)
                .padding(14)
                .background(SketchyRoundedRectangle(cornerRadius: 13, seed: 32).fill(Palette.drawSheet))
                .overlay(SketchyRoundedRectangle(cornerRadius: 13, seed: 32).stroke(Palette.sheetInk, lineWidth: 2))
                .padding(.bottom, 12)

            TextField("", text: $prompt,
                      prompt: Text("Example: funny beach vacation objects").foregroundColor(Palette.sheetInkFaint),
                      axis: .vertical)
                .lineLimit(4...8)
                .font(.marker(17))
                .foregroundColor(Palette.sheetInk)
                .padding(14)
                .background(SketchyRoundedRectangle(cornerRadius: 13, seed: 33).fill(Palette.drawSheet))
                .overlay(SketchyRoundedRectangle(cornerRadius: 13, seed: 33).stroke(Palette.sheetInk, lineWidth: 2))
                .padding(.bottom, 14)

            Toggle(isOn: $generateCardArt) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Generate Doodle Pictures")
                        .font(.marker(16, bold: true))
                        .foregroundColor(Palette.ink)
                    Text(generateCardArt
                         ? "Creates a hand-drawn doodle for every card."
                         : "Off: quick text-only cards.")
                        .font(.marker(12, bold: true))
                        .foregroundColor(generateCardArt ? Palette.danger : Palette.inkSoft)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Palette.leaf))
            .padding(13)
            .background(SketchyRoundedRectangle(cornerRadius: 13, seed: 41).fill(Palette.cardSunken))
            .overlay(SketchyRoundedRectangle(cornerRadius: 13, seed: 41)
                .stroke(generateCardArt ? Palette.danger : Palette.ink, lineWidth: generateCardArt ? 2.5 : 2))
            .padding(.bottom, 14)

            Button { Task { await generate() } } label: {
                Group {
                    if isGenerating { ProgressView().tint(Palette.cream) }
                    else {
                        HStack(spacing: 8) {
                            Doodle(kind: .sparkle, size: 20, color: Palette.cream)
                            Text(generateButtonTitle).font(.marker(17, bold: true))
                        }
                    }
                }
                .foregroundColor(Palette.cream)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(SketchyRoundedRectangle(cornerRadius: 13, seed: 34).fill(Palette.grape))
                .overlay(SketchyRoundedRectangle(cornerRadius: 13, seed: 34).stroke(Palette.ink, lineWidth: 2.5))
            }
            .buttonStyle(.plain)
            .opacity(isGenerating ? 0.75 : 1)
            .disabled(isGenerating)

            if isGenerating && !generationStatus.isEmpty {
                Text(generationStatus)
                    .font(.marker(13, bold: true))
                    .foregroundColor(Palette.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
            }
        }
        .padding(16)
        .sketchCard(fill: Palette.card, border: Palette.grape, lineWidth: 2.5, seed: 30)
        .padding(.bottom, 20)
    }

    private var creditCostNote: some View {
        HStack(spacing: 10) {
            Doodle(kind: .sparkle, size: 25, color: Palette.grape)
                .frame(width: 32, height: 32)
                .background(SketchyCircle(seed: 42).fill(Palette.cardSunken))
                .overlay(SketchyCircle(seed: 42).stroke(Palette.ink, lineWidth: 1.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(aiCreditAvailableText)
                    .font(.marker(15, bold: true))
                    .foregroundColor(Palette.ink)
                Text("Text deck: 1 credit. Doodle deck: 6 credits.")
                    .font(.marker(12, bold: true))
                    .foregroundColor(Palette.inkSoft)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(SketchyRoundedRectangle(cornerRadius: 13, seed: 43).fill(Palette.cardSunken))
        .overlay(SketchyRoundedRectangle(cornerRadius: 13, seed: 43).stroke(Palette.ink, lineWidth: 2))
    }

    private var creditStore: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("AI Credit Packs")
                    .font(.display(24))
                    .foregroundColor(Palette.ink)
                Spacer()
                SketchBadge(text: aiCreditCountText, fill: Palette.grape, seed: 44)
            }

            Text("Use credits to make custom decks. Text-only decks use 1 credit; illustrated decks use 6 because they create a doodle for every card.")
                .font(.marker(13, bold: true))
                .foregroundColor(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 10)], spacing: 10) {
                ForEach(LaunchPricing.creditPacks) { offering in
                    creditPackButton(offering)
                }
            }
        }
        .padding(.bottom, 20)
    }

    private func creditPackButton(_ offering: PaidOffering) -> some View {
        Button {
            buyOffering(offering)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    if let badge = offering.badge {
                        miniBadge(text: badge, fill: Palette.mustard, foreground: Palette.buttonInk, seed: UInt64(offering.title.count + 80))
                    }
                    Spacer(minLength: 0)
                }

                Text(offering.title)
                    .font(.marker(17, bold: true))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                Text(purchases.displayPrice(for: offering.productID, fallback: offering.price))
                    .font(.display(24))
                    .foregroundColor(Palette.grape)
                Text(offering.subtitle)
                    .font(.marker(11, bold: true))
                    .foregroundColor(Palette.inkSoft)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
            .padding(12)
            .sketchCard(fill: Palette.card,
                        border: offering.badge == nil ? Palette.sky : Palette.mustard,
                        cornerRadius: 15,
                        lineWidth: 2.3,
                        seed: UInt64(offering.title.count + 50))
        }
        .buttonStyle(.plain)
    }

    private var summaryHeader: some View {
        HStack {
            Text("Generated Deck").font(.marker(20, bold: true)).foregroundColor(Palette.ink)
            Spacer()
            SketchBadge(text: "\(cards.count) cards", fill: Palette.teal, seed: 35)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder private var cardGrid: some View {
        if cards.isEmpty {
            Text("Generated cards will appear here.")
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
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    previewCard(card, index: index)
                }
            }
        }
    }

    private func previewCard(_ card: GameObject, index: Int) -> some View {
        Group {
            if card.photoData != nil ||
                (!card.prefersTextOnly && (card.doodleRecipe != nil || ObjectDoodle.Kind(object: card) != nil)) {
                VStack(spacing: 6) {
                    ObjectTile(object: card, size: 54, emojiSize: 36, titleFontSize: 10,
                               seed: UInt64(200 + index))
                    Text(card.name)
                        .font(.marker(11, bold: true))
                        .foregroundColor(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }
                .padding(7)
            } else {
                Text(card.name)
                    .font(.marker(15, bold: true))
                    .foregroundColor(Palette.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .minimumScaleFactor(0.56)
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.9, contentMode: .fit)
        .sketchCard(fill: Palette.cardSunken, border: Palette.ink, cornerRadius: 12,
                    lineWidth: 1.8, seed: UInt64(180 + index), shadow: false)
    }

    private func miniBadge(text: String, fill: Color, foreground: Color, seed: UInt64) -> some View {
        Text(text)
            .font(.marker(9, bold: true))
            .foregroundColor(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.64)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                SketchyRoundedRectangle(cornerRadius: 7, roughness: 0.8, seed: seed)
                    .fill(fill)
            )
            .overlay(
                SketchyRoundedRectangle(cornerRadius: 7, roughness: 0.8, seed: seed)
                    .stroke(Palette.ink.opacity(0.8), lineWidth: 1.4)
            )
    }

    private var generationCreditCost: Int {
        LaunchPricing.aiDeckCreditCost(illustrated: generateCardArt)
    }

    private var generateButtonTitle: String {
        "Generate Deck"
    }

    // MARK: - Actions

    private func generate() async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            alert = AlertMessage(title: "Add a Prompt", body: "Describe the kind of deck you want to generate.")
            return
        }
        isGenerating = true
        generationStatus = "Starting..."
        defer {
            isGenerating = false
            generationStatus = ""
        }
        do {
            cards = try await DeckGenerator.generate(prompt: trimmed,
                                                     generateImages: generateCardArt) { status in
                Task { @MainActor in generationStatus = status }
            }
            if deckTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                deckTitle = suggestedTitle(from: trimmed)
            }
        } catch {
            alert = AlertMessage(title: "Generation Failed",
                                 body: error.localizedDescription)
        }
    }

    private func buyOffering(_ offering: PaidOffering) {
        Task {
            do {
                try await purchases.purchase(offering)
                alert = AlertMessage(title: "Credits Added",
                                     body: "\(offering.title) has been added to your account.")
            } catch PurchaseStoreError.userCancelled {
                return
            } catch {
                alert = AlertMessage(title: "Purchase Unavailable",
                                     body: error.localizedDescription)
            }
        }
    }

    private func useDeck() {
        guard cards.count >= 2 else {
            alert = AlertMessage(title: "Generate a Deck", body: "Generate at least two cards before using this deck.")
            return
        }
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedDeck = store.saveGeneratedDeck(title: deckTitle, prompt: trimmedPrompt, objects: cards)
        store.setAIDeck(prompt: trimmedPrompt, objects: cards)
        store.setPack(savedDeck.packId)
        router.push(.rules)
    }

    private func suggestedTitle(from prompt: String) -> String {
        let words = prompt
            .split { !$0.isLetter && !$0.isNumber }
            .prefix(4)
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
        let title = words.joined(separator: " ")
        return title.isEmpty ? "Generated Deck" : title
    }
}
