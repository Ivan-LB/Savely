# Spike — Receipt scanning: where we are, what the industry does, what's free

**Date:** 2026-08-16
**Status:** research complete; phase 1 implemented in PR `feature/receipt-scan-parser` (see §7)
**Scope:** the "Scan a receipt" flow (`Managers/CameraManager`, `Utilities/TextRecognizer`,
`ViewModels/Camera/CameraViewModel`, `Views/Components/CameraScanner/*`).
**Method:** code audit with the extraction code executed verbatim against receipt
fixtures; Apple APIs checked against the local iOS SDK `.swiftinterface` files and
developer.apple.com; industry/vendor claims checked against primary pages; eight
load-bearing claims independently re-verified. Everything marked *unverified* is
labelled as such.

---

## 0. TL;DR

- Today the scanner is **on-device Apple Vision OCR + a fragile string heuristic**.
  The OCR engine is fine; the pipeline around it is not: the photo reaches Vision
  **without its orientation**, with **English-only** recognition, the amount regex
  **drops leading digits** (`1234.56 → 234.56`), totals **under 10 are rejected**
  (a coffee), `SUBTOTAL` counts as "total", the exclusion words are English-only so
  on the standard Mexican layout `TOTAL / EFECTIVO / CAMBIO` the scanner **saves the
  cash tendered, not the total** (fixture: 100.00 instead of 41.18), and the saved
  row is `"Recibo escaneado"` with no merchant, no date, no category.
- The industry (Expensify, Zoho, Wave, Dext, Fetch…) is **cloud OCR + parsers +
  sometimes humans**, and even Expensify says OCR alone lands "around 85%". Every
  cloud option conflicts with Savely's stated promise ("money data lives on the
  phone and never leaves it") and none has a free tier that can back a consumer
  app. **On-device is Savely's differentiator**; a few indie apps market exactly
  that ("no servers, no uploads").
- **Best free option = Apple's own stack, which we already have.** iOS 26 (our
  floor) ships `RecognizeDocumentsRequest` → `DocumentObservation` with lines +
  bounding boxes and `detectedData` that includes **`.moneyAmount` (Decimal +
  currency) and `.calendarEvent` (dates)**; VisionKit gives a document camera
  (perspective correction, auto-capture) and a live scanner with a `.currency`
  content type; Foundation Models is an on-device LLM for structured extraction on
  Apple-Intelligence devices only. Nothing third-party (ML Kit, Tesseract, VLMs,
  cloud receipt APIs) beats it for this app.
- **Plan:** (1) a pure, unit-tested `ReceiptParser` over OCR lines *with geometry*
  (row clustering, receipt amount grammar, es/en label hierarchy + blocklist,
  scoring, merchant, date, category hint) + fix the Vision call (orientation,
  languages, Swift API, single `RecognizeDocumentsRequest`) + lifecycle fixes;
  (2) a Warm Meadow review sheet (editable amount, alternatives, merchant, date,
  category, thumbnail, honest empty state) + gallery import; (3) later, optional
  on-device enhancers (Foundation Models chooser, lens-smudge hint). No cloud.

---

## 1. What we do now (audited 2026-08-16, `dev` @ 61c8aa3)

### 1.1 Flow

Two entry points — the "+" sheet (`MainNavigationView.swift:55-75`, `.fullScreenCover(item:)`)
and the Money-tab banner (`ExpenseTrackerView.swift:58-86`, view model created *inside* the
cover closure) → `CameraView` → `CameraManager.startSession()` (hand-rolled `AVCaptureSession`,
photo output + a video output running `VNDetectRectanglesRequest` on every frame whose result
**nothing draws**) → shutter → `photo.fileDataRepresentation()` → `UIImage(data:)` → `.cgImage`
→ `TextRecognizer` (`VNRecognizeTextRequest`, `.accurate`, **no orientation, no languages**) →
top candidates joined with `\n` (**bounding boxes discarded**) → `CameraViewModel.extractTotalAmount`
→ `TotalConfirmationView` (disabled text field + Yes/No + first-3-regex-hits "alternatives") →
`ExpenseTrackerViewModel.addExpense()` with description `"Recibo escaneado"`, `date: Date()`,
`category: nil`.

### 1.2 Verified failure modes (extraction code run verbatim — `regex_probe.swift`)

| Input | Today | Should be | Cause |
|---|---|---|---|
| `1234.56` | **234.56** | 1234.56 | regex `\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})` is unanchored — leading digits dropped when there is no thousands separator (`CameraViewModel.swift:146`) |
| `SUBTOTAL 12499.00 / IVA 1999.84 / TOTAL 14498.84` | **999.84** | 14498.84 | same bug, then MAX-near-"total" |
| `1.234,56` | discarded | 1234.56 | commas stripped globally → `1.23456` |
| `250`, `TOTAL $250` | nothing | 250 | two decimals mandatory |
| `TOTAL 8.50` (a coffee) | nothing | 8.50 | `amount >= 10` floor (`:116`) |
| OXXO layout `SUBTOTAL 35.50 / IVA 5.68 / TOTAL 41.18 / EFECTIVO 100.00 / CAMBIO 58.82` | **100.00** | 41.18 | picks the MAX within ±3 lines of any line containing "total"; exclusions are English only (`cash/change/tend/debit`) — `EFECTIVO`/`CAMBIO`/`PROPINA`/`IVA`/`SUBTOTAL` are not excluded |
| Restaurant `TOTAL 162.40 / PROPINA 24.36 / TOTAL CON PROPINA 186.76` | 186.76 | 162.40 (+ alternative) | `contains("total")` also matches `SUBTOTAL`, `TOTAL CON PROPINA`, `TOTAL ARTICULOS` |
| Column-split OCR (labels and amounts as separate observations) | SUBTOTAL 35.50 | 41.18 | text is joined in observation order; label and amount are no longer on the same "line" |
| `IVA 16.00%` | 16.00 counted as an amount | ignore | no `%` guard |
| Alternatives | first 3 regex hits (`:163-166`) | ranked candidates | in every fixture above the true total is **not** among them |

Other correctness issues (file:line):

- **Orientation lost:** `UIImage(data:).cgImage` drops EXIF; `VNImageRequestHandler(cgImage:options:)`
  assumes `.up`; the photo connection's rotation is never set from an
  `AVCaptureDevice.RotationCoordinator` (`CameraManagerExtension.swift:16-18`, `TextRecognizer.swift:42`).
  Portrait captures reach OCR rotated. (Mechanism certain; magnitude to confirm on device.)
- **English-only OCR:** no `recognitionLanguages`; language correction left on for a numeric document
  (`TextRecognizer.swift:40`).
- **Silent failure:** no total / no text / Vision error → `print` only; the shutter shows no
  processing state; a failed save through the "+" path shows no alert (`CameraViewModel.swift:85-90`,
  `MainNavigationView.swift:73-75`).
- **Crash path:** shutter enabled with no configured session (permission denied, simulator) →
  `AVCapturePhotoOutput.capturePhoto` on an output without a connection raises an ObjC exception
  (`CameraView.swift:59-66`, `CameraManager.swift:125-128`).
- **Retain cycle:** `.assign(to:on: self)` stored in `self.cancellables` (`CameraViewModel.swift:44-57`)
  → every scan session leaks a `CameraViewModel` + `CameraManager` + `AVCaptureSession`.
- **Wasted work:** rectangle detection at ~30 fps published to a view that never reads it; the
  request is performed from a concurrent queue with a plain `Bool` guard (data race).
- **Dead code:** `Utilities/OCRUtilities.swift` (118 lines, second divergent price regex, unused
  `preprocessImage`).
- **Rules broken:** hardcoded Spanish literal `"Recibo escaneado"` and English literals in
  `CameraView`; `.gray` colours, `RoundedBorderTextFieldStyle`, fixed 300×400 card, `.font(.headline)`
  instead of `.warmFont`, no accessibility labels on shutter/close (PRODUCT.md WCAG-AA commitment;
  DESIGN.md tokens); a **disabled text field showing the amount** ("a dead control is worse than no
  control"); Money-tab banner promises "the total and category" while the scanner never sets a category.
- **Untestable:** all extraction is `private` on a VM that instantiates AVFoundation;
  `SavelyTests` has zero scanner tests.

What is *right* today and must be preserved: everything runs on-device, no network.

---

## 2. How the industry does it

| Product | Technique | UX after capture | Free? | On-device? |
|---|---|---|---|---|
| Expensify SmartScan | OCR + vendor parsers + **human review** when unsure; states OCR alone ≈ 85% | pre-filled expense; "Receipt scanning failed. Enter details manually" | 25 scans/mo | No (2017: receipts seen by MTurk workers) |
| Zoho Expense Autoscan | cloud; date/amount/merchant/currency/payment mode + line items; **remembers category per merchant** | 3 states: scanning / processed / failed-retry-manually; share-sheet import | 20 scans/mo | No |
| Wave, Dext, Shoeboxed | cloud OCR (Shoeboxed adds humans) | "processing" inbox → editable fields → "mark as reviewed" | paid | No |
| Fetch / Ibotta | in-house doc-understanding ML, server-side | best-in-class **capture guidance** (edge guide, lighting tips, long-receipt sections), confirm step | free (they monetise the data) | No |
| Splitwise Pro | cloud; total/date/description | camera-only (no gallery import since 2019), edits were delete-and-recreate | paid | No |
| YNAB, Monefy, Money Manager, Wallet by BudgetBakers | **no OCR** — photo attach at most | — | — | — |
| Apple (Notes, Live Text, iOS 26 Wallet order tracking) | on-device Vision / Apple Intelligence | "tap the text you mean" | built-in | Yes |
| Indie: Recu, "Receipt Scanner & Expense Tracker", Receipts (Nineone), Receipts Space (Mac) | Apple Vision (+ Foundation Models) | highlighted values you tap to confirm; "AI drafts, you decide"; category memory per merchant | one-time / free | **Yes — and they market it** |

Patterns worth copying: framing guide + light/flat tips → capture (auto or shutter) →
visible *processing* state → **editable review form pre-filled with amount, merchant, date,
category** + receipt thumbnail → save; failure falls to "enter it yourself" instead of a dead end;
nobody shows a fake numeric confidence; gallery/share-sheet import is table stakes.
Anti-patterns seen in the field: camera-only capture, non-editable extracted values, auto-save
without confirmation, generic descriptions when the merchant line is right there.

Sources: use.expensify.com/blog/mastering-accuracy-for-receipts; help.expensify.com (SmartScan
troubleshooting); zoho.com/expense/help/expenses/autoscan-receipts; waveapps.com/receipts;
help.dext.com; home.ibotta.com; kb.splitwise.com + feedback.splitwise.com; ynab.com/whats-new;
App Store pages for Recu (id6757321214), Receipts (id1584452416); receipts-app.com/help;
qz.com/1141695 (Expensify/MTurk).

---

## 3. Apple's on-device stack (free, already in the SDK) — verified against `iPhoneOS27.0.sdk` interfaces

| API | Since | What it gives us | Caveat |
|---|---|---|---|
| **`Vision.RecognizeDocumentsRequest` → `DocumentObservation`** | iOS 26 | `document.text.lines: [RecognizedTextObservation]` (with `boundingRegion`, `topCandidates`), `paragraphs`, `tables`, `title`, and **`detectedData: [DataDetectorMatch]`** whose `match.details` includes **`.moneyAmount(amount: Decimal, currency: Locale.Currency)`** and `.calendarEvent`, plus phone/email/address (useful to *exclude* lines from merchant). Options: `recognitionLanguages`, `useLanguageCorrection`, `customWords`, `minimumTextHeightFraction`. Apple's doc names **receipts** as a target. | Forum report (thread 788381): each receipt line becomes its own paragraph and 2-column blocks come back column-by-column → **we must cluster rows ourselves from line boxes**; `tables` rarely appear on thermal receipts. Money detector needs a symbol/code (`$1,234.56`, `MXN 350.00` match; bare `TOTAL 350.00` does **not**) and guesses `$` as the device-region currency → keep a numeric grammar. Perf numbers unpublished. |
| `Vision.RecognizeTextRequest` (Swift API) | iOS 18 | async, `recognitionLanguages: [Locale.Language]`, `supportedRecognitionLanguages` (query at runtime — Spanish + English are supported for `.accurate`), `usesLanguageCorrection`, `customWords`, `perform(on:orientation:)` | Fallback if the document request returns nothing. |
| `DataDetection.DataDetector` / `String.dataDetectorMatches(.moneyAmount)` | iOS 26 | modern NSDataDetector with money + dates + `Options(documentRegion:)` | same symbol requirement |
| **`VisionKit.VNDocumentCameraViewController`** | iOS 13 | edge detection, auto-capture, perspective correction, multi-page; returns `VNDocumentCameraScan.imageOfPage(at:)` upright | zero theming (system chrome, not Warm Meadow); iOS 26 UI regression reports; `isSupported == false` in Simulator |
| `VisionKit.DataScannerViewController` `.text(textContentType: .currency)` | iOS 16 / currency iOS 17 | live "tap the amount" mode; A12+ (every iOS 26 iPhone) | only symbol-tagged amounts, no merchant/date; system highlights |
| `Vision.DetectLensSmudgeRequest` | iOS 26 | 0–1 smudge confidence (Apple sample threshold 0.9) → "wipe your lens" hint | A14+ only (not iPhone 11/SE2) → `try?` |
| **`FoundationModels.SystemLanguageModel`** | iOS 26 | ~3B on-device LLM, `@Generable` constrained decoding, `availability` = `.available` / `.unavailable(.deviceNotEligible \| .appleIntelligenceNotEnabled \| .modelNotReady)`, ~4096-token context, Spanish supported | iPhone 15 Pro/16-family and later **only** — many LatAm users get `.deviceNotEligible`; text-only on iOS 26 (image `Attachment` and Private Cloud Compute are iOS 27, and PCC leaves the phone); can hallucinate numbers → may only *choose among* OCR candidates |
| `PhotosUI.PhotosPicker` | iOS 16 | gallery import with **no** photo-library permission string; also the Simulator/QA path | — |
| `VisionKit.ImageAnalysisInteraction` (Live Text) | iOS 16 | user selects the total by touch on the photo | UIKit interaction; optional polish |

Verified locally: `DocumentObservation`, `DataDetector.Match.SemanticDetails.moneyAmount`,
`DataScannerViewController.TextContentType.currency (iOS 17)`, `SystemLanguageModel.Availability`
all present in the iOS SDK shipped with Xcode 27 beta; baseline `xcodebuild build` passes on
iPhone 17 Pro simulator. Empirical DataDetection runs on macOS 27 beta (not an iOS 26 device):
`"$1,234.56" → MXN 1234.56` (device region), `"Total MXN 350.00" → MXN 350`,
`"IMPORTE 1.234,56 €" → EUR 1234.56`, `"TOTAL 1,234.56" → no match`, `"14/08/2026 15:32" → calendarEvent`.

---

## 4. Free / open-source / third-party options — evaluated against "never leaves the phone"

| Option | Cost | On-device | Verdict |
|---|---|---|---|
| **Apple Vision (+ iOS 26 document/money detection)** | free, 0 MB | yes | **Adopt** — already the engine; the gap is orientation/languages/parser |
| **Own `ReceiptParser` porting proven OSS heuristics** (receipt-parser-core, tinvois-parser: keyword tables, first-after-keyword vs max-in-window, merchant list, date regex set) | free | yes | **Adopt** as concepts (not code) |
| **Apple Foundation Models** | free | yes (AI-eligible devices) | **Later** (phase 3), as a chooser over candidate IDs with heuristic fallback |
| Google ML Kit Text Recognition v2 (iOS) | free, +~38 MB, CocoaPods | yes, but SDK **sends usage metrics to Google** (terms) | Reject — no accuracy edge on receipts, telemetry conflicts with premise |
| Tesseract (SwiftyTesseract archived 2022, gali8 = Tesseract 3.03) | free | yes | Reject — unmaintained, worst accuracy on phone photos |
| PaddleOCR / RapidOCR via ONNX / Paddle-Lite | free | yes | Reject — C++ bridge + model conversion for no gain over Vision |
| Core ML KIE models (LayoutLMv3 CC-BY-NC, Donut MIT ~200M params) | free weights | yes | Reject — licence / weeks of conversion / English-only training data |
| Small on-device VLMs (LFM2-VL, SmolVLM, Qwen2-VL 2B via MLX/LEAP; FastVLM is research-only) | free | yes | Reject for now — 1–2 GB download, 1.3–3 GB RAM, 5–10 s/receipt; superseded by Foundation Models |
| Azure Document Intelligence prebuilt-receipt | F0 500 pages/mo (shared by all users) | **no** | Reject — off-device, needs key + proxy |
| Google Document AI Expense, AWS Textract AnalyzeExpense | ~$0.01/page, trial-only free tiers | no | Reject |
| Mindee (free plan discontinued 2025), Veryfi (100/mo, $500 min paid), Taggun (trial), Klippa, Nanonets | business pricing | no | Reject |
| OpenAI gpt-5-nano / gpt-4.1-nano vision (~$0.0001–0.0004 per receipt) | cheap | no | **Not in the default build.** Only conceivable as an explicit per-scan opt-in behind a proxy after rewording the onboarding promise. Note: `Config.plist` (with the OpenAI key) is *currently copied into the app bundle* as a resource even though tips are flagged off — pre-existing issue to fix separately, independent of this spike. |
| Gemini free tier | free but **trains on your data** | no | Reject |

Public datasets for offline evaluation: SROIE (1,000 English scanned receipts, GT
company/date/address/total; free registration), CORD (Indonesian, CC-BY-4.0, labels subtotal vs
total vs cash/change), WildReceipt (1,740 in-the-wild English receipts, Apache-2.0),
ExpressExpense SRD (200 restaurant receipts, MIT, no field GT). **There is no public Spanish/Mexican
receipt dataset** — Savely must build its own anonymized fixture set. Repo is public → fixtures are
JSON OCR dumps only (no images), with PII lines (RFC, phone, address, card, names) stripped.

Reported accuracy for context: SROIE Task-3 winner at competition time was lexicon + regex rules
(90.5% F1); fine-tuned LayoutLMv3 ≈ 96.9%; naive LLM prompting ≈ 79–82%; hobby text-only rule
parsers ≈ 63% on totals. → **Layout-aware rules are competitive; LLMs help most as a chooser over
structured candidates.**

---

## 5. Extraction heuristics we will implement (all deterministic, unit-tested)

1. **Rows** = OCR lines clustered by vertical overlap of their boxes (≥ 50 % of line height),
   sorted left→right; a row's text is its lines joined by spaces. Never trust observation order.
2. **Amount grammar** (receipt-specific — deliberately different from `AmountParsing.parseAmount`,
   which rejects thousands separators for *typed* input): word-bounded tokens
   `[$MX$USD]? 1,234.56 | 1.234,56 | 1234.56 | 1234 | 8.50 | 8,50`; per-token separator
   inference (a `,` followed by exactly 3 digits and then `.dd` is a thousands separator;
   `1.234,56` is decimal-comma); OCR confusions normalized only inside amount tokens
   (`O→0, l/I→1, S→5, B→8`); tokens followed by `%` ignored; date/time-like and long digit
   runs (RFC, card, ticket numbers) ignored; currency token captured as a *hint*.
   Ambiguous tokens surface as alternatives — never silently pick a ×100/×1000 reading.
3. **Candidate scoring** for the total (each amount gets a score):
   - label class on the same row (or the row directly above when the row has no label):
     strong positive `TOTAL`, `TOTAL A PAGAR`, `IMPORTE TOTAL`, `IMPORTE`, `GRAN TOTAL`,
     `GRAND TOTAL`, `AMOUNT DUE`, `BALANCE DUE`, `TOTAL MXN|USD`, `TOTAL VENTA`;
     strong negative `SUBTOTAL`/`SUB-TOTAL`/`SUB TOTAL`, `IVA`/`IEPS`/`TAX`/`VAT`,
     `PROPINA`/`TIP`/`GRATUITY`, `EFECTIVO`/`CASH`, `CAMBIO`/`CHANGE`, `TARJETA`/`CARD`/`VISA`/
     `MASTERCARD`/`DEBITO`/`CREDITO`, `PAGO`/`TENDERED`/`RECIBIDO`/`SU PAGO`, `PUNTOS`,
     `AHORRO`/`SAVINGS`/`DESCUENTO`/`DISCOUNT`, `TOTAL ARTICULOS`/`ITEMS`, `TOTAL CON PROPINA`
     (kept as an alternative);
   - bottom-most among total-labelled rows (+), member of the right-aligned amount column (+),
     math consistency `subtotal + taxes == x` or `cash − change == x` (+), text height above
     the receipt median (+), largest plausible non-excluded amount (small +), duplicate value
     elsewhere (card charge repeats the total) (+).
   - Output: best candidate + ranked alternatives + a `confidence` (high/medium/low from the
     score gap). Low confidence → the review sheet says so and focuses the amount.
4. **Dual-currency border receipts** (`TOTAL MXN … / TOTAL USD … / TIPO DE CAMBIO`): prefer the row
   whose currency matches `Locale.current.currency`; the other becomes the first alternative.
5. **Merchant** = most prominent (tallest / top-most / centred) row among the top ~25 % that is not a
   date, phone, address, RFC, URL, or a label; brand dictionary + razón-social map
   (`CADENA COMERCIAL OXXO → OXXO`, `NUEVA WAL MART DE MEXICO → Walmart`, `TIENDAS SORIANA → Soriana`,
   Costco, HEB, Chedraui, Calimax, Smart & Final, 7-Eleven, Starbucks, Uber Eats, Rappi, DiDi Food,
   Pemex, Farmacias …). Written to `expenseDescription` (no schema change).
6. **Date** = `dd/mm/yyyy`, `dd-mm-yy`, `yyyy-mm-dd`, `dd/MMM/yyyy`, `d MMM yyyy` with es/en month
   names, preferring a row that also carries a time or a `FECHA`/`DATE` label; day/month order
   resolved by `>12` first, then by language signal (Spanish labels/`IVA` ⇒ dd/mm; en-US ⇒ mm/dd);
   rejected if in the future or older than 2 years → today, flagged for confirmation.
7. **Category hint** from merchant/keywords onto the five stored chips (`Coffee`, `Food`,
   `Transit`, `Shopping`, `Other`) — pre-selects the chip; the user's tap wins.
8. **Evaluation:** JSON fixtures `{id, locale, source, lines:[{text, box, confidence}], expected}`
   under `SavelyTests/Fixtures/Receipts/`, one parametrized XCTest reporting per-field hits.
   Phase-1 fixtures are hand-authored layouts (OXXO, restaurant + tip, Costco no-separator, US
   cash/change, column-split, comma-decimal, whole-peso, sub-10) — **they prove behaviour, not
   real-world accuracy**. A DEBUG-only "Export OCR dump" action in the review sheet lets the owner
   collect real anonymized fixtures; only then are accuracy numbers meaningful. Never fabricate.

---

## 6. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | **All on-device. No cloud path in the default build.** | PRODUCT.md promise; Expensify/MTurk precedent; free tiers cannot back a consumer app; a shipped key is a security issue. |
| D2 | **Single `RecognizeDocumentsRequest` per capture** (`recognitionLanguages` resolved at runtime from `supportedRecognitionLanguages` → Spanish + English variants; `useLanguageCorrection = false` for a numeric document; `customWords` = label vocabulary), **orientation always passed**, fallback `RecognizeTextRequest`. Rows are clustered by us from `text.lines`; `detectedData` money/date are extra candidate sources, not the truth. | One OCR pass, geometry + detectors from one API on our iOS 26 floor. Correction on/off to be A/B'd once real fixtures exist. |
| D3 | **Pure `ReceiptParser` in `Utilities/`, XCTest fixtures, no Vision/UI dependency** (input = `[OCRLine]`). | Testable on CI simulators without a camera; house style (`GoalPace`, `AutoMoveSuggestion`). |
| D4 | **No SwiftData schema change now.** merchant → `expenseDescription`; receipt date → `ExpenseModel.date` when unambiguous; category → chip; currency shown as a hint only, not stored. Receipt image is **not persisted** (discarded after save). | Zero migration risk; the app has no currency concept yet (every formatter hardcodes `$`) — that is a separate product decision. |
| D5 | **Capture: keep the Warm Meadow custom camera** (fix rotation via `RotationCoordinator`, guard the shutter, remove the unused per-frame rectangle detection, add torch + gallery import) **and ship `VNDocumentCameraViewController` behind `FeatureFlags.useSystemDocumentCamera` (default off)** so the owner can A/B on a real device (Simulator cannot run either camera). | Perspective correction likely improves OCR, but the system sheet breaks Warm Meadow and cannot be evaluated here; both feed the same pipeline. |
| D6 | **Review sheet replaces `TotalConfirmationView`**: thumbnail, editable amount (WarmKeypad), alternative chips, merchant field, date, category chips, "We read this — is it right?" copy, "no clear total" state that focuses the amount and never dead-ends; processing state; single in-flight scan; all strings localizable, `.warmFont`, a11y labels. | Industry pattern; PRODUCT.md principles 1 & 3; DESIGN.md tokens. |
| D7 | Foundation Models, `DetectLensSmudgeRequest`, `DataScannerViewController` live mode, merchant→category memory, line items: **out of this PR** (phase 3 / backlog). | Cannot be tested on the available hardware; parser must be measured first. |
| D8 | Deployment target stays iOS 26.0. | Just set; iOS 27-only APIs are not planned on. |

Open questions for the owner (do not block phase 1): keep custom camera vs system document camera
after a device check; whether to add a currency concept to the app; usesLanguageCorrection A/B on
real fixtures; whether a small thumbnail should ever be stored.

---

## 7. Plan

- **Phase 1 (this PR)** — parser + pipeline correctness + review UX:
  `Utilities/Receipt/{OCRLine, ReceiptAmount, ReceiptParser, ReceiptVocabulary, ReceiptDates,
  ReceiptMerchant}`, `Utilities/ReceiptOCR.swift` (Vision, orientation, languages),
  `ViewModels/Camera/ReceiptScanModel.swift` (@Observable, @MainActor; owns capture → processing →
  review; single in-flight scan), `Views/Components/CameraScanner/{CameraView, CameraPreview,
  ReceiptReviewSheet, DocumentCameraView}`, `CameraManager` fixes, delete `OCRUtilities.swift` +
  `TotalConfirmationView.swift`, both entry points migrated, banner/onboarding copy made true,
  `SavelyTests/ReceiptParserTests.swift` + `Fixtures/Receipts/*.json`, docs (this file,
  `CLAUDE.md` invariant 7 correction, `gotchas.yaml`).
  Verification: 16 hand-authored fixtures + unit tests for the grammar/dates/labels/rows,
  and `ReceiptOCRIntegrationTests` running the real Vision pipeline on a script-rendered
  receipt image (reads total 57.50, merchant, date, subtotal alternative; and the same
  bitmap rotated + tagged sideways still reads — the orientation fix). Manual review found
  and fixed: TOTAL rows demoted by IVA/PAGADO/TARJETA words, masked card digits offered as
  alternatives, column headers lending IMPORTE to the first item, "2 MARGARITAS 26.00"
  parsing as a date, detector fallbacks bypassing plausibility rules, session/torch left
  running behind the review, VoiceOver reaching the camera under overlays.
- **Phase 2** — owner collects ~30 real es-MX/US OCR dumps with the DEBUG export → commit
  anonymized fixtures → tune weights, A/B language correction, decide camera surface.
- **Phase 3** — optional on-device enhancers: Foundation Models chooser (candidate IDs only,
  gated on `SystemLanguageModel.default.availability`, timeout, labelled as a draft),
  lens-smudge hint (A14+), merchant→category memory.

---

## 8. Sources (primary)

Apple: developer.apple.com/documentation/vision/recognizedocumentsrequest ·
…/vision/documentobservation · …/datadetection/datadetector/match/semanticdetails/moneyamount ·
…/vision/recognizetextrequest · …/visionkit/vndocumentcameraviewcontroller ·
…/visionkit/datascannerviewcontroller/textcontenttype/currency · …/vision/detectlenssmudgerequest ·
…/foundationmodels/systemlanguagemodel · …/foundationmodels/managing-the-context-window ·
WWDC25 272 "Read documents using the Vision framework" · WWDC25 286/301 (Foundation Models) ·
WWDC23 10048 (VisionKit currency) · support.apple.com/121115 (Apple Intelligence devices/languages) ·
developer.apple.com/forums/thread/788381 (RecognizeDocumentsRequest on receipts).
Industry/vendors: see §2; pricing pages: developers.openai.com/api/docs/pricing,
ai.google.dev/gemini-api/docs/pricing, azure.microsoft.com (Document Intelligence),
aws.amazon.com/textract/pricing, docs.mindee.com/account-management/plans, faq.veryfi.com,
taggun.io/pricing, developers.google.com/ml-kit/terms + ios-data-disclosure.
Datasets/heuristics: rrc.cvc.uab.es/?ch=13 (SROIE), github.com/clovaai/cord, WildReceipt (MMOCR),
expressexpense.com SRD, arxiv 2103.10213 (SROIE report), arxiv 2303.05063 (ICL-D3IE),
github.com/ReceiptManager/receipt-parser-legacy, github.com/knipknap/receiptparser.
