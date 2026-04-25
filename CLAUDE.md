# CLAUDE.md

Front door for Claude Code sessions in this repo. **Read this file first**, then follow the link to the orchestrator protocol if you're starting non-trivial work.

> If you're starting a task: invoke `/orch` (or read `.claude/protocols/orchestrator.md` directly). The orchestrator classifies the request and routes it to the right specialist.

---

## What this is

Savely is a personal finance iOS app (iOS 26+) built with SwiftUI + SwiftData + Firebase. Solo developer. No CI/CD yet — being added now.

---

## Build & test commands

The only shared scheme is `Savely`. Its Test action runs both `SavelyTests` and `SavelyUITests`.

```bash
# Build
xcodebuild build \
  -project Savely.xcodeproj \
  -scheme Savely \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Test (unit + UI together — they share the Savely scheme)
xcodebuild test \
  -project Savely.xcodeproj \
  -scheme Savely \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -resultBundlePath build/TestResults.xcresult

# Lint (after SwiftLint is installed: `brew install swiftlint`)
swiftlint --strict
```

> **Note:** `-scheme SavelyTests` and `-scheme SavelyUITests` will fail — those schemes aren't shared. Always use `-scheme Savely`.

---

## Branch model

| Branch | Role | Who pushes here |
|---|---|---|
| `main` | Production / released code | Releases only — merge from `dev` when shipping |
| `dev` | Integration branch | All feature/fix PRs target this |
| `feature/<slug>` | Short-lived feature branches | Off `dev`, PR back to `dev` |
| `fix/<slug>` | Short-lived bug fixes | Off `dev`, PR back to `dev` |
| `refactor/<slug>` | Structural changes, no behavior change | Off `dev`, PR back to `dev` |
| `chore/<slug>` | Tooling, deps, docs | Off `dev`, PR back to `dev` |
| `ci/<slug>` | CI/CD config changes | Off `dev`, PR back to `dev` |
| `release/<version>` | Release prep (changelog, version bump) | Off `dev`, PR to `main` |

**Commit messages** follow [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `ci:`, `build:`, `test:`. The `commit-msg` hook in `.githooks/` enforces this — run `scripts/install-hooks.sh` once after cloning.

**Never** force-push `main` or `dev`. Never `--no-verify`. Never amend already-pushed commits.

---

## Repository map

```
Savely/
├── SavelyApp.swift            # @main entry point — configures ModelContainer
├── ContentView.swift          # AppState routing (loading / loggedOut / onboarding / main)
├── Models/                    # SwiftData @Model classes + DTOs (Firestore, OpenAI)
├── ViewModels/                # @MainActor view models, organized per tab
├── Views/                     # SwiftUI screens, organized per tab
├── Managers/                  # Singletons that touch the outside world
├── Extensions/                # <Manager>Extension.swift — split implementations
├── Utilities/                 # OpenAIClient, OCR, helpers
├── Resources/                 # Strings.swift, Localizable.xcstrings, Color+Warm.swift, UIConstants.swift
├── Assets.xcassets/           # Images + ColorPalette
├── Savely.entitlements        # Sign in with Apple
├── Config.plist               # OpenAI API key — GITIGNORED
└── GoogleService-Info.plist   # Firebase creds — GITIGNORED

SavelyTests/                   # XCTest unit tests (skeleton only today)
SavelyUITests/                 # XCTest UI tests (skeleton only today)

.claude/
├── protocols/orchestrator.md  # The classify → plan → dispatch flow
├── agents/<role>.md           # 6 specialist subagents
├── knowledge/                 # Narrative docs each agent can pull
└── commands/orch.md           # /orch slash command
```

---

## Load-bearing constraints

These are invariants that future changes must respect. They were discovered during the initial survey; new ones get appended to `.claude/knowledge/gotchas.yaml`.

1. **Signing is automatic, team `ZHLD96SP29`.** Don't switch to manual signing. Don't edit signing build settings.
2. **No `.xcconfig` files exist** — all settings live in `project.pbxproj`. Touching pbxproj is risky; prefer Xcode UI edits and review the diff carefully.
3. **Secrets are gitignored:** `Savely/Config.plist` (OpenAI), `GoogleService-Info.plist` (Firebase), anything matching `.env*`. Never commit these. Never paste their contents.
4. **iOS 26.0 is the minimum deployment target** for the app target. Use modern APIs freely (`@Observable`, `NavigationStack`, Swift Testing, etc.).
5. **Only `Savely.xcscheme` is shared.** Test commands must use `-scheme Savely`, never `-scheme SavelyTests`.
6. **Localization rule:** all user-facing strings go through `Resources/Strings.swift` constants and are registered in `Localizable.xcstrings`. No hardcoded literals in views.
7. **Singletons own external I/O:** `AuthenticationManager.shared`, `UserManager.shared`, `NotificationManager.shared`, `CameraManager.shared`, `OpenAIClient.shared`. Manager bodies are split across `Managers/<Name>.swift` and `Extensions/<Name>Extension.swift`.
8. **`main` and `dev` are protected.** PRs only, CI must be green, no force-push. No auto-merge — the developer merges manually.
9. **Solo workflow:** one PR at a time. For non-trivial calls (architecture, dependencies, new patterns), present options with trade-offs instead of deciding silently.

---

## Secrets & never-commit list

| Path / pattern | What it is |
|---|---|
| `Savely/Config.plist` | OpenAI API key |
| `Savely/GoogleService-Info.plist` | Firebase config |
| `.env`, `.env.*` | Any environment files |
| `*.mobileprovision`, `*.provisionprofile` | Provisioning profiles |
| `*.p12`, `*.cer`, `*.certSigningRequest` | Signing certs |
| `AuthKey_*.p8` | App Store Connect API keys |
| `xcuserdata/`, `*.xcuserstate` | User-local Xcode state |
| `DerivedData/`, `build/` | Build artifacts |
| `*.xcresult` | Test result bundles |
| `fastlane/report.xml`, `fastlane/test_output/`, `fastlane/screenshots/` | Fastlane outputs |

If you see any of these in `git status` about to be staged, **stop and tell the user**.

---

## Specialist routing (quick reference)

The orchestrator (`.claude/protocols/orchestrator.md`) handles full classification. Quick map:

| Change touches… | Specialist |
|---|---|
| `Savely/Views/**` or `Savely/ViewModels/**` | `swiftui-feature-specialist` |
| `Savely/Models/**` (incl. SwiftData migrations) | `data-model-specialist` |
| `Savely/Managers/**`, `Extensions/**`, `Utilities/OpenAIClient.swift` | `services-specialist` |
| `Savely.xcodeproj/**`, `.github/workflows/**`, entitlements, SPM bumps | `build-ci-specialist` |
| `SavelyTests/**`, `SavelyUITests/**` | `qa-tester` |
| Branch / commit / PR hygiene, `.gitignore`, `.github/` templates | `git-workflow-specialist` |

---

## Definition of Done (every PR)

1. `xcodebuild build -scheme Savely` succeeds for `iPhone 16 Pro` simulator.
2. `xcodebuild test -scheme Savely` passes.
3. `swiftlint --strict` exits 0 (soft-skip until SwiftLint is installed).
4. No hardcoded user-facing strings — everything routed through `Strings.swift`.
5. No secrets staged.
6. `CLAUDE.md` updated if a new invariant is introduced.
7. `.claude/knowledge/gotchas.yaml` appended if a workaround was needed.
8. Branch name uses approved prefix; commits follow Conventional Commits.
9. PR opened against `dev` (never `main` directly, except `release/*` branches). CI green. **No auto-merge** — user merges manually.

---

## Pointers

- Orchestrator: `.claude/protocols/orchestrator.md`
- Specialists: `.claude/agents/<role>.md`
- Knowledge base: `.claude/knowledge/`
- Slash command: `/orch` to start a routed task
