# App Store screenshots — direction & production plan

**Date:** 2026-08-17
**Status:** direction chosen (this doc); production is the next job (Opus, ultracode).
**Owner decision needed:** none blocking — the choices below are recommendations
with the alternatives kept; flip anything before production starts.

Research method: three parallel researchers (Apple specs & review rules verified on
developer.apple.com; a survey of ~20 finance/indie/editorial App Store pages opened
live; copy craft for en-US + es-MX), three independent art-direction proposals against
DESIGN.md/PRODUCT.md, then a judge scoring fit / distinctness / store effectiveness /
honesty / producibility. Full research dump: session artifact "Savely storefront".

---

## 0. TL;DR

- **Direction: "Seed to Sprout" on the notebook page.** Every screenshot is one page of
  the same warm notebook (ground `#f6f4ee`, one full-bleed hairline rule under a small
  green tracked kicker, a two-line *regular* New York headline, one SF Pro sentence) with
  the real app as a flat, untilted photo in a thin warm-ink bezel tucked under the page
  edge. The only thing that changes from page to page besides the copy is the
  **SproutMark growing one stage per page** — seed on 1, stem on 2–3, first leaf 4–5,
  second leaf 6–7, full sprout under a lamp (dark mode) on 8. It is the splash
  animation's own geometry laid across the gallery: "a well-made notebook that
  something is growing in", literally.
- Why it is *ours*: not Alisio (no colored bands, no bold sans, no dark UI), not Fingo
  (no gradients, no tilt, no shouting), not Thirds (Thirds floats UI cards on cream with a
  heavy serif and no device; Savely tucks a framed photo, keeps the serif at weight 400,
  puts a green kicker on a rule, and grows a plant), and not the 2025-26 "cream +
  serif + orange kicker" default that Monarch/Matter now own (green kicker, sprout,
  ink bezel, no italics, warm `#f6f4ee` not ivory).
- **Ledger rule** (from PRODUCT.md, applied to the store): every state a caption names —
  "on track", "behind", "a drop", "never uploaded", a figure — must be visible in the UI
  on that same page. This decides which screen each frame shows.
- **8 frames, en-US + Spanish (Mexico)**, master at 1320×2868 (6.9"), Apple scales the
  rest. Light 1–7, dark 8. Order 1 goal → 2 privacy → 3 payday; PPO-test payday-first
  and a full-dark set later.
- **Blocking prerequisites before shooting** (§5): es-419 gaps (~139 strings + hard-coded
  English literals on the exact screens we show), the truth gate for "No account. No
  cloud." (Config.plist with the OpenAI key is in the Resources phase; ATS exception for
  openai.com; stray GoogleService-Info.plist), `TARGETED_DEVICE_FAMILY = 1,2` (iPad set
  or go iPhone-only), a seeded fictional dataset, and dark mode via `-darkModeEnabled YES`.

---

## 1. Facts that shape the plan (verified 2026-08-17)

| Fact | Consequence |
|---|---|
| iPhone: only the **6.9"** set is effectively required (1320×2868 / 1290×2796 / 1260×2736, portrait); every smaller size scales down from it. 1–10 images, PNG/JPG, **no alpha**. | One master set per language. Skip 6.5"/6.3"/6.1"/5.5". Optional 4.7" (750×1334) only if SE users matter. |
| iPad 13" (2064×2752) is required **if the app runs on iPad**; the project has `TARGETED_DEVICE_FAMILY = "1,2"`. | Set it to `1` (iPhone-only) or budget an iPad adaptation. |
| Search results show the **first 3 portrait screenshots** (1 if landscape); Apple: "make sure these highlight the essence of your app"; one Dark Mode screenshot recommended. | Portrait; frames 1–3 carry the whole pitch; frame 8 dark. |
| Review 2.3.3: screenshots must show the app in use — not merely title art / splash. Overlays and text allowed. 2.3.7: no prices/"free"/"best". 2.3.9: fictional data, not a real person's. | Every frame shows real UI; the privacy frame shows a settings screen, not a slogan card; no laurels/user counts; seeded fictional data. |
| App Store Connect languages: **Spanish (Mexico)** (default for MX + 16 LatAm storefronts, and an additional language on the US storefront) — there is no es-419 slot. | Upload en-US + es-MX; the es-MX set serves LatAm and US Spanish speakers. |
| Product Page Optimization: ≤3 treatments, 90 days, per locale, submittable without a new build (if no icon change). | Full-dark set and "payday-first" order are PPO treatments, not part of v1. |
| iOS 27 "Creative Assets" (product-page header + search-results image) announced at WWDC26, specs pending. | Keep the same grammar (kicker + rule + sprout) ready for a header asset later; iOS 26 users still see frames 1–3. |
| Legibility math (derived, not Apple's): a 1320px canvas is ≈118pt wide in a 3-up search result → a 136–144px headline reads ≈12–13pt. | Headline ≥136px, ≤5 words, exactly 2 lines, in the top 25% of the canvas. |
| Dark mode in Savely is an **in-app override** (`.preferredColorScheme` from `@AppStorage("darkModeEnabled")`); `simctl ui appearance dark` does nothing. | Launch with `-darkModeEnabled YES` for frame 8. |

---

## 2. The system ("Seed to Sprout on the notebook page")

All coordinates on the 1320×2868 master. Everything is left-aligned at x=96 on every
frame; nothing alternates, nothing pans across frames — patience means the same
position on every page.

**Page**
- Ground: `bg #f6f4ee` (dark frame: `bg-dark #161512`). No texture, grain, vignette or gradient.
- Header rule: 3px `line` rgba(30,25,15,.08) full-bleed at **y=192** (dark: `line-dark` rgba(242,239,231,.10)). The only "ruled paper" cue.
- Kicker: x=96, baseline ≈ y 156, **SF Pro Semibold 36px, uppercase, tracking +0.10em, Meadow Green `#2f6b4a`** (dark `#78b58f`). ≤3 words. It is the app's own 11pt tracked label scaled up — the one and only kicker style. No tinted tile, no glyph.
- Headline: y 256–540, **New York Regular 136–144px**, line-height 1.04, tracking −0.005em, ink `#1a1a17` (dark `#f2efe7`), max-width 1128, ≤5 words, **hand-broken to exactly two lines** on every frame so the horizon never moves. Never bold, never italic.
- Sub: 28px below, **SF Pro Regular 44–46px** / 1.3, `ink-soft #55524c` (dark `#c6c1b5`), max-width 980, ≤12 words, ≤2 lines. Sentence case, periods, no exclamation marks.
- Growth mark: SproutMark geometry (SproutMark.swift, 120-unit space) in a **~180px box right-aligned to x=1224, seed tangent to the header rule** (box top ≈ 192 − 180·101/120 ≈ 40) — the plant grows out of the notebook line. Stages: 1 seed only · 2 stem 35% · 3 stem 100% · 4 + left leaf 45% · 5 left leaf 100% · 6 + right leaf 45% · 7 full · 8 full in dark tokens (leaves `#78b58f`/`#5d9c7c`, seed `#dea64a`). Flat fills, no outline, no gradient, never bigger, never a mascot.
- Device ("the photo"): flat, untilted, left-flush. Bezel x=96→1098 (1002 wide), y=1024→off canvas, 26px warm ink `#1a1a17`, outer radius 160; screen 950 wide = the source capture ×0.72, radius 134, `overflow:hidden`; Dynamic Island 270×80 in the same ink as part of the bezel silhouette. The canvas bottom crops the tab bar/home indicator under the page edge. Dark frame: bezel `surface-dark #262420` + a `line-dark` hairline outside it (an ink bezel vanishes on the dark ground). No shadow, no reflection, no Apple photographic titanium.
- Right of the device the page keeps its empty margin (x 1098–1224) — the notebook margin.

**Color discipline (One-Green Rule at poster scale):** green appears only *as ink* — kicker + sprout — plus whatever the real UI carries. Never a green ground/band/frame. Amber/clay/sky/lilac appear only *inside* the screenshot (tiles, chips, the clay "Behind"). Ink-not-gray for every muted text.

**Banned:** colored bands (Alisio), gradients/blobs/tilt (Fingo/YNAB/Copilot), silver photographic bezels, drop shadows, floating Dynamic-Island pill without a bezel, callouts/arrows/pop-out cards (v1), laurels/press/user counts, illustration or mascot beyond the four SproutMark shapes, confetti, emoji, italic or bold serif, a second kicker style, prices/"free"/"best"/"#1", a brand-only slide, page folios.

**Contrast:** ink on ground ≈16:1, ink-soft ≈7:1, green kicker ≈5.6:1 (light); `#f2efe7`/`#78b58f` on `#161512` ≈15:1 / 7:1 (dark) — all AA+.

---

## 3. Sequence & copy (en-US · es-MX)

Kickers are page headers, headlines are ≤5 words / 2 lines, subs ≤12 words. Spanish is
written as its own sentence (tú, no exclamation marks, "recibo" not "ticket",
"quincena" is deliberately Mexican). Every sub obeys the ledger rule.

| # | Screen (must show…) | Sprout | Kicker | Headline | Sub |
|---|---|---|---|---|---|
| 1 | **GoalDetailView** of the favorite goal — ring, status line "On track · by Dec 12 · $125/wk", pace pills. (The Dashboard hero card only says "PACE · On track", so the detail view is the honest choice.) | seed | SAVINGS · AHORRO | Your goal.<br>A real pace. · Tu meta.<br>Ritmo real. | On track or behind — from what you actually put in. · A tiempo o atrasada, según lo que de verdad depositas. |
| 2 | **Profile → Data & privacy** ("Your data never leaves this iPhone." — es-419 exists). PPO alternate: onboarding "Yours, and only yours" (needs es-419 first). | stem 35% | YOUR DATA · TUS DATOS | No account.<br>No cloud. · Sin cuenta.<br>Sin nube. | Your money data lives on your iPhone and never leaves it. · Tus datos viven en tu iPhone y nunca salen de ahí. |
| 3 | **Log income sheet** with the green-soft auto-move banner, un-armed ("Auto-move $150 to Trip to Oaxaca from this paycheck?" + YES pill), keypad cut at its last row. | stem 100% | PAYDAY · DÍA DE PAGO | Save before<br>you spend. · Ahorra antes<br>de gastar. | Log your pay, tap Yes, and part of it goes to your goal. · Registra tu quincena, toca Sí y una parte se va a tu meta. |
| 4 | **Log expense keypad**, Display amount, Coffee chip selected (amber tile visible). | left leaf 45% | EVERYDAY MONEY · GASTO DIARIO | Log it in<br>seconds. · Anótalo en<br>segundos. | Amount, a category, done. The rest is optional. · Monto, una categoría y listo. Lo demás es opcional. |
| 5 | **Receipt review sheet** ("We read this — is it right?"), fictional merchant "Corner Market" / "Abarrotes La Esquina", total, date. Reached via Photos import of a synthetic receipt (Simulator has no camera). Never the live viewfinder. | left leaf 100% | RECEIPTS · RECIBOS | Scan it.<br>It stays here. · Escanéalo.<br>Se queda aquí. | Total, merchant, date — read on your iPhone, never uploaded. · Total, comercio y fecha. Se leen en tu iPhone y nunca se suben. |
| 6 | **Money tab**, 7-month trend with a genuinely lower month (July > August), month total. | right leaf 45% | THE MONTH · EL MES | Bad months<br>count too. · Los meses malos<br>también cuentan. | Real trends, month over month. Drops included. · Tendencia real, mes a mes. Bajadas incluidas. |
| 7 | **GoalDetailView of a Behind goal** — clay status line "Behind · by Mar 1, 2027 · $25/wk", ETA pill "1+ year". (Goal rows only say "Behind"; the detail view proves the caption.) | full | THE PACE · EL RITMO | The date<br>is honest. · La fecha<br>no miente. | The ETA comes from real deposits. Behind is shown, not hidden. · La fecha sale de depósitos reales. Si vas atrasado, se ve. |
| 8 | **Home, dark mode** (`-darkModeEnabled YES`), same seeded state as frame 1. | full, dark | AT NIGHT · DE NOCHE | The notebook,<br>under a lamp. · La libreta,<br>de noche. | Dark mode keeps the warmth. Same calm. · El modo oscuro conserva la calidez. La misma calma. |

Order rationale: all three researchers and the judge agree privacy is the stated
differentiator and belongs in the search trio; PPO treatment B tests 1 → 3 → 2
(payday-first) since casual savers may respond more to the active benefit.

**Fictional dataset (2.3.9-safe, one state for all frames; ×10 in MXN for es-MX):**
Goal A "Trip to Oaxaca / Viaje a Oaxaca" target $2,400, saved $1,010 (42%), $500 deposited
inside the last 4 weeks (GoalPace window) → $125/wk, deadline Dec 12 2026 → On track.
Goal B "Laptop" target $1,800, saved $320, $100 in the last 4 weeks → $25/wk, deadline
Mar 1 2027 → Behind, ETA 59 wk → "1+ year". Payday +$1,240, auto-move $150 to Goal A
(keep the ES auto-move under $1,000 until the banner formats thousands). Expense $7.50
Coffee. Receipt "Corner Market" $23.80 dated the capture day. Income July > August so
the trend badge is genuinely negative. Fictional merchants only; no real names.

---

## 4. Alternatives considered (kept for the record)

- **Marginalia (the ruled notebook page).** Same page as above but with a static sprout
  colophon and a "marginal clipping" (a 1.15× pixel crop of one UI row pinned over the
  device corner) on task frames. Best token discipline; lost on distinctness — kicker
  above serif on warm ground with a static mark is the Thirds/Monarch grammar, and the
  clipping reads as a template callout at thumbnail size. Its page composition is what
  we kept.
- **Honest Ledger.** Typography-led: headline + a 216px pull-figure lifted from the
  screen ("$125 /wk", "0 accounts", "−12%") + a frameless full-bleed native crop of one
  hero object; two dark frames (2 and 8). Its "ledger check" rule is what we kept; the
  giant figures pull toward fintech "big number" energy (not Discreet), frameless UI on
  cream is structurally Thirds, and date-sensitive figures make re-shoots brittle.
- Judge scores (fit / distinct / store / voice / producible): Marginalia 5·3·4·4·4 = 20,
  Seed to Sprout 4·4·4·4·4 = 20, Honest Ledger 4·3·3·4·3 = 17 → tie-break on "its own
  style" → Seed to Sprout on Marginalia's page.

---

## 5. Prerequisites (do these before any capture)

1. **Localization of the frames we show.** ~139 catalog entries are en-only, several on
   these exact screens (Log expense/income, Recent, Expenses, Achievements, 7-month
   trend, Scan a receipt), and these are hard-coded English literals: `On track` /
   `Behind` / `1+ year` / `/wk` (GoalPace, GoalDetailView), `Morning/Afternoon/Evening`
   (Dashboard greeting), the auto-move banner text, and date patterns
   (`EEEE · MMMM d`, `MMM d, yyyy` render "mar 12, 2027" in es_MX). Also normalize the
   ~23 old usted/exclamation strings to tú, and "Escanear Recibo" → "Escanear recibo".
   Without this the es-MX set leaks English on frames 1, 3, 6, 7, 8.
2. **Truth gate for "No account. No cloud."** — `Savely/Config.plist` (OPENAI_API_KEY) is
   in the app's Resources build phase even though tips are flagged off: remove it from
   the target (CI already generates a placeholder — adjust) and rotate the key; drop the
   `openai.com` ATS exception from Info.plist; delete the leftover
   `GoogleService-Info.plist`; App Privacy label = "Data Not Collected". Do not write
   "no network" in copy while OpenAIClient is compiled — "No account. No cloud." is as
   far as the claim goes.
3. **iPad:** set `TARGETED_DEVICE_FAMILY = 1` (iPhone-only) or plan a 13" (2064×2752)
   adaptation of the same page.
4. **Seed dataset behind a launch argument** (e.g. `-SavelyScreenshotSeed en|es`): wipes
   and seeds SwiftData with §3's dataset, pins "today" for stable greeting/month/ETA,
   marks Goal A favorite. Never Iván's real data (house rule + 2.3.9). Wipe after.
5. **Capture rig:** iPhone 17 Pro Max simulator (1320×2868 native);
   `xcrun simctl status_bar booted override --time 9:41 --batteryState charged
   --batteryLevel 100 --wifiBars 3 --cellularBars 4`; `-AppleLanguages (es-MX)
   -AppleLocale es_MX` for the ES run; `-darkModeEnabled YES` for frame 8;
   `SavelyUITests/StoreScreenshotTourUITests` (already in the repo) as the driver —
   extend it to the exact frames and read `XCTAttachment`s out with
   `xcrun xcresulttool export attachments`. Capture in the submission week so month
   headers are true; never edit pixels inside a capture.

---

## 6. Production pipeline (for the Opus session)

1. **Composer:** one HTML template (`Design/ScreenshotKit/page.html`, 1320×2868) with
   the tokens as CSS variables, `data-theme="light|dark"`, `copy.json` keyed by locale
   and frame, `stage` 1–8 selecting the SproutMark SVG (traced 1:1 from
   SproutMark.swift: stem `M60 87 C52 76 68 68 60 56`, seed r9 at (60,92), the two leaf
   curves; stem stages via `stroke-dasharray`, leaf stages via scale about (60,56)).
   Device = ink bezel div with `overflow:hidden` and the capture at ×0.72.
2. **Fonts:** render on macOS WebKit so `font-family: ui-serif` → New York and
   `-apple-system` → SF Pro (nothing embedded, nothing licensed for web). Playwright:
   `npx playwright install webkit`; `page.setViewportSize({width:1320,height:2868})`,
   `deviceScaleFactor: 1`, `page.screenshot({type:'png'})`. Check New York's optical
   size at 136px against a SwiftUI reference (`.font(.system(size: 45, design: .serif))`
   at 3×); if WebKit picks a spindlier cut, use the alternative: a tiny SwiftUI
   `ScreenshotComposer` target with `.warmFont`, `Color+Warm` and `SproutMark`, exported
   with `ImageRenderer` at 1320×2868 — same result, zero web fonts. Stand-ins for
   off-Mac previews only (Fraunces opsz 144 / Newsreader Regular + Inter) — never
   sign off line breaks on them.
3. **Export:** 8 PNGs per locale, 1320×2868, sRGB, **no alpha** (`sips -g hasAlpha`;
   flatten with `-background '#f6f4ee' -alpha remove` if needed), named
   `savely-en-US-01-goal.png` … `savely-es-MX-08-night.png`. Upload only the 6.9" slot
   for English (U.S.) and Spanish (Mexico).
4. **Checks before upload:** 25% zoom legibility in both languages; ES two-liners
   ("Los meses malos / también cuentan.", "La libreta, / de noche.") hold at ≥128px;
   hairlines visible in the ASC preview (go 4px, never darker); ledger check on every
   frame; no real merchant/person data; no text cut by the bottom crop.
5. **Later (PPO):** treatment B = full-dark set (all 8 under the lamp; template flips
   with `data-theme`); treatment C = payday-first order (1 → 3 → 2). Keep the header
   grammar ready for the iOS 27 Creative Assets header.

---

## 7. Open questions for Iván (non-blocking)

- Keep iPad support (then an iPad set) or go iPhone-only for the App Store release?
- Frame 2: Profile → Data & privacy (real settings, safest under 2.3.3) vs the
  onboarding "Yours, and only yours" page (prettier, has the sprout) — recommend
  Profile in v1, onboarding as the PPO alternate.
- Any objection to the drawn warm-ink bezel (vs Apple's silver product bezel)? The ink
  bezel keeps "warmth by type and tint, not chrome" and is the same on both themes.
