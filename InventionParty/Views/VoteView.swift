//
//  VoteView.swift
//  Invention Party
//
//  Crowd Favorite voting. Every player votes (pass-the-phone) for their
//  favorite invention — but never their own. Votes are tallied, ranked, and
//  fed into the normal round-result scoring (1st/2nd/3rd = 3/2/1 points).
//

import SwiftUI

struct VoteView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router

    @State private var currentVoterIndex = 0
    @State private var selected: String?           // submission's playerId
    @State private var tally: [String: Int] = [:]
    @State private var showingPass = true
    @State private var didArrive = false
    @State private var alert: AlertMessage?

    private var submissions: [Submission] { store.submissions }
    private var voters: [Player] { store.players }

    var body: some View {
        Group {
            if let voter = voters[safe: currentVoterIndex] {
                if showingPass {
                    passScreen(voter: voter)
                } else {
                    ballot(voter: voter)
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
                showingPass = true
            }
        }
        .alert(item: $alert) { msg in
            Alert(title: Text(msg.title), message: Text(msg.body), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Pass the phone

    private func passScreen(voter: Player) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Doodle(kind: .face, size: 76, color: Palette.grape)
            Text("Pass the phone to")
                .font(.marker(20)).foregroundColor(Palette.inkSoft)
            Text(voter.name)
                .font(.display(40)).foregroundColor(Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.5)
            Text("Time to vote for your favorite invention!")
                .font(.marker(14, bold: true)).foregroundColor(Palette.inkSoft)
                .multilineTextAlignment(.center)
            Spacer()
            FilledButton(title: "That's me!", background: Palette.leaf,
                         foreground: Palette.cream, fontSize: 20, verticalPadding: 18,
                         seed: 6, icon: .controller) {
                withAnimation(.easeInOut(duration: 0.2)) { showingPass = false }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    // MARK: - Ballot

    private func ballot(voter: Player) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("\(voter.name), Vote!")
                    .font(.display(32)).foregroundColor(Palette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
                Text("Tap your favorite invention")
                    .font(.marker(15)).foregroundColor(Palette.inkSoft)
                    .padding(.bottom, 4)
                Text("(you can't vote for your own)")
                    .font(.marker(13, bold: true)).foregroundColor(Palette.tomato)
                    .padding(.bottom, 18)

                VStack(spacing: 14) {
                    ForEach(Array(submissions.enumerated()), id: \.element.id) { index, submission in
                        submissionCard(index: index, submission: submission, voter: voter)
                    }
                }
                .padding(.bottom, 20)

                FilledButton(title: voteButtonTitle, background: Palette.leaf,
                             foreground: Palette.cream, seed: 5) { castVote(voter: voter) }
            }
            .padding(20)
        }
    }

    private var voteButtonTitle: String {
        currentVoterIndex < voters.count - 1 ? "Submit Vote & Pass" : "Submit Vote & See Results"
    }

    private func label(for index: Int) -> String {
        let letter = Character(UnicodeScalar(UInt8(65 + index)))
        return "Submission \(letter)"
    }

    private func submissionCard(index: Int, submission: Submission, voter: Player) -> some View {
        let isOwn = submission.playerId == voter.id
        let isSelected = selected == submission.playerId
        return Button {
            guard !isOwn else { return }
            selected = isSelected ? nil : submission.playerId
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(label(for: index)).font(.marker(18, bold: true)).foregroundColor(Palette.ink)
                    Spacer()
                    if isOwn {
                        Text("Your invention")
                            .font(.marker(13, bold: true)).foregroundColor(Palette.inkSoft)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(SketchyRoundedRectangle(cornerRadius: 9, seed: 71).fill(Palette.cardSunken))
                            .overlay(SketchyRoundedRectangle(cornerRadius: 9, seed: 71).stroke(Palette.inkFaint, lineWidth: 1.8))
                    } else if isSelected {
                        HStack(spacing: 6) {
                            Doodle(kind: .sparkle, size: 18, color: Palette.buttonInk)
                            Text("Your vote").font(.marker(14, bold: true)).foregroundColor(Palette.buttonInk)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(SketchyRoundedRectangle(cornerRadius: 9, seed: 71).fill(Palette.mustard))
                        .overlay(SketchyRoundedRectangle(cornerRadius: 9, seed: 71).stroke(Palette.ink, lineWidth: 1.8))
                    }
                }
                if let encoded = submission.drawing, let data = DrawingData.decode(from: encoded) {
                    DrawingPreview(drawing: data)
                        .frame(height: 200)
                        .background(SketchyRoundedRectangle(cornerRadius: 12, seed: 72).fill(Palette.drawSheet))
                        .overlay(SketchyRoundedRectangle(cornerRadius: 12, seed: 72).stroke(Palette.sheetInk, lineWidth: 2))
                }
                if let text = submission.text, !text.isEmpty {
                    Text(text)
                        .font(.marker(16)).foregroundColor(Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .sketchCard(fill: isOwn ? Palette.cardSunken : Palette.card,
                        border: isSelected ? Palette.mustard : Palette.ink,
                        lineWidth: isSelected ? 3.5 : 2.5,
                        seed: UInt64(150 + index))
            .opacity(isOwn ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isOwn)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Actions

    private func castVote(voter: Player) {
        guard let choice = selected else {
            alert = AlertMessage(title: "Pick One", body: "Tap an invention to cast your vote")
            return
        }
        tally[choice, default: 0] += 1

        if currentVoterIndex < voters.count - 1 {
            currentVoterIndex += 1
            selected = nil
            showingPass = true
        } else {
            finishVoting()
        }
    }

    private func finishVoting() {
        let ranked = submissions.enumerated()
            .map { (id: $0.element.playerId, votes: tally[$0.element.playerId] ?? 0, idx: $0.offset) }
            .sorted { $0.votes != $1.votes ? $0.votes > $1.votes : $0.idx < $1.idx }
        let winners = ranked.filter { $0.votes > 0 }

        if let firstId = winners.first?.id {
            let secondId = winners.count > 1 ? winners[1].id : nil
            let thirdId = winners.count > 2 ? winners[2].id : nil
            store.saveRoundResults(RoundResult(roundNumber: store.currentRound,
                                               first: firstId, second: secondId, third: thirdId))
        }
        router.push(.scoreboard)
    }
}
