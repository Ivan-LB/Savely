# Signing & CI/CD

Everything about signing, schemes, and the GitHub Actions pipeline.

## Signing today

- **Style:** Automatic
- **Team:** `ZHLD96SP29`
- **Bundle IDs:**
  - App: `IvanLB.Savely`
  - Unit tests: `IvanLB.SavelyTests`
  - UI tests: `IvanLB.SavelyUITests`
- **Capabilities:** Sign in with Apple (configured in `Savely/Savely.entitlements`)

Don't switch to manual signing. Don't introduce `.xcconfig` files without explicit approval — they're a non-trivial refactor.

## Schemes

Only `Savely.xcscheme` is shared (under `Savely.xcodeproj/xcshareddata/xcschemes/`). Its Test action runs both `SavelyTests` and `SavelyUITests` together.

**Consequence:** `xcodebuild -scheme SavelyTests` fails on a fresh checkout. Always use `-scheme Savely`.

If you want them runnable independently, share the test schemes via Xcode → Manage Schemes → check "Shared" for `SavelyTests` and `SavelyUITests`. Then commit the new files in `xcshareddata/xcschemes/`.

## Build & test commands (canonical)

```bash
# Build
xcodebuild build \
  -project Savely.xcodeproj \
  -scheme Savely \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Test (both unit + UI via the shared scheme)
xcodebuild test \
  -project Savely.xcodeproj \
  -scheme Savely \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -resultBundlePath build/TestResults.xcresult
```

## The CI pipeline

`.github/workflows/ci.yml` runs on:
- every PR (any base branch)
- every push to `dev` and `main`

Steps:

1. **Checkout** — `actions/checkout@v4`.
2. **Select Xcode** — pins to a specific Xcode version. Without this, GitHub silently bumps Xcode and your builds break "for no reason."
3. **Cache SPM** — caches `~/Library/Developer/Xcode/DerivedData/.../SourcePackages` keyed on `Package.resolved`'s hash. Saves ~60–90s per run when nothing changed.
4. **SwiftLint** — `swiftlint --strict` exits non-zero on any violation. This is the cheapest gate, runs first.
5. **Build** — `xcodebuild build` for the `Savely` scheme. Fails fast if compilation breaks.
6. **Test** — `xcodebuild test`. Emits `.xcresult` bundle.
7. **Upload artifact** — the `.xcresult` is uploaded so you can download it and open in Xcode when CI fails. Without this you're stuck reading 5,000 lines of CI logs.

## Cost reality

GitHub Actions free tier: 2,000 minutes/month for private repos, but **macOS counts at 10×** → effectively 200 macOS minutes/month.

A typical iOS run is ~6–10 min on `macos-15`, billed as 60–100 minutes. Solo dev with ~5 PRs/week → ~1,500–2,500 billed minutes/month.

When you hit the cap:
- **Pay-as-you-go**: ~$0.08 per macOS minute.
- **Self-hosted runner** on your own Mac: free, but you have to maintain it.
- **Skip CI on draft PRs**: saves minutes during WIP. Configure via `if: github.event.pull_request.draft == false`.

## Branch protection (set up via GitHub UI)

After pushing the workflow at least once and creating the `dev` branch:

1. Go to **Settings → Branches → Branch protection rules → Add rule**.
2. Branch name pattern: `main`. Settings:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging → select `ci` (the workflow's job name)
   - ✅ Require branches to be up to date before merging
   - ✅ Require linear history
   - ✅ Do not allow bypassing the above settings
3. Repeat for `dev` with the same settings.
4. Optionally enable: **Settings → General → Pull Requests → Automatically delete head branches**.

## Secrets management

Repo secrets live at **Settings → Secrets and variables → Actions**.

Today, the CI workflow needs **no secrets** (it doesn't sign or upload). When `release.yml` is added later, it will need:
- `APP_STORE_CONNECT_API_KEY` — the JSON contents of an App Store Connect API key
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `MATCH_PASSWORD` — encrypts the signing certs repo (if using fastlane match)

**Never** echo a secret in a workflow. **Never** `set -x` in a step that touches one.

## Deployment target reality (open task)

Current state:
- Project default: `IPHONEOS_DEPLOYMENT_TARGET = 17.0`
- App target: `26.0`
- Test targets: `17.5`

User decision: **iOS 26 is the floor everywhere.** First job for `build-ci-specialist` is to align all three to `26.0` in one PR (`build: align deployment target to iOS 26`).

## Releases (future)

Not implemented yet. When ready, the flow will be:

1. Cut a `release/<version>` branch off `dev`.
2. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj`.
3. Generate changelog from `git log dev..main --oneline`.
4. PR `release/<version>` → `main`. CI runs.
5. Merge. Tag `v<version>` on `main`.
6. (Future) `release.yml` workflow uploads to TestFlight via fastlane.
7. Back-merge `main` → `dev` so `dev` has the version bump.
