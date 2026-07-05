//
//  InventionPartyApp.swift
//  Invention Party
//
//  App entry point. Owns the GameStore and Router and hosts the custom
//  RootView, which drives every screen with a handmade page transition.
//

import SwiftUI

@main
struct InventionPartyApp: App {
    @StateObject private var store = GameStore()
    @StateObject private var router = Router()
    @StateObject private var purchases = PurchaseStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .environmentObject(purchases)
                .tint(Palette.tomato)
        }
    }
}

/// Hosts the current screen and animates between screens with a handmade,
/// directional page transition instead of the default navigation swipe.
/// Screens drive navigation through the `Router`'s push/pop API as before.
struct RootView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: GameStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Persisted appearance choice from Settings ("system" / "light" / "dark").
    @AppStorage("appearance") private var appearance: String = "system"
    /// Persisted toggle for the handmade page transition + pop-in flourishes.
    @AppStorage("playfulAnimations") private var playfulAnimations: Bool = true

    // The menu opens these as panels that slide down over the current screen, so
    // they feel built-in and leave the screen underneath (e.g. a drawing on the
    // Idea Pad) fully intact instead of tearing it down with a navigation push.
    @State private var showHowToPlay = false
    @State private var showSettings = false
    /// Confirmation before abandoning the current game to return to the splash.
    @State private var confirmMainMenu = false

    /// A unique key for the currently visible screen. Changing it triggers the
    /// transition — including same-depth resets like "Play Again".
    private var screenKey: String {
        router.path.isEmpty
            ? "home"
            : router.path.map { String(describing: $0) }.joined(separator: ">")
    }

    /// Whether handmade motion is on: respects both the user's Settings toggle
    /// and the system "Reduce Motion" accessibility setting.
    private var animate: Bool { playfulAnimations && !reduceMotion }

    var body: some View {
        ZStack {
            // Base layer so the brief overlap during a transition never flashes
            // white (or the wrong appearance) behind the two pages.
            Palette.paper.ignoresSafeArea()

            currentScreen
                .id(screenKey)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(animate ? .paperShuffle(forward: router.lastWasPush) : .opacity)

            // Menu panels slide down from the top, over the current screen.
            if showHowToPlay {
                HowToPlayView { closePanels() }
                    .zIndex(20)
                    .transition(.move(edge: .top))
            }
            if showSettings {
                SettingsView { closePanels() }
                    .zIndex(20)
                    .transition(.move(edge: .top))
            }
        }
        .animation(animate
                   ? .spring(response: 0.45, dampingFraction: 0.74)
                   : .easeInOut(duration: 0.2),
                   value: screenKey)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: showHowToPlay)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: showSettings)
        // The menu lives above every screen so How to Play / Settings are always
        // one tap away — but it stays hidden on the splash and while a panel is open.
        .overlay(alignment: .topTrailing) {
            if !router.path.isEmpty && !showHowToPlay && !showSettings {
                menuButton
                    .padding(.trailing, 16)
                    .padding(.top, 6)
                    .transition(.opacity)
            }
        }
        .confirmationDialog("Return to the main menu?", isPresented: $confirmMainMenu,
                            titleVisibility: .visible) {
            Button("Main Menu", role: .destructive) {
                closePanels()
                store.resetGame()
                router.popToRoot()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current game will be lost.")
        }
        .preferredColorScheme(preferredScheme)
    }

    private func closePanels() {
        showHowToPlay = false
        showSettings = false
    }

    /// Tucks the secondary screens (How to Play, Settings) behind a single
    /// doodled button that floats above whatever screen is showing.
    private var menuButton: some View {
        Menu {
            Button { showHowToPlay = true } label: {
                Label("How to Play", systemImage: "list.bullet.clipboard")
            }
            Button { showSettings = true } label: {
                Label("Settings", systemImage: "gearshape")
            }
            Divider()
            Button(role: .destructive) { confirmMainMenu = true } label: {
                Label("Main Menu", systemImage: "house")
            }
        } label: {
            menuGlyph
                .padding(9)
                .background(SketchyRoundedRectangle(cornerRadius: 12, seed: 7).fill(Palette.card))
                .overlay(SketchyRoundedRectangle(cornerRadius: 12, seed: 7).stroke(Palette.ink, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    /// A hand-drawn "hamburger" icon: three wobbly horizontal lines.
    private var menuGlyph: some View {
        Canvas { ctx, area in
            let w = area.width, h = area.height
            let lw = max(2, h * 0.11)
            let style = StrokeStyle(lineWidth: lw, lineCap: .round)
            let x0 = w * 0.18, x1 = w * 0.82
            for i in 0..<3 {
                let y = h * (0.3 + CGFloat(i) * 0.2)
                ctx.stroke(wobblyLine(from: CGPoint(x: x0, y: y), to: CGPoint(x: x1, y: y),
                                      seed: UInt64(70 + i), roughness: h * 0.012, segments: 3),
                           with: .color(Palette.ink), style: style)
            }
        }
        .frame(width: 24, height: 24)
    }

    /// Maps the persisted appearance string onto a SwiftUI color scheme.
    /// `nil` means "follow the system."
    private var preferredScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark":  return .dark
        default:       return nil
        }
    }

    @ViewBuilder private var currentScreen: some View {
        if let route = router.path.last {
            view(for: route)
        } else {
            SplashView()
        }
    }

    @ViewBuilder private func view(for route: Route) -> some View {
        switch route {
        case .packs:       PacksView()
        case .aiDeck:      AIDeckView()
        case .setup:       SetupView()
        case .rules:       RulesView()
        case .round:       RoundView()
        case .ideaPad:     IdeaPadView()
        case .judge:       JudgeView()
        case .vote:        VoteView()
        case .scoreboard:  ScoreboardView()
        case .podium:      PodiumView()
        }
    }
}
