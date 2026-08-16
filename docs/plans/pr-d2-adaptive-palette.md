# PR D2 — Adaptive palette: Warm Meadow under a lamp

**Source:** Impeccable design pass 2026-08-15 (`DESIGN.md`), contrast
measurements below, `reference/ios.md` (Dark Mode is a first-class
appearance; semantic colors, not raw hex).
**Depends on:** PR D merged (the Dark Mode row is hidden behind
`FeatureFlags.darkModeEnabled`; this PR flips it).
**Branch:** `feat/adaptive-palette` off `dev`, PR back to `dev` (developer
merges manually).
**Complexity:** Large in surface area, small in design risk: one file
defines the palette, ~97 call sites route through it, every screen gets
re-checked in both schemes.

> **The light appearance does not change.** Every light value in
> `DESIGN.md`'s frontmatter is preserved byte-for-byte except the two AA
> corrections listed under *Decisions* — and those only if the owner
> accepts them. Dark is the *same notebook under a lamp*: warm, low
> chroma, one green; not a neutral-gray inversion.

## Evidence

- `Color+Warm.swift` holds 18 tokens, all light-only constants.
  `.preferredColorScheme` already flips with the switch (status bar
  proves it) — nothing else listens.
- **0** uses of `@Environment(\.colorScheme)` in the app.
- Hardcodes outside the palette file (must be routed through tokens or
  they will stay light in dark): **29 `Color(red:…)`, 57 `.white`,
  11 `.black`, 5 legacy `Color("primaryGreen"…)` asset refs**.
- 12 `.shadow(...)` calls; only the hero-card lift and the "+" shell are
  by rule (`DESIGN.md` Elevation). The rest are legacy.

### Contrast today (light) — WCAG AA

| pair | ratio | AA text 4.5 | AA large/graphic 3.0 |
|---|---|---|---|
| ink / bg · surface | 15.9 · 17.4 | ✓ | ✓ |
| ink-soft / bg · surface | 7.1 · 7.8 | ✓ | ✓ |
| **ink-muted #8c8880 / bg · surface** | **3.21 · 3.53** | **✗** | ✓ |
| green / bg · surface · green-soft | 5.8 · 6.3 · 5.4 | ✓ | ✓ |
| white on green (CTA) | 6.3 | ✓ | ✓ |
| **amber #c48a2a on amber-soft** | **2.55** | ✗ | **✗** |
| clay on clay-soft · surface | 3.6 · 4.5 | ✗ · ✓ | ✓ |
| sky on sky-soft | 3.6 | ✗ | ✓ |

`ink-muted` is used at 12–13pt regular for metadata everywhere ("August ·
$500", dates, kickers). That is body text under AA and it fails.

## Decisions

1. **Implementation:** keep the `Color.warm*` API exactly as is; change
   the definitions to dynamic colors:
   ```swift
   static let warmBg = Color(light: 0xF6F4EE, dark: 0x161512)
   ```
   with a tiny private helper built on
   `UIColor { $0.userInterfaceStyle == .dark ? dark : light }`. Zero
   call-site changes for the 18 existing tokens. (Asset-catalog color sets
   would also work; the code-defined helper keeps the palette in one
   reviewable file and matches how the app already defines color.)
2. **New tokens** for what is hardcoded today, named by role not by hue:
   `warmOnGreen` (white on green fills, both schemes), `warmTrack` (ring
   track, was `Color(red: .93,.90,.83)`), `warmShadow` (hero lift),
   `warmLilac` / `warmLilacSoft` (the "New goal" quick action, was two
   inline `Color(red:…)`), plus whatever the sweep finds. `.white` used as
   *ink on a dark shell* becomes `warmOnInk`. Genuinely-white things (the
   sprout mark on the splash) stay `.white`.
3. **AA corrections in light — owner's call, both imperceptible:**
   - `warmInkMuted` `#8c8880` → **`#746f66`** (4.54:1 on bg, 4.99 on
     surface). Same warm-ink family, one step darker. This is the only way
     "AA formal" and "12pt muted metadata" coexist without restyling.
     Alternative if declined: keep the value and move every ≤13pt use of
     `ink-muted` to `ink-soft` — a much larger, more visible change.
   - `warmAmber` `#c48a2a` → **`#a8741c`** where it is a *glyph on
     amber-soft* (3.45:1). Keep `#c48a2a` for the favorite star and the
     monogram if you prefer — those are decorative; declare it.
   If declined, note the deviation from PRODUCT.md's AA commitment in the
   PR body rather than silently failing it.
4. **Legacy `ColorPalette` assets** (`primaryGreen`, `cardBackgroundColor`,
   `listBackgroundColor`, `primaryBlue` — 5 refs): route to the nearest
   Warm token and delete the asset sets in the same PR.
5. **Shadows:** the hero lift and the "+" shell keep theirs (`warmShadow`
   token, darker in dark). The remaining legacy `.shadow(...)` calls go.

## Dark palette (proposed — verified AA)

Same hue family as light, chroma kept low, one green. Ratios computed
against the dark ground/surface; all text pairs ≥ 4.5, all glyph/tile
pairs ≥ 3.0.

| token | light (unchanged) | dark | check |
|---|---|---|---|
| bg | `#f6f4ee` | `#161512` | — |
| surface | `#ffffff` | `#262420` | sep 1.18 + hairline (depth is the hairline by rule) |
| ink | `#1a1a17` | `#f2efe7` | 15.9 / 14.3 ✓ |
| ink-soft | `#55524c` | `#c6c1b5` | 10.2 / 9.2 ✓ |
| ink-muted | `#8c8880` (→ `#746f66` if D.3 accepted) | `#9d978a` | 6.3 / 5.7 ✓ |
| line | warm black 8% | warm white 10% | — |
| line-soft | warm black 4% | warm white 5% | — |
| green (text/icon) | `#2f6b4a` | `#78b58f` | 7.7 / 6.9 ✓ |
| green-fill (CTA, income card) | `#2f6b4a` | `#367c56` (white text 5.0 ✓, ≥3:1 vs surface) | ✓ |
| green-deep (text on green-soft) | `#1f4a33` | `#b6dcc4` | 8.4 on green-soft ✓ |
| green-soft | `#e8f0ea` | `#22382c` | — |
| green-tint | `#f2f7f3` | `#1b2a21` | — |
| amber | `#c48a2a` (`#a8741c` on tile) | `#dea64a` | 6.0 on amber-soft ✓ |
| amber-soft | `#f6ecd6` | `#3a2f19` | — |
| clay | `#b85c42` | `#d9846a` | 4.9 tile ✓ · 5.8 as trend-down text ✓ |
| clay-soft | `#f6e1d8` | `#3d2721` | — |
| sky | `#4a7ba6` | `#7ea9d0` | 5.7 tile ✓ |
| sky-soft | `#dce8f2` | `#1e2d3b` | — |
| track (new) | `#ede6d4` | `#3a362e` | ring 5.0 vs track ✓ |
| onGreen / onInk (new) | `#ffffff` | `#ffffff` / `#f2efe7` | ✓ |

Note `green` splits into *text/icon* (lightened for dark) and *fill*
(unchanged): the CTA stays the same Meadow Green in both schemes with
white text; only green *as ink* brightens. That is what keeps dark from
reading as a different brand.

## Also in this PR (owner's request, 2026-08-16): drop the "User" identity

There is no account, so the monogram + "User" card on Profile and the
`person.fill` circle in the Dashboard greeting (`DashboardView.swift:~63-71`)
are placeholders for an identity the app deliberately does not have.
Remove both:

- **Profile:** delete the identity card. Move its one useful line —
  "Saving since <month>" / "Just getting started" — into the lifetime
  income card as its subtitle (replacing "Total income logged in Savely").
- **Dashboard:** delete the amber `person.fill` circle from the greeting
  row; the greeting keeps its date + "Evening." only.
- **Display name:** with the card gone nothing reaches `EditProfileSheet`.
  Delete the sheet, `ProfileViewModel.displayName` /
  `updatePersonalInformation()`, and `AppViewModel.currentUserName` +
  its `"displayName"` UserDefaults key. Also drop the now-unused
  `Strings.Profile.editNameHint` and its catalog entry. Confirm nothing
  else reads `"displayName"` (grep) before deleting.

Sequenced as its own commit (commit 0 below) so it can be reverted alone.

## Commits

0. **Drop the identity placeholders** (Profile card, Dashboard avatar,
   display-name plumbing) as described above.
1. **Palette:** dynamic-color helper + all 18 tokens get a dark value + the
   new role tokens. Build must be green with **no call-site changes** yet.
2. **Sweep the hardcodes:** route the 97 sites through tokens, screen by
   screen (Dashboard, Goals + AddGoalFlow, Money, Profile, sheets in
   MainNavigationView, onboarding, splash). Delete legacy asset sets and
   legacy shadows.
3. **Flip `FeatureFlags.darkModeEnabled = true`.** Also honor the system:
   `.preferredColorScheme(darkModeEnabled ? .dark : nil)` — a user who
   never touched the switch follows iOS; the switch forces dark. (Today
   `false` forces *light*, which overrides a system-dark user. Confirm
   with owner; recommended.)
4. **AA corrections** (if accepted): the two light values, one commit,
   with before/after ratios in the message.

## Validation

- `xcrun simctl ui <UDID> appearance dark` / `light` between passes;
  screenshots of **every** screen in both schemes, side by side, on iPhone
  17 Pro (`xcrun simctl io <UDID> screenshot`).
- Contrast re-run of the table above from the final hex values (script it;
  paste the table into the PR body).
- Sheets, alerts and the custom tab bar in dark; the keypad; the green
  hero cards; `.warmGreenSoft` chips (the ones most likely to lose
  contrast).
- Populated data, not fresh seed (house rule), then uninstall.

## Acceptance

- [ ] Build + tests + `swiftlint --strict` green
- [ ] `grep -rn "Color(red:\|\.white\b\|\.black\b" Savely --include=*.swift | grep -v Color+Warm` → only the deliberate exceptions, each with a comment
- [ ] Both schemes screenshotted for every screen; light matches pre-PR pixel-for-pixel except the accepted AA corrections
- [ ] Contrast table regenerated and green
- [ ] Dark Mode row visible and working; system appearance followed when the switch is off
- [ ] `DESIGN.md` re-documented (`/impeccable document`) with the dark values in the frontmatter
- [ ] PR to `dev`, CI green, do NOT merge
