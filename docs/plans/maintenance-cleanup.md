# Maintenance cleanup — plan

**Date drafted:** 2026-04-25
**Status:** DONE — all 3 tasks shipped 2026-04-25 (Task 1 → PR #27, Task 2 → PR #28, Task 3 → PR #29)
**Owner:** orchestrator (`.claude/protocols/orchestrator.md`)

Three queued cleanup tasks identified during the agentic scaffold work
(PR #22). Each is independently dispatchable. Pick one at a time and run
through the orchestrator protocol — do not bundle them into one PR
(different specialists, different blast radii).

This file is the orchestrator's plan output for Step 2 (classify → plan).
When you're ready to execute a task, invoke `/orch <task name>` and the
orchestrator will dispatch the specialists named below.

---

## Task 1 — Resolve duplicate `ContentView.swift`

**Class:** `refactor`
**Branch:** `refactor/dedupe-contentview`
**Specialist:** `swiftui-feature-specialist`
**Estimated size:** small (delete one file, possibly fix one import)

### Background

Two files exist with the same name:
- `Savely/ContentView.swift`
- `Savely/Views/ContentView.swift`

Only one is referenced by the Xcode target — the other is stale, left over
from a refactor that moved view files into `Views/` but didn't delete the
old root-level copy. SwiftUI templates put `ContentView.swift` next to
`SavelyApp.swift` by default; when the project later adopted the
`Views/<Tab>/` structure, the duplicate slipped in.

### Plan

1. **Investigate which file is real.**
   - `grep -n "ContentView" Savely.xcodeproj/project.pbxproj` to see which
     path the target references.
   - `diff Savely/ContentView.swift Savely/Views/ContentView.swift` to see
     whether they are identical or have diverged.
   - Search the codebase for `ContentView()` usages and confirm what
     imports them (likely `SavelyApp.swift` and possibly previews).

2. **Decide which to keep.**
   - If both are byte-identical: keep the one referenced by the target,
     delete the other.
   - If they have diverged: read both, identify the canonical one (the
     one the target references is the "real" one), confirm with the user
     before deleting the other if there's any doubt.

3. **Delete the stale file** via Xcode (so the project file updates) or
   via `git rm` followed by removing the file reference from
   `project.pbxproj` if it's still listed.

4. **Build + run** to confirm nothing breaks.

### Risks / unknowns

- The "stale" file might actually be referenced by a test target or
  preview that the grep doesn't surface. Verify all references before
  deleting.
- `project.pbxproj` may have ghost references to the deleted file — these
  are easy to miss until Xcode refuses to build.

### Open questions

None — this is a mechanical cleanup once the canonical file is identified.

### Definition of Done

- One `ContentView.swift` exists under the canonical path.
- `xcodebuild build -scheme Savely` succeeds.
- App launches and shows the same first screen as before.
- No references to the deleted file remain in `project.pbxproj`.

---

## Task 2 — Decide on the `*.xcscheme` gitignore rule

**Class:** `chore` (with possible `build-config` follow-up)
**Branch:** `chore/xcscheme-gitignore-decision`
**Specialist:** `git-workflow-specialist` (gitignore edit) → optional
follow-up by `build-ci-specialist` (sharing additional schemes)
**Estimated size:** small (one-line gitignore edit + decision)

### Background

`.gitignore` line 18 contains `*.xcscheme`, which globally ignores every
`.xcscheme` file. The current `Savely.xcscheme` is tracked because it was
committed before the rule existed — git keeps tracked files even after a
matching ignore rule appears.

The hidden cost: any **new** shared scheme (e.g., a future
`SavelyTests.xcscheme` made shared via Xcode) will be silently dropped from
commits. This is a footgun.

### Decision needed (open question)

**Three options, with trade-offs:**

| Option | What it does | Pro | Con |
|---|---|---|---|
| A. Keep `*.xcscheme` | Status quo | No change needed | New shared schemes blocked silently |
| B. Narrow to user-specific schemes | Drop the global rule, rely on `xcuserdata/` to gitignore user-only state | Allows future shared schemes; cleaner intent | One extra check that no user-specific scheme escapes |
| C. Drop the rule entirely | Treat all schemes as commit-worthy | Most flexible; teaches you to share schemes by default | Slight risk of accidentally committing a personal scheme |

**Recommendation: B.** User-specific schemes already live under
`xcuserdata/` (which we gitignore separately), so the global `*.xcscheme`
rule is overly broad. Dropping the rule from `.gitignore` allows future
shared schemes (e.g., a separate `SavelyTests.xcscheme`) to be committed
naturally.

### Plan (if option B chosen)

1. Edit `.gitignore`: delete the `*.xcscheme` line.
2. Verify `Savely.xcscheme` remains tracked: `git ls-files | grep xcscheme`.
3. Verify no untracked personal schemes are about to be committed:
   `git status` should not list anything new under `xcshareddata/xcschemes/`.
4. Commit: `chore: drop overly broad *.xcscheme gitignore rule`.

### Optional follow-up (if you also want to share test schemes now)

Hand off to `build-ci-specialist`:
1. In Xcode → Manage Schemes → tick "Shared" for `SavelyTests` and
   `SavelyUITests`.
2. Two new files appear under `xcshareddata/xcschemes/` — commit them.
3. `xcodebuild test -scheme SavelyTests` now works independently of the
   `Savely` scheme.

This unlocks the ability to run unit tests separately from UI tests in
local dev (faster) without breaking the existing CI workflow that uses
`-scheme Savely`.

### Risks / unknowns

- If you have a personal `.xcscheme` in `xcshareddata/` that you don't
  want to commit (rare), you'll need to gitignore it specifically by name.

### Definition of Done

- `.gitignore` decision applied (whichever option you pick).
- `git status` clean after pulling — no surprise additions.
- If option B + follow-up: `xcodebuild test -scheme SavelyTests` works
  on a fresh checkout.

---

## Task 3 — Clean up force-unwraps and tighten the lint ratchet

**Class:** `refactor`
**Branch:** `refactor/cleanup-force-unwraps`
**Specialists:** `services-specialist` → `data-model-specialist` →
`swiftui-feature-specialist` → `build-ci-specialist` (sequential)
**Estimated size:** medium (10 sites across 3 layers + 1-line lint config flip)

### Background

The first CI run on PR #22 surfaced ~10 `force_unwrapping` violations.
They're currently warnings (not errors) so CI passes, but every new force
unwrap that gets written from now on adds to the warning pile without
failing CI. The "ratchet" pattern says: clean up the existing violations,
then flip the rule severity to `error` so any new violation fails CI.

### The ten sites (from CI output)

| File | Line | Layer | Specialist |
|---|---|---|---|
| `Savely/ViewModels/ProfileTab/ProfileViewModel.swift` | 125, 142 | viewmodel | swiftui-feature |
| `Savely/ViewModels/Dashboard/ReportsViewModel.swift` | 77, 92 | viewmodel | swiftui-feature |
| `Savely/Views/MainNavigationView.swift` | 659 | view | swiftui-feature |
| `Savely/Models/IncomeModel.swift` | 32 | model | data-model |
| `Savely/Models/ExpenseModel.swift` | 32 | model | data-model |
| `Savely/Managers/CameraManager.swift` | 93 | service | services |
| `Savely/Utilities/OpenAIClient.swift` | 26 | service | services |
| `Savely/Utilities/SignInWithAppleHelper.swift` | 236 | service | services |

### Single PR or three?

**Recommendation: one PR**, with sequential dispatch in this order:
`services-specialist` → `data-model-specialist` → `swiftui-feature-specialist`
→ `build-ci-specialist` (for the lint flip).

Rationale: the *purpose* of the change is "enable the ratchet for force
unwraps." Splitting by layer would delay the ratchet flip until all three
PRs merge, creating a window where new violations could land. One PR
keeps the change atomic.

The orchestrator's "no two specialists touching the same file" rule still
holds — these specialists touch disjoint files.

### Plan

For each file, the relevant specialist applies one of these patterns
based on the surrounding code:

1. **Replace `value!` with safe unwrapping:**
   - `guard let unwrapped = value else { return /* sensible default */ }`
   - `if let unwrapped = value { ... }` for optional-chain branches
   - `value ?? defaultValue` for fallback-with-default
2. **Document the choice** in a one-line comment if the unwrap was
   intentional and the safe form is non-obvious. (Don't over-comment.)
3. **Never** silence with `// swiftlint:disable:next force_unwrapping` —
   the whole point is to remove the unwraps, not paper over them.

### After the ten sites are clean

`build-ci-specialist` flips one line in `.swiftlint.yml`:

```diff
 force_unwrapping:
-  severity: warning                  # warning today → bump to error after cleanup PR
+  severity: error
```

That's the ratchet. Any new force unwrap from this commit forward fails CI.

### Risks / unknowns

- Some force unwraps may be on values that are *guaranteed* non-nil at
  runtime by some invariant (e.g., a URL literal that's known-valid).
  Those are still worth replacing with `guard let` + `fatalError("invariant
  violated")` so the failure mode is explicit instead of "unwrap of nil."
- Two of the model file unwraps are on line 32 in both `IncomeModel.swift`
  and `ExpenseModel.swift` — likely the same pattern (probably an `init?`
  decode path). Worth checking if a shared helper would clean both.

### Open questions

- Want to also bump severity on `force_cast` and `force_try` to `error`
  in the same PR? They're already `error`, so no — already strict. ✅
- After this PR, want to enable `implicit_optional_initialization` (we
  disabled it for the scaffold)? It's a style preference, not a bug
  catcher — recommend leave disabled.

### Definition of Done

- Zero `force_unwrapping` warnings on `swiftlint lint`.
- `.swiftlint.yml` has `force_unwrapping: severity: error`.
- CI passes.
- Smoke test: launch the app, hit each touched code path manually
  (especially camera, sign-in-with-apple, reports — the riskiest ones).

---

## Recommended sequencing

Three small to medium PRs. Pick whichever feels right; they don't
strictly depend on each other.

| Order | Task | Why this order |
|---|---|---|
| 1 | Task 1 — ContentView dedupe | Smallest, fastest, clears mental clutter |
| 2 | Task 2 — xcscheme rule | One-line decision; unblocks future scheme sharing |
| 3 | Task 3 — Force-unwrap cleanup | Largest; do when you have a focused block of time |

Alternatively: **batch tasks 1 and 2 into one "small cleanup" PR** since
they're both tiny and uncontroversial, then do Task 3 separately. This
violates the "single-purpose PR" rule strictly, but it's a defensible
exception when both changes are sub-10-line cleanups. Decide when ready.

---

## How to dispatch

When ready to start any task, in a fresh Claude session:

```
/orch trabaja en la Task N de docs/plans/maintenance-cleanup.md
```

The orchestrator will pull this file, re-run classification (verifying
the plan is still accurate against current code state), and dispatch the
specialists named above.

If the codebase has drifted since this plan was written, the orchestrator
will flag the drift and ask for re-confirmation before dispatching.
