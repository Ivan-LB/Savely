---
name: Savely
description: A warm, patient, local-first savings app — the Warm Meadow system
colors:
  bg: "#f6f4ee"
  surface: "#ffffff"
  ink: "#1a1a17"
  ink-soft: "#55524c"
  ink-muted: "#8c8880"
  line: "rgba(30, 25, 15, 0.08)"
  line-soft: "rgba(30, 25, 15, 0.04)"
  green: "#2f6b4a"
  green-deep: "#1f4a33"
  green-soft: "#e8f0ea"
  green-tint: "#f2f7f3"
  amber: "#c48a2a"
  amber-soft: "#f6ecd6"
  clay: "#b85c42"
  clay-soft: "#f6e1d8"
  sky: "#4a7ba6"
  sky-soft: "#dce8f2"
typography:
  display:
    fontFamily: "system serif (New York)"
    fontSize: "64–72pt"
    fontWeight: 400
    lineHeight: 1
  headline:
    fontFamily: "system serif (New York)"
    fontSize: "30–36pt"
    fontWeight: 400
    lineHeight: 1.1
  title:
    fontFamily: "system serif (New York)"
    fontSize: "18–26pt"
    fontWeight: 400
    lineHeight: 1.2
  body:
    fontFamily: "system sans (SF Pro)"
    fontSize: "14–15pt"
    fontWeight: 400
    lineHeight: 1.4
  body-strong:
    fontFamily: "system sans (SF Pro)"
    fontSize: "14–15pt"
    fontWeight: 600
  label:
    fontFamily: "system sans (SF Pro)"
    fontSize: "11–13pt"
    fontWeight: 600
    letterSpacing: "0.8–1pt"
rounded:
  chip: "10pt"
  control: "14pt"
  row: "16pt"
  panel: "18–20pt"
  hero: "22–24pt"
  sheet: "28pt"
spacing:
  xs: "4pt"
  sm: "8pt"
  md: "12pt"
  base: "14pt"
  lg: "16pt"
  screen: "20pt"
  hero: "24pt"
components:
  button-primary:
    backgroundColor: "{colors.green}"
    textColor: "#ffffff"
    rounded: "{rounded.control}"
    height: "48–50pt"
  button-primary-dark-shell:
    backgroundColor: "{colors.ink}"
    textColor: "#ffffff"
    rounded: "18pt"
    size: "52pt"
  button-icon-outline:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    size: "40pt"
  chip-selected:
    backgroundColor: "{colors.green-soft}"
    textColor: "{colors.green-deep}"
    rounded: "999pt"
    padding: "8pt 14pt"
  chip-unselected:
    backgroundColor: "transparent"
    textColor: "{colors.ink-soft}"
    rounded: "999pt"
    padding: "8pt 14pt"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.row}"
    padding: "{spacing.base}"
  card-hero:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.hero}"
    padding: "{spacing.hero}"
  input-inline:
    backgroundColor: "{colors.bg}"
    textColor: "{colors.ink}"
    rounded: "{rounded.chip}"
    height: "40pt"
  tile-icon:
    backgroundColor: "{colors.green-soft}"
    textColor: "{colors.green}"
    rounded: "{rounded.chip}"
    size: "36pt"
---

# Design System: Savely

## Overview

**Creative North Star: "Warm Meadow"**

Savely looks like a well-made notebook that something is growing in. A
warm off-white page, a serif that speaks quietly, and small tinted tiles
that hold one glyph each — never a dashboard, never a bank. Density is
low on purpose: one hero object per screen (the favorite goal, the amount
being typed, the month's total), then a short list. The eye is meant to
land once and rest.

Color is restrained: one committed green carries every primary action and
every "money in" signal; amber, clay and sky exist only as soft tiles
behind icons and as one-word category tints. Ink does the rest. Depth is
flat by rule — a 1px hairline and a white surface on a warm ground are the
whole vocabulary; shadows survive only on the hero card and modal sheets.

Confirmed rejections: bank-fintech purple/neon and balance cards; SaaS
KPI grids and pie charts; cold gray-on-white spreadsheets.

**Key Characteristics:**
- Serif display, sans body — one contrast axis, no third face.
- One green, three soft tints, warm ink. Nothing saturated except the CTA.
- Hairline borders instead of shadows; surface-on-ground instead of elevation.
- Generous radii (14–24pt) that get larger as the object gets more important.
- Motion is one short entrance per screen, spring damping ≥ 0.9, no bounce.

## Colors

A warm neutral ground with a single committed green; everything else is a soft tint that holds an icon.

### Primary
- **Meadow Green** (`green`, #2f6b4a): the only saturated color. Primary buttons, income figures, active tab, progress rings, selected-state text. It is what "growing" looks like.
- **Meadow Green Deep** (`green-deep`, #1f4a33): text on green-soft chips and banners; darker end of the ring gradient.
- **Meadow Green Soft** (`green-soft`, #e8f0ea): selected chip fill, income icon tile, the auto-move banner. Never text.
- **Meadow Green Tint** (`green-tint`, #f2f7f3): selected row background in goal pickers; the tip-of-the-day card. The quietest possible "this one".

### Secondary (category tints — icons and chips only)
- **Amber** (`amber`, #c48a2a) on **Amber Soft** (`amber-soft`, #f6ecd6): coffee / expense category, the "favorite" star, the identity monogram tile.
- **Clay** (`clay`, #b85c42) on **Clay Soft** (`clay-soft`, #f6e1d8): shopping / receipt scanning tile; the *only* negative-trend color (income badge going down).
- **Sky** (`sky`, #4a7ba6) on **Sky Soft** (`sky-soft`, #dce8f2): goals / transit tile.

### Neutral
- **Warm Ground** (`bg`, #f6f4ee): every screen background and every inline input field. Deliberately not white.
- **Paper** (`surface`, #ffffff): cards, rows, action sheets, tab bar. Sits on the ground with a hairline, never a shadow.
- **Warm Ink** (`ink`, #1a1a17): all display and title type; primary body; the dark "+" shell and the scan-receipt banner.
- **Warm Ink Soft** (`ink-soft`, #55524c): body copy under a title, unselected chip text, settings icons.
- **Warm Ink Muted** (`ink-muted`, #8c8880): metadata — dates, "August · $500", uppercase section labels, placeholders. **Measured 3.2:1 on ground / 3.5:1 on paper: passes AA only as large text (≥18pt or bold ≥14pt).** Its current use at 12–13pt regular is a known AA gap, tracked in `docs/plans/pr-d-profile.md`.
- **Hairline** (`line`, 8% warm black) and **Hairline Soft** (`line-soft`, 4%): card borders and row dividers respectively. This *is* the depth system.

### Named Rules
**The One Green Rule.** Meadow Green is the only saturated fill on any screen, and it appears on at most one primary action plus the income figures. Amber, clay and sky never fill a button.

**The Soft-Holds-a-Glyph Rule.** The `-soft` tints exist to sit behind a single icon or a single selected chip. They are never a text color and never a card background.

**The Ink-Not-Gray Rule.** Muted text is warm ink at lower lightness, never a neutral gray. Anything that must be *read* (not skimmed) is `ink-soft` or darker.

## Typography

**Display Font:** system serif (New York on iOS), regular weight only
**Body Font:** system sans (SF Pro)
**Label Font:** SF Pro semibold, uppercase, tracked

**Character:** A book face for anything that names a thing (screen title, goal name, an amount being typed) and the system sans for anything that explains it. The serif is never bolded — its size carries the hierarchy, its regular weight carries the calm.

### Hierarchy
- **Display** (regular, 64–72pt, tight): the amount on the keypad screens ("+$500"). One per screen, monospaced digits, scales down to 40% before it wraps.
- **Headline** (regular, 30–36pt): screen titles ("Expenses", "Goals", "Evening."), onboarding titles, the "Planted." moment.
- **Title** (regular, 18–26pt): card headings ("Recent", "Achievements"), goal names, sheet titles ("Log income", "What's the move?").
- **Body** (regular 400 / strong 600, 14–15pt): row primary text, descriptions, button labels. Row titles are 600; supporting copy 400.
- **Label** (600, 11–13pt, tracking 0.8–1pt, uppercase): section kickers ("FAVORITE GOAL", "SETTINGS", "HISTORY", "7-MONTH TREND") and metadata lines. This is an incumbent, committed convention — one kicker style used consistently, not a new pattern to add elsewhere.
- **Figures**: every money figure uses `.monospacedDigit()`. Non-tabular money is a bug.

### Named Rules
**The Serif-Names, Sans-Explains Rule.** If it is the name of a thing or the number that matters, it is serif. If it tells you what to do with it, it is sans.

**The Regular-Serif Rule.** The serif is never used above weight 400. Emphasis comes from size and from ink, not from boldness.

## Layout

Single-column, 20pt screen inset on both edges, content stacked with a base rhythm of 14pt between siblings and 16–18pt between sections. Every screen is a `ScrollView` under a hidden navigation bar; the title lives in the content, not in the chrome. One hero object first (goal card, month total, the amount being typed), then supporting rows.

Cards use 14pt inner padding; the hero goal card uses 24pt. Rows inside a card are 12–14pt tall-padded and separated by a soft hairline inset 58pt from the leading edge (past the icon tile). Two-up summary cells sit in an `HStack` with 10pt gap. The tab bar is custom: 4 items around a raised 52pt dark "+" shell, 28pt bottom padding into the home indicator.

Sheets: `.presentationCornerRadius(28)`, drag indicator hidden and drawn manually as a 40×4 capsule in `line`. Action-sheet detent 540pt; entry sheets `.large`.

## Elevation & Depth

**Flat by rule.** Depth is conveyed by a white surface on the warm ground plus a 1px hairline (`line`, 8%). Row separation uses `line-soft` (4%). There is no shadow vocabulary for cards, rows, chips or inputs.

### Shadow Vocabulary
- **Hero lift** (`Color.black.opacity(0.04–0.06), radius 12–16, y 4–8`): the favorite goal card on the dashboard and the goal detail card. The one object allowed to float.
- **Shell shadow** (`black 0.18 / green 0.38, radius 10, y 4`): the raised "+" tab-bar shell, deeper when expanded.

Everything else that still carries a `.shadow(...)` is legacy from before the Warm Meadow redesign and should lose it when touched.

### Named Rules
**The Hairline-Is-Depth Rule.** If two surfaces need separating, use `line`. If a surface needs to feel raised, it had better be the hero card or the "+" shell.

## Shapes

Continuous rounded rectangles throughout, with the radius growing with the object's importance: 10pt for chips, inline inputs and 36pt icon tiles; 14pt for buttons and 40pt square icon buttons; 16pt for list containers and rows; 18–20pt for panels, banners and chart cards; 22–24pt for hero and identity cards; 28pt for sheet corners. Selection chips are full capsules. Progress is a 4pt-tall capsule bar or a 12pt-stroke ring with round caps. Borders are always 1px hairline, never colored strokes — the sole exception is the 2px `green` ring on a selected radio circle.

## Components

Discreet and precise: wide radii without exaggeration, no heavy borders, active state shown by a soft tint rather than a solid fill. The primary button is the only solid piece on a screen.

### Buttons
- **Shape:** rounded 14pt (`control`), full width for CTAs.
- **Primary:** `green` fill, white 15pt semibold, 48–50pt tall. Disabled: `ink-muted` fill (deposit) or 40% opacity (sheet Save).
- **Dark shell:** the "+" tab button and the scan-receipt banner — `ink` fill, white glyph, 18–20pt radius. Expanded state turns the shell `green` and rotates the plus 45°.
- **Icon outline:** 40×40, `surface` fill, `line` hairline, 14pt radius, `ink` glyph (bell, search — the latter removed in PR A).
- **Text action:** `green` 13pt medium ("See all", "Save" in sheets), no chrome.
- **Press:** system default; no custom scale. Motion elsewhere uses `.spring(response 0.28–0.35, damping 0.65–0.9)`.

### Chips
- **Style:** capsule, 13pt semibold, 8pt × 14pt padding.
- **Selected:** category tint fill (`green-soft` / `amber-soft` …) with its deep or accent text; border matches the fill.
- **Unselected:** clear fill, `ink-soft` text, `line` hairline border.
- **Transition:** `.easeInOut(0.15)`.

### Cards / Containers
- **Corner Style:** 16pt for lists, 18–20pt for panels, 22–24pt for hero.
- **Background:** `surface`; the "lifetime" card and the "Planted." screen are the only `green`-filled containers, with white type at 70–100% opacity.
- **Shadow Strategy:** none, except the hero lift (see Elevation).
- **Border:** 1px `line`.
- **Internal Padding:** 14pt (16–18pt for panels, 24pt for hero).

### Inputs / Fields
- **Inline add:** 40pt tall, `bg` fill on a `surface` card, 10pt radius, `line-soft` border, 14pt text; the "$" prefix is `ink-muted`.
- **Keypad amount:** custom 3×4 keypad, 52pt cells, serif 24pt keys on `surface`, hairline top rule; the entered amount is Display serif.
- **Focus:** no ring; the caret is enough. Onboarding name field is the exception: 1.5px `green` border when focused.
- **Error:** system `.alert` titled "Error" (`Strings.Errors.errorLabel`), plain-language message.

### Navigation
- Custom bottom bar: `surface`, 1px `line` top rule, four `WarmTabBarItem`s (22pt SF symbol + 10pt label, active = `green` semibold, inactive = `ink-muted`) around the raised "+" shell. Segmented control on Money uses the system `.segmented` picker.

### Signature: Icon Tile
A 36–44pt rounded square (10–12pt radius) in a `-soft` tint holding one 14–18pt SF symbol in the matching accent. It fronts every row (expense, income, goal, settings) and every onboarding page. It is how Savely says "category" without a label.

### Signature: Goal Ring
132pt ring, 12pt stroke, `green` on a warm-beige track (#ede6d4), round caps, rotated −90°, serif percentage inside. Progress bars elsewhere are 4pt capsules on `goal.trackColor`.

## Do's and Don'ts

### Do:
- **Do** put the screen title in the content as a 30–36pt regular serif under a hidden nav bar.
- **Do** separate surfaces with the 1px `line` hairline and rows with `line-soft` inset 58pt.
- **Do** keep `.monospacedDigit()` on every money figure.
- **Do** use a `-soft` tile + accent glyph as the row's leading element.
- **Do** honor Reduce Motion with an instant transition; default motion is one entrance per screen, damping ≥ 0.9.
- **Do** keep the primary CTA `green`, full-width, 48–50pt, 14pt radius.

### Don't:
- **Don't** add shadows to cards, rows, chips or inputs — the hero card and the "+" shell are the only lifted objects.
- **Don't** fill a button with amber, clay or sky, and don't use a `-soft` tint as a card background.
- **Don't** bold the serif or use it below 18pt.
- **Don't** introduce gradients, glass, or a second accent hue.
- **Don't** hardcode `.white` / `Color(red:…)` in a view — every color goes through `Color+Warm.swift`, which is the single place a dark scheme can be introduced.
- **Don't** invent a new kicker or eyebrow style; the existing 11pt uppercase tracked label is the one and only.
