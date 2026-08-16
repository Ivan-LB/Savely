# PR A — Honesty & correctness

**Source audit:** `docs/plans/money-surfaces-audit.md` (2026-08-15)
**Branch:** `fix/money-surfaces-honesty` off `dev`, PR back to `dev` (the developer merges manually — never merge yourself)
**Complexity:** Medium. Pure Swift edits + 5 file deletions; one small behavioral removal with a regression risk that task 1 covers.

> **Execute the tasks in order.** Every design decision here is already
> made and approved by the owner — do not re-litigate, do not widen scope.
> Read `CLAUDE.md` and `.claude/knowledge/gotchas.yaml` first; the
> **Repo traps** section at the bottom of this file covers what they don't.

## Context (self-contained)

Savely is a local-first SwiftUI + SwiftData iOS app (iOS 26+, no accounts,
no backend). A five-surface code audit found correctness bugs in the
income/expense/goals flows. This PR fixes everything that **lies or
corrupts data** without adding features. Money model stays `Double` for
now (cents migration is explicitly deferred — do not touch it).

## Tasks

### 1. Remove the hidden favorite-goal coupling (CRITICAL)

Every logged income/expense silently mutates the favorite goal's
`current`: income adds the FULL amount, expense subtracts it, via
NotificationCenter handlers in `GoalsViewModel` (registration ~
`GoalsViewModel.swift:160-183`, mutation `updateFavoriteGoalProgress`
~`:199-219`). This **double-counts** with the payday auto-move shipped in
PR #33 (`AutoMoveSuggestion.apply()` already adds `autoMoveAmount` on
income save), fires only if the Goals tab was ever opened, and lets
history edits distort savings.

- **Delete** `updateFavoriteGoalProgress` and the `.incomeAdded` /
  `.expenseAdded` / `.incomeDeleted` / `.expenseDeleted` observer
  registrations + handler methods in `GoalsViewModel`.
- **Keep the NotificationCenter posts** in
  `ExpensesTrackerViewModel.swift:62,83` and
  `IncomesTrackerViewModel.swift:99` (+ its delete post) — task 2 reuses
  them for list refresh.
- After this task, the ONLY code paths that mutate `GoalModel.current`
  must be the three deposit flows (`GoalDetailView.swift:236-242`,
  `DashboardView.swift:385-390`, `MainNavigationView.swift` quick-deposit
  `saveDeposit`) and `AutoMoveSuggestion.apply()`.
- **Validate:** `grep -rn "updateFavoriteGoalProgress\|incomeAdded\|expenseAdded" Savely/` —
  posts remain, goal-mutating observers gone. Then in the simulator:
  create a goal (favorite), log a $500 income with auto-move armed at
  $100 → goal rises by exactly $100, not $600; log an expense → goal
  unchanged.

### 2. Fix stale lists (movements logged via "+" never appear)

The Money tab's view models hold manual fetch arrays and refetch only
when `modelContext == nil` on appear; the global "+" sheets write through
their **own** VM instances (`MainNavigationView.swift:350, 441`), so new
movements are invisible until app relaunch (`MoneyView.swift:19-22` keeps
both sub-views alive in a ZStack, so `onAppear` never refires).

- In `ExpensesTrackerViewModel` and `IncomesTrackerViewModel`: subscribe
  (in `init` or `setModelContext`) to the already-posted notifications
  (`.expenseAdded`/`.expenseDeleted`, `.incomeAdded`/`.incomeDeleted`)
  and call the existing `fetchExpenses()`/`fetchIncomes()`. Remove
  observers in `deinit`.
- Also make `onAppear` refetch unconditionally
  (`ExpenseTrackerView.swift:178`, `IncomesTrackerView.swift:156`) —
  belt and suspenders.
- Do NOT convert these views to `@Query` in this PR (bigger refactor,
  separate risk).
- **Validate (simulator):** log an expense and an income via the global
  "+" sheet → switch to Money tab → both appear immediately, chart and
  monthly total update, no relaunch.

### 3. Truthful headers

- `ExpenseTrackerView.swift:48` — replace the hardcoded `"April"` with
  the current month (`DateFormatter` with `"MMMM"` format, or
  `Date().formatted(.dateTime.month(.wide))`).
- `ExpenseTrackerView.swift:184-188` — `formattedTotal` currently sums
  ALL expenses ever; filter to the current calendar month
  (`Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)`)
  so the label and the number agree.
- `IncomesTrackerView.swift:34` — same `"April"` fix (its amount is
  already monthly; only the label lies).
- **Validate (simulator):** both headers show the actual current month;
  add an expense dated today → expenses header total equals just that
  amount even if legacy all-time data exists.

### 4. Input honesty (silent failures + es-MX decimals)

- `ExpensesTrackerViewModel.addExpense` (`:48-73`) and
  `IncomesTrackerViewModel.addIncome` (`:85-110`) parse with
  `Double(amount)` and silently no-op on failure. (Note: es_MX uses "."
  as decimal separator, so it is NOT the broken case — comma-decimal
  locales like es_ES/fr_FR/de_DE are.) Create ONE shared helper —
  `Savely/Utilities/AmountParsing.swift` with
  `parseAmount(_ raw: String) -> Double?` that **accepts both separators
  regardless of locale** (the in-app keypad hardcodes "."): try
  `Double(raw)` first, then retry with "," replaced by "." when the
  string contains exactly one comma and no period. Reject empty,
  non-numeric, and `<= 0` results. On `nil`: set the VM's
  `errorMessage`/`showError` instead of silently returning.
- `IncomesTrackerView` has NO `.alert` at all — add one bound to
  `viewModel.showError`, mirroring `ExpenseTrackerView.swift:179-181`.
- Show the negative income trend: drop the `> 0` guard at
  `IncomesTrackerView.swift:50` and color the badge by sign (green up /
  `warmClay` down). A finance app hiding bad news undermines trust.
- **Validate:** unit-test `parseAmount` with explicit expectations:
  `"1234.56"` → 1234.56 · `"1234,56"` → 1234.56 · `"12,34,56"` → nil ·
  `""` → nil · `"abc"` → nil · `"0"` → nil (rejected as non-positive).
  Simulator: entering garbage in the inline add shows an alert instead
  of nothing.

### 5. One-line resurrections

- `ProfileView.swift:126` — the "Weekly PDF report" row's `onTap: {}` is
  the ONLY reachable entry to a fully working PDF pipeline. Wire it to
  `viewModel.generateWeeklyReportPDF()` (the VM's `modelContext` is set
  at `ProfileView.swift:148`; the `.alert` for its error path already
  exists at `:142-144`).
- `DashboardView.swift:99-101` — "See all" next to Recent is inert. Give
  `DashboardView` an `var onSeeAll: () -> Void = {}` and have
  `MainNavigationView` (tab creation at `:20-25`) pass a closure that
  switches the selected tab to Money.
- **Validate (simulator):** with a few movements logged this week,
  tapping "Weekly PDF report" opens the share sheet with a PDF; "See
  all" lands on the Money tab.

### 6. Remove dead affordances and dead files

Controls that render but do nothing — **remove them** (do not implement):

- Search button `ExpenseTrackerView.swift:53` (empty closure).
- Expense row `chevron.right` `ExpenseTrackerView.swift:218` (no action).
- HeroGoalCard chevron-in-a-box `DashboardView.swift:185-190` (plain
  Image implying navigation that does not exist; PR C wires the card's
  pencil to an edit sheet instead — the chevron stays gone).
- "Tip: long-press + to repeat your last action" line
  `MainNavigationView.swift:254-256` (no such gesture exists).

Dead files — **delete** (each needs its pbxproj references removed too;
see Repo traps):

- `Savely/Views/DashboardTab/AddExpenseView.swift` (unreferenced; would
  crash if presented — missing environment object).
- `Savely/Views/DashboardTab/AddIncomeView.swift` (unreferenced legacy,
  off-design-system).
- `Savely/Views/IncomesView.swift` ("Hello, World!" scaffold).
- `Savely/Views/DashboardTab/AddGoalView.swift` (unreferenced legacy).
- `Savely/Views/ProfileTab/WeeklyInsightsView.swift` (orphaned; its PDF
  row is superseded by task 5; also delete the now-unused
  `newTipsCount` placeholder in `ProfileViewModel.swift:39-43`).
- Leave `ReportsView.swift` in place — PR B resurrects it.

- **Validate:** `grep -rn "AddExpenseView\|AddIncomeView(\|IncomesView(\|AddGoalView\|WeeklyInsightsView\|newTipsCount" Savely/` → no hits;
  `plutil -lint Savely.xcodeproj/project.pbxproj` OK; full build green.

## Acceptance (all must pass before opening the PR)

- [ ] `xcodebuild build` + `xcodebuild test -skip-testing:SavelyUITests` green (see Repo traps for destination)
- [ ] `swiftlint lint --strict` → 0 violations
- [ ] Simulator walk-through: the four Validate scenarios above, then **uninstall the app** (test-data cleanup is a house rule)
- [ ] `Localizable.xcstrings` staleness churn from deleted files is committed (Xcode marks keys stale on build — expected, include it)
- [ ] Conventional commits, no AI attribution, PR to `dev`, wait for CI green, do NOT merge

## String policy (decision)

New user-facing strings in this PR (alerts, month header) **match the
surrounding warm-redesign views: literal strings**, relying on the String
Catalog auto-extraction. Do NOT refactor existing literals into
`Strings.swift` here — that cleanup is deliberately out of scope despite
CLAUDE.md's general rule; note it in the PR description.

## Out of scope (do not touch)

Category/source fields (PR B) · goal editing, deposit ledger, pace math,
wizard fixes (PR C) · Double→cents migration (deferred) · any `@Query`
rewrite of the tracker VMs.

## Repo traps (read before writing code)

1. **pbxproj uses explicit file references** — no synchronized groups.
   Deleting a file requires removing its 4 line-entries (PBXBuildFile,
   PBXFileReference, group child, Sources-phase entry). A safe recipe
   used successfully in this repo: filter every pbxproj line containing
   the filename with a small python script, then `plutil -lint` the
   result. Adding files similarly requires generating a 24-hex ID and
   inserting all 4 entries (group IDs: Utilities
   `1D88B7D62CC9FA28009B6538`, Views/Components
   `1DC258402CC61D250002DDE3`, Models `1DC258472CC629120002DDE3`,
   SavelyTests `1DC258172CC07DCF0002DDE3`; app Sources-phase anchor line:
   `/* SplashScreenView.swift in Sources */,`).
2. **commit-msg hook** enforces Conventional Commits with subject
   **≤ 72 chars after the `type: ` prefix** — long subjects are rejected.
3. **SwiftLint ratchet:** `force_unwrapping`/`force_cast`/`force_try`
   are `error`. In tests use `try XCTUnwrap(...)`, never `!`. The
   pre-commit hook lints staged files.
4. **Tests are XCTest** (not Swift Testing). New test files must be
   registered in the SavelyTests target in pbxproj.
5. **Simulator name drifts** — pick from
   `xcrun simctl list devices available` (currently `iPhone 17 Pro`
   locally); never hardcode in CI (CI already picks dynamically).
6. `try? modelContext.save()` is the codebase's (bad) habit — for NEW
   code, use do/catch with the VM's error surface.
