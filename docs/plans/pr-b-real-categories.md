# PR B — Real categories & sources

**Source audit:** `docs/plans/money-surfaces-audit.md` (2026-08-15)
**Depends on:** PR A merged (stale-list fixes and honest headers land first).
**Branch:** `feat/real-categories` off `dev`, PR back to `dev` (developer merges manually)
**Complexity:** Medium. One additive model migration + persistence wiring + display fallback + ReportsView resurrection.

> Decisions below are made — do not re-litigate. Read `CLAUDE.md`,
> `.claude/knowledge/gotchas.yaml`, and the **Repo traps** section of
> `docs/plans/pr-a-honesty-correctness.md` (same traps apply, especially
> the pbxproj procedure for any new file).

## Context (self-contained)

Categorization is currently fake at every layer: `ExpenseModel` and
`IncomeModel` have no category/source field; the quick-add sheets collect
chips and discard them; the Money tab re-infers "categories" by matching
English keywords against the description string; ReportsView's charts
group by raw free text. This PR makes categorization real with the
smallest possible model change.

## Design decisions (fixed)

- **Plain optional strings, not entities:** `category: String?` on
  `ExpenseModel`, `source: String?` on `IncomeModel`. Additive with `nil`
  default → SwiftData lightweight migration is automatic. No Category
  entity/table — YAGNI until budgets exist.
- **Canonical values = the chips that already exist in the UI:**
  expenses `Coffee / Food / Transit / Shopping / Other`
  (`MainNavigationView.swift:335-341`), incomes
  `Paycheck / Freelance / Gift / Other` (`sources` array,
  `MainNavigationView.swift:443`).
  Store the chip string as-is.
- **Legacy rows:** display falls back to the existing keyword inference
  when `category == nil`. Never backfill-write inferred values into the
  store (inference is a guess; the store holds only user-chosen truth).
- **Description and category are independent** — picking "Shopping" and
  typing "Zara" stores both; the chip is no longer a description
  fallback.

> Line numbers below were verified against `dev` **before PR A merges**;
> PR A shifts some of these files by a few lines. Treat citations as
> symbol anchors (search for the identifier), not absolute offsets.

## Tasks

### 1. Model fields + migration

- `ExpenseModel.swift`: add `var category: String?` (+ init param,
  default `nil`). `IncomeModel.swift`: add `var source: String?` (same).
- **Validate:** app upgrades in-place in the simulator over a store that
  already has data (install current `dev` build, add rows, then install
  this branch's build — data survives, fields read as nil).

### 2. Persist the chips at the write paths

- `WarmQuickExpenseView` (`MainNavigationView.swift:~343-426`): pass
  `selectedCat` through to the insert. Today `:423` folds the chip into
  the description only when the description is empty — replace that:
  description = typed text (or chip label if empty, unchanged), AND
  `category = selectedCat` always.
- `WarmQuickIncomeView` (`:~430-585`): same for `selectedSource` at
  `:576` — keep the description fallback behavior, and additionally
  store `source = selectedSource` always.
- `ExpensesTrackerViewModel.addExpense` / `IncomesTrackerViewModel.addIncome`:
  add optional `category:`/`source:` parameters (default `nil`) so the
  inline tab forms keep compiling; thread them into the model insert.
- Receipt scanner (`CameraViewModel.confirmTotal` ~`:163-169`):
  **decision — leave `category` as `nil`** for scanned expenses (display
  falls back to inference); scanner improvements are out of scope.
- **Validate:** add expense "Zara" + chip "Shopping" via quick-add →
  Money tab row shows Shopping icon/label (not keyword guess); same for
  income source.

### 3. Display uses stored truth, inference as fallback

- `ExpenseTrackerView.swift:230-257` (`categoryLabel` + icon/color
  mapping): if the row's `expense.category` is non-nil use it directly;
  else run the existing keyword inference (rename it
  `legacyInferredCategory` so intent is explicit).
- Fixed icon/tile mapping for the five canonical chips (the existing
  switches have no branches for "Food"/"Shopping"/"Other" — use these,
  matching the Warm Meadow pairings already used for badges):

  | Chip | SF Symbol | Tile bg / icon color |
  |---|---|---|
  | Coffee | `cup.and.saucer.fill` | warmAmberSoft / warmAmber |
  | Food | `fork.knife` | warmGreenSoft / warmGreen |
  | Transit | `car.fill` | warmSkySoft / warmSky |
  | Shopping | `bag.fill` | warmClaySoft / warmClay |
  | Other | `creditcard` | warmBg / warmInkMuted |
- Income history rows (`IncomesTrackerView.swift` list ~`:136-200`): show
  a small source tag/icon when `source != nil` (match Warm Meadow: soft
  tile + label, look at how expense rows do it).
- **Validate (simulator):** legacy rows (nil) still show inferred
  labels; new rows show the chosen chip even when the description
  contains a misleading keyword (e.g. description "coffee mug gift",
  category "Shopping" → shows Shopping).

### 4. Resurrect ReportsView (charts become meaningful)

`ReportsView.swift` works but is orphaned, and its `SectorMark` pie
groups by description free-text. With real categories:

- Group the expense distribution chart by `category ?? legacy inference`
  instead of raw description (`ReportsView.swift:76-83`).
- Fix the init anti-pattern at `ReportsView.swift:17` (reading
  `Environment(\.modelContext).wrappedValue` inside `init`) — rely on
  the existing `onAppear` `setModelContext` (`:100`) only.
- **Entry point (decision):** a "Reports" `SettingsNavRow` in
  ProfileView's Settings section (below "Weekly PDF report"), pushing
  `ReportsView` via `navigationDestination` — ProfileView already has
  the NavigationStack + the pattern (see `showingAchievements`).
- **Validate (simulator):** Profile → Reports opens; charts render from
  real data; category pie shows chip-named slices.

### 5. Tests

XCTest, registered in the SavelyTests target (pbxproj procedure in PR A's
Repo traps). Suggested file: `SavelyTests/CategoryPersistenceTests.swift`
using an in-memory `ModelContainer`
(`ModelConfiguration(isStoredInMemoryOnly: true)`):

- Expense round-trips `category`; income round-trips `source`; both nil
  by default.
- The display fallback helper: stored category wins over a description
  full of contradicting keywords; nil falls back to inference; unknown
  text infers the generic label.

## String policy (decision)

New user-facing strings (source tags, "Reports" row, chart labels) match
the surrounding warm views: **literal strings**, String Catalog
auto-extraction. No `Strings.swift` refactor in this PR.

## Acceptance

- [ ] Build + tests green, `swiftlint lint --strict` clean (local gate before push)
- [ ] In-place upgrade over existing data verified in the simulator (no store reset)
- [ ] Quick-add chips persist; legacy rows unchanged visually
- [ ] Reports reachable from Profile with category-grouped charts
- [ ] Simulator test data cleaned (uninstall) · conventional commits, subject ≤72 chars, no AI attribution · PR to `dev`, CI green, do NOT merge

## Out of scope

Budgets, category management/custom categories, scanner category
detection, cents migration, goal work (PR C).
