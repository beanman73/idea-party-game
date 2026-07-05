//
//  JudgeView.swift
//  Invention Party
//
//  Ported from app/judge.tsx. Sketchbook redesign. Submissions are shown
//  anonymously ("Submission A", "B", ...).
//

import SwiftUI

struct JudgeView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var router: Router

    @State private var first: String?
    @State private var second: String?
    @State private var third: String?
    @State private var alert: AlertMessage?

    private var submissions: [Submission] { store.submissions }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Judge's Decision")
                    .font(.display(32)).foregroundColor(Palette.ink)
                    .padding(.bottom, 6)
                Text("\(store.players[safe: store.judgeRotationIndex]?.name ?? "Judge"), rank the top inventions!")
                    .font(.marker(16)).foregroundColor(Palette.inkSoft)
                    .multilineTextAlignment(.center).padding(.bottom, 14)
                Text("Tap to award 1st, 2nd & 3rd place")
                    .font(.marker(14, bold: true)).foregroundColor(Palette.tomato)
                    .multilineTextAlignment(.center).padding(.bottom, 18)

                VStack(spacing: 14) {
                    ForEach(Array(submissions.enumerated()), id: \.element.id) { index, submission in
                        submissionCard(index: index, submission: submission)
                    }
                }
                .padding(.bottom, 20)

                if first != nil || second != nil || third != nil { rankingsSummary }

                FilledButton(title: "Confirm Results", background: Palette.leaf,
                             foreground: Palette.cream, seed: 5) { confirm() }
            }
            .padding(20)
        }
        .screenBackground()
        .alert(item: $alert) { msg in
            Alert(title: Text(msg.title), message: Text(msg.body), dismissButton: .default(Text("OK")))
        }
    }

    private func label(for index: Int) -> String {
        let letter = Character(UnicodeScalar(UInt8(65 + index)))
        return "Submission \(letter)"
    }

    private func medal(for playerId: String) -> Int? {
        if playerId == first { return 1 }
        if playerId == second { return 2 }
        if playerId == third { return 3 }
        return nil
    }

    private func placeText(for playerId: String) -> String {
        if playerId == first { return "1st · 3 pts" }
        if playerId == second { return "2nd · 2 pts" }
        if playerId == third { return "3rd · 1 pt" }
        return ""
    }

    private func placeColor(for playerId: String) -> Color {
        if playerId == first { return Palette.gold }
        if playerId == second { return Palette.silver }
        if playerId == third { return Palette.bronze }
        return Palette.ink
    }

    private func isSelected(_ playerId: String) -> Bool {
        playerId == first || playerId == second || playerId == third
    }

    private func submissionCard(index: Int, submission: Submission) -> some View {
        let selected = isSelected(submission.playerId)
        let accent = placeColor(for: submission.playerId)
        return Button {
            selectPlace(submission.playerId)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(label(for: index)).font(.marker(18, bold: true)).foregroundColor(Palette.ink)
                    Spacer()
                    if selected, let m = medal(for: submission.playerId) {
                        HStack(spacing: 6) {
                            MedalDoodle(place: m, size: 22)
                            Text(placeText(for: submission.playerId))
                                .font(.marker(14, bold: true)).foregroundColor(Palette.ink)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(SketchyRoundedRectangle(cornerRadius: 9, seed: 71).fill(accent))
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
            .sketchCard(fill: Palette.card,
                        border: selected ? accent : Palette.ink,
                        lineWidth: selected ? 3.5 : 2.5,
                        seed: UInt64(150 + index))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
    }

    private var rankingsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Rankings")
                .font(.marker(18, bold: true)).foregroundColor(Palette.ink)
            if let first, let idx = submissions.firstIndex(where: { $0.playerId == first }) {
                summaryRow(place: 1, text: "1st: \(label(for: idx))")
            }
            if let second, let idx = submissions.firstIndex(where: { $0.playerId == second }) {
                summaryRow(place: 2, text: "2nd: \(label(for: idx))")
            }
            if let third, let idx = submissions.firstIndex(where: { $0.playerId == third }) {
                summaryRow(place: 3, text: "3rd: \(label(for: idx))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .sketchCard(fill: Palette.cardSunken, border: Palette.mustard, lineWidth: 2.5, seed: 73)
        .padding(.bottom, 18)
    }

    private func summaryRow(place: Int, text: String) -> some View {
        HStack(spacing: 8) {
            MedalDoodle(place: place, size: 20)
            Text(text).font(.marker(16)).foregroundColor(Palette.inkSoft)
        }
    }

    private func selectPlace(_ playerId: String) {
        if first == nil { first = playerId }
        else if first == playerId { first = nil }
        else if second == nil { second = playerId }
        else if second == playerId { second = nil }
        else if third == nil { third = playerId }
        else if third == playerId { third = nil }
        else {
            alert = AlertMessage(title: "Info", body: "You can only select 3 places. Tap a selected submission to deselect it.")
        }
    }

    private func confirm() {
        guard let first else {
            alert = AlertMessage(title: "Error", body: "Please select at least 1st place")
            return
        }
        store.saveRoundResults(RoundResult(roundNumber: store.currentRound,
                                           first: first, second: second, third: third))
        router.push(.scoreboard)
    }
}
