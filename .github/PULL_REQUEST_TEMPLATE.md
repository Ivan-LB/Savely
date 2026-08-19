## Summary
- <bullet 1: what changed>
- <bullet 2>

## Why
<one short paragraph on motivation. Link issues if any.>

## Test plan
- [ ] `xcodebuild build -scheme Savely -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- [ ] `xcodebuild test -scheme Savely -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- [ ] Manual: <steps to verify visually / functionally>

## Risks
<anything reviewer should look at closely — migrations, networking changes, etc.>

## Checklist
- [ ] Branch named with approved prefix (`feature/`, `fix/`, `refactor/`, `chore/`, `ci/`, `release/`, `hotfix/`)
- [ ] Commits follow Conventional Commits
- [ ] No hardcoded user-facing strings (all routed through `Strings.swift`)
- [ ] No secrets staged (`Config.plist`, `GoogleService-Info.plist`, `.env*`)
- [ ] `CLAUDE.md` / knowledge files updated if a new invariant emerged
- [ ] Tests added or updated for behavior changes

🤖 Generated with [Claude Code](https://claude.com/claude-code)
