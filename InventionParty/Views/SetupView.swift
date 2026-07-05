//
//  SetupView.swift
//  Invention Party
//
//  Ported from app/setup.tsx. Sketchbook redesign.
//

import SwiftUI

struct SetupView: View {
    private static let savedSetupKey = "savedGameSetup"

    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router

    @State private var playerName = ""
    @State private var players: [Player] = []
    @State private var selectedMode: GameMode = .classic
    @State private var rounds = "5"
    @State private var secondsPerTurn = 60
    @State private var useCustomTime = false
    @State private var customTimeText = ""
    @State private var useModifiers = true
    @State private var isSolo = false
    @State private var judgeIndex = 0
    @State private var alert: AlertMessage?
    @State private var didLoadDefaults = false

    /// The player's preferred starting round count, set in Settings.
    @AppStorage("defaultRounds") private var defaultRounds: Int = 5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Game Setup")
                    .font(.display(34))
                    .foregroundColor(Palette.ink)
                    .frame(maxWidth: .infinity)

                modeSection
                if selectedMode == .speed { timeSection }
                roundsSection
                modifiersSection
                if selectedMode != .crowd { soloToggle }
                playersSection
                if selectedMode != .crowd && !isSolo && !players.isEmpty { judgeSection }

                FilledButton(title: "Continue", background: Palette.mustard,
                             foreground: Palette.ink, fontSize: 22, seed: 3) { startGame() }
                FilledButton(title: "Reset to Default", background: Palette.card,
                             foreground: Palette.danger, fontSize: 18, verticalPadding: 14, seed: 81) {
                    resetSetupDefaults()
                }
                FilledButton(title: "← Back", background: Palette.card,
                             foreground: Palette.ink, fontSize: 18, verticalPadding: 14, seed: 80) { router.pop() }
            }
            .padding(20)
            .animation(.spring(response: 0.32, dampingFraction: 0.85), value: selectedMode)
        }
        .screenBackground()
        .onAppear {
            // Seed the fields once without clobbering anything the user has typed
            // while staying on this screen.
            if !didLoadDefaults {
                loadSavedSetup()
                didLoadDefaults = true
            }
        }
        .alert(item: $alert) { msg in
            Alert(title: Text(msg.title), message: Text(msg.body), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Sections

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.marker(19, bold: true)).foregroundColor(Palette.ink)
    }

    private func sketchField<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(15)
            .background(SketchyRoundedRectangle(cornerRadius: 13, seed: 33).fill(Palette.cardSunken))
            .overlay(SketchyRoundedRectangle(cornerRadius: 13, seed: 33).stroke(Palette.ink, lineWidth: 2))
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Game Mode")
            HStack(spacing: 12) {
                modeButton(title: "Classic", desc: "Judge ranks inventions", active: selectedMode == .classic, seed: 14) {
                    selectedMode = .classic
                }
                modeButton(title: "Speed Round", desc: "Quick timer mode", active: selectedMode == .speed, seed: 15) {
                    selectedMode = .speed
                }
            }
            modeButton(title: "Crowd Favorite", desc: "No judge — everyone votes",
                       active: selectedMode == .crowd, seed: 13) {
                // Crowd is multiplayer only: drop the auto-added solo player.
                if isSolo { players = []; isSolo = false }
                selectedMode = .crowd
            }
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Time Per Turn")
            Text("How long each player has to create their invention.")
                .font(.marker(13)).foregroundColor(Palette.inkSoft)
            FlowRow(spacing: 10) {
                ForEach(timePresets, id: \.self) { secs in
                    Button {
                        useCustomTime = false
                        secondsPerTurn = secs
                    } label: {
                        timeChip(formatTime(secs), active: !useCustomTime && secondsPerTurn == secs,
                                 seed: UInt64(160 + secs))
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    useCustomTime = true
                    if let n = Int(customTimeText), n > 0 {
                        secondsPerTurn = n
                    } else {
                        customTimeText = String(secondsPerTurn)
                    }
                } label: {
                    timeChip("Custom", active: useCustomTime, seed: 159)
                }
                .buttonStyle(.plain)
            }

            if useCustomTime {
                sketchField {
                    HStack(spacing: 10) {
                        TextField("", text: $customTimeText,
                                  prompt: Text("Seconds").foregroundColor(Palette.inkFaint))
                            .keyboardType(.numberPad)
                            .font(.marker(18))
                            .foregroundColor(Palette.ink)
                            .onChange(of: customTimeText) {
                                if let n = Int(customTimeText), n > 0 { secondsPerTurn = n }
                            }
                        Text("seconds")
                            .font(.marker(15)).foregroundColor(Palette.inkSoft)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: useCustomTime)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func timeChip(_ text: String, active: Bool, seed: UInt64) -> some View {
        Text(text)
            .font(.marker(16, bold: true))
            .foregroundColor(active ? Palette.cream : Palette.inkSoft)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(SketchyRoundedRectangle(cornerRadius: 12, seed: seed)
                .fill(active ? Palette.tomato : Palette.card))
            .overlay(SketchyRoundedRectangle(cornerRadius: 12, seed: seed)
                .stroke(Palette.ink, lineWidth: active ? 3 : 2))
    }

    private let timePresets = [15, 30, 45, 60, 90, 120]

    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m) min" : "\(m):\(String(format: "%02d", s))"
    }

    private func modeButton(title: String, desc: String, active: Bool, seed: UInt64,
                            icon: AnyView? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let icon {
                    icon.padding(.bottom, 2)
                }
                Text(title)
                    .font(.marker(17, bold: true))
                    .foregroundColor(active ? Palette.ink : Palette.inkSoft)
                Text(desc)
                    .font(.marker(12))
                    .foregroundColor(active ? Palette.ink.opacity(0.7) : Palette.inkFaint)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .sketchCard(fill: active ? Palette.mustard : Palette.card,
                        border: Palette.ink, lineWidth: active ? 3 : 2, seed: seed, shadow: active)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: active)
    }

    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Number of Rounds")
            sketchField {
                TextField("", text: $rounds, prompt: Text("5").foregroundColor(Palette.inkFaint))
                    .keyboardType(.numberPad)
                    .font(.marker(18))
                    .foregroundColor(Palette.ink)
            }
        }
    }

    private var modifiersSection: some View {
        Toggle(isOn: $useModifiers) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Invention Modifiers")
                    .font(.marker(17, bold: true))
                    .foregroundColor(Palette.ink)
                Text("Adds a random twist like must be wearable or for outer space.")
                    .font(.marker(13))
                    .foregroundColor(Palette.inkSoft)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Palette.leaf))
        .padding(16)
        .sketchCard(fill: Palette.card, border: useModifiers ? Palette.leaf : Palette.ink,
                    lineWidth: useModifiers ? 3 : 2, seed: 17)
    }

    private var soloToggle: some View {
        Button { toggleSolo() } label: {
            HStack(spacing: 12) {
                Image(systemName: isSolo ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isSolo ? Palette.leaf : Palette.inkSoft)
                Text("Solo Mode (Auto-judge)")
                    .font(.marker(17, bold: true))
                    .foregroundColor(Palette.ink)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .sketchCard(fill: Palette.card, border: isSolo ? Palette.leaf : Palette.ink,
                        lineWidth: isSolo ? 3 : 2, seed: 18)
        }
        .buttonStyle(.plain)
    }

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Players")
            if !isSolo {
                HStack(spacing: 12) {
                    sketchField {
                        TextField("", text: $playerName,
                                  prompt: Text("Enter player name").foregroundColor(Palette.inkFaint))
                            .font(.marker(16))
                            .foregroundColor(Palette.ink)
                            .onSubmit { addPlayer() }
                    }
                    Button { addPlayer() } label: {
                        Text("Add")
                            .font(.marker(16, bold: true))
                            .foregroundColor(Palette.cream)
                            .padding(.vertical, 15).padding(.horizontal, 22)
                            .background(SketchyRoundedRectangle(cornerRadius: 13, seed: 19).fill(Palette.leaf))
                            .overlay(SketchyRoundedRectangle(cornerRadius: 13, seed: 19).stroke(Palette.ink, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 10) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    HStack {
                        Doodle(kind: .face, size: 22, color: Palette.teal)
                        Text(player.name).font(.marker(17, bold: true)).foregroundColor(Palette.ink)
                        Spacer()
                        if !isSolo {
                            HStack(spacing: 14) {
                                Button { movePlayer(at: index, by: -1) } label: {
                                    Image(systemName: "chevron.up").font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Palette.inkSoft).opacity(index == 0 ? 0.3 : 1)
                                }
                                .buttonStyle(.plain).disabled(index == 0)
                                Button { movePlayer(at: index, by: 1) } label: {
                                    Image(systemName: "chevron.down").font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Palette.inkSoft).opacity(index == players.count - 1 ? 0.3 : 1)
                                }
                                .buttonStyle(.plain).disabled(index == players.count - 1)
                                Button { removePlayer(player) } label: {
                                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(Palette.danger)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(14)
                    .sketchCard(fill: Palette.card, border: Palette.ink, lineWidth: 2,
                                seed: UInt64(120 + index))
                }
            }
        }
    }

    private var judgeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Starting Judge")
            FlowRow(spacing: 10) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    Button { judgeIndex = index } label: {
                        Text(player.name)
                            .font(.marker(15, bold: true))
                            .foregroundColor(judgeIndex == index ? Palette.cream : Palette.inkSoft)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(SketchyRoundedRectangle(cornerRadius: 11, seed: UInt64(140 + index))
                                .fill(judgeIndex == index ? Palette.sky : Palette.card))
                            .overlay(SketchyRoundedRectangle(cornerRadius: 11, seed: UInt64(140 + index))
                                .stroke(Palette.ink, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Actions

    private func addPlayer() {
        let trimmed = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            alert = AlertMessage(title: "Error", body: "Please enter a player name")
            return
        }
        players.append(Player(id: "\(Date().timeIntervalSince1970)", name: trimmed))
        playerName = ""
    }

    private func movePlayer(at index: Int, by offset: Int) {
        let target = index + offset
        guard target >= 0, target < players.count else { return }
        players.swapAt(index, target)
        clampJudgeIndex()
    }

    private func removePlayer(_ player: Player) {
        players.removeAll { $0.id == player.id }
        clampJudgeIndex()
    }

    private func clampJudgeIndex() {
        guard !players.isEmpty else {
            judgeIndex = 0
            return
        }
        judgeIndex = min(judgeIndex, players.count - 1)
    }

    private func toggleSolo() {
        if !isSolo {
            players = [Player(id: "1", name: "You")]
            judgeIndex = 0
        } else {
            players = []
        }
        isSolo.toggle()
    }

    private func startGame() {
        if selectedMode == .crowd && players.count < 3 {
            alert = AlertMessage(title: "Not Enough Players", body: "Crowd Favorite needs at least 3 players so everyone has someone to vote for")
            return
        }
        if players.count < 2 && !isSolo {
            alert = AlertMessage(title: "Not Enough Players", body: "Add at least 2 players to start the game")
            return
        }
        if isSolo && players.isEmpty {
            alert = AlertMessage(title: "Error", body: "Please add yourself as a player in solo mode")
            return
        }
        guard let roundsNum = Int(rounds), roundsNum >= 1 else {
            alert = AlertMessage(title: "Invalid Rounds", body: "Please enter a valid number of rounds (at least 1)")
            return
        }
        if selectedMode == .speed && secondsPerTurn < 5 {
            alert = AlertMessage(title: "Invalid Time", body: "Please choose a turn time of at least 5 seconds")
            return
        }
        store.setMode(selectedMode)
        store.setRounds(roundsNum)
        store.setSecondsPerTurn(secondsPerTurn)
        store.setModifiersEnabled(useModifiers)
        store.setPlayers(players)
        store.setJudgeIndex(min(judgeIndex, max(players.count - 1, 0)))
        store.setSoloMode(isSolo)
        saveCurrentSetup(roundsNum: roundsNum)
        router.push(.packs)
    }

    private func loadSavedSetup() {
        guard let data = UserDefaults.standard.data(forKey: Self.savedSetupKey),
              let setup = try? JSONDecoder().decode(SavedGameSetup.self, from: data) else {
            rounds = String(defaultRounds)
            return
        }

        selectedMode = setup.mode
        rounds = String(setup.rounds)
        secondsPerTurn = setup.secondsPerTurn
        useCustomTime = !timePresets.contains(setup.secondsPerTurn)
        customTimeText = useCustomTime ? String(setup.secondsPerTurn) : ""
        useModifiers = setup.modifiersEnabled
        isSolo = setup.isSolo
        players = setup.players.map { player in
            Player(id: player.id, name: player.name)
        }
        judgeIndex = min(setup.judgeIndex, max(players.count - 1, 0))

        if selectedMode == .crowd && isSolo {
            isSolo = false
            players = []
            judgeIndex = 0
        }
    }

    private func saveCurrentSetup(roundsNum: Int) {
        let setup = SavedGameSetup(mode: selectedMode,
                                   rounds: roundsNum,
                                   secondsPerTurn: secondsPerTurn,
                                   modifiersEnabled: useModifiers,
                                   isSolo: isSolo,
                                   players: players.map { Player(id: $0.id, name: $0.name) },
                                   judgeIndex: min(judgeIndex, max(players.count - 1, 0)))
        guard let data = try? JSONEncoder().encode(setup) else { return }
        UserDefaults.standard.set(data, forKey: Self.savedSetupKey)
    }

    private func resetSetupDefaults() {
        selectedMode = .classic
        rounds = String(defaultRounds)
        secondsPerTurn = 60
        useCustomTime = false
        customTimeText = ""
        useModifiers = true
        isSolo = false
        players = []
        judgeIndex = 0
        UserDefaults.standard.removeObject(forKey: Self.savedSetupKey)
    }

    private struct SavedGameSetup: Codable {
        var mode: GameMode
        var rounds: Int
        var secondsPerTurn: Int
        var modifiersEnabled: Bool
        var isSolo: Bool
        var players: [Player]
        var judgeIndex: Int
    }
}
