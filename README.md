# Invention Party — Swift / SwiftUI

A native SwiftUI port of your Expo / React Native game **Invention Party**
(folder `MyNewApp`). Everything is plain Swift source — no CocoaPods, no SPM
dependencies, no Expo. You create one Xcode project and drop these files in.

Tested target: **iOS 17+** (uses SwiftUI `NavigationStack`, `PhotosPicker`,
`Canvas`, and the `Layout` protocol).

For App Store pricing, subscriptions, and AI credit setup, see
[`APP_STORE_PRICING_SETUP.md`](APP_STORE_PRICING_SETUP.md).

---

## What's included

```
InventionParty-Swift/
├── InventionParty/
│   ├── InventionPartyApp.swift     ← @main entry point
│   ├── Core/
│   │   ├── Models.swift            ← GameObject, Player, Submission, etc.
│   │   ├── GameStore.swift         ← game state (was the reducer/context)
│   │   ├── ObjectPacks.swift       ← the 4 built-in decks
│   │   ├── DeckGenerator.swift     ← AI deck: endpoint + local fallback
│   │   ├── Router.swift            ← navigation (was expo-router)
│   │   ├── Theme.swift             ← colors
│   │   └── SharedUI.swift          ← reusable views & helpers
│   └── Views/
│       ├── HomeView.swift          ← app/index.tsx
│       ├── HowToPlayView.swift     ← app/howtoplay.tsx
│       ├── PacksView.swift         ← app/packs.tsx
│       ├── CustomCardsView.swift   ← app/custom-cards.tsx
│       ├── AIDeckView.swift        ← app/ai-deck.tsx
│       ├── SetupView.swift         ← app/setup.tsx
│       ├── RulesView.swift         ← app/rules.tsx
│       ├── RoundView.swift         ← app/round.tsx
│       ├── IdeaPadView.swift       ← app/ideapad.tsx
│       ├── DrawingCanvasView.swift ← app/components/DrawingCanvas.tsx
│       ├── JudgeView.swift         ← app/judge.tsx
│       ├── ScoreboardView.swift    ← app/scoreboard.tsx
│       └── PodiumView.swift        ← app/podium.tsx
└── Resources/
    ├── AppIcon-1024.png            ← your original app icon (optional)
    └── splash-icon.png             ← your original splash image (optional)
```

---

## Setup in Xcode (about 5 minutes)

1. **Create the project.** Open Xcode → **File ▸ New ▸ Project… ▸ iOS ▸ App**.
   - Product Name: `InventionParty`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Save it anywhere on your Mac.

2. **Delete the two starter files** Xcode created: `ContentView.swift` and the
   `…App.swift` it generated (e.g. `InventionPartyApp.swift`). Move them to
   Trash when prompted — the versions in this folder replace them.

3. **Add these files.** In Finder, open the `InventionParty/` folder from this
   download. Drag the **`Core`** and **`Views`** folders, plus the
   **`InventionPartyApp.swift`** file, onto your project in the Xcode sidebar.
   In the dialog that appears:
   - ✅ Check **"Copy items if needed"**
   - ✅ Check **"Create groups"**
   - ✅ Make sure your app target is checked under "Add to targets"

4. **Set the deployment target to iOS 17.** Select the project in the sidebar →
   your target → **General** → **Minimum Deployments** → iOS **17.0**.

5. **Run.** Pick an iPhone simulator (or your device) and press ▶. The app
   should launch on the "🎨 Invention Party 🎨" home screen.

That's it — no other configuration is required to play with the built-in decks,
custom photo cards, and drawing.

---

## Notes on the port

**Navigation.** `expo-router`'s `router.push('/x')` / `router.back()` became a
small `Router` object driving a `NavigationStack` path. Each screen calls
`router.push(.route)` / `router.pop()`.

**State.** The `useReducer` + Context store became `GameStore`, an
`ObservableObject` injected with `.environmentObject`. Every reducer action is
now a method (`startRound`, `saveRoundResults`, `nextRound`, `resetGame`, …)
with identical scoring rules (3 / 2 / 1 points, judge rotation, etc.).

**Drawing.** The React Native SVG `PanResponder` canvas became a SwiftUI
`Canvas` + `DragGesture`. Strokes are saved as JSON inside a submission and
re-rendered for the judge with `DrawingPreview`. Undo and Clear both work.

**Custom card photos.** `expo-image-picker` became Apple's `PhotosPicker`
(`PhotosUI`). Because `PhotosPicker` runs out-of-process, **no photo-library
permission string is needed** — you can ignore the old Info.plist photo
permission from the Expo app. Images are held in memory for the session, same
as before.

**AI deck generation.** Production builds call your own AI backend at
`/api/generate-deck` so the OpenAI API key never ships inside the app. Debug
builds can still use the local fallback when no backend URL or test key is set.
See `AI_BACKEND_SETUP.md` before submitting an App Store update.

**App icon (optional).** To use your original icon: open `Assets.xcassets` →
`AppIcon`, and drag `Resources/AppIcon-1024.png` into the 1024×1024 slot.

---

## Not ported

- **`app/main.tsx`** — a standalone "casino roller" slot-machine screen. It
  isn't reachable from the game flow (nothing navigates to it), so it was left
  out. Ask if you'd like it added as a SwiftUI view.
- **In-app purchases** — the locked packs show the same "coming soon" alerts as
  the original; no StoreKit wiring was added.
- **Speed Round timer** — still a placeholder in the original ("TODO: Timer
  implementation coming soon"); carried over as-is.

---

## Quick map: original file → Swift file

| React Native (`MyNewApp/app/`) | Swift (`InventionParty/`) |
|---|---|
| `state/gameStore.tsx` | `Core/Models.swift` + `Core/GameStore.swift` |
| `data/objectPacks.ts` | `Core/ObjectPacks.swift` |
| `ui/theme.ts` | `Core/Theme.swift` |
| `index.tsx` | `Views/HomeView.swift` |
| `packs.tsx` | `Views/PacksView.swift` |
| `custom-cards.tsx` | `Views/CustomCardsView.swift` |
| `ai-deck.tsx` (+ `api/generate-deck.js`) | `Views/AIDeckView.swift` + `Core/DeckGenerator.swift` |
| `setup.tsx` | `Views/SetupView.swift` |
| `rules.tsx` | `Views/RulesView.swift` |
| `round.tsx` | `Views/RoundView.swift` |
| `ideapad.tsx` | `Views/IdeaPadView.swift` |
| `components/DrawingCanvas.tsx` | `Views/DrawingCanvasView.swift` |
| `judge.tsx` | `Views/JudgeView.swift` |
| `scoreboard.tsx` | `Views/ScoreboardView.swift` |
| `podium.tsx` | `Views/PodiumView.swift` |
| `howtoplay.tsx` | `Views/HowToPlayView.swift` |
