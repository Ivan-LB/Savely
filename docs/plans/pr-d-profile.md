# PR D — Profile: real settings, real identity

**Source:** live diagnosis 2026-08-15 (see *Evidence*), the inert-affordance
thread from `docs/plans/money-surfaces-audit.md`, and the Impeccable
product/design pass that produced `PRODUCT.md` + `DESIGN.md` (2026-08-15).
**Depends on:** PR A merged (Weekly PDF row already wired). Independent of
PR B and PR C.
**Followed by:** `pr-d2-adaptive-palette.md` (dark mode) and
`pr-d3-accessibility.md` (VoiceOver + Dynamic Type across the whole app).
The Dark Mode row ships **hidden** in this PR and is re-enabled by D2.
**Branch:** `feat/profile-real-settings` off `dev`, PR back to `dev`
(developer merges manually — never merge yourself).
**Complexity:** Medium.

> Read `CLAUDE.md`, `PRODUCT.md`, `DESIGN.md`, `.claude/knowledge/gotchas.yaml`,
> and the **Repo traps** section of `docs/plans/pr-a-honesty-correctness.md`
> (pbxproj procedure, commit-msg hook ≤72 chars, XCTest, SwiftLint ratchet).
> **Do not change the current look.** DESIGN.md is the record of what the
> app looks like today; this PR adds content and makes controls real, it
> does not restyle.

## Context

The Profile tab reads as an afterthought: a name nobody set, one real
number, six padlocks, and three settings rows of which one is dead, one is
one-way, and one changes nothing. Savely has **no accounts by design** —
onboarding says so out loud. The fix is not registration; it is to stop
treating the absence of an account as an absence of content. Everything
this screen needs is already in SwiftData (`PRODUCT.md` principle 2:
*local-first is content, not absence*).

## Evidence (verified in the simulator, 2026-08-15)

| Symptom | Root cause | File |
|---|---|---|
| Bell button does nothing | `Button(action: {})` | `ProfileView.swift:27` |
| Notifications toggle is one-way | `handleExpenseReminderToggle()` only *cancels*; on never re-schedules. Console: `cancelled` on off, nothing on on | `ProfileViewModel.swift:~184` |
| Setting forgets itself | `@Published var expenseReminders = true` is not persisted; resets to on every launch while the reminder stays cancelled | `ProfileViewModel.swift:19` |
| `goalAlerts` can never be turned off | Onboarding schedules `goalAlert`; no UI binds `goalAlerts` | `OnboardingView.swift:87` |
| Reminder times cannot be changed | `@State` in onboarding, used once, stored nowhere | `OnboardingView.swift:12-13` |
| Onboarding cannot decline reminders | The step only picks times; finishing always schedules both | `OnboardingView.swift:74-95` |
| Dark Mode changes nothing | `.preferredColorScheme` **is** applied (status bar flips) but every surface paints a hardcoded light constant | `Color+Warm.swift` → **PR D2** |
| Dark Mode switch looks stuck | `@AppStorage` inside an `ObservableObject` never fires `objectWillChange`; persists, does not re-render | `ProfileViewModel.swift:18` |
| Toggles have no VoiceOver name | `Toggle("", isOn:).labelsHidden()` — announces "Switch, on" with no label | `ProfileView.swift:233` → set here, generalized in **D3** |
| Nested `NavigationStack` | ProfileView wraps itself although `MainNavigationView` already does | `ProfileView.swift:21` |

**Needs a human hand first:** under the automation harness the toggles
flip on a *drag* but not on a synthetic *tap* (a `Button` in the same
container taps fine). Tap both switches with your finger before building.
If they respond, drop this; if not, the nested `NavigationStack` is the
first suspect.

## Decisions (already taken)

- Dark mode **is** in scope — split: D hides the row behind
  `FeatureFlags.darkModeEnabled = false`; **D2** makes the palette adaptive
  and flips the flag. Never ship a switch that does nothing.
- VoiceOver + Dynamic Type must cover the **whole app** → **D3**. This PR
  sets the bar on the surfaces it touches (every new control labeled,
  every new text scalable) but does not audit other screens.
- Bell: **remove** (consistent with PR A's treatment of dead affordances).
- Identity: "no account, but a real profile" — commit 3 in full.

## Commits

### 1. Make notification settings real and two-way

- Persist in `ProfileViewModel`, backed by explicit `UserDefaults` reads
  plus `@Published` (not `@AppStorage`, see the re-render trap):
  `expenseRemindersEnabled`, `goalAlertsEnabled`, `expenseReminderTime`,
  `goalAlertTime`.
- `handleExpenseReminderToggle()` becomes symmetric: off →
  `cancelNotification`, on → `scheduleNotification` at the stored time.
  Same for goal alerts. Changing a time re-schedules under the same id.
- Settings section shows both reminders with their times — the first time
  `goalAlert` can be turned off at all. Use the system `Toggle` and a
  `DatePicker(.hourAndMinute)` (platform controls, `DESIGN.md` Navigation
  / ios.md), styled inside the existing `ProfileSection` rows.
- Denied-permission state: if `UNUserNotificationCenter` authorization is
  `.denied`, render the rows disabled with a one-line hint and a
  "Open Settings" text action (`UIApplication.openSettingsURLString`)
  instead of a switch that silently no-ops.
- **Onboarding:** add a per-reminder opt-out (Toggle, default on) on the
  notifications step and write times + enabled through the same
  persistence, so onboarding and Profile agree.
- **Accessibility on what you touch:** every `Toggle` gets a real label
  (`Toggle("Expense reminder", isOn:)`, hide the *visual* label if the row
  already shows it — never `Toggle("")`); the time picker gets
  `.accessibilityLabel`; new text uses `Font.warm(...)` from D3's helper if
  it has landed, otherwise `.system(size:, relativeTo:)`-equivalent via
  `@ScaledMetric`.
- **Validate:** unit-test the schedule/cancel decision (pure function over
  `enabled × time`, no `UNUserNotificationCenter`). Simulator: off →
  `cancelled` in console; on → `Scheduled`; relaunch → state persists;
  VoiceOver reads "Expense reminder, switch, on".

### 2. Remove the dead bell

`ProfileView.swift:27` — delete the button and its `HStack`; the top-right
slot is simply empty (the greeting on Dashboard has no bell either).

### 3. Give the screen real content

Everything below is derived from existing SwiftData. No new entities.
Composition follows `DESIGN.md`: one hero object, then rows; hairline
depth; serif names, sans explains; `-soft` tile + glyph as row lead.

- **Identity card:** name (the one thing the user set) + "Saving since
  <month of first logged movement>" in `ink-muted`… **use `ink-soft`** for
  this line (it must be readable — see the AA note in D2). The whole card
  is the edit affordance; drop the chevron-in-a-box.
- **Stats strip** replacing the lone lifetime-income card: lifetime income
  stays as the serif headline inside the green card; underneath, a
  three-up row of `surface` cells — *saved across goals · movements
  logged · active goals*. No streak counter (PRODUCT.md: no streak
  pressure).
- **Achievements:** six padlocks on a fresh install is the "simplón".
  Show the **next** achievement as a single row: its `-soft` tile + glyph,
  name, and a 4pt capsule progress bar ("3 of 5 movements"). Unlocked
  ones stay as the tile row above it. `AchievementEngine` already computes
  the states.
- **Data & privacy section:** "Your data never leaves this iPhone" as the
  section's one-line intro (this is the product's premise stated as a
  feature), Weekly PDF export (wired in PR A), and a destructive
  "Delete all data" with `confirmationDialog` + a second explicit confirm.
- Remove ProfileView's own `NavigationStack`.
- **Validate:** fresh-install and populated screenshots side by side; the
  empty state must look deliberate, not broken. That is the acceptance
  bar for this commit.

### 4. Hide Dark Mode until D2

Add `FeatureFlags.darkModeEnabled = false` and gate the row. Leave the
`@AppStorage("darkModeEnabled")` plumbing and `.preferredColorScheme` in
`SavelyApp.swift` in place — D2 turns them on.

## Out of scope

Categories/sources (PR B) · goal editing, deposit ledger, pace math
(PR C) · the adaptive palette itself (D2) · app-wide VoiceOver / Dynamic
Type / touch-target pass (D3) · `Double`→cents · accounts or sync (against
the premise) · tips (behind `FeatureFlags.tipsEnabled`) · restyling
anything documented in `DESIGN.md`.

## Acceptance

- [ ] `xcodebuild build` + `xcodebuild test -skip-testing:SavelyUITests` green
- [ ] `swiftlint lint --strict` → 0 violations
- [ ] Notification toggles survive a relaunch and are two-way (console, both directions)
- [ ] Denied-permission state renders the hint, not a dead switch
- [ ] No empty closures left in `ProfileView.swift`; no `Toggle("")`
- [ ] Fresh-install Profile screenshot looks intentional
- [ ] VoiceOver walk of the Profile tab: every control has a name and a state
- [ ] Simulator walk-through, then **uninstall the app** (house rule)
- [ ] Conventional commits, no AI attribution, PR to `dev`, CI green, do NOT merge
