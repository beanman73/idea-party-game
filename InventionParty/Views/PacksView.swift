//
//  PacksView.swift
//  Invention Party
//
//  Ported from app/packs.tsx. Sketchbook redesign.
//

import SwiftUI
import UIKit

struct PacksView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var purchases: PurchaseStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("playfulAnimations") private var playfulAnimations: Bool = true
    @State private var lockedAlert = false
    @State private var purchaseAlert: AlertMessage?
    @State private var deckPendingDelete: SavedDeck?
    @State private var showingDeleteConfirmation = false
    @State private var isMixingDecks = false
    @State private var selectedMixedDeckIds: Set<String> = []
    @State private var shelfSettled = false
    @State private var selectedDeckDetail: DeckDetail?
    @State private var showingPricingPanel = false

    private let gridColumns = [
        GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14, alignment: .top)
    ]

    private var selectableDecks: [ObjectPack] {
        ObjectPacks.all + store.savedDecks.map(\.objectPack)
    }

    private var totalShelfCount: Int {
        ObjectPacks.all.count + store.savedDecks.count + 1
    }

    private var animationsEnabled: Bool {
        playfulAnimations && !reduceMotion
    }

    private var aiCreditBadgeText: String {
        "\(purchases.aiCredits) AI \(purchases.aiCredits == 1 ? "credit" : "credits")"
    }

    var body: some View {
        ZStack {
            mainContent

            if let selectedDeckDetail {
                deckDetailOverlay(selectedDeckDetail)
                    .zIndex(10)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.88, anchor: .center)
                            .combined(with: .opacity)
                            .combined(with: .move(edge: .bottom)),
                        removal: .scale(scale: 0.96, anchor: .center)
                            .combined(with: .opacity)
                    ))
            }

            if showingPricingPanel {
                pricingOverlay
                    .zIndex(11)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.96).combined(with: .opacity)
                    ))
            }
        }
        .screenBackground()
        .onAppear {
            runShelfIntro()
        }
        .task {
            await purchases.refreshProductsAndEntitlements()
        }
        .alert("Deck Locked", isPresented: $lockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Unlock this pack by buying it once, getting the full deck library, or subscribing to Party Pass.")
        }
        .alert(item: $purchaseAlert) { msg in
            Alert(title: Text(msg.title), message: Text(msg.body), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Delete this deck?", isPresented: $showingDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Delete Deck", role: .destructive) {
                if let deck = deckPendingDelete {
                    store.deleteSavedDeck(deck)
                    deckPendingDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                deckPendingDelete = nil
            }
        } message: {
            Text("This generated deck may have cost money to create. You will not be able to get it back after deleting it.")
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            storeHeader

            mixDeckToggle
                .padding(.top, 14)
                .padding(.bottom, 9)
                .zIndex(2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if !isMixingDecks {
                        aiDeckCard
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text(isMixingDecks ? "Mix Shelf" : "Pack Library")
                            .font(.display(25))
                            .foregroundColor(Palette.ink)
                        Spacer()
                        Text("\(ObjectPacks.all.count + store.savedDecks.count) packs")
                            .font(.marker(13, bold: true))
                            .foregroundColor(Palette.inkSoft)
                    }

                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(Array(ObjectPacks.all.enumerated()), id: \.element.id) { index, pack in
                            packCard(pack, index: index)
                                .deckShelfEntrance(index: gridEntranceIndex(index),
                                                   active: shelfSettled,
                                                   enabled: animationsEnabled)
                        }
                        ForEach(Array(store.savedDecks.enumerated()), id: \.element.id) { index, deck in
                            savedDeckCard(deck, index: index)
                                .deckShelfEntrance(index: gridEntranceIndex(ObjectPacks.all.count + index),
                                                   active: shelfSettled,
                                                   enabled: animationsEnabled)
                        }
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 16)
            }

            if isMixingDecks {
                FilledButton(title: mixStartTitle,
                             background: selectedMixedDeckIds.count >= 2 ? Palette.mustard : Palette.card,
                             foreground: selectedMixedDeckIds.count >= 2 ? Palette.buttonInk : Palette.inkFaint,
                             fontSize: 18,
                             verticalPadding: 14,
                             seed: 83,
                             icon: .puzzle) {
                    startMixedDeck()
                }
                .disabled(selectedMixedDeckIds.count < 2)
                .padding(.top, 12)
            }

            FilledButton(title: "Back", background: Palette.card,
                         foreground: Palette.ink, fontSize: 18, verticalPadding: 14, seed: 80) {
                dismissDeckDetail(animated: false)
                router.pop()
            }
            .padding(.top, 12)
        }
        .padding(20)
    }

    // MARK: - Header

    private var storeHeader: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                SketchBadge(text: "\(totalShelfCount) shelves", fill: Palette.leaf, seed: 13)
            }

            Text("Deck Shop")
                .font(.display(36))
                .foregroundColor(Palette.ink)
                .multilineTextAlignment(.center)

            Text("Pick a pack with its own invention vibe.")
                .font(.marker(15, bold: true))
                .foregroundColor(Palette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Controls

    private var mixDeckToggle: some View {
        Toggle(isOn: $isMixingDecks) {
            HStack(spacing: 12) {
                Doodle(kind: isMixingDecks ? .puzzle : .dice,
                       size: 30,
                       color: isMixingDecks ? Palette.leaf : Palette.sky)
                    .frame(width: 38, height: 38)
                    .background(
                        SketchyCircle(seed: 82)
                            .fill(Palette.cardSunken)
                    )
                    .overlay(
                        SketchyCircle(seed: 82)
                            .stroke(Palette.ink, lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Mix Decks")
                        .font(.marker(17, bold: true))
                        .foregroundColor(Palette.ink)
                    Text(isMixingDecks
                         ? "Select two or more covers for one mashed-up round."
                         : "Blend packs after you browse the shelf.")
                        .font(.marker(13, bold: true))
                        .foregroundColor(Palette.inkSoft)
                        .lineLimit(2)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Palette.leaf))
        .padding(13)
        .sketchCard(fill: Palette.card,
                    border: isMixingDecks ? Palette.leaf : Palette.ink,
                    cornerRadius: 17,
                    lineWidth: isMixingDecks ? 3 : 2,
                    seed: 82)
        .onChange(of: isMixingDecks) {
            if !isMixingDecks { selectedMixedDeckIds = [] }
            runShelfIntro(restart: true)
        }
    }

    private var mixStartTitle: String {
        selectedMixedDeckIds.count < 2
            ? "Select 2+ Decks"
            : "Use \(selectedMixedDeckIds.count) Mixed Decks"
    }

    // MARK: - Cards

    private var pricingOverlay: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture {
                    hidePricingPanel()
                }

            VStack {
                Spacer(minLength: 18)
                pricingPanel
                Spacer(minLength: 18)
            }
            .padding(.horizontal, 18)
        }
    }

    private var pricingPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Text("Pricing")
                        .font(.display(28))
                        .foregroundColor(Palette.ink)
                    Spacer()
                    Button {
                        hidePricingPanel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Palette.ink)
                            .frame(width: 36, height: 36)
                            .background(SketchyCircle(seed: 121).fill(Palette.cardSunken))
                            .overlay(SketchyCircle(seed: 121).stroke(Palette.ink, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }

                Text("Choose a pass for premium packs, or add credits for custom AI decks.")
                    .font(.marker(13, bold: true))
                    .foregroundColor(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 154), spacing: 12)], spacing: 12) {
                    pricingTile(title: LaunchPricing.partyPass.title,
                                price: purchases.displayPrice(for: LaunchPricing.partyPass.productID,
                                                              fallback: LaunchPricing.partyPass.price),
                                subtitle: LaunchPricing.partyPass.subtitle,
                                badge: LaunchPricing.partyPass.badge,
                                tint: Palette.mustard,
                                seed: 123) {
                        buyOffering(LaunchPricing.partyPass,
                                    successTitle: "Party Pass Active",
                                    successBody: "Premium packs are unlocked and 10 AI credits were added for this month.")
                    }

                    pricingTile(title: LaunchPricing.fullLibrary.title,
                                price: purchases.displayPrice(for: LaunchPricing.fullLibrary.productID,
                                                              fallback: LaunchPricing.fullLibrary.price),
                                subtitle: LaunchPricing.fullLibrary.subtitle,
                                badge: LaunchPricing.fullLibrary.badge,
                                tint: Palette.sky,
                                seed: 124) {
                        buyOffering(LaunchPricing.fullLibrary,
                                    successTitle: "Deck Library Unlocked",
                                    successBody: "Every premium deck pack in this release is ready to play.")
                    }

                    pricingTile(title: "AI Credits",
                                price: "10 for \(purchases.displayPrice(for: LaunchPricing.creditPacks[0].productID, fallback: LaunchPricing.creditPacks[0].price))",
                                subtitle: "24 for \(purchases.displayPrice(for: LaunchPricing.creditPacks[1].productID, fallback: LaunchPricing.creditPacks[1].price)) • 50 for \(purchases.displayPrice(for: LaunchPricing.creditPacks[2].productID, fallback: LaunchPricing.creditPacks[2].price)). Text decks cost 1 credit; doodle decks cost 6.",
                                badge: "AI",
                                tint: Palette.grape,
                                seed: 126) {
                        hidePricingPanel(animated: false)
                        router.push(.aiDeck)
                    }
                }

                Button {
                    restorePurchases()
                } label: {
                    Text("Restore Purchases")
                        .font(.marker(14, bold: true))
                        .foregroundColor(Palette.grape)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(SketchyRoundedRectangle(cornerRadius: 12, seed: 127).fill(Palette.cardSunken))
                        .overlay(SketchyRoundedRectangle(cornerRadius: 12, seed: 127).stroke(Palette.grape, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
            .padding(17)
        }
        .frame(maxWidth: 540)
        .frame(maxHeight: 560)
        .sketchCard(fill: Palette.card,
                    border: Palette.grape,
                    cornerRadius: 22,
                    lineWidth: 3,
                    seed: 120)
    }

    private func pricingTile(title: String,
                             price: String,
                             subtitle: String,
                             badge: String?,
                             tint: Color,
                             seed: UInt64,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    if let badge {
                        miniBadge(text: badge, fill: tint, foreground: Palette.cream, seed: seed &+ 2)
                    }
                    Spacer(minLength: 0)
                }

                Text(title)
                    .font(.marker(17, bold: true))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(price)
                    .font(.display(23))
                    .foregroundColor(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(subtitle)
                    .font(.marker(11, bold: true))
                    .foregroundColor(Palette.inkSoft)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
            .padding(12)
            .sketchCard(fill: Palette.card,
                        border: tint,
                        cornerRadius: 15,
                        lineWidth: 2.3,
                        seed: seed)
        }
        .buttonStyle(.plain)
    }

    private var aiDeckCard: some View {
        let marketing = DeckMarketing(
            eyebrow: "CUSTOM",
            shortName: "AI Deck",
            salesLine: store.aiDeckObjects.isEmpty
                ? "Turn one idea into a fresh invention pack."
                : "\(store.aiDeckObjects.count) generated cards are waiting.",
            coverFill: Palette.grape,
            coverAccent: Palette.mustard,
            titleColor: Palette.cream,
            seed: 31
        )

        return Button {
            router.push(.aiDeck)
        } label: {
            HStack(spacing: 15) {
                promoDeckCover(marketing: marketing,
                               title: "AI Deck",
                               badge: "AI",
                               seed: 31)
                    .frame(width: 108)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Build Your Own Pack")
                        .font(.display(22))
                        .foregroundColor(Palette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.74)
                    Text(marketing.salesLine)
                        .font(.marker(14, bold: true))
                        .foregroundColor(Palette.inkSoft)
                        .lineLimit(3)
                    Text("Open Generator")
                        .font(.marker(14, bold: true))
                        .foregroundColor(Palette.grape)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .sketchCard(fill: Palette.card,
                        border: Palette.grape,
                        cornerRadius: 18,
                        lineWidth: 3,
                        seed: 30)
        }
        .buttonStyle(.plain)
        .deckShelfEntrance(index: 0, active: shelfSettled, enabled: animationsEnabled)
    }

    private func packCard(_ pack: ObjectPack, index: Int) -> some View {
        let marketing = marketing(for: pack, index: index)
        let selected = selectedMixedDeckIds.contains(pack.id)
        let locked = isPackLocked(pack)
        let badge = deckBadge(for: pack, selected: selected)

        return Button {
            if isMixingDecks {
                toggleMixedDeck(pack)
            } else {
                presentDeckDetail(pack: pack, marketing: marketing, seed: UInt64(200 + index))
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                deckCover(pack: pack,
                          marketing: marketing,
                          badge: badge.text,
                          badgeFill: badge.fill,
                          badgeForeground: badge.foreground,
                          selected: selected,
                          seed: UInt64(200 + index))

                VStack(alignment: .leading, spacing: 6) {
                    Text(marketing.salesLine)
                        .font(.marker(13, bold: true))
                        .foregroundColor(Palette.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text("\(pack.objects.count) cards")
                            .font(.marker(12, bold: true))
                            .foregroundColor(Palette.inkSoft)
                        Spacer(minLength: 0)
                        Text(deckActionLabel(for: pack, selected: selected))
                            .font(.marker(12, bold: true))
                            .foregroundColor(selected ? Palette.leaf : marketing.coverAccent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .sketchCard(fill: Palette.card,
                        border: selected ? Palette.leaf : (locked ? Palette.inkFaint : marketing.coverAccent),
                        cornerRadius: 17,
                        lineWidth: selected ? 4 : 2.5,
                        seed: UInt64(60 + index))
            .opacity(locked ? 0.84 : 1)
            .selectedDeckBounce(selected, index: index, enabled: animationsEnabled)
        }
        .buttonStyle(.plain)
    }

    private func savedDeckCard(_ deck: SavedDeck, index: Int) -> some View {
        let pack = deck.objectPack
        let marketing = savedMarketing(for: deck, index: index)
        let selected = selectedMixedDeckIds.contains(pack.id)
        let badge = selected ? ("SELECTED", Palette.leaf, Palette.cream) : ("SAVED", marketing.coverAccent, Palette.cream)

        return VStack(spacing: 8) {
            Button {
                if isMixingDecks {
                    toggleMixedDeck(pack)
                } else {
                    presentDeckDetail(pack: pack, marketing: marketing, seed: UInt64(520 + index), saved: true)
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    deckCover(pack: pack,
                              marketing: marketing,
                              badge: badge.0,
                              badgeFill: badge.1,
                              badgeForeground: badge.2,
                              selected: selected,
                              seed: UInt64(520 + index))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(deck.prompt.isEmpty ? "A handmade invention pack." : deck.prompt)
                            .font(.marker(13, bold: true))
                            .foregroundColor(Palette.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            Text("\(deck.objects.count) cards")
                                .font(.marker(12, bold: true))
                                .foregroundColor(Palette.inkSoft)
                            Spacer(minLength: 0)
                            Text(selected ? "Added" : (isMixingDecks ? "Tap to Add" : "Play"))
                                .font(.marker(12, bold: true))
                                .foregroundColor(selected ? Palette.leaf : marketing.coverAccent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .sketchCard(fill: Palette.card,
                            border: selected ? Palette.leaf : marketing.coverAccent,
                            cornerRadius: 17,
                            lineWidth: selected ? 4 : 2.5,
                            seed: UInt64(80 + index))
                .selectedDeckBounce(selected, index: index + ObjectPacks.all.count, enabled: animationsEnabled)
            }
            .buttonStyle(.plain)

            if !isMixingDecks {
                Button {
                    deckPendingDelete = deck
                    showingDeleteConfirmation = true
                } label: {
                    Text("Delete Deck")
                        .font(.marker(13, bold: true))
                        .foregroundColor(Palette.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            SketchyRoundedRectangle(cornerRadius: 10, seed: UInt64(120 + index))
                                .fill(Palette.cardSunken)
                        )
                        .overlay(
                            SketchyRoundedRectangle(cornerRadius: 10, seed: UInt64(120 + index))
                                .stroke(Palette.danger, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Deck detail

    private func deckDetailOverlay(_ detail: DeckDetail) -> some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissDeckDetail()
                }

            VStack {
                Spacer(minLength: 18)
                deckDetailPanel(detail)
                Spacer(minLength: 18)
            }
            .padding(.horizontal, 18)
        }
    }

    private func deckDetailPanel(_ detail: DeckDetail) -> some View {
        let badge = detail.isSaved ? (detail.badgeText, detail.badgeFill, detail.badgeForeground) : deckBadge(for: detail.pack, selected: false)
        let locked = !detail.isSaved && isPackLocked(detail.pack)

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    SketchBadge(text: detail.marketing.eyebrow.uppercased(),
                                fill: detail.marketing.coverAccent,
                                foreground: Palette.cream,
                                seed: detail.seed &+ 60)
                    Spacer()
                    Button {
                        dismissDeckDetail()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Palette.ink)
                            .frame(width: 36, height: 36)
                            .background(
                                SketchyCircle(seed: detail.seed &+ 61)
                                    .fill(Palette.cardSunken)
                            )
                            .overlay(
                                SketchyCircle(seed: detail.seed &+ 61)
                                    .stroke(Palette.ink, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }

                HStack(alignment: .top, spacing: 16) {
                    deckCover(pack: detail.pack,
                              marketing: detail.marketing,
                              badge: badge.0,
                              badgeFill: badge.1,
                              badgeForeground: badge.2,
                              selected: false,
                              seed: detail.seed)
                        .frame(width: 128)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(detail.marketing.shortName)
                            .font(.display(28))
                            .foregroundColor(Palette.ink)
                            .lineLimit(3)
                            .minimumScaleFactor(0.62)
                        Text(deckDescription(for: detail))
                            .font(.marker(14, bold: true))
                            .foregroundColor(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            miniBadge(text: "\(detail.pack.objects.count) CARDS",
                                      fill: Palette.cardSunken,
                                      foreground: Palette.ink,
                                      seed: detail.seed &+ 62)
                            miniBadge(text: badge.0,
                                      fill: badge.1,
                                      foreground: badge.2,
                                      seed: detail.seed &+ 63)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                deckSampleShelf(objects: detail.pack.objects, seed: detail.seed &+ 80)

                FilledButton(title: deckDetailActionTitle(for: detail),
                             background: locked ? detail.marketing.coverAccent : Palette.mustard,
                             foreground: locked ? Palette.cream : Palette.buttonInk,
                             fontSize: 18,
                             verticalPadding: 14,
                             seed: detail.seed &+ 90,
                             icon: locked ? .lock : .controller) {
                    useDeckFromDetail(detail)
                }
            }
            .padding(17)
        }
        .frame(maxWidth: 520)
        .frame(maxHeight: 640)
        .sketchCard(fill: Palette.card,
                    border: detail.marketing.coverAccent,
                    cornerRadius: 22,
                    lineWidth: 3,
                    seed: detail.seed &+ 70)
    }

    private func deckSampleShelf(objects: [GameObject], seed: UInt64) -> some View {
        let columns = [
            GridItem(.adaptive(minimum: 112), spacing: 8, alignment: .top)
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("Sample Cards")
                .font(.marker(16, bold: true))
                .foregroundColor(Palette.ink)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(objects.prefix(8).enumerated()), id: \.element.id) { index, object in
                    HStack(spacing: 7) {
                        coverObjectArt(object: object,
                                       size: 30,
                                       seed: seed &+ UInt64(index))
                            .frame(width: 32, height: 32)
                        Text(object.name)
                            .font(.marker(12, bold: true))
                            .foregroundColor(Palette.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(
                        SketchyRoundedRectangle(cornerRadius: 11,
                                                roughness: 1,
                                                seed: seed &+ UInt64(index))
                            .fill(Palette.cardSunken)
                    )
                    .overlay(
                        SketchyRoundedRectangle(cornerRadius: 11,
                                                roughness: 1,
                                                seed: seed &+ UInt64(index))
                            .stroke(Palette.ink.opacity(0.58), lineWidth: 1.6)
                    )
                }
            }
        }
    }

    // MARK: - Deck cover art

    private func deckCover(pack: ObjectPack,
                           marketing: DeckMarketing,
                           badge: String,
                           badgeFill: Color,
                           badgeForeground: Color,
                           selected: Bool,
                           seed: UInt64) -> some View {
        ZStack {
            SketchyRoundedRectangle(cornerRadius: 16, roughness: 1.2, seed: seed)
                .fill(marketing.coverFill)

            coverPattern(accent: marketing.coverAccent, titleColor: marketing.titleColor, seed: seed)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 6) {
                    Text(marketing.eyebrow.uppercased())
                        .font(.marker(10, bold: true))
                        .foregroundColor(marketing.titleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Spacer(minLength: 4)
                    miniBadge(text: badge, fill: badgeFill, foreground: badgeForeground, seed: seed &+ 6)
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)

                Spacer(minLength: 4)

                coverObjectCluster(objects: pack.objects, seed: seed &+ 20)

                Spacer(minLength: 4)

                Text(marketing.shortName.uppercased())
                    .font(.display(23))
                    .foregroundColor(marketing.titleColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.62)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 9)
                    .padding(.bottom, 12)
                    .shadow(color: Palette.ink.opacity(0.18), radius: 0, x: 1.2, y: 1.4)
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .overlay(
            SketchyRoundedRectangle(cornerRadius: 16, roughness: 1.2, seed: seed)
                .stroke(selected ? Palette.leaf : Palette.cream, lineWidth: selected ? 4 : 4)
        )
        .overlay(
            SketchyRoundedRectangle(cornerRadius: 12, roughness: 1.0, seed: seed &+ 1)
                .stroke(Palette.ink.opacity(0.34), lineWidth: 1.6)
                .padding(5)
        )
        .shadow(color: Palette.ink.opacity(0.18), radius: 0, x: 3, y: 4)
    }

    private func promoDeckCover(marketing: DeckMarketing,
                                title: String,
                                badge: String,
                                seed: UInt64) -> some View {
        ZStack {
            SketchyRoundedRectangle(cornerRadius: 16, roughness: 1.2, seed: seed)
                .fill(marketing.coverFill)
            coverPattern(accent: marketing.coverAccent, titleColor: marketing.titleColor, seed: seed)

            VStack(spacing: 9) {
                HStack {
                    Text(marketing.eyebrow)
                        .font(.marker(10, bold: true))
                        .foregroundColor(marketing.titleColor)
                    Spacer(minLength: 0)
                    miniBadge(text: badge, fill: Palette.leaf, foreground: Palette.cream, seed: seed &+ 3)
                }
                Doodle(kind: .sparkle, size: 54, color: marketing.titleColor)
                    .frame(maxWidth: .infinity)
                Text(title.uppercased())
                    .font(.display(21))
                    .foregroundColor(marketing.titleColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.68)
            }
            .padding(10)
        }
        .aspectRatio(0.72, contentMode: .fit)
        .overlay(
            SketchyRoundedRectangle(cornerRadius: 16, roughness: 1.2, seed: seed)
                .stroke(Palette.cream, lineWidth: 4)
        )
        .shadow(color: Palette.ink.opacity(0.18), radius: 0, x: 3, y: 4)
    }

    private func coverPattern(accent: Color, titleColor: Color, seed: UInt64) -> some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 2
            var y: CGFloat = -size.height
            while y < size.height * 2 {
                var path = Path()
                path.move(to: CGPoint(x: -8, y: y))
                path.addLine(to: CGPoint(x: size.width + 8, y: y + size.width * 0.55))
                context.stroke(path,
                               with: .color(titleColor.opacity(0.14)),
                               style: StrokeStyle(lineWidth: stripeWidth, lineCap: .round))
                y += 20
            }

            for index in 0..<8 {
                let column = CGFloat((index * 37 + Int(seed % 11)) % 100) / 100
                let row = CGFloat((index * 29 + Int(seed % 17)) % 100) / 100
                let radius = CGFloat(3 + (index % 3))
                let rect = CGRect(x: column * size.width,
                                  y: row * size.height,
                                  width: radius,
                                  height: radius)
                context.fill(Path(ellipseIn: rect), with: .color(accent.opacity(0.28)))
            }
        }
        .allowsHitTesting(false)
    }

    private func coverObjectCluster(objects: [GameObject], seed: UInt64) -> some View {
        let samples = Array(objects.prefix(3))

        return ZStack {
            ForEach(Array(samples.enumerated()), id: \.element.id) { index, object in
                coverObjectArt(object: object,
                               size: objectArtSize(index),
                               seed: seed &+ UInt64(index))
                    .frame(width: objectArtSize(index), height: objectArtSize(index))
                    .background(
                        SketchyCircle(seed: seed &+ UInt64(index * 13))
                            .fill(Palette.cardSunken.opacity(0.92))
                    )
                    .overlay(
                        SketchyCircle(seed: seed &+ UInt64(index * 13))
                            .stroke(Palette.ink.opacity(0.64), lineWidth: index == 1 ? 2.4 : 2)
                    )
                    .offset(objectArtOffset(index))
                    .zIndex(index == 1 ? 2 : 1)
            }
        }
        .frame(height: 92)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func coverObjectArt(object: GameObject, size: CGFloat, seed: UInt64) -> some View {
        if let data = object.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .clipShape(SketchyCircle(seed: seed))
        } else if !object.prefersTextOnly, let kind = ObjectDoodle.Kind(object: object) {
            ObjectDoodle(kind: kind, size: size * 0.82)
        } else if !object.prefersTextOnly, let recipe = object.doodleRecipe {
            GeneratedDoodle(recipe: recipe, size: size * 0.82, seed: seed)
        } else {
            Text(object.name)
                .font(.marker(8, bold: true))
                .foregroundColor(Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .padding(5)
        }
    }

    private func objectArtSize(_ index: Int) -> CGFloat {
        index == 1 ? 66 : 52
    }

    private func objectArtOffset(_ index: Int) -> CGSize {
        switch index {
        case 0: return CGSize(width: -35, height: 9)
        case 1: return CGSize(width: 0, height: -2)
        default: return CGSize(width: 35, height: 10)
        }
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

    // MARK: - Metadata

    private func marketing(for pack: ObjectPack, index: Int) -> DeckMarketing {
        switch pack.id {
        case "starter":
            return DeckMarketing(eyebrow: "STARTER",
                                 shortName: "Household",
                                 salesLine: "Everyday objects, surprise inventions, instant table energy.",
                                 coverFill: Palette.sky,
                                 coverAccent: Palette.mustard,
                                 titleColor: Palette.cream,
                                 seed: 100)
        case "tech":
            return DeckMarketing(eyebrow: "NEW",
                                 shortName: "Tech & Gadgets",
                                 salesLine: "Sensors, screens, trackers, and tiny future things.",
                                 coverFill: Palette.grape,
                                 coverAccent: Palette.teal,
                                 titleColor: Palette.cream,
                                 seed: 101)
        case "kitchen":
            return DeckMarketing(eyebrow: "PARTY TABLE",
                                 shortName: "Kitchen",
                                 salesLine: "Utensils and appliances made weird on purpose.",
                                 coverFill: Palette.tomato,
                                 coverAccent: Palette.mustard,
                                 titleColor: Palette.cream,
                                 seed: 102)
        case "sports":
            return DeckMarketing(eyebrow: "ACTION",
                                 shortName: "Sports Gear",
                                 salesLine: "Training gear, arena props, and fast-moving ideas.",
                                 coverFill: Palette.leaf,
                                 coverAccent: Palette.sky,
                                 titleColor: Palette.cream,
                                 seed: 103)
        case "school":
            return DeckMarketing(eyebrow: "CLASSROOM",
                                 shortName: "School Supplies",
                                 salesLine: "Desk objects, classroom tools, and brilliant nonsense.",
                                 coverFill: Palette.mustard,
                                 coverAccent: Palette.tomato,
                                 titleColor: Palette.ink,
                                 seed: 104)
        default:
            let accents: [(Color, Color, Color)] = [
                (Palette.teal, Palette.mustard, Palette.cream),
                (Palette.sky, Palette.tomato, Palette.cream),
                (Palette.grape, Palette.leaf, Palette.cream)
            ]
            let colors = accents[index % accents.count]
            return DeckMarketing(eyebrow: "PACK",
                                 shortName: pack.name,
                                 salesLine: "A fresh set of objects for quick invention rounds.",
                                 coverFill: colors.0,
                                 coverAccent: colors.1,
                                 titleColor: colors.2,
                                 seed: UInt64(120 + index))
        }
    }

    private func savedMarketing(for deck: SavedDeck, index: Int) -> DeckMarketing {
        let colors: [(Color, Color, Color)] = [
            (Palette.teal, Palette.mustard, Palette.cream),
            (Palette.sky, Palette.tomato, Palette.cream),
            (Palette.grape, Palette.leaf, Palette.cream)
        ]
        let colorSet = colors[index % colors.count]
        return DeckMarketing(eyebrow: "CUSTOM",
                             shortName: deck.title,
                             salesLine: deck.prompt.isEmpty ? "A handmade invention pack." : deck.prompt,
                             coverFill: colorSet.0,
                             coverAccent: colorSet.1,
                             titleColor: colorSet.2,
                             seed: UInt64(200 + index))
    }

    private func deckDescription(for detail: DeckDetail) -> String {
        switch detail.pack.id {
        case "starter":
            return "A friendly first shelf of familiar objects that turns ordinary rooms into invention prompts."
        case "tech":
            return "A gadget-heavy pack for smart homes, sensors, tiny screens, and future-facing inventions."
        case "kitchen":
            return "Food tools, countertop gear, and kitchen chaos for inventions that feel practical and ridiculous."
        case "sports":
            return "Fast, competitive objects from courts, gyms, fields, and training rooms."
        case "school":
            return "Classroom supplies and desk gear for clever school-day inventions."
        default:
            return detail.marketing.salesLine
        }
    }

    private func deckBadge(for pack: ObjectPack, selected: Bool) -> (text: String, fill: Color, foreground: Color) {
        if selected {
            return ("SELECTED", Palette.leaf, Palette.cream)
        }
        if isPackLocked(pack) {
            return (priceText(for: pack), Palette.inkFaint, Palette.cream)
        }
        if LaunchPricing.isPremiumPack(pack.id) {
            return ("OWNED", Palette.sky, Palette.cream)
        }
        return ("FREE", Palette.leaf, Palette.cream)
    }

    private func deckActionLabel(for pack: ObjectPack, selected: Bool) -> String {
        if selected { return "Added" }
        if isMixingDecks { return "Tap to Add" }
        if isPackLocked(pack) { return "Unlock" }
        return "Details"
    }

    private func deckDetailActionTitle(for detail: DeckDetail) -> String {
        if detail.isSaved || !isPackLocked(detail.pack) {
            return "Use This Deck"
        }
        return "Unlock \(priceText(for: detail.pack))"
    }

    private func isPackLocked(_ pack: ObjectPack) -> Bool {
        if pack.isLocked { return true }
        return !purchases.canUsePack(pack.id)
    }

    private func priceText(for pack: ObjectPack) -> String {
        guard let productID = LaunchPricing.productID(forPackID: pack.id) else {
            return pack.price ?? "LOCKED"
        }
        return purchases.displayPrice(for: productID, fallback: pack.price ?? LaunchPricing.premiumPackPrice)
    }

    // MARK: - Actions

    private func presentDeckDetail(pack: ObjectPack,
                                   marketing: DeckMarketing,
                                   seed: UInt64,
                                   saved: Bool = false) {
        let badge: (text: String, fill: Color, foreground: Color) = saved
            ? ("SAVED", marketing.coverAccent, Palette.cream)
            : deckBadge(for: pack, selected: false)
        let detail = DeckDetail(pack: pack,
                                marketing: marketing,
                                seed: seed,
                                badgeText: badge.text,
                                badgeFill: badge.fill,
                                badgeForeground: badge.foreground,
                                isSaved: saved)

        if animationsEnabled {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.74)) {
                selectedDeckDetail = detail
            }
        } else {
            selectedDeckDetail = detail
        }
    }

    private func dismissDeckDetail(animated: Bool = true) {
        guard selectedDeckDetail != nil else { return }

        if animated && animationsEnabled {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedDeckDetail = nil
            }
        } else {
            selectedDeckDetail = nil
        }
    }

    private func showPricingPanel() {
        dismissDeckDetail(animated: false)
        if animationsEnabled {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingPricingPanel = true
            }
        } else {
            showingPricingPanel = true
        }
    }

    private func hidePricingPanel(animated: Bool = true) {
        guard showingPricingPanel else { return }
        if animated && animationsEnabled {
            withAnimation(.easeInOut(duration: 0.18)) {
                showingPricingPanel = false
            }
        } else {
            showingPricingPanel = false
        }
    }

    private func buyOffering(_ offering: PaidOffering,
                             successTitle: String,
                             successBody: String) {
        Task {
            do {
                try await purchases.purchase(offering)
                purchaseAlert = AlertMessage(title: successTitle, body: successBody)
            } catch PurchaseStoreError.userCancelled {
                return
            } catch {
                purchaseAlert = AlertMessage(title: "Purchase Unavailable",
                                             body: error.localizedDescription)
            }
        }
    }

    private func buyPack(_ pack: ObjectPack) {
        guard let productID = LaunchPricing.productID(forPackID: pack.id) else {
            purchaseAlert = AlertMessage(title: "Deck Locked",
                                         body: "This deck is not available for purchase yet.")
            return
        }

        Task {
            do {
                try await purchases.purchase(productID: productID)
                purchaseAlert = AlertMessage(title: "Deck Unlocked",
                                             body: "\(pack.name) is ready to play.")
            } catch PurchaseStoreError.userCancelled {
                return
            } catch {
                purchaseAlert = AlertMessage(title: "Purchase Unavailable",
                                             body: error.localizedDescription)
            }
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await purchases.restorePurchases()
                purchaseAlert = AlertMessage(title: "Purchases Restored",
                                             body: "Any active subscriptions and purchased deck packs are available again.")
            } catch {
                purchaseAlert = AlertMessage(title: "Restore Failed",
                                             body: error.localizedDescription)
            }
        }
    }

    private func useDeckFromDetail(_ detail: DeckDetail) {
        if !detail.isSaved && isPackLocked(detail.pack) {
            buyPack(detail.pack)
            return
        }
        dismissDeckDetail(animated: false)
        store.setPack(detail.pack.id)
        router.push(.rules)
    }

    private func toggleMixedDeck(_ pack: ObjectPack) {
        guard !isPackLocked(pack) else {
            lockedAlert = true
            return
        }
        if selectedMixedDeckIds.contains(pack.id) {
            selectedMixedDeckIds.remove(pack.id)
        } else {
            selectedMixedDeckIds.insert(pack.id)
        }
    }

    private func startMixedDeck() {
        let chosenDecks = selectableDecks.filter { selectedMixedDeckIds.contains($0.id) && !$0.isLocked }
        guard chosenDecks.count >= 2 else { return }
        store.setMixedDeck(from: chosenDecks)
        router.push(.rules)
    }

    private func gridEntranceIndex(_ index: Int) -> Int {
        index + (isMixingDecks ? 0 : 1)
    }

    private func runShelfIntro(restart: Bool = false) {
        guard animationsEnabled else {
            shelfSettled = true
            return
        }

        if restart {
            shelfSettled = false
        }

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.72)) {
                shelfSettled = true
            }
        }
    }
}

private struct DeckDetail: Identifiable {
    var id: String { pack.id }
    let pack: ObjectPack
    let marketing: DeckMarketing
    let seed: UInt64
    let badgeText: String
    let badgeFill: Color
    let badgeForeground: Color
    let isSaved: Bool
}

private struct DeckMarketing {
    let eyebrow: String
    let shortName: String
    let salesLine: String
    let coverFill: Color
    let coverAccent: Color
    let titleColor: Color
    let seed: UInt64
}

private struct DeckShelfEntrance: ViewModifier {
    let index: Int
    let active: Bool
    let enabled: Bool

    private var delay: Double {
        min(Double(index) * 0.055, 0.38)
    }

    private var entryTilt: Double {
        index.isMultiple(of: 2) ? -7 : 7
    }

    func body(content: Content) -> some View {
        if enabled {
            content
                .opacity(active ? 1 : 0)
                .scaleEffect(active ? 1 : 0.92)
                .rotationEffect(.degrees(active ? 0 : entryTilt), anchor: .bottom)
                .offset(x: active ? 0 : (index.isMultiple(of: 2) ? -18 : 18),
                        y: active ? 0 : 34)
                .animation(.spring(response: 0.58, dampingFraction: 0.72).delay(delay), value: active)
        } else {
            content
        }
    }
}

private struct SelectedDeckBounce: ViewModifier {
    let selected: Bool
    let index: Int
    let enabled: Bool

    private var tilt: Double {
        index.isMultiple(of: 2) ? -1.3 : 1.3
    }

    func body(content: Content) -> some View {
        if enabled {
            content
                .scaleEffect(selected ? 1.025 : 1)
                .rotationEffect(.degrees(selected ? tilt : 0))
                .animation(.spring(response: 0.28, dampingFraction: 0.52), value: selected)
        } else {
            content
        }
    }
}

private extension View {
    func deckShelfEntrance(index: Int, active: Bool, enabled: Bool) -> some View {
        modifier(DeckShelfEntrance(index: index, active: active, enabled: enabled))
    }

    func selectedDeckBounce(_ selected: Bool, index: Int, enabled: Bool) -> some View {
        modifier(SelectedDeckBounce(selected: selected, index: index, enabled: enabled))
    }
}
