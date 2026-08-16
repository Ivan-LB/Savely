# Product

## Register

product

## Users

Casual savers — young adults who want a simple place for goals and everyday
money, open the app for a few seconds a day, and are not finance
enthusiasts. Primary market is Mexico / LatAm and US; UI is written in
English first and translated to es-419.

They use it in ordinary moments: after a purchase, on payday, at the end of
the week. The job is "put this movement down and see where my goal stands"
— never analysis, never a session.

## Product Purpose

Savely is a local-first personal savings app for iOS: goals with a real
pace, income and expense logging, receipt scanning, and a payday
"auto-move" that turns income into savings with one tap. **No accounts, no
cloud, no bank connections** — money data lives on the phone and never
leaves it. That premise is stated out loud in onboarding and is a feature,
not a limitation.

Success is a saver who keeps logging because the app never lies to them
(headers say the real month, trends show drops, totals mean what they say)
and never nags them.

## Brand Personality

**Warm · Patient · Discreet.**

Like a well-made notebook: it accompanies without pushing. Serif display
type, soft tinted tiles, a sprout mark that grows. Achievements exist but
are quiet — real states from real data, no confetti, no streak pressure.
Voice is plain and honest ("Enter a valid amount greater than zero", not
"Oops!").

## Anti-references

- **Bank fintech** (Nu, Revolut, BBVA): purple/neon, balance cards,
  trading-style charts, the feeling of a bank.
- **Generic SaaS dashboard**: KPI grid, identical cards, pie charts.
- **Cold spreadsheet / accountant**: dense tables, gray on white, no
  warmth.

Not an anti-reference but a boundary: gamification is allowed only in the
quiet form already shipped (AchievementEngine states). No Duolingo
mechanics.

## Design Principles

1. **Never lie with a number.** Labels and figures must agree; bad news is
   shown, not hidden. Honesty over comfort.
2. **Local-first is content, not absence.** No account ≠ empty profile.
   Everything the app knows lives in SwiftData; surface it.
3. **A dead control is worse than no control.** Empty closures, one-way
   toggles, and switches that change nothing are removed or made real —
   never left as decoration.
4. **Warmth is carried by type and tint, not by chrome.** Serif display,
   soft tiles, 1px hairlines. No shadows-as-depth, no glass, no gradients.
5. **Patient by default.** One short entrance per screen, damping ≥ 0.9,
   no bounce. Reduce Motion means instant.

## Accessibility & Inclusion

Target **WCAG AA, formally, across the whole app** — not only new
surfaces:

- Text contrast ≥ 4.5:1 (body) / ≥ 3:1 (large) in **both** color schemes.
- Dynamic Type respected on every screen (no fixed `.system(size:)` that
  clips at accessibility sizes).
- **VoiceOver on every flow**, not just the critical ones: every control
  has a label, every custom row has a trait, every toggle announces its
  state, decorative images are hidden.
- Reduce Motion honored (already the house rule for onboarding; extend
  everywhere).
- Both es-419 and en must pass; string length differences must not break
  layouts.
