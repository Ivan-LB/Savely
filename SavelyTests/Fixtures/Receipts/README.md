# Receipt parser fixtures

Each `*.json` is one OCR dump run through `ReceiptParser` by
`ReceiptFixtureTests`:

```json
{
  "id": "oxxo-cash",
  "source": "hand-authored OXXO-style thermal ticket (not a real receipt)",
  "locale": "es_MX",
  "now": "2026-08-16T12:00:00Z",
  "lines": [{ "text": "TOTAL", "box": { "x": 0.05, "y": 0.37, "width": 0.45, "height": 0.022 }, "confidence": 1 }],
  "expected": { "total": 41.18, "alternativesInclude": [35.5], "merchant": "OXXO",
                "date": "2026-08-14", "category": "Food", "confidence": "high" }
}
```

- `box` is normalized, origin top-left (what `ReceiptOCR` produces).
- Every `expected` key is optional; only the keys present are asserted.
- **`source` must say where the fixture came from.** The current set is
  hand-authored (layouts written to pin behaviour) — it proves rules, not
  real-world accuracy.
- Real receipts: use the DEBUG-only "Export OCR dump" button on the review
  screen, then **strip PII before committing** (RFC, phone, address, card
  digits, names, ticket/folio ids). JSON only — never commit receipt images.
