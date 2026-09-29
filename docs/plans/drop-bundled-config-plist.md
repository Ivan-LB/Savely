# Drop the bundled Config.plist from Resources

> Found 2026-08-19 during an external privacy review of all shipping apps.
> Status: **DONE in 1.1 (branch `chore/release-hygiene`)** — steps 1–2 shipped,
> the CI placeholder steps (ci.yml, ci_post_clone.sh) were retired with it and the
> Xcode Cloud gate now refuses any archive with Tips on. Step 3 stands for when
> Tips returns. Key revoked by Iván 2026-08-19.

## What happened

`Savely/Config.plist` holds the OpenAI API key for the tips feature and is
**bundled into the app**: it appears in the Resources build phase at
`Savely.xcodeproj/project.pbxproj:27` and `:721`, loaded at
`Savely/Utilities/OpenAIClient.swift:16-22` via
`Bundle.main.path(forResource: "Config")`. It is gitignored
(`.gitignore:14`) so it never reached git history, but anything in Resources
is extractable from the .ipa by anyone. The build submitted to App Review
carried a live key. The feature itself is unreachable
(`FeatureFlags.tipsEnabled = false`, `Savely/Utilities/FeatureFlags.swift:22`)
but the plist ships regardless.

Iván revoked the key in the OpenAI account on 2026-08-19, so the shipped copy
is dead. Remaining work is hygiene:

## The chore

1. Remove `Config.plist` from the Resources build phase (keep the file on disk
   and gitignored for local dev when the feature returns).
2. Verify: `grep -n "Config.plist" Savely.xcodeproj/project.pbxproj` shows no
   `in Resources` entry, the app still builds, and a fresh archive's .app
   bundle contains no Config.plist (`unzip -l` the .ipa or inspect the archive).
3. When the tips feature is ever turned back on: the key must NOT return via
   bundled plist. Ship it behind a proxy you control, or at minimum load from
   Keychain after first launch. A bundled plist is equivalent to publishing
   the key.

## Why not urgent anymore

Revoked key = dead file. But the pattern regenerates the incident the moment
someone rotates the key locally and archives: the build phase entry is the
bug, not the key value.
