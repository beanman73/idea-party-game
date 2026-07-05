//
//  SettingsView.swift
//  Invention Party
//
//  A real settings screen (replaces the old "coming soon" alert). Styled to
//  match the Sketchbook theme. All preferences persist via @AppStorage
//  (UserDefaults), since the game's state model is otherwise in-memory.
//
//  Where each setting takes effect:
//   • appearance        → RootView.preferredColorScheme
//   • playfulAnimations → RootView page transition + PopIn entrance flourishes
//   • hapticsEnabled    → FilledButton tap feedback
//   • defaultRounds     → SetupView's initial "Number of Rounds" field
//

import SwiftUI

struct SettingsView: View {
    var onClose: () -> Void = {}

    @AppStorage("appearance") private var appearance: String = "system"
    @AppStorage("playfulAnimations") private var playfulAnimations: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("defaultRounds") private var defaultRounds: Int = 5
    /// Which invention inputs players get on the Idea Pad. Both default on; at
    /// least one must always stay enabled.
    @AppStorage("inputDrawing") private var inputDrawing: Bool = true
    @AppStorage("inputWriting") private var inputWriting: Bool = true

    private let roundsRange = 1...20

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.display(34))
                    .foregroundColor(Palette.ink)
                    .frame(maxWidth: .infinity)

                appearanceSection
                roundsSection
                inventionInputsSection
                togglesSection
                aboutSection

                FilledButton(title: "Done", background: Palette.card,
                             foreground: Palette.ink, fontSize: 18, verticalPadding: 14, seed: 80) {
                    onClose()
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .screenBackground()
    }

    // MARK: - Shared bits

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.marker(19, bold: true)).foregroundColor(Palette.ink)
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Appearance")
            HStack(spacing: 12) {
                appearanceButton(title: "System", icon: "circle.lefthalf.filled", value: "system", seed: 41)
                appearanceButton(title: "Light", icon: "sun.max.fill", value: "light", seed: 42)
                appearanceButton(title: "Dark", icon: "moon.fill", value: "dark", seed: 43)
            }
        }
    }

    private func appearanceButton(title: String, icon: String, value: String, seed: UInt64) -> some View {
        let active = appearance == value
        return Button { appearance = value } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(active ? Palette.ink : Palette.inkSoft)
                Text(title)
                    .font(.marker(15, bold: true))
                    .foregroundColor(active ? Palette.ink : Palette.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 6)
            .sketchCard(fill: active ? Palette.mustard : Palette.card,
                        border: Palette.ink, lineWidth: active ? 3 : 2, seed: seed, shadow: active)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: active)
    }

    // MARK: - Default rounds

    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Default Rounds")
            HStack(spacing: 16) {
                Text("Start new games with")
                    .font(.marker(16)).foregroundColor(Palette.inkSoft)
                Spacer()
                stepperButton(symbol: "minus", seed: 44) {
                    if defaultRounds > roundsRange.lowerBound { defaultRounds -= 1 }
                }
                .disabled(defaultRounds <= roundsRange.lowerBound)
                .opacity(defaultRounds <= roundsRange.lowerBound ? 0.4 : 1)

                Text("\(defaultRounds)")
                    .font(.marker(22, bold: true)).foregroundColor(Palette.ink)
                    .frame(minWidth: 34)

                stepperButton(symbol: "plus", seed: 45) {
                    if defaultRounds < roundsRange.upperBound { defaultRounds += 1 }
                }
                .disabled(defaultRounds >= roundsRange.upperBound)
                .opacity(defaultRounds >= roundsRange.upperBound ? 0.4 : 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .sketchCard(fill: Palette.card, border: Palette.teal, lineWidth: 2.5, seed: 46)
        }
    }

    private func stepperButton(symbol: String, seed: UInt64, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Palette.cream)
                .frame(width: 40, height: 40)
                .background(SketchyRoundedRectangle(cornerRadius: 11, seed: seed).fill(Palette.grape))
                .overlay(SketchyRoundedRectangle(cornerRadius: 11, seed: seed).stroke(Palette.ink, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Invention inputs

    /// Bindings that flip a flag but guarantee the other stays on, so players are
    /// never left with no way to submit an invention.
    private var drawingBinding: Binding<Bool> {
        Binding(get: { inputDrawing }, set: { newValue in
            inputDrawing = newValue
            if !inputDrawing && !inputWriting { inputWriting = true }
        })
    }
    private var writingBinding: Binding<Bool> {
        Binding(get: { inputWriting }, set: { newValue in
            inputWriting = newValue
            if !inputDrawing && !inputWriting { inputDrawing = true }
        })
    }

    private var inventionInputsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Invention Inputs")
            Text("How players capture their invention. Keep both on to draw and write.")
                .font(.marker(13)).foregroundColor(Palette.inkSoft)
            toggleRow(title: "Drawing",
                      subtitle: "Sketch the invention on a canvas",
                      isOn: drawingBinding, accent: Palette.teal, seed: 51)
            toggleRow(title: "Writing",
                      subtitle: "Describe the invention in words",
                      isOn: writingBinding, accent: Palette.sky, seed: 52)
        }
    }

    // MARK: - Toggles

    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Feel")
            toggleRow(title: "Playful Animations",
                      subtitle: "Page shuffles & pop-in flourishes",
                      isOn: $playfulAnimations, accent: Palette.grape, seed: 47)
            toggleRow(title: "Haptics",
                      subtitle: "A little buzz on button taps",
                      isOn: $hapticsEnabled, accent: Palette.tomato, seed: 48)
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>,
                           accent: Color, seed: UInt64) -> some View {
        Button { isOn.wrappedValue.toggle() } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.marker(17, bold: true)).foregroundColor(Palette.ink)
                    Text(subtitle).font(.marker(13)).foregroundColor(Palette.inkSoft)
                }
                Spacer()
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isOn.wrappedValue ? accent : Palette.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .sketchCard(fill: Palette.card, border: isOn.wrappedValue ? accent : Palette.ink,
                        lineWidth: isOn.wrappedValue ? 3 : 2, seed: seed)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn.wrappedValue)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("About")
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    LightbulbDoodle(size: 30)
                    Text("Invention Party").font(.marker(18, bold: true)).foregroundColor(Palette.ink)
                    Spacer()
                }
                Text("Mash two objects together and invent something gloriously ridiculous. Made for laughing with friends.")
                    .font(.marker(14)).foregroundColor(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(appVersion)
                    .font(.marker(13)).foregroundColor(Palette.inkFaint)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .sketchCard(fill: Palette.cardSunken, border: Palette.ink, lineWidth: 2, seed: 49)
        }
    }
}
