# Money surfaces audit — expenses, incomes, Money tab, goals, dashboard/reports

**Date:** 2026-08-15 (post PR #33 merge)
**Method:** 5 parallel code readers, one per surface, findings verified in
code with file:line citations. Full detail below; roadmap at the end.

## The three findings that matter most

### 1. CRITICAL — hidden coupling corrupts goal balances (and double-counts with auto-move)

Every income/expense logged anywhere silently mutates the **favorite
goal's** `current` via NotificationCenter: income adds the FULL amount,
expense subtracts the full amount (`GoalsViewModel.updateFavoriteGoalProgress`,
GoalsViewModel.swift:160-219; posted from IncomesTrackerViewModel.swift:99
and ExpensesTrackerViewModel.swift:62).

- **Double-count with auto-move (shipped in #33):** logging a $500 income
  with an armed $100 auto-move adds $500 (handler) + $100 (apply()) = $600
  to the goal.
- Only fires after the Goals tab has been opened once (observers register
  in its onAppear) — same action, different outcome depending on
  navigation history.
- Deleting an old expense "restores" the favorite goal's progress with
  clamping, so history edits distort savings arbitrarily.

**Fix:** delete the coupling. Deposits (manual + auto-move) become the
only thing that moves `goal.current`.

### 2. Fake categorization, everywhere

`ExpenseModel`/`IncomeModel` have **no category/source field**. The
quick-add chips (Coffee/Food/… and Paycheck/Freelance/…) are collected
and discarded (MainNavigationView.swift:423, 576); list "categories" are
keyword-guesses over the description string (ExpenseTrackerView.swift:230-257,
English-only); ReportsView's charts group by raw free text, making the
"distribution" pie meaningless.

### 3. Lists lie / go stale

- Quick-add writes through its own VM instance; the Money tab's VMs hold
  manual fetch arrays and never refetch (`onAppear` guard, MoneyView keeps
  views alive in a ZStack) — movements logged via "+" don't appear until
  app relaunch.
- Both tab headers hardcode "**April**" (it's August); the expenses header
  total is the ALL-TIME sum labeled as monthly.
- Goal detail's "Per week" divides by a hardcoded 24 and its ETA is
  circular (always ~24 weeks); dashboard PACE always says "On track".

## Dead/mock inventory (compressed)

- Empty-closure buttons: expense search (ExpenseTrackerView.swift:53),
  both goal edit pencils (GoalDetailView.swift:82, DashboardView.swift:261),
  wizard Skip (AddGoalFlow.swift:588), **Weekly PDF report row
  (ProfileView.swift:126) — the entire working PDF pipeline is dead code
  behind this one empty closure**.
- Inert affordances: Dashboard "See all" (DashboardView.swift:99-101),
  expense row chevrons, HeroGoalCard chevron, "long-press + to repeat"
  tip with no gesture.
- Collected-but-discarded input: expense category chip, income source
  chip, deposit NOTE fields (two places), wizard emoji, wizard Reminders
  toggle, "No date" preset (still saves an 18-month deadline).
- Dead files: AddExpenseView.swift, AddIncomeView.swift, IncomesView.swift,
  AddGoalView.swift; orphaned-but-working: ReportsView, WeeklyInsightsView.
- Silent failures: `Double(amount)` no-ops on invalid input (comma
  decimals! es-MX cannot type cents); income view has no error alert at
  all; `try? save()` swallows errors.
- Missing CRUD: **no edit for anything** (expenses, incomes, goals);
  income history capped at 20 with no "see all"; no date picker
  (backfilling impossible); negative income trend hidden (>0 guard).
- Model debt: money as Double (not integer cents); no deposit entity
  (goal funding history unrepresentable); no goal createdAt (real pace
  incomputable); GoalColor has 13 cases, wizard exposes 6.

## Recommended roadmap (3 PRs, in this order)

> Executable implementation plans (self-contained, written for a fresh
> session with no shared context):
> [PR A](pr-a-honesty-correctness.md) ·
> [PR B](pr-b-real-categories.md) ·
> [PR C](pr-c-goals-complete.md)

### PR A — Honesty & correctness (fix what lies or corrupts)
1. **Remove the favorite-goal coupling** (finding #1) — deposits become
   the only mutation path. Regression test for the double-count.
2. Fix stale lists: VMs observe .expenseAdded/.incomeAdded (or move to
   @Query). 3. Truthful headers: real month + monthly totals.
4. Input honesty: locale-aware amount parsing (es-MX comma), error
   alerts on parse/save failures everywhere, income view gets its alert.
5. One-line resurrections: PDF row wired (ProfileView.swift:126),
   "See all" → Money tab. 6. Remove dead affordances + delete 4 dead files.

### PR B — Real categories (small model change, big unlock)
`category: String?` on ExpenseModel + `source: String?` on IncomeModel
(additive migration). Persist the chips that already exist; list falls
back to keyword inference for legacy rows. Unblocks per-source income
breakdown, meaningful category charts, future budgets. ReportsView gets
resurrected with a Profile entry point once its charts mean something
(decision in the PR B plan).

### PR C — Goals, completed (the biggest CRUD hole + deposit ledger)
1. **Goal edit sheet** wired to both dead pencils (name/target/deadline/
   color/auto-move — every field already exists on the model).
2. **Deposit entity** (goalId, amount, date, note, source: manual|auto):
   fixes the auto-move month-margin overestimation, persists the
   discarded notes, gives GoalDetailView a real history, enables undo,
   surfaces deposits in Recent.
3. Real pace/ETA from `deadline` (reuse AutoMoveSuggestion's weeks math);
   completion state + celebration; success-screen "Add a deposit" wired;
   "No date" actually saves nil; star toggles unfavorite.

### Known debt, deliberately after A-C
Double → integer-cents migration (float money). Real, but touches every
amount path — do it standalone once the surfaces above stop moving.
