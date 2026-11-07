# App Store Connect Setup — How Far Can You Hit It?

Run this once the Apple Developer account is active. The product and leaderboard IDs below already match the code — use them exactly.

## 1. Create the app record
- App Store Connect → My Apps → + → New App
- Bundle ID: `com.tntfamily.howfar` (create this App ID first in Certificates, Identifiers & Profiles if it doesn't exist)
- Name: How Far Can You Hit It? — subtitle, description, keywords, and icon from `AppStore/listing.md` and `AppStore/app-icon.png`
- Price: Free (Tier 0) — the app is free-to-play with in-app purchases
  (build 16). Set the price tier to Free.

## 2. In-app purchases (App Store Connect → your app → Monetization → In-App Purchases)

| Product ID | Type | Price | Display name | What it unlocks |
|---|---|---|---|---|
| `com.tntfamily.howfar.customslugger` | Non-consumable | $0.99 | Custom Slugger | Build-a-Slugger (make your own character) |
| `com.tntfamily.howfar.custombat` | Non-consumable | $0.99 | Custom Bat | Build-a-Bat (make your own bat) |
| `com.tntfamily.howfar.rankedrefill20` | Consumable | $0.99 | Ranked Refill | 20 ranked swings |
| `com.tntfamily.howfar.removeads` | Non-consumable | $4.99 | Remove Ads | Removes ads + unlimited ranked swings |
| `com.tntfamily.howfar.coins1000` | Consumable | $0.99 | 1,000 Coins | Coins for bat upgrades |
| `com.tntfamily.howfar.coins5000` | Consumable | $2.99 | 5,000 Coins | Coins for bat upgrades |
| `com.tntfamily.howfar.seasonpass` | Non-consumable | $4.99 | Premium Season Pass | Premium track of the season pass (more coins + Golden Bat) |

Fill in a short description for each, plus the review information App Store Connect asks for. These IDs must match `StoreManager.swift` exactly — they already do.

## 3. Game Center leaderboard (App Store Connect → your app → Game Center)
- Leaderboard ID: `com.tntfamily.howfar.leaderboard`
- Reference name: Farthest Hits
- Score format: Integer, higher is better (distance in feet)
- This matches `GameCenterManager.swift` already.

## 3b. Game Center achievements (App Store Connect → your app → Game Center → Achievements)

Build 19 added 6 achievements, reported from `GameCenterManager.swift` / `SeasonPass.swift`. Create each with the exact Achievement ID below — the code reports 100% complete when the trigger fires, and reporting an achievement that does not exist yet simply does nothing, so the game never breaks if these are added later.

| Achievement ID | Title | Description |
|---|---|---|
| `com.tntfamily.howfar.achievement.firsthit` | First Hit | Record your first hit |
| `com.tntfamily.howfar.achievement.hit300` | 300 Club | Hit 300+ feet |
| `com.tntfamily.howfar.achievement.hit400` | 400 Club | Hit 400+ feet |
| `com.tntfamily.howfar.achievement.swings100` | Century | Take 100 ranked swings |
| `com.tntfamily.howfar.achievement.coins1000` | Coin Hoarder | Earn 1,000 total coins |
| `com.tntfamily.howfar.achievement.maxbat` | Maxed Out | Upgrade a bat to max level |

Note: the "This Week" board in the app is a local filter on the on-device leaderboard, not a second Game Center leaderboard — do not create another leaderboard for it. The one leaderboard in §3 is the only one the code uses.

## 4. Flip the code from demo to real
- `StoreManager.stubMode` is already `false` (real StoreKit 2). Purchases
  run through real StoreKit against the products above — create them first.
- Game Center submission is already wired in `GameCenterManager.swift` — it activates once the leaderboard exists and the player is signed in.

## 5. Small Business Program (do this early)
- App Store Connect → Business → enroll in the Small Business Program. This drops Apple's commission from 30% to 15% and applies to all in-app purchases. (The app itself is now Free under build 16, and there are 7 products, not 3.)

## 6. Build, TestFlight, submit
- Builds now compile via Codemagic (free tier) and build 15 (1.0 (15)) is processed in TestFlight — the app record, IAPs, and leaderboard in §§1–3 are created, and `stubMode` in §4 is already flipped to real StoreKit.
- Screenshots come from the built app, per `AppStore/screenshots-checklist.md` (6-shot order, one iPhone 6.9-inch set; no roast lines in screenshots — hype lines and neutral result cards only).
- TestFlight: internal testers first, then external, then Submit for Review. Review is usually a day or two.

## Still needed from Bruce
- Privacy policy contact email + a permanent public URL for the policy page (`AppStore/privacy-policy.html` is ready except for the email).
- iPhone-only or iPhone + iPad (decides whether an iPad screenshot set is needed).
