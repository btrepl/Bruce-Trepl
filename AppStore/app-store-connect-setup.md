# App Store Connect Setup — How Far Can You Hit It?

Run this once the Apple Developer account is active. The product and leaderboard IDs below already match the code — use them exactly.

## 1. Create the app record
- App Store Connect → My Apps → + → New App
- Bundle ID: `com.tntfamily.howfar` (create this App ID first in Certificates, Identifiers & Profiles if it doesn't exist)
- Name: How Far Can You Hit It? — subtitle, description, keywords, and icon from `AppStore/listing.md` and `AppStore/app-icon.png`
- Price: $1.00 (Tier 1)

## 2. In-app purchases (App Store Connect → your app → Monetization → In-App Purchases)

| Product ID | Type | Price | Display name | What it unlocks |
|---|---|---|---|---|
| `com.tntfamily.howfar.customslugger` | Non-consumable | $0.99 | Custom Slugger | Build-a-Slugger (make your own character) |
| `com.tntfamily.howfar.custombat` | Non-consumable | $0.99 | Custom Bat | Build-a-Bat (make your own bat) |
| `com.tntfamily.howfar.swingpack5` | Consumable | $1.00 | 5 Extra Swings | 5 extra swings on top of the 10 free per day |

Fill in a short description for each, plus the review information App Store Connect asks for. These IDs must match `StoreManager.swift` exactly — they already do.

## 3. Game Center leaderboard (App Store Connect → your app → Game Center)
- Leaderboard ID: `com.tntfamily.howfar.leaderboard`
- Reference name: Farthest Hits
- Score format: Integer, higher is better (distance in seasonal units)
- This matches `GameCenterManager.swift` already.

## 4. Flip the code from demo to real
- In `Sources/StoreManager.swift`, set `stubMode = false` (line 45). Purchases then run through real StoreKit against the products above.
- Game Center submission is already wired in `GameCenterManager.swift` — it activates once the leaderboard exists and the player is signed in.

## 5. Small Business Program (do this early)
- App Store Connect → Business → enroll in the Small Business Program. This drops Apple's commission from 30% to 15% and applies to the $1.00 app price and all three purchases.

## 6. Build, TestFlight, submit
- The code has never been compiled — the first Xcode build (on a Mac, or via a cloud Mac build service) may surface small fixes. Budget a round for that.
- Screenshots come from the built app, per `AppStore/screenshots-checklist.md` (6-shot order, one iPhone 6.9-inch set; no roast lines in screenshots — hype lines and neutral result cards only).
- TestFlight: internal testers first, then external, then Submit for Review. Review is usually a day or two.

## Still needed from Bruce
- Privacy policy contact email + a permanent public URL for the policy page (`AppStore/privacy-policy.html` is ready except for the email).
- iPhone-only or iPhone + iPad (decides whether an iPad screenshot set is needed).
