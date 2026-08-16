# PR D3 — Accessibility: VoiceOver, Dynamic Type, touch targets (whole app)

**Source:** PRODUCT.md commitment "WCAG AA, formally, across the whole app";
Impeccable `audit.native` scan of the source 2026-08-15 (numbers below);
`reference/ios.md`.
**Depends on:** PR D2 merged (contrast in both schemes is D2's job; this PR
assumes the palette is final). Can start in parallel on a branch but rebase
before opening.
**Branch:** `feat/a11y-pass` off `dev`, PR back to `dev` (developer merges
manually).
**Complexity:** Large but mechanical. Best done screen by screen, one commit
each, with a VoiceOver walk per commit.

> **The default look does not change.** Dynamic Type support is added so
> that at the *default* content size every glyph renders at exactly the
> point size it renders today; only larger accessibility sizes differ.

## Evidence (source scan)

| Check | Finding |
|---|---|
| `accessibilityLabel` / `Hint` / `Value` / `AddTraits` | **0 / 0 / 0 / 0** in the whole app |
| `accessibilityHidden` | 1 |
| Fixed `.system(size:)` | **268** — Dynamic Type is defeated everywhere |
| `relativeTo:` / `@ScaledMetric` | **0 / 0** |
| Semantic text styles (`.body`, `.caption`…) | 20 (legacy views) |
| `accessibilityReduceMotion` | 5, all in `SplashScreenView` — onboarding entrance and sheet springs ignore it |
| Tappable frames < 44pt | 8 × 40pt (inline "+" add buttons, icon buttons), 7 × 32pt (chevron / dismiss buttons) |
| Icon-only controls with no label | tab-bar "+" shell, keypad ⌫ (image only), favorite star, delete-in-context-menu (labeled), quick-action rows (labeled by text), sheet dismiss ×, chevron buttons |
| `Toggle("").labelsHidden()` | Profile settings rows — announced as "Switch, on" with no name |

## Decisions

1. **One font helper, no per-site rewriting of sizes.** Add
   `Font.warm(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, relativeTo style: Font.TextStyle = .body)`
   that scales `size` with `UIFontMetrics(forTextStyle:)`. Then a mechanical
   replace: `.font(.system(size: 14, weight: .semibold))` →
   `.font(.warm(14, weight: .semibold))`. Identical at default size.
   Display serif amounts (64–72pt) scale `relativeTo: .largeTitle` and keep
   their existing `.minimumScaleFactor(0.4)`.
2. **Layouts must survive AX3.** Fixed `frame(width: 70)` on the inline
   amount fields, the 3-up stats, the 7-bar chart labels and the tab bar
   labels are the likely breakers. Use `@ScaledMetric` for those widths or
   let them wrap; do not clip.
3. **Touch targets:** keep the visuals; enlarge the *hit area* to ≥ 44pt
   with `.frame(minWidth: 44, minHeight: 44)` + `.contentShape(Rectangle())`
   around the existing 32/40pt visuals. Nothing moves on screen.
4. **Labels:** every icon-only control gets `.accessibilityLabel`; toggles
   get real titles with the visual label hidden (`.labelsHidden()` after a
   real title, never `Toggle("")`); custom rows become one element
   (`.accessibilityElement(children: .combine)`) with a `.isButton` trait
   where they act; money figures get `.accessibilityValue` with the
   currency spelled out; decorative tiles/images `.accessibilityHidden(true)`.
   Progress ring/bars expose `.accessibilityValue("38 percent")`.
5. **Reduce Motion everywhere:** onboarding entrance, sheet spring, "+"
   shell rotation, chip animations → instant when
   `accessibilityReduceMotion`. Reuse the splash's pattern.
6. **Custom tab bar stays.** ios.md prefers the system tab bar; the custom
   one is an incumbent design decision (`DESIGN.md` Navigation). Make it
   *behave* like one instead: `.accessibilityAddTraits(.isTabBar)` on the
   container, `.isSelected` on the active item, labels already visible.
   Record this as an accepted deviation.
7. **Localization is part of AA here:** every new label goes through
   `Strings.swift` + the catalog in **both** en and es-419 (labels are
   read aloud; an untranslated label is a defect, not a nit).

## Commits (one per surface, VoiceOver walk each)

1. `Font.warm` helper + `@ScaledMetric` primitives + hit-area modifier
   (`.tappable44()`); unit test that `Font.warm(14)` at default content
   size equals `.system(size: 14)`'s metrics.
2. Dashboard + HeroGoalCard + DepositSheet.
3. Goals list + GoalDetailView + AddGoalFlow (4 steps + Planted).
4. Money tab (Expense/Income trackers, rows, chart, inline add).
5. MainNavigationView: tab bar, action sheet, keypad, quick sheets.
6. Profile + Achievements + onboarding + splash.
7. Reduce Motion sweep.

## Validation

- VoiceOver walk on the simulator (Accessibility Inspector audit per
  screen; zero "no label"/"hit area too small" warnings).
- Dynamic Type at Large (default), AX1 and AX3: screenshots per screen —
  no clipping, no overlap, no truncated money figure.
- Reduce Motion on: onboarding + sheets are instant.
- Both schemes (dark from D2) at AX3.
- Populated data, then uninstall.

## Acceptance

- [ ] Build + tests + `swiftlint --strict` green
- [ ] `grep -rn "\.system(size:" Savely --include=*.swift` → 0 outside `Font.warm`
- [ ] `grep -rn 'Toggle("")' Savely` → 0
- [ ] Accessibility Inspector audit: 0 errors on every screen
- [ ] AX3 screenshots for every screen, both schemes, nothing clipped
- [ ] Every new label present in `Localizable.xcstrings` for en **and** es-419
- [ ] PR to `dev`, CI green, do NOT merge
