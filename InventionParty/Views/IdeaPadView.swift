//
//  IdeaPadView.swift
//  Invention Party
//
//  Ported from app/ideapad.tsx. Sketchbook redesign.
//

import Combine
import SwiftUI

struct IdeaPadView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router

    @State private var currentPlayerIndex = 0
    @State private var inventionText = ""
    @State private var drawing = DrawingData(strokes: [], width: 0, height: 0)
    @State private var alert: AlertMessage?

    /// When true, a "pass the phone" handoff screen is shown instead of the
    /// drawing/writing area, so the device reaches the right player privately.
    @State private var showingPass = false
    @State private var didArrive = false

    // Speed Round timer
    @State private var timeRemaining = 0
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// Which invention inputs are enabled (set in Settings). Both default on.
    @AppStorage("inputDrawing") private var allowDrawing = true
    @AppStorage("inputWriting") private var allowWriting = true

    /// Effective availability — if both were somehow turned off, show both so a
    /// player always has a way to submit.
    private var showDrawing: Bool { allowDrawing || (!allowDrawing && !allowWriting) }
    private var showWriting: Bool { allowWriting || (!allowDrawing && !allowWriting) }

    /// When both inputs are on, the turn is split into a draw step then a
    /// description step so neither feels cramped. This tracks the second step.
    @State private var onWriteStep = false
    private var bothInputs: Bool { showDrawing && showWriting }
    private var drawingVisible: Bool { showDrawing && !onWriteStep }
    private var writingVisible: Bool { showWriting && (onWriteStep || !showDrawing) }

    private var isSpeed: Bool { store.mode == .speed }

    private var nonJudgePlayers: [Player] {
        // Crowd Favorite has no judge, so everyone submits an invention.
        if store.isSoloMode || store.mode == .crowd { return store.players }
        return store.players.enumerated()
            .filter { $0.offset != store.judgeRotationIndex }
            .map { $0.element }
    }

    var body: some View {
        Group {
            if let player = nonJudgePlayers[safe: currentPlayerIndex],
               let obj1 = store.currentRoundObjects[safe: 0],
               let obj2 = store.currentRoundObjects[safe: 1] {
                if showingPass {
                    passScreen(nextPlayer: player)
                } else {
                    content(player: player, obj1: obj1, obj2: obj2)
                }
            } else {
                Text("Loading…").font(.display(28)).foregroundColor(Palette.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
        .onAppear {
            if !didArrive {
                didArrive = true
                // Hand the phone to the first player too (skipped in solo mode).
                showingPass = !store.isSoloMode
            }
            if isSpeed && timeRemaining == 0 { timeRemaining = store.secondsPerTurn }
        }
        .onChange(of: currentPlayerIndex) { resetTimer() }
        .onReceive(ticker) { _ in tick() }
        .alert(item: $alert) { msg in
            Alert(title: Text(msg.title), message: Text(msg.body), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Timer

    private func resetTimer() {
        guard isSpeed else { return }
        timeRemaining = store.secondsPerTurn
    }

    private func tick() {
        guard isSpeed, !showingPass, timeRemaining > 0 else { return }
        timeRemaining -= 1
        if timeRemaining == 0, let player = nonJudgePlayers[safe: currentPlayerIndex] {
            submit(player: player, timedOut: true)
        }
    }

    private var timerPill: some View {
        let low = timeRemaining <= 10
        let accent = low ? Palette.danger : Palette.teal
        return HStack(spacing: 8) {
            Doodle(kind: .stopwatch, size: 18, color: Palette.cream)
            rollingTime
        }
        .padding(.horizontal, 18).padding(.vertical, 8)
        .background(SketchyRoundedRectangle(cornerRadius: 12, seed: 9).fill(accent))
        .overlay(SketchyRoundedRectangle(cornerRadius: 12, seed: 9).stroke(Palette.ink, lineWidth: 2))
        .scaleEffect(low ? 1.06 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: low)
    }

    /// Old-fashioned mechanical-counter roll. Each digit is its own little wheel:
    /// when a digit changes, only that one drops away downward while its
    /// replacement rolls in from the top (clipped, like a split-flap board).
    /// Digits that don't change stay put — so "0:43 → 0:42" only rolls the ones.
    private var rollingTime: some View {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return HStack(spacing: 1) {
            digitWheel(minutes)
            colon
            digitWheel(seconds / 10)
            digitWheel(seconds % 10)
        }
    }

    private func digitWheel(_ value: Int) -> some View {
        ZStack {
            Text("\(value)")
                .font(.marker(20, bold: true))
                .foregroundColor(Palette.cream)
                .monospacedDigit()
                .id(value)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
        }
        .frame(width: 14, height: 24)
        .clipped()
        .animation(.easeInOut(duration: 0.3), value: value)
    }

    private var colon: some View {
        Text(":")
            .font(.marker(20, bold: true))
            .foregroundColor(Palette.cream)
            .frame(width: 7, height: 24)
    }

    private func content(player: Player, obj1: GameObject, obj2: GameObject) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(store.isSoloMode ? "Your Turn" : "\(player.name)'s Turn")
                    .font(.display(32)).foregroundColor(Palette.ink)
                    .padding(.top, 18)
                    .padding(.bottom, store.isSoloMode ? (isSpeed ? 14 : 22) : 6)
                if !store.isSoloMode {
                    Text("Player \(currentPlayerIndex + 1) of \(nonJudgePlayers.count)")
                        .font(.marker(15)).foregroundColor(Palette.inkSoft)
                        .padding(.bottom, isSpeed ? 14 : 22)
                }

                if isSpeed {
                    timerPill
                        .padding(.bottom, 20)
                }

                HStack(alignment: .top, spacing: 12) {
                    labeledObject(obj1, seed: 21)
                    Text("+").font(.display(28)).foregroundColor(Palette.tomato)
                        .frame(height: 60)
                    labeledObject(obj2, seed: 22)
                }
                .padding(.bottom, store.currentRoundModifier == nil ? 22 : 12)

                if let modifier = store.currentRoundModifier {
                    compactModifierCard(modifier)
                        .padding(.bottom, 20)
                }

                if drawingVisible {
                    inputHeader(icon: AnyView(PaletteDoodle(size: 26)),
                                text: "Draw your invention!")
                    VStack(spacing: 12) {
                        // Seed the canvas with any strokes already made (so stepping
                        // back from the description keeps the drawing), and key it to
                        // the player so it resets for the next person.
                        DrawingCanvasView(width: 350, height: 250,
                                          initialStrokes: drawing.strokes) { drawing = $0 }
                            .id(currentPlayerIndex)
                    }
                    .padding(.bottom, 20)
                }

                if writingVisible {
                    inputHeader(icon: AnyView(Doodle(kind: .pencil, size: 24, color: Palette.ink)),
                                text: "Describe your invention!")
                    sketchTextEditor
                        .padding(.bottom, 20)
                }

                primaryButton(player: player)
                    .padding(.bottom, 14)

                if bothInputs && onWriteStep {
                    Button { withAnimation { onWriteStep = false } } label: {
                        Text("← Back to Drawing")
                            .font(.marker(15, bold: true))
                            .foregroundColor(Palette.inkSoft)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                }

                if !store.isSoloMode {
                    HStack(spacing: 8) {
                        Doodle(kind: .warning, size: 16, color: Palette.inkSoft)
                        Text("After you submit, pass the device to the next player!")
                            .font(.marker(13, bold: true))
                            .foregroundColor(Palette.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(20)
        }
    }

    private func compactModifierCard(_ modifier: InventionModifier) -> some View {
        HStack(spacing: 8) {
            Doodle(kind: .sparkle, size: 17, color: Palette.grape)
            Text(modifier.text)
                .font(.marker(15, bold: true))
                .foregroundColor(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .sketchCard(fill: Palette.card, border: Palette.grape, lineWidth: 2, seed: 53)
        .padding(.horizontal, 22)
    }

    // MARK: - Pass the phone

    /// A handoff screen shown before a player's turn so the device reaches the
    /// right person without anyone peeking at the previous invention.
    private func passScreen(nextPlayer player: Player) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Doodle(kind: .face, size: 76, color: Palette.teal)
            Text("Pass the phone to")
                .font(.marker(20))
                .foregroundColor(Palette.inkSoft)
            Text(player.name)
                .font(.display(40))
                .foregroundColor(Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            HStack(spacing: 8) {
                Doodle(kind: .warning, size: 16, color: Palette.inkSoft)
                Text("No peeking at the last invention!")
                    .font(.marker(14, bold: true))
                    .foregroundColor(Palette.inkSoft)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            FilledButton(title: "That's me!", background: Palette.leaf,
                         foreground: Palette.cream, fontSize: 20, verticalPadding: 18,
                         seed: 6, icon: .controller) {
                startTurn()
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    private func startTurn() {
        withAnimation(.easeInOut(duration: 0.2)) { showingPass = false }
        if isSpeed { timeRemaining = store.secondsPerTurn }
    }

    /// The object tile with its name underneath, so a player can still tell what
    /// the object is if a teammate's drawing is hard to read. The card itself
    /// keeps its size; only a small caption is added below it.
    private func labeledObject(_ object: GameObject, seed: UInt64) -> some View {
        VStack(spacing: 6) {
            ObjectTile(object: object, size: 60, emojiSize: 38, titleFontSize: 11, seed: seed)
            if !object.prefersTextOnly {
                Text(object.name)
                    .font(.marker(12, bold: true))
                    .foregroundColor(Palette.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
                    .frame(width: 76)
            }
        }
    }

    private var sketchTextEditor: some View {
        TextField("", text: $inventionText,
                  prompt: Text("Describe your invention…").foregroundColor(Palette.sheetInkFaint),
                  axis: .vertical)
            .lineLimit(6...12)
            .font(.marker(17))
            .foregroundColor(Palette.sheetInk)
            .padding(16)
            .frame(minHeight: 160, alignment: .topLeading)
            .background(SketchyRoundedRectangle(cornerRadius: 16, seed: 33).fill(Palette.drawSheet))
            .overlay(SketchyRoundedRectangle(cornerRadius: 16, seed: 33).stroke(Palette.sheetInk, lineWidth: 2.5))
    }

    /// On the draw step (when both inputs are on) this moves to the description
    /// step; otherwise it submits the turn.
    @ViewBuilder private func primaryButton(player: Player) -> some View {
        if bothInputs && !onWriteStep {
            FilledButton(title: "Continue to Description →", background: Palette.mustard,
                         foreground: Palette.buttonInk, fontSize: 18, verticalPadding: 17, seed: 5) {
                continueToDescription()
            }
        } else {
            FilledButton(title: submitTitle, background: Palette.leaf,
                         foreground: Palette.cream, fontSize: 18, verticalPadding: 17, seed: 5) {
                submit(player: player)
            }
        }
    }

    private func inputHeader(icon: AnyView, text: String) -> some View {
        HStack(spacing: 9) {
            icon
            Text(text)
                .font(.marker(19, bold: true)).foregroundColor(Palette.ink)
        }
        .padding(.bottom, 14)
    }

    private var submitTitle: String {
        if currentPlayerIndex < nonJudgePlayers.count - 1 { return "Submit & Next Player" }
        return store.isSoloMode ? "Submit (Auto-Score)" : "Submit & Go to Judge"
    }

    /// Moves from the drawing step to the description step, but only once the
    /// player has actually drawn something (both inputs are required).
    private func continueToDescription() {
        if drawing.strokes.isEmpty {
            alert = AlertMessage(title: "Draw First", body: "Please draw your invention before adding a description")
            return
        }
        withAnimation { onWriteStep = true }
    }

    private func submit(player: Player, timedOut: Bool = false) {
        let typed = inventionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasDrawing = showDrawing && !drawing.strokes.isEmpty
        let hasText = showWriting && !typed.isEmpty

        // When the clock runs out we accept whatever the player has, even nothing.
        if !timedOut {
            if bothInputs {
                // Both inputs enabled → both are required.
                if !hasDrawing {
                    alert = AlertMessage(title: "Draw First", body: "Please draw your invention first")
                    return
                }
                if !hasText {
                    alert = AlertMessage(title: "Add a Description", body: "Please describe your invention too")
                    return
                }
            } else if showDrawing && !hasDrawing {
                alert = AlertMessage(title: "Draw First", body: "Please draw your invention first")
                return
            } else if showWriting && !hasText {
                alert = AlertMessage(title: "Describe It", body: "Please type your invention idea")
                return
            }
        }

        var submission = Submission(playerId: player.id, playerName: player.name)
        if hasDrawing { submission.drawing = drawing.encodedString() }
        if hasText { submission.text = typed }
        if submission.isEmpty { submission.text = "Ran out of time!" }
        store.addSubmission(submission)

        if currentPlayerIndex < nonJudgePlayers.count - 1 {
            currentPlayerIndex += 1
            inventionText = ""
            drawing = DrawingData(strokes: [], width: 0, height: 0)
            onWriteStep = false
            showingPass = true
        } else if store.mode == .crowd {
            router.push(.vote)
        } else if store.isSoloMode {
            store.saveRoundResults(RoundResult(roundNumber: store.currentRound, first: player.id))
            router.push(.scoreboard)
        } else {
            router.push(.judge)
        }
    }
}
