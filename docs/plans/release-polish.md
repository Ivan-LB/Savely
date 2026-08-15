# Release polish — onboarding, tips flag, real achievements

**Date:** 2026-08-15
**Status:** in progress (this branch)
**Branch:** `feature/release-polish-onboarding-flags`
**Context:** prep for the first official App Store version, right after the
auth/Firebase removal + sprout rebrand (PR #32).

## 1. Tips behind a feature flag

Decision (Iván): the official Apple release ships **without** the AI tips
surface. `Savely/Utilities/FeatureFlags.swift` → `tipsEnabled = false`,
compile-time (local-first app; there is no backend to serve runtime flags).

- Gates: DashboardView (Tip of the Day card + view-model wiring — no OpenAI
  calls at all while off), ProfileView (About/Tip history section),
  WeeklyInsightsView (tip row), OnboardingData (Receive Tips step).
- Tips code is **not deleted**; the flag is the off switch. `TipModel`
  stays in the SwiftData container so stored tips survive a round trip.
- Documented in `CLAUDE.md` invariant #9 + `gotchas.yaml#tips-behind-feature-flag`.

## 2. Onboarding redesign (Warm Meadow)

The old flow predated the design system: bright system-green SF symbols,
bold system font, `primaryGreen`/`backgroundColor` legacy assets. Redesign:

- **New welcome page** leads with the sprout mark + the local-first promise
  ("no accounts, your data lives on your iPhone") — the one thing worth
  saying first now that auth is gone, and it wasn't sayable before.
- Feature pages: soft Warm Meadow tile (warmSkySoft/warmGreenSoft/
  warmAmberSoft) + strong glyph, serif 30 titles, warmInkSoft body.
  Content updated to real features: goals, track income+expenses (merged
  from two stale pages), **receipt scanning** (existed all along, was never
  advertised). Tips page only renders when the flag is on.
- Notifications page keeps its function (time pickers) restyled as a
  bordered warmSurface card, no shadows.
- Custom page dots (active pill in warmGreen), warmGreen button.
- Motion: one short entrance per page (tile settles + text rises,
  ≤400 ms, damping 0.9 — no bounce). Reduce Motion → instant.
- All new user-facing strings go through `Strings.swift` (onboarding
  already used it; kept the discipline).
- Deleted `Views/Onboarding/Untitled.swift` (empty stray, not in target).

## 3. Real achievements (replaces the mock)

`AchievementsView` and ProfileView's badge tiles were 100% hardcoded
(fixed unlocks, invented progress percentages — including a "Tipster"
badge for the now-hidden tips). Replaced with a real engine:

- **`Savely/Utilities/AchievementEngine.swift`** — pure evaluation over
  plain values (`AchievementInput`): 10 achievements, all derived from
  SwiftData contents (first income/expense, first goal, 50% on a goal,
  completed goal, 7/30/100-day logging streaks, $1k/$10k lifetime income).
  No side-channel counters, no fabricated numbers: if the data doesn't
  show it, it stays locked. (A "scan your first receipt" badge was
  considered and dropped — scans aren't distinguishable in the data model
  today, and a UserDefaults counter would break the no-side-channel rule.)
- `AchievementStore` (UserDefaults) tracks which unlocks were already
  *celebrated* so the unlock pop runs exactly once per badge.
- `AchievementsView`: staggered row entrance (40 ms/row), progress bars
  fill to their real value on appear, newly unlocked tiles pop with a soft
  amber glow. Reduce Motion → everything instant, celebration skipped.
- ProfileView badge previews = first six real states (locked → lock tile).
- Unit tests: `SavelyTests/AchievementEngineTests.swift` (XCTest, matching
  the existing target) — streak edge cases (empty, duplicates, gap resets,
  month boundary, unordered input) + threshold/clamping logic.

## 4. Payday auto-move suggestion — built for real

Iván's call (2026-08-15): the App Store version SHOULD have this kind of
recommendation, done properly — so the placeholder banner ("$230 to
Kyoto", YES did nothing) became a real feature instead of staying hidden:

- **`GoalModel` gains `autoMoveEnabled`, `autoMoveAmount` and `deadline`**
  (additive defaults, automatic lightweight migration). The AddGoalFlow
  wizard always asked for all three ("Auto-move on payday" toggle, pace,
  target date) but never persisted any of them — now it does.
- **`Utilities/AutoMoveSuggestion.swift`** — the priority question Iván
  raised ("¿cómo se hace el cálculo de prioridades?") answered with flows:
  - *Which goal*: favorite first (explicit user signal); else the most
    urgent = highest required weekly pace (`remaining ÷ weeks to
    deadline`); open-ended goals rank last, by lowest progress.
  - *How much*: min(configured pace, remaining to target, income being
    logged, **month margin** = month incomes + this income − month
    expenses). An under-water month suggests nothing — money the month
    already spent is not "savable". Recomputed live from the keypad;
    nothing below $1 suggested.
- **YES arms, Save executes**: the deposit applies only together with the
  income save, using the exact clamp of the manual "Deposit to a goal"
  flow. Undo available while armed. No move without a saved income.
- `FeatureFlags.autoMoveSuggestionsEnabled` flips to **true** and stays as
  the kill switch. Unit tests in `AutoMoveSuggestionTests` (16 cases: eligibility,
  favorite/urgency/progress priority, income/target/month-margin caps,
  under-water month, apply clamps).

## Shared

- `Views/Components/SproutMark.swift` — the sprout shapes extracted from
  SplashScreenView (same 120-unit space as the app icon) + a static
  `SproutMark` view; splash animates the same shapes, welcome page and
  future surfaces use the static mark.

## Verification

1. `xcodebuild test` (unit tests incl. the new engine tests) green.
2. `swiftlint lint --strict` clean.
3. Simulator: fresh onboarding walk-through (5 pages, no tips page, Warm
   Meadow styling, dots/button), dashboard shows no tip card, profile has
   no tip row, achievements show real locked/unlocked states from data.
