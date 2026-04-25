# Common rules — the shared rulebook

Every specialist follows these. Listed once here so the agent files don't repeat them.

## Definition of Done (every PR)

1. `xcodebuild build -scheme Savely -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` succeeds.
2. `xcodebuild test -scheme Savely -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` passes.
3. `swiftlint --strict` exits 0 (soft-skip until SwiftLint is installed).
4. No hardcoded user-facing strings — everything routed through `Resources/Strings.swift`.
5. No secrets staged. See list below.
6. `CLAUDE.md` updated if a new invariant is introduced.
7. `.claude/knowledge/gotchas.yaml` appended if a workaround was needed.
8. Branch named with approved prefix.
9. Commits follow Conventional Commits.
10. PR opened against `dev` (or `main` for `release/*` only). CI green. **No auto-merge.**

## Prohibited git operations

Never, regardless of who asks:

- `git push --force` to `main` or `dev`
- `git commit --no-verify` — fix the hook failure instead
- `git commit --amend` on already-pushed commits on shared branches
- `git rebase -i main` or `dev` after push
- `git branch -D <branch>` if it has unmerged work and the user hasn't confirmed
- Deleting `Savely.xcodeproj/project.pbxproj`

If a hook fails, the commit didn't happen. Fix the issue, re-stage, create a **new** commit. Don't `--amend` after a hook failure — that would modify the previous commit.

## Secrets — never commit

| Path / pattern | What it is |
|---|---|
| `Savely/Config.plist` | OpenAI API key |
| `Savely/GoogleService-Info.plist` | Firebase config |
| `.env`, `.env.*` | Environment files |
| `*.mobileprovision`, `*.provisionprofile` | Provisioning profiles |
| `*.p12`, `*.cer`, `*.certSigningRequest` | Signing certs |
| `AuthKey_*.p8` | App Store Connect API keys |
| `*.xcresult` | Test result bundles (large, sometimes contain user data) |

If you see any of these about to be staged: **stop and tell the user.**

## Branch naming

| Prefix | Targets | Use for |
|---|---|---|
| `feature/<slug>` | `dev` | New user-facing capability |
| `fix/<slug>` | `dev` | Bug fix |
| `refactor/<slug>` | `dev` | Restructure, no behavior change |
| `chore/<slug>` | `dev` | Tooling, deps, docs |
| `ci/<slug>` | `dev` | CI/CD config |
| `release/<version>` | `main` | Release prep |
| `hotfix/<slug>` | `main` | Critical production fix |

Slug: kebab-case, ≤40 chars, descriptive.

## Commit messages — Conventional Commits

```
<type>(<optional scope>): <imperative summary, ≤72 chars>

<optional body — wrapped at 72 chars>

<optional footer>
```

Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `ci`, `build`, `test`, `style`, `perf`.

Enforced by the `commit-msg` git hook (`.githooks/commit-msg`).

## When you discover a new invariant

Append to `.claude/knowledge/gotchas.yaml`:

```yaml
- id: <kebab-case-id>
  summary: <one-line statement>
  why: <what breaks if you ignore this>
  how-to-apply: <when this rule kicks in>
```

Then mention it in the PR description.

## Language

Match the user's language. If they switch from English to Spanish mid-conversation, switch with them.

## Surfacing options vs. deciding silently

For non-trivial choices (architecture, dependencies, naming patterns, new abstractions), present 2 options with trade-offs and let the user pick. Don't decide silently. The user is solo and is using this project to learn — explanations are part of the value.

Trivial decisions (variable names, where exactly to put a small helper) — just decide and move on.

## Auto-merge

**Never.** The user reviews and merges every PR manually.

## Long-running commands

`xcodebuild build`, `xcodebuild test`, `swift package resolve` — ask before running. They're slow and noisy in the terminal.
