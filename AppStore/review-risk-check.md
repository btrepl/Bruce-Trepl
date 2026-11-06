# Pre-submission review check — How Far Can You Hit It?

Checked 2026-10-27 (America/Chicago) from the files already in this folder.
No change to the game is needed now. This is a heads-up for App Store Connect
time, so two items don't come as surprises at review.

## 1. The 9+ age rating in listing.md is an estimate, and it may be low

- `listing.md` currently says: estimated 9+ — "cartoon humor, mild language
  in the roast sayings, no realistic violence. Final rating comes from Apple's
  questionnaire in App Store Connect."
- That last sentence is the important part: Apple assigns the rating from
  the questionnaire answers, not from the estimate in the listing.
- Apple's current bands (per 2026 reporting) are 4+, 9+, 13+, 16+, 18+ —
  the old 12+ / 17+ bands are what older systems still display. So a result
  that would once have read 12+ now reads 13+.
- What the code actually contains (checked 2026-10-28 in
  `Sources/Models.swift`): small hits (1–149) get the roast lines, medium
  hits (150–279) get lightly mocking lines, and misses get tame teasing
  ("Swing and a miss!", "You whiffed it!") — misses are not roasted.
  The only mild-language line in the whole game is one of the five
  small-hit lines ("Wow, that sucked"); the other roast lines are
  playground teasing with no profanity. So the teasing is frequent, but
  the mild language itself is a single line that appears only sometimes.
- Practical takeaway: answer the questionnaire honestly about both
  frequency and content type, and don't promise "9+" anywhere outside
  this folder until App Store Connect returns the actual rating. A 13+
  result remains possible, but this correction makes 9+ more plausible
  than the 2026-10-27 version of this note suggested. A 13+ result is
  not a rejection — it just narrows the youngest audience.

## 2. The Trump caricature — REMOVED in build 16 (2026-11-06)

Bruce decided to remove Trump from the game entirely. The PresetID case,
his sprite + portrait + the Trump-based Robot Head variation, his Driver
bat, and the listing mention are all gone as of build 16. The review risk
in this section is now moot — there is no real person left in the game.
Kept below for the record only.

- Apple Guideline 1.1.1 covers defamatory / mean-spirited content about a
  targeted individual or group, and says professional political satirists
  and humorists are generally exempt. That exemption is worded for
  satirists, and this is a batting game, not a satire app — so a reviewer
  has discretion here. This is not a prediction of rejection.
- Why the risk looks low:
  - Trump is a playable hero, not an enemy or a target to hit.
  - The art is an original goofy caricature (blond swoop, golf driver),
    not a copied photo or a licensed likeness.
  - The roast lines are generic swing jokes, not political attacks, and
    they apply to every slugger, not just him.
  - There is no realistic violence, and no real government, company, or
    group is an "enemy" in the game.
  - The other sluggers are folklore / generic (Santa, Bigfoot, a generic
    funny snowman, a generic ballplayer), so he is the only real person
    in the game — which is also why he is the only one to watch.
- If a reviewer ever flags him (only then, not now), the two fallbacks
  are: appeal with a short note that he is a goofy parody hero in a
  comedy batting game, or swap him for a generic golfer. That is a
  decision for review time, not a change to make pre-emptively.

## App Store Connect values — ready to copy (from README.md)

These were already in the code; collected here so they are in one place
when the Developer account is active:

| Item | Value |
|---|---|
| Bundle ID | com.tntfamily.howfar |
| Custom Slugger (non-consumable, $0.99) | com.tntfamily.howfar.customslugger |
| Custom Bat (non-consumable, $0.99) | com.tntfamily.howfar.custombat |
| Ranked Refill, 20 ranked swings (consumable, $0.99) | com.tntfamily.howfar.rankedrefill20 |
| Remove Ads + Unlimited Ranked (non-consumable, $4.99) | com.tntfamily.howfar.removeads |
| Game Center leaderboard | com.tntfamily.howfar.leaderboard |

The app price tier is Free (build 16). The old swingpack5 product
($1.00 for 5 swings) is retired; do not re-create it.

After those products exist in App Store Connect, set `stubMode = false`
in `Sources/StoreManager.swift` and test in TestFlight before submitting.

## Verification note — 2026-10-28 (America/Chicago)

- Apple's official App Store Review Guidelines page was checked directly
  this morning (page last updated 2026-10-16). Section 1.1.1 is confirmed
  in substance as described in section 2 above: it covers defamatory,
  discriminatory, or mean-spirited content about a targeted individual or
  group, with a general exemption for professional political satirists
  and humorists. The Trump-slugger assessment in section 2 is unchanged:
  low risk, not zero, reviewer discretion, appeal-or-swap fallback.
- The same official page stresses answering the App Store Connect
  age-rating questions honestly, and holds store metadata (icons,
  screenshots, previews) to a standard suitable for all audiences.
  Practical consequence for the screenshots checklist: keep the roast
  lines out of the screenshots and preview — use a hype line or a
  neutral result card for the gameplay shot, not a small-hit roast.

## Still open from earlier today (not new — listed only so nothing is lost)

- Apple Developer enrollment (Individual, $99/yr) — Bruce's step, with
  verification that can take up to 48 hours.
- Privacy policy contact email + a permanent public host for
  `privacy-policy.html` (already delivered as a separate prep item).
- Screenshots from the compiled native app (checklist already delivered).
