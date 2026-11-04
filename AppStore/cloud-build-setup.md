# Cloud Build Setup — How Far Can You Hit It?

Route chosen by Bruce (2026-10-31): **cloud build, Codemagic free tier first** (no Mac).
Codemagic pricing verified 2026-10-31: 500 free macOS M2 minutes/month on a personal
account (resets on the 1st), then $0.095/min M2 / $0.114/min M4, one build at a time.

## What was created here
- `HowFarCanYouHitIt.xcodeproj/` — project file + shared scheme. Bundle ID
  `com.tntfamily.howfar`, iOS 17+, iPhone-only (TARGETED_DEVICE_FAMILY = 1 — a
  one-line change if iPad is added later), Swift 5 mode.
- `codemagic.yaml` — two workflows: `ios-first-build` (simulator, no signing,
  just proves it compiles) and `ios-testflight` (needs signing, see below).
- Git repo initialized in this folder, files staged (commit + push are Bruce's,
  under his own GitHub identity).

## Honest caveat
The project file was hand-built — there is no Mac here to open it in Xcode.
It is internally consistent (all references resolve, all 10 source files exist),
but the first cloud build may still flag project settings Xcode wants changed.
Treat the first build as a smoke test, not a finished app.

## Bruce's steps, in order
1. Create a free Codemagic account (individual plan).
2. Create a GitHub repo, then from this folder:
   - `git config user.name "Your Name"` and `git config user.email "your@email.com"`
   - `git add -A` (already staged) then `git commit -m "Initial commit"`
   - `git remote add origin <your repo URL>` then `git push -u origin main`
3. Connect the repo in Codemagic and run the `ios-first-build` workflow.
4. Send back whatever the compiler flags — those get fixed here and pushed again.
5. Later, for TestFlight: add an App Store Connect API key inside Codemagic
   (never paste keys in chat), create the app record + 3 in-app purchases +
   leaderboard per `AppStore/app-store-connect-setup.md`, set `stubMode = false`
   in `Sources/StoreManager.swift`, then run the `ios-testflight` workflow.
