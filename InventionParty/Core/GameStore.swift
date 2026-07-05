//
//  GameStore.swift
//  Invention Party
//
//  Ported from the reducer + context in app/state/gameStore.tsx.
//  Each reducer action becomes a method that mutates @Published state.
//

import Combine
import SwiftUI

final class GameStore: ObservableObject {
    private static let savedDecksKey = "savedDecks"

    // Deck selection
    @Published var selectedPackId: String? = nil
    @Published var customDeckObjects: [GameObject] = []
    @Published var aiDeckObjects: [GameObject] = []
    @Published var aiDeckPrompt: String = ""
    @Published private var mixedDeck: ObjectPack? = nil
    @Published private(set) var savedDecks: [SavedDeck] = []

    // Game configuration
    @Published var mode: GameMode? = nil
    @Published var roundsTotal: Int = 5
    /// Time allotted for each player's turn in Speed Round (seconds). Ignored in Classic.
    @Published var secondsPerTurn: Int = 60
    @Published var modifiersEnabled: Bool = false

    // Live game state
    @Published var currentRound: Int = 0
    @Published var players: [Player] = []
    @Published var judgeRotationIndex: Int = 0
    @Published var currentRoundObjects: [GameObject] = []
    @Published var submissions: [Submission] = []
    @Published var roundResults: [RoundResult] = []
    @Published var isSoloMode: Bool = false
    @Published var currentRoundModifier: InventionModifier? = nil
    @Published var recentObjectIds: [String] = []

    init() {
        savedDecks = Self.loadSavedDecks()
    }

    // MARK: - Deck actions

    func setPack(_ packId: String) {
        selectedPackId = packId
        mixedDeck = nil
    }

    func setMixedDeck(from packs: [ObjectPack]) {
        let unlockedPacks = packs.filter { !$0.isLocked }
        let objects = unlockedPacks.flatMap { pack in
            pack.objects.map { object -> GameObject in
                var mixedObject = object
                mixedObject.id = "\(pack.id)::\(object.id)"
                return mixedObject
            }
        }
        let title = unlockedPacks.map(\.name).joined(separator: " + ")
        mixedDeck = ObjectPack(id: "mixed", name: title.isEmpty ? "Mixed Deck" : title,
                               isLocked: false, objects: objects)
        selectedPackId = "mixed"
    }

    func setCustomDeck(_ objects: [GameObject]) {
        customDeckObjects = objects
    }

    func setAIDeck(prompt: String, objects: [GameObject]) {
        aiDeckPrompt = prompt
        aiDeckObjects = objects
    }

    func saveGeneratedDeck(title: String, prompt: String, objects: [GameObject]) -> SavedDeck {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let deck = SavedDeck(id: UUID().uuidString,
                             title: trimmedTitle.isEmpty ? "Generated Deck" : trimmedTitle,
                             prompt: prompt,
                             objects: objects,
                             createdAt: Date())
        savedDecks.insert(deck, at: 0)
        persistSavedDecks()
        return deck
    }

    func deleteSavedDeck(_ deck: SavedDeck) {
        savedDecks.removeAll { $0.id == deck.id }
        if selectedPackId == deck.packId {
            selectedPackId = nil
        }
        persistSavedDecks()
    }

    // MARK: - Configuration actions

    func setMode(_ mode: GameMode) { self.mode = mode }
    func setRounds(_ rounds: Int) { roundsTotal = rounds }
    func setSecondsPerTurn(_ seconds: Int) { secondsPerTurn = seconds }
    func setModifiersEnabled(_ enabled: Bool) { modifiersEnabled = enabled }
    func setPlayers(_ players: [Player]) { self.players = players }
    func setJudgeIndex(_ index: Int) { judgeRotationIndex = index }
    func setSoloMode(_ isSolo: Bool) { isSoloMode = isSolo }

    // MARK: - Round actions

    func startRound(objects: [GameObject], modifier: InventionModifier? = nil) {
        currentRound += 1
        currentRoundObjects = objects
        currentRoundModifier = modifier
        recentObjectIds = Array((recentObjectIds + objects.map(\.id)).suffix(8))
        submissions = []
    }

    func addSubmission(_ submission: Submission) {
        submissions.append(submission)
    }

    func saveRoundResults(_ result: RoundResult) {
        players = players.map { player in
            var p = player
            if p.id == result.first { p.score += 3 }
            else if p.id == result.second { p.score += 2 }
            else if p.id == result.third { p.score += 1 }
            return p
        }
        roundResults.append(result)
    }

    func nextRound() {
        guard !players.isEmpty else { return }
        judgeRotationIndex = (judgeRotationIndex + 1) % players.count
        currentRoundObjects = [] // clear so new objects generate
        currentRoundModifier = nil
        submissions = []
    }

    /// RESET_GAME: keep deck selection, clear everything else.
    func resetGame() {
        mode = nil
        roundsTotal = 5
        secondsPerTurn = 60
        modifiersEnabled = false
        currentRound = 0
        players = []
        judgeRotationIndex = 0
        currentRoundObjects = []
        currentRoundModifier = nil
        recentObjectIds = []
        submissions = []
        roundResults = []
        isSoloMode = false
        // selectedPackId / customDeckObjects / aiDeckObjects / aiDeckPrompt preserved
    }

    // MARK: - Derived helpers

    /// Resolve the pack the player chose, including the custom and AI decks.
    func activePack() -> ObjectPack? {
        switch selectedPackId {
        case "mixed":
            return mixedDeck
        case "custom":
            return ObjectPack(id: "custom", name: "Custom Deck", isLocked: false, objects: customDeckObjects)
        case "ai":
            return ObjectPack(id: "ai", name: "AI Generated Deck", isLocked: false, objects: aiDeckObjects)
        default:
            if let deck = savedDecks.first(where: { $0.packId == selectedPackId }) {
                return deck.objectPack
            }
            return ObjectPacks.byId(selectedPackId ?? "starter")
        }
    }

    private func persistSavedDecks() {
        guard let data = try? JSONEncoder().encode(savedDecks) else { return }
        UserDefaults.standard.set(data, forKey: Self.savedDecksKey)
    }

    private static func loadSavedDecks() -> [SavedDeck] {
        guard let data = UserDefaults.standard.data(forKey: savedDecksKey),
              let decks = try? JSONDecoder().decode([SavedDeck].self, from: data) else {
            return []
        }
        return decks
    }
}
