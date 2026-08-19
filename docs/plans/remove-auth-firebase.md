# Remove auth + Firebase, go local-first — plan

**Date drafted:** 2026-08-14
**Status:** in progress (this branch)
**Branch:** `refactor/remove-auth-firebase`
**Decision (Iván, 2026-08-14):** the repo is public and `GoogleService-Info.plist`
lives in git history (committed in `80cf033`, untracked since PR #26 — but
history keeps it). Rather than scrub history, kill the dependency at the
root: **no more login, all data lives on-device** (CloudKit sync is a
follow-up phase, not this PR). Also: drop every dependency we don't use,
and prefer native replacements over libraries wherever possible.

## Why this is small

Firebase touches exactly 7 files, and all domain data (Expense, Income,
Goal, Tip) is **already local SwiftData** — Firestore only ever stored a
5-field user-profile doc (`userId`, `email`, `displayName`,
`isOnboardingComplete`, `dateCreated`). Auth gated nothing except that doc.

## Phase 1 — delete the auth layer

Files deleted outright (no other file imports them, verified by grep):

- `Savely/Views/Auth/LoginView.swift`, `SignUpView.swift`
- `Savely/ViewModels/Auth/LoginViewModel.swift`, `SignUpViewModel.swift`
- `Savely/Managers/AuthenticationManager.swift` + `Extensions/AuthenticationManagerExtension.swift`
- `Savely/Managers/UserManager.swift` + `Extensions/UserManagerExtension.swift`
- `Savely/Models/AuthDataResultModel.swift`, `Models/DBUserModel.swift`

## Phase 2 — rewire the app flow (5 files)

- **`AppViewModel.swift`**: drop the FirebaseAuth state listener; `AppState`
  loses `.loggedOut` → `loading → onboarding → main`. Onboarding flag and
  display name live in UserDefaults/`@AppStorage` (the fallback path that
  already existed becomes the only path). Keep `NWPathMonitor` — the
  OpenAI-backed features still want the network-warning sheet.
- **`ContentView.swift`**: drop the `.loggedOut` case + `LoginView` ref.
- **`SavelyApp.swift`**: drop `FirebaseCore` import + `FirebaseApp.configure()`.
- **`OnboardingView.swift`**: `UserManager.updateOnboardingStatus` → local save.
- **`ProfileView/ProfileViewModel`**: display name reads/writes local
  storage; email + sign-out row die with auth. Profile redesign is
  deliberately deferred ("tendremos que pensar en el perfil") — this PR
  only keeps it compiling with local data, nothing more.

## Phase 3 — dependencies: 3 direct SPM packages → 0

| Package | Usage found | Action |
|---|---|---|
| `firebase-ios-sdk` (FirebaseAuth, FirebaseFirestore) | the 7 auth files | **Remove.** Entire transitive tree dies with it (grpc, abseil, leveldb, nanopb, googleappmeasurement, …) |
| `IQKeyboardManager` | 2 lines in `SavelyApp.swift` (`resignOnTouchOutside`) | **Remove, native.** iOS 26 SwiftUI handles keyboard avoidance; add `.scrollDismissesKeyboard(.interactively)` on scrollable forms if any feels sticky after removal |
| `MarkdownUI` | 1 call site (`TipHistoryView`: `Markdown(tip.content)`) | **Remove, native.** `Text(AttributedString(markdown:))` with inline-preserving options — tips are short OpenAI strings (bold/italic), block markdown not needed |

`project.pbxproj` surgery (careful, per repo rule #2): remove the 3
`XCRemoteSwiftPackageReference` blocks, 4 product dependencies
(FirebaseAuth, FirebaseFirestore, IQKeyboardManagerSwift, MarkdownUI),
their Frameworks-phase build files, and the 4 `GoogleService-Info.plist`
references (build file, file ref, group child, Resources phase — it's a
required build input today, which is why CI generates a placeholder).

## Phase 4 — CI cleanup

`.github/workflows/ci.yml`: drop the `GoogleService-Info.plist` placeholder
generation (keep the `Config.plist` one — OpenAI stays). The
`ci-placeholder-secrets` gotcha in `.claude/knowledge/gotchas.yaml` gets
updated to match.

## Verification

1. `xcodebuild build -scheme Savely -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
2. `xcodebuild test -scheme Savely` (same destination)
3. `swiftlint lint --strict`
4. Run in simulator: fresh install goes splash → onboarding → main with no
   login anywhere; profile shows/edits a local display name; tips history
   renders; keyboard behaves on the add-expense form.

## Explicitly out of scope (follow-ups)

- **CloudKit sync** for the SwiftData container — needs a model-constraint
  audit first (all attributes optional/defaulted, no unique constraints,
  optional relationships) + entitlements. Own branch/PR.
- **Profile redesign** — what a profile even means with no account.
- **Firebase console teardown** — Iván deletes/rotates the Firebase project
  so the plist in public git history points at a dead project. Manual step,
  console-side; do it any time after this PR merges.
- **New app icon** — being explored in parallel (iOS 26 Liquid Glass /
  Icon Composer direction).
