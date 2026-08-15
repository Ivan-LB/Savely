# PR C — Goals, completed: edit sheet, deposit ledger, real pace

**Source audit:** `docs/plans/money-surfaces-audit.md` (2026-08-15)
**Depends on:** PR A merged (the favorite-goal coupling must already be
dead — this PR assumes deposits are the only mutation path). Independent
of PR B.
**Branch:** `feat/goals-complete` off `dev`, PR back to `dev` (developer merges manually)
**Complexity:** Large. New model entity + one new sheet + three flows
touched + math replacement. Split into the 4 commits suggested below.

> Decisions are made — do not re-litigate. Read `CLAUDE.md`,
> `.claude/knowledge/gotchas.yaml`, and the **Repo traps** section of
> `docs/plans/pr-a-honesty-correctness.md` (pbxproj procedure, commit
> hook, XCTest, SwiftLint ratchet).

## Context (self-contained)

Goals can be created (4-step wizard) and deleted, but **nothing can be
edited afterward** — both edit pencils are empty closures. Deposits
mutate `GoalModel.current` in place with no record: notes are collected
and discarded, history is unrepresentable, and the payday auto-move's
month-margin math (PR #33, `AutoMoveSuggestion`) cannot subtract money
already moved to goals this month. Goal detail fakes its stats ("Per
week" divides by a hardcoded 24; ETA is circular; dashboard PACE always
says "On track") even though `deadline` is persisted.

## Design decisions (fixed)

- **`DepositModel`** (new `@Model`, file `Savely/Models/DepositModel.swift`):
  `id: UUID`, `goalID: UUID`, `amount: Double`, `date: Date`,
  `note: String?`, `source: String` (`"manual"` or `"auto-move"`).
  Registered in the container list at `SavelyApp.swift:26` (additive —
  new entity, lightweight migration automatic).
- **One write path:** a small helper (suggestion:
  `Savely/Utilities/GoalDeposits.swift`) with
  `record(goal:amount:note:source:context:)` that (a) clamps and mutates
  `goal.current` exactly like today (`min(current + amount, target)`),
  (b) inserts the `DepositModel`, (c) saves with do/catch. All four
  writers use it: `GoalDetailView.swift:236-242`,
  `DashboardView.swift:385-390`, quick-deposit `saveDeposit` in
  `MainNavigationView.swift:~734-739`, and the auto-move apply path in
  `WarmQuickIncomeView.saveAndDismiss` (replace the bare
  `suggestion.apply()` call with `GoalDeposits.record(..., source:
  "auto-move")`). **Delete `AutoMoveSuggestion.apply()`** and migrate its
  two tests (`AutoMoveSuggestionTests.testApplyClampsAtTarget` and
  `testApplyAddsAmount`, `SavelyTests/AutoMoveSuggestionTests.swift:~89-99`)
  into `GoalDepositsTests` as clamp tests of `record(...)`. Note: the
  "defaults keep existing tests valid" guarantee applies to the
  `compute` signature change only — the apply-tests MUST be migrated or
  the suite breaks.
- **Month margin correction:** `AutoMoveSuggestion.compute` gains
  `monthDepositTotal: Double = 0`, subtracted in the margin:
  `margin = monthIncomeTotal + incomeAmount − monthExpenseTotal − monthDepositTotal`.
  `WarmQuickIncomeView` passes the current-month sum from a `@Query` of
  deposits. Default `0` keeps existing tests valid.
- **Pace policy (used by GoalDetailView stats + HeroGoalCard PACE):**
  - `requiredWeeklyPace = remaining ÷ weeks-to-deadline` (same math as
    `AutoMoveSuggestion.compute`'s inner function — extract it into the
    new helper file so there is exactly one implementation).
  - `actualWeeklyPace` = average of the goal's deposits over the last 4
    weeks; if the goal has no deposits yet, fall back to
    `autoMoveAmount / 4.33` (its configured monthly pace as weekly).
  - On track ⇔ no deadline, or `actualWeeklyPace >= requiredWeeklyPace`.
  - ETA = `remaining ÷ actualWeeklyPace` weeks from today (cap display
    at "1+ year"); if pace is 0, show "—" (never fake a date).
- **No date option (do it exactly this way):** keep
  `AddGoalState.deadline: Date` NON-optional, and add
  `@Published var hasDeadline: Bool = true`. The "No date" preset
  (`AddGoalFlow.swift:441-443`) sets `hasDeadline = false` (today it
  silently keeps a stale 18-month default); picking any date or duration
  preset sets it back to `true`. `plantGoal` persists
  `deadline: state.hasDeadline ? state.deadline : nil`. This avoids
  optional plumbing through `MiniCalendarView` (whose binding is a
  non-optional `Date`, `AddGoalFlow.swift:504-505`). When
  `hasDeadline == false`: Step 3's pace card and `formattedDeadline`
  (`:419, :495-498`) show "—", Step 4's `formattedDeadline`/
  `shortDeadline`/"Goal · deadline"/"By" tile (`:707-712, :608, :638`)
  show "No date"/"—", the calendar keeps rendering its current selection
  (visually deemphasized is fine, no behavior change needed), and
  `plantGoal`'s `autoMoveAmount: state.monthlyPace.rounded()` falls back
  to `0` (pace is undefined without a deadline; the user can set the
  amount later in the edit sheet from Commit 2).

## Tasks (suggested commit boundaries)

### Commit 1 — Deposit ledger

1. `DepositModel.swift` (+ pbxproj registration, Models group
   `1DC258472CC629120002DDE3`; container list `SavelyApp.swift:26`).
2. `GoalDeposits.record(...)` helper; migrate the four write paths to it.
   The deposit NOTE fields (`GoalDetailView.swift:149,199-211`,
   `DashboardView.swift:301,349-361`) finally persist — pass them through.
3. `AutoMoveSuggestion`: add `monthDepositTotal` param + margin change;
   `WarmQuickIncomeView` supplies it via `@Query` deposits summed for the
   current month.
4. GoalDetailView: deposits history section (query by `goalID`, date
   desc; Warm Meadow list rows: amount, relative date, note, small
   "auto" tag when `source == "auto-move"`).
5. Tests (`SavelyTests/GoalDepositsTests.swift`, in-memory container):
   record() clamps at target and inserts the entity; margin math
   subtracts deposits (extend `AutoMoveSuggestionTests` — defaults keep
   old cases green).

### Commit 2 — Goal edit sheet

1. New `Savely/Views/GoalsTab/GoalEditSheet.swift` (pbxproj group:
   `1DC014012CDE00DB009A46E1` — the **Views**/GoalsTab group, the one
   whose children include GoalDetailView.swift and AddGoalFlow.swift.
   CAUTION: a grep for `/* GoalsTab */` returns TWO groups; the other,
   `1DAF5D192CEDC103001C0AF3`, is ViewModels/GoalsTab — registering the
   file there makes the build fail with "Build input file cannot be
   found").
   Fields: name, target, color (expose **all 13** `GoalColor` cases —
   the wizard only shows 6), deadline (optional, with a "no date"
   clear), auto-move toggle + amount. Validation: name non-empty,
   `target > 0`, `target >= current` (shrinking below saved money is
   confusing — reject with a clear message), deadline nil-or-future.
   One explicit Save button; do/catch around save with visible error.
2. Wire BOTH dead pencils to it: `GoalDetailView.swift:82` and
   `DashboardView.swift:261` (HeroGoalCard — present as a sheet).
3. Star behavior: make `setFavorite` a toggle (currently re-favorites,
   `GoalsViewModel.swift:118-139`) — tapping the current favorite's star
   unfavorites it.
4. Tests: validation matrix for the sheet's rules (pure helper if
   extracted, else skip UI-only paths).

### Commit 3 — Real pace, ETA, completion

1. Extract the weeks/pace math into the helper (single implementation;
   `AutoMoveSuggestion` consumes it too).
2. `GoalDetailView.swift:95-108`: replace `/24` "Per week" and circular
   ETA with the pace policy above; also display the deadline (persisted
   since PR #33 but shown nowhere).
3. `DashboardView.swift:281-283` + `GoalsView.swift:282-284`: PACE label
   from the policy ("On track" / "Behind" / "Complete!"), never
   hardcoded.
4. Completion: when `current >= target`, GoalsView shows the goal in a
   "Completed" section (out of the active count at `GoalsView.swift`
   header) with a one-time celebration pop on the card — reuse the
   high-damping spring + glow pattern from `AchievementRow`
   (`AchievementsView.swift`), gate one-time via UserDefaults set of
   celebrated goal IDs (mirror `AchievementStore`), respect
   `accessibilityReduceMotion` (instant, no pop).
5. Tests: pace policy (required vs actual, no-deadline, zero-pace ETA).

### Commit 4 — Wizard traps

1. "No date" → `deadline: Date?` = nil (decision above),
   `AddGoalFlow.swift:441-443` + state type change + pace fallbacks.
2. "Plant goal" silent no-op (`AddGoalFlow.swift:65-66`): disable the
   button when name is empty or amount <= 0 instead of guard-return.
3. Success screen "Add a deposit" (`AddGoalFlow.swift:41-45,788-796`):
   store the created `GoalModel` in `@State` on `AddGoalFlowView`
   (`plantGoal` currently drops the reference, `:65-80`), and present
   `DepositSheet(goal:modelContext:)` — the self-contained sheet defined
   in `DashboardView.swift` — over the success screen. Do NOT route
   through `WarmQuickDepositView`/`QuickAddScreen` (needless plumbing).
4. Step-4 Skip empty closure (`AddGoalFlow.swift:588`): make it advance
   (same as Next without changes) or remove the button.
5. Emoji picker + Reminders toggle (collected, never persisted): neither
   is a step — the emoji picker is the SYMBOL section inside Step 1
   (`AddGoalFlow.swift:212-234`) and the Reminders toggle is a recap row
   inside Step 4 (`:661`). **Remove that section and that row**; the
   wizard stays 4 steps, dots/`AddGoalHeader(step:total:)` unchanged.
   Delete `AddGoalState.emoji` and `showReminders`, and replace the emoji
   in its three render spots (Step 1 live preview `:165`, Step 2 chip
   `:299`, Step 4 hero card `:603`) with the goal-name initial on the
   color circle — the pattern `WarmGoalCard`/`WarmQuickDepositView`
   already use. Do not add model fields (YAGNI; reminders belong to a
   future notifications pass).

## String policy (decision)

New user-facing strings (edit sheet labels, deposit history, "Completed"
section, pace/ETA labels) match the surrounding warm views: **literal
strings**, String Catalog auto-extraction. No `Strings.swift` refactor in
this PR.

## Acceptance

- [ ] Full gate green locally (build, tests incl. new suites, `swiftlint lint --strict`)
- [ ] Simulator end-to-end: create goal (with and without date) → edit it (name/target/color/deadline/auto-move) → deposit with a note from all three flows → history shows all deposits with the auto tag after an armed auto-move income → PACE/ETA react to deadline changes → complete a goal → celebration once, listed under Completed
- [ ] Armed auto-move income: goal rises by exactly the suggestion amount; a second income the same month sees a margin reduced by the first deposit
- [ ] In-place upgrade over existing data (no store reset)
- [ ] Test data cleaned (uninstall) · conventional commits ≤72-char subjects, no AI attribution · PR to `dev`, CI green, do NOT merge

## Out of scope

Budgets · quick-deposit custom amount keypad · notifications/reminders ·
cents migration · `ReportsView` concerns (PR B).
