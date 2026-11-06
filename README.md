# How Far Can You Hit It? — Native iOS Version

A native SwiftUI rebuild of the "How Far Can You Hit It?" batting game.
Pick a slugger, time your swing at a pitched **baseball**, and see how
far it flies — measured in feet.

> **IMPORTANT — NOT COMPILED HERE.** This code was written on a Linux VM
> with no Xcode, so it has never been built. Open it in Xcode (below) and
> fix anything the compiler flags. The code targets iOS 17+ / Xcode 15+ and
> uses only standard SwiftUI, StoreKit 2, and GameKit APIs.

## The game

- **5 free sluggers, each with a signature bat that auto-equips:**
  - Santa — Gift Wrap Roll (Power 3, Speed 4)
  - Donald Trump — Driver, a golf driver (Power 4, Speed 4)
  - The Ballplayer — Classic Bat, a classic American baseball bat shape (Power 4, Speed 4)
  - Bigfoot — Wooden Club, a chunky caveman-style club (Power 6, Speed 2)
  - Snowman — Ice Club, a chunky frozen club (Power 4, Speed 2)
- **Build-a-Slugger** ($0.99 unlock): name, face style, expression, hat,
  jersey color. Smaller body, larger goofy head, cartoonish person look.
- **Build-a-Bat** ($0.99 unlock): pick an object, split 8 points between
  power and speed (power slider 1–7, speed is the rest).
- **Seasons (exactly 3):** Fall → a few pumpkins on the ground · Christmas
  → Christmas lights dangling · Normal → plain field. The player picks; the
  season only decorates the field. Distance is always in feet.
- **Gameplay:** the Pitch-O-Matic throws a baseball. Tap SWING with
  timing — the closer to the sweet spot, the farther it flies. Bat power
  scales distance, bat speed widens the timing window. Visible swing
  animation (wind-up → whip through → follow-through, whole figure
  twists, not just the bat). No background scenery: a plain backdrop,
  a flat ground strip, and the camera pans to follow the ball as it
  bounces and rolls to a stop.
- **Sayings after every swing, tiered by hit size:**
  - Big (280+): hype — "It's outta here!", "Bye-bye!", "See ya!", "Oooooofffff!"
  - Medium (150–279): lightly mocking — "Not bad… for you",
    "Solid-ish. If you squint, that's almost impressive"
  - Small (1–149): full roast — "Nice swing, Alice",
    "Your mom swings harder than that", "Wow, that sucked"
  - Miss/whiff: roasted.
- **Swings:** 10 free per day (resets on the calendar day, stored in
  UserDefaults). Extra swings: 5 for $1.00.
- **Leaderboard:** top 20 local bests now; Game Center is the integration
  point for the real global board (see below).
- **Pricing:** $1.00 paid download (set in App Store Connect) + the $0.99
  unlocks + $1.00 swing packs. Enroll in the App Store Small Business
  Program so Apple takes 15% instead of 30%.

## Art and naming rules (baked into the code)

- All characters and bats are **original SwiftUI shapes** drawn in
  `CharacterArt.swift` and `BatArt.swift`. No copied images, no photo
  assets, no licensed characters.
- The snowman is a **generic funny snowman** drawn from scratch.
- The Ballplayer's bat is called **"Classic Bat"** in-game and is drawn as
  a generic classic American baseball bat shape.

## How to open in Xcode

1. On a Mac, open Xcode and create a new project:
   **File → New → Project → iOS → App**, interface **SwiftUI**, language
   **Swift**. Name it `HowFarCanYouHitIt`.
2. Delete the template's `ContentView.swift` and `<ProjectName>App.swift`
   (this repo's `HowFarCanYouHitItApp.swift` is the entry point — do not
   keep two `@main` structs).
3. Drag every `.swift` file from `Sources/` into the project target
   (check "Copy items if needed").
4. Set the **Bundle Identifier** to `com.tntfamily.howfar` (or your own;
   if you change it, update the product IDs in `StoreManager.swift` to
   match).
5. Set the deployment target to **iOS 17.0** or later.
6. Build and run on a simulator or device. Fix any compiler complaints
   first — this code has not been compiled (see note at the top).

## File map

| File | What it does |
|---|---|
| `HowFarCanYouHitItApp.swift` | `@main` entry, wires up the three managers |
| `Models.swift` | Seasons, characters, bats, faces, hats, sayings tiers, leaderboard entry, screens |
| `GameState.swift` | Shared state: selection, daily swings, scores, persistence |
| `StoreManager.swift` | In-app purchases (StoreKit 2, currently stubbed) |
| `GameCenterManager.swift` | Game Center sign-in + score submission (integration point) |
| `CharacterArt.swift` | Original cartoon art for all 5 presets + custom sluggers |
| `BatArt.swift` | Original art for all 8 bat objects, drawn upright for swinging |
| `ContentView.swift` | Screen router, Home, Character Select, Season Picker, Leaderboard |
| `BuilderViews.swift` | Build-a-Slugger and Build-a-Bat workshops |
| `GameView.swift` | The field: pitching, timing, flight, result card, plain background, panning camera, bouncing ball |

## What is stubbed (and what to wire up next)

### 1. StoreKit purchases — STUBBED (simulated, no real charges)
`StoreManager.stubMode` is `true`. Purchases simulate a short delay and
succeed, and the UI labels them as simulated. To go live:
- Create these products in App Store Connect (same bundle ID):
  - `com.tntfamily.howfar.customslugger` — non-consumable, $0.99
  - `com.tntfamily.howfar.custombat` — non-consumable, $0.99
  - `com.tntfamily.howfar.swingpack5` — consumable, $1.00
- Set `stubMode = false` in `StoreManager.swift`.
- Test in the sandbox / TestFlight before submitting.

### 2. Game Center leaderboard — LOCAL ONLY for now
Scores are stored on-device (top 20). `GameCenterManager` already signs
the player in and calls the real submit API when authenticated, but nothing
happens until you:
- Enable the Game Center capability (Signing & Capabilities in Xcode).
- Create a leaderboard in App Store Connect with ID
  `com.tntfamily.howfar.leaderboard` (already the value in code).
- Test with a sandbox Game Center account in TestFlight.

### 3. App Store listing — still to do
- App icon (1024×1024, no transparency).
- Screenshots for current iPhone sizes (and iPad if you go universal).
- Description, keywords, category (Games), age-rating questionnaire.
- Privacy policy URL (required in App Store Connect even for a game that
  collects no data — this game collects none).
- Apple Developer Program enrollment ($99/year) + Small Business Program.

### 4. Testing before submission
- Run through TestFlight with real players: check the swing timing feel,
  the daily swing reset, and the purchase flows once un-stubbed.
- Apple review usually takes a day or two; a rejection for fixes is normal.

## Known limitations / things to double-check in Xcode

- **Never compiled here.** Treat the first Xcode build as a real step:
  expect small fixes (e.g., an API nuance or a layout value).
- The swing timing window and distance curve are tuned by feel
  (`GameView.swingNow()`); playtest on a device and adjust the 380-point
  scale or the 280/150 tier thresholds if hits feel too long or too short.
- The Trump caricature is an original cartoon in a parody style; the
  generic snowman and the "Classic Bat" name are deliberate choices to
  avoid licensed-character and trademark issues at review.
