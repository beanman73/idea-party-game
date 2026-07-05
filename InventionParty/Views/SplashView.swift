//
//  SplashView.swift
//  Invention Party
//
//  Animated title / intro screen. Plays a short staged entrance that
//  introduces the game name, then offers a single big "Play!" button that
//  pushes the main menu. Respects the Settings "playful animations" toggle and
//  the system Reduce Motion setting, falling back to a static layout.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var router: Router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("playfulAnimations") private var playfulAnimations: Bool = true

    /// Whether the staged entrance should play.
    private var animate: Bool { playfulAnimations && !reduceMotion }

    // Staged reveal flags, flipped on appear with increasing delays.
    @State private var showMarks = false
    @State private var showInvention = false
    @State private var showParty = false
    @State private var showTagline = false
    @State private var showButton = false
    @State private var pulse = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 42)

                // Doodled "invention" mark: two hand-drawn objects + a spark. Each
                // piece swings/pops in, then the whole cluster keeps a gentle wiggle.
                HStack(spacing: 14) {
                    LightbulbDoodle(size: 66)
                        .rotationEffect(.degrees(showMarks ? 0 : -28))
                    Text("+")
                        .font(.display(40))
                        .foregroundColor(Palette.tomato)
                        .scaleEffect(showMarks ? 1 : 0.1)
                    PaletteDoodle(size: 66)
                        .rotationEffect(.degrees(showMarks ? 0 : 28))
                }
                .opacity(showMarks ? 1 : 0)
                .scaleEffect(showMarks ? 1 : 0.6)
                .wiggle(2.5)
                .padding(.bottom, 24)

                // Title, revealed one word at a time from opposite sides.
                VStack(spacing: -4) {
                    Text("Invention")
                        .font(.display(58))
                        .foregroundColor(Palette.ink)
                        .offset(x: showInvention ? 0 : -44)
                        .opacity(showInvention ? 1 : 0)
                    Text("Party")
                        .font(.display(58))
                        .foregroundColor(Palette.tomato)
                        .rotationEffect(.degrees(showParty ? -3 : 6))
                        .offset(x: showParty ? 0 : 44)
                        .opacity(showParty ? 1 : 0)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)

                Text("Mash two objects together and invent something gloriously ridiculous.")
                    .font(.marker(17))
                    .foregroundColor(Palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 12)
                    .padding(.bottom, 52)

                // The single call to action. Pops in last, then breathes gently.
                FilledButton(title: "Play!", background: Palette.mustard,
                             foreground: Palette.ink, fontSize: 30, verticalPadding: 22,
                             seed: 3, icon: .controller) {
                    router.push(.setup)
                }
                .frame(maxWidth: 260)
                .scaleEffect(showButton ? (pulse ? 1.04 : 1.0) : 0.4)
                .opacity(showButton ? 1 : 0)
                .padding(.bottom, 28)
            }
            .padding(20)
        }
        .screenBackground()
        .onAppear(perform: runIntro)
    }

    /// Kicks off the staged entrance, or snaps everything into place when
    /// animations are disabled.
    private func runIntro() {
        guard animate else {
            showMarks = true; showInvention = true; showParty = true
            showTagline = true; showButton = true
            return
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            showMarks = true
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.28)) {
            showInvention = true
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.62).delay(0.46)) {
            showParty = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.74)) {
            showTagline = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.58).delay(0.98)) {
            showButton = true
        }
        // Gentle, never-ending "press me" breathing once the button has landed.
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(1.35)) {
            pulse = true
        }
    }
}
