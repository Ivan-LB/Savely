//
//  ReceiptAmountGrammar.swift
//  Savely
//
//  Reads money amounts out of OCR'd receipt text. Deliberately NOT the same
//  grammar as `parseAmount` (AmountParsing.swift): that one parses what the
//  user types and rejects thousands separators; a printed receipt uses them
//  all the time ("1,250.00") and OCR adds its own noise ("1O0.00", "S 41.18").
//  Every guess this file makes is a *candidate* the user confirms on the
//  review sheet — never something saved silently.
//

import Foundation

/// A money amount found in a row of receipt text.
struct ReceiptAmountToken: Equatable {
    var value: Double
    /// True when the token carried decimals ("41.18"), false for "250".
    var hasDecimals: Bool
    /// "MXN", "USD", … when a symbol or code sat next to the number, else nil.
    var currency: String?
    /// True when ANY marker sat next to the number — including a bare "$",
    /// which names no currency but does say "this is money".
    var hasCurrencyMarker: Bool
    /// True when the separators could be read more than one way and we
    /// picked the most likely reading (surface as an alternative, not truth).
    var isAmbiguous: Bool
    /// True when the number was preceded by a minus sign or wrapped in
    /// parentheses — a discount or refund line.
    var isNegative: Bool
    /// The whitespace-token index within the row, for left/right ordering.
    var tokenIndex: Int
}

enum ReceiptAmountGrammar {
    /// Longest digit run allowed in an amount. Ticket numbers, RFCs, card
    /// numbers and barcodes are longer.
    static let maxIntegerDigits = 7

    /// Currency markers that may be glued to or sit next to a number.
    /// Value: ISO code the marker implies (nil for the ambiguous "$").
    private static let currencyMarkers: [(marker: String, code: String?)] = [
        ("MXN", "MXN"), ("MX$", "MXN"), ("M.N.", "MXN"), ("MN", "MXN"), ("PESOS", "MXN"),
        ("USD", "USD"), ("US$", "USD"), ("DLLS", "USD"), ("DLS", "USD"), ("DOLARES", "USD"), ("DOLLARS", "USD"),
        ("EUR", "EUR"), ("€", "EUR"), ("$", nil), ("S/", nil),
    ]

    /// Amounts in `rowText`, left to right. Date/time spans and percentages
    /// are skipped first so "16/08/2026 12:34" or "IVA 16.00%" never yield
    /// numbers.
    static func amounts(in rowText: String) -> [ReceiptAmountToken] {
        let cleaned = spaced(ReceiptDateParser.removingDateAndTimeSpans(from: rowText))
        let tokens = cleaned.replacingOccurrences(of: "\t", with: " ").split(separator: " ").map(String.init)
        var found: [ReceiptAmountToken] = []
        var pendingCurrency: String?? = nil // a bare marker ("$", "MXN") waiting for the next number
        var pendingMinus = false            // a standalone "-" waiting for the next number

        for (index, rawToken) in tokens.enumerated() {
            let token = rawToken.trimmingCharacters(in: CharacterSet(charactersIn: ":;,.()[]"))
            if token.isEmpty { continue }
            // Percentages are never money.
            if rawToken.hasSuffix("%") || (index + 1 < tokens.count && tokens[index + 1] == "%") { continue }

            if let markerOnly = currencyMarkerOnly(token) {
                pendingCurrency = .some(markerOnly)
                continue
            }
            if rawToken == "-" || rawToken == "−" {
                pendingMinus = true
                continue
            }

            var body = token
            var currency: String? = nil
            var sawMarker = false
            if let (stripped, code) = strippingCurrencyMarker(from: body) {
                body = stripped
                currency = code
                sawMarker = true
            }
            if !sawMarker, let pending = pendingCurrency {
                currency = pending
                sawMarker = true
            }
            // "350.00 MXN": the marker may follow the number.
            if !sawMarker, index + 1 < tokens.count, let trailing = currencyMarkerOnly(tokens[index + 1]) {
                currency = trailing
                sawMarker = true
            }
            pendingCurrency = nil

            var isNegative = pendingMinus
            pendingMinus = false
            if body.hasPrefix("-") || body.hasPrefix("−") { body.removeFirst(); isNegative = true }
            if body.hasSuffix("-") || body.hasSuffix("−") { body.removeLast(); isNegative = true }
            if rawToken.hasPrefix("(") && rawToken.hasSuffix(")") { isNegative = true }
            body = body.trimmingCharacters(in: CharacterSet(charactersIn: ":;,.()[]"))

            // Trailing letters glued to the number ("41.18MXN") were handled
            // above; anything else attached means it is not an amount.
            guard let parsed = parseNumber(body) else { continue }
            // "12.00 -" — a trailing standalone minus after the number.
            if index + 1 < tokens.count, tokens[index + 1] == "-" || tokens[index + 1] == "−" { isNegative = true }
            found.append(ReceiptAmountToken(
                value: parsed.value,
                hasDecimals: parsed.hasDecimals,
                currency: currency,
                hasCurrencyMarker: sawMarker,
                isAmbiguous: parsed.isAmbiguous,
                isNegative: isNegative,
                tokenIndex: index
            ))
        }
        return found
    }

    /// Puts whitespace around the characters that OCR glues to numbers
    /// ("TOTAL:$41.18" → "TOTAL: $ 41.18") so whitespace tokenizing sees the
    /// number on its own. Two-letter currency prefixes are rewritten to
    /// their ISO code first so the "$" split does not lose them.
    static func spaced(_ text: String) -> String {
        var out = text
            .replacingOccurrences(of: "MX$", with: " MXN ")
            .replacingOccurrences(of: "US$", with: " USD ")
        for glyph in ["$", "€", ":", "=", "*", "#"] {
            out = out.replacingOccurrences(of: glyph, with: " \(glyph) ")
        }
        return out
    }

    // MARK: - Number parsing

    struct ParsedNumber: Equatable {
        var value: Double
        var hasDecimals: Bool
        var isAmbiguous: Bool
    }

    /// Parses one whitespace token that should be a bare number. Accepts
    /// "1,234.56", "1.234,56", "1234.56", "1234", "8.50", "8,50", "12.5",
    /// "1,234" (→ 1234, ambiguous). Fixes OCR letter/digit confusion only
    /// when the token is mostly digits already. Rejects long digit runs
    /// (ticket numbers), letters, and anything with more than two separator
    /// kinds.
    static func parseNumber(_ raw: String) -> ParsedNumber? {
        guard !raw.isEmpty else { return nil }
        let normalized = normalizeDigits(raw)
        let allowed = CharacterSet(charactersIn: "0123456789.,")
        guard normalized.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        let digits = normalized.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        // Must start and end with a digit ("1,234.56", not ".56" or "1,")
        guard let first = normalized.first, first.isNumber, let last = normalized.last, last.isNumber else { return nil }

        let commaCount = normalized.filter { $0 == "," }.count
        let dotCount = normalized.filter { $0 == "." }.count

        // No separators: a whole amount.
        if commaCount == 0 && dotCount == 0 {
            guard digits.count <= maxIntegerDigits, let value = Double(digits) else { return nil }
            return ParsedNumber(value: value, hasDecimals: false, isAmbiguous: false)
        }

        // Both kinds present: the LAST separator is the decimal one.
        if commaCount > 0 && dotCount > 0 {
            guard let lastComma = normalized.lastIndex(of: ","), let lastDot = normalized.lastIndex(of: ".") else { return nil }
            let decimalSep: Character = lastComma > lastDot ? "," : "."
            let thousandsSep: Character = decimalSep == "," ? "." : ","
            // Exactly one decimal separator; the other kind groups thousands.
            guard normalized.filter({ $0 == decimalSep }).count == 1 else { return nil }
            let parts = normalized.split(separator: decimalSep, omittingEmptySubsequences: false)
            guard parts.count == 2 else { return nil }
            let intPart = String(parts[0]), fracPart = String(parts[1])
            guard (1...2).contains(fracPart.count) else { return nil }
            guard validThousandsGroups(intPart, separator: thousandsSep) else { return nil }
            let intDigits = intPart.filter(\.isNumber)
            guard intDigits.count <= maxIntegerDigits, let value = Double(intDigits + "." + fracPart) else { return nil }
            return ParsedNumber(value: value, hasDecimals: true, isAmbiguous: false)
        }

        // One kind of separator.
        let sep: Character = commaCount > 0 ? "," : "."
        let count = commaCount > 0 ? commaCount : dotCount
        let parts = normalized.split(separator: sep, omittingEmptySubsequences: false).map(String.init)
        guard parts.allSatisfy({ !$0.isEmpty }) else { return nil }

        if count == 1 {
            let intPart = parts[0], tail = parts[1]
            switch tail.count {
            case 1, 2:
                // "12.5", "41.18", "12,50" → decimal
                guard intPart.count <= maxIntegerDigits, let value = Double(intPart + "." + tail) else { return nil }
                return ParsedNumber(value: value, hasDecimals: true, isAmbiguous: false)
            case 3:
                // "1,234" / "1.234" → almost always a thousands group on a receipt.
                guard intPart.count <= 3, let value = Double(intPart + tail) else { return nil }
                return ParsedNumber(value: value, hasDecimals: false, isAmbiguous: true)
            default:
                return nil
            }
        }

        // Several of the same separator: thousands groups ("1.234.567").
        guard validThousandsGroups(normalized, separator: sep) else { return nil }
        guard digits.count <= maxIntegerDigits, let value = Double(digits) else { return nil }
        return ParsedNumber(value: value, hasDecimals: false, isAmbiguous: true)
    }

    private static func validThousandsGroups(_ text: String, separator: Character) -> Bool {
        let groups = text.split(separator: separator, omittingEmptySubsequences: false)
        guard let head = groups.first, (1...3).contains(head.count) else { return false }
        return groups.dropFirst().allSatisfy { $0.count == 3 }
    }

    /// Maps the classic OCR confusions to digits, but only when the token
    /// is already mostly numeric — "SOL" stays a word, "1O0.00" becomes
    /// "100.00".
    static func normalizeDigits(_ raw: String) -> String {
        let confusable: [Character: Character] = ["O": "0", "o": "0", "l": "1", "I": "1", "S": "5", "B": "8", "Z": "2"]
        let digitCount = raw.filter(\.isNumber).count
        let letters = raw.filter(\.isLetter)
        // At least one real digit, every letter must be a known confusion,
        // and letters may not outnumber digits by more than two ("3S.OO" is
        // fixed; "SOL", "1ST" and "IVA" are left alone).
        guard digitCount >= 1, !letters.isEmpty, letters.allSatisfy({ confusable[$0] != nil }),
              letters.count <= digitCount + 2 else { return raw }
        return String(raw.map { confusable[$0] ?? $0 })
    }

    // MARK: - Currency markers

    /// "$", "MXN", "USD" on their own → the code they imply (nil for "$").
    private static func currencyMarkerOnly(_ token: String) -> String?? {
        let upper = token.uppercased()
        for entry in currencyMarkers where entry.marker == upper {
            return .some(entry.code)
        }
        return nil
    }

    /// Strips a currency marker glued to the number ("$41.18", "41.18MXN",
    /// "MX$1,250.00"). Returns the bare number and the implied code.
    private static func strippingCurrencyMarker(from token: String) -> (String, String?)? {
        let upper = token.uppercased()
        // "S41.18": Vision's usual misread of a glued "$" — a lone leading S
        // followed by a decimal amount is the peso sign, not a 5.
        if upper.hasPrefix("S"), token.count > 3 {
            let rest = String(token.dropFirst())
            if let first = rest.first, first.isNumber, rest.contains(".") || rest.contains(",") {
                return (rest, nil)
            }
        }
        for entry in currencyMarkers {
            if upper.hasPrefix(entry.marker) {
                let stripped = String(token.dropFirst(entry.marker.count))
                if !stripped.isEmpty { return (stripped, entry.code) }
            }
            if upper.hasSuffix(entry.marker) {
                let stripped = String(token.dropLast(entry.marker.count))
                if !stripped.isEmpty { return (stripped, entry.code) }
            }
        }
        return nil
    }
}
