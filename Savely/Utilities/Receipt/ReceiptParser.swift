//
//  ReceiptParser.swift
//  Savely
//
//  Turns OCR lines (text + boxes) into a draft expense: the most likely
//  total, the other amounts worth offering, the merchant, the printed date
//  and a category hint. Pure and deterministic — every rule here is covered
//  by ReceiptParserTests over JSON fixtures, and every output is a
//  *suggestion* the review sheet shows the user before anything is saved.
//
//  Pipeline: lines → rows (clustered by vertical overlap, sorted left→right)
//  → amount candidates per row (ReceiptAmountGrammar) → label class per row
//  (ReceiptVocabulary) → score → pick + rank alternatives → merchant / date /
//  category from the same rows.
//

import Foundation

/// One amount the parser considered, with why it scored the way it did.
struct ReceiptCandidate: Equatable {
    var value: Double
    var currency: String?
    /// The text of the row it was found on — shown as context for alternatives.
    var rowText: String
    var rowIndex: Int
    var label: ReceiptLabelClass
    var score: Double
}

/// What the parser thinks about its own answer.
enum ReceiptConfidence: Equatable {
    /// A total-labelled amount with a clear margin.
    case high
    /// A total-labelled amount, but another candidate is close.
    case medium
    /// No total label found — best guess from position/size only.
    case low
    /// No amount at all.
    case none
}

struct ReceiptDraft: Equatable {
    var total: ReceiptCandidate?
    /// Other amounts, best first, distinct values, never the chosen total.
    var alternatives: [ReceiptCandidate]
    var confidence: ReceiptConfidence
    var merchant: String?
    /// The date printed on the receipt when one plausible date was found.
    var date: Date?
    /// "MXN" / "USD" when the receipt said so; nil otherwise.
    var currencyHint: String?
    var categoryHint: ExpenseCategory?
    /// Rows as the parser saw them (top→bottom), for debugging and fixtures.
    var rows: [String]

    static let empty = ReceiptDraft(total: nil, alternatives: [], confidence: .none, merchant: nil,
                                    date: nil, currencyHint: nil, categoryHint: nil, rows: [])
}

enum ReceiptParser {
    /// A visual row of the receipt.
    struct Row: Equatable {
        var index: Int
        var text: String
        var normalized: String
        var box: OCRBox
        var lineHeight: Double
        var amounts: [ReceiptAmountToken]
        var label: ReceiptLabelClass
    }

    /// Two lines are on the same row when their boxes overlap vertically by
    /// at least this fraction of the shorter one.
    static let rowOverlapThreshold = 0.5
    /// Amounts above this are ticket numbers, not purchases, for this app.
    static let maxPlausibleTotal: Double = 500_000
    /// Alternatives offered on the review sheet.
    static let maxAlternatives = 4

    // MARK: - Entry point

    static func parse(
        lines: [OCRLine],
        now: Date = Date(),
        locale: Locale = .current,
        calendar: Calendar = .current
    ) -> ReceiptDraft {
        let rows = buildRows(from: lines)
        guard !rows.isEmpty else { return .empty }

        let candidates = scoreCandidates(rows: rows, locale: locale)
        let ranked = candidates.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.rowIndex > rhs.rowIndex // lower on the receipt wins ties
        }
        let total = ranked.first
        let alternatives = rankAlternatives(ranked, excluding: total)
        let confidence = confidence(for: total, runnerUp: alternatives.first)
        let normalizedRows = rows.map(\.normalized)
        let merchant = merchant(rows: rows)
        let categoryHint = categoryHint(merchant: merchant, rows: rows)
        let order = ReceiptDateParser.dayMonthOrder(normalizedRows: normalizedRows, locale: locale)
        let date = receiptDate(rows: rows, order: order, now: now, calendar: calendar)
        let currencyHint = total?.currency ?? candidates.compactMap(\.currency).first

        return ReceiptDraft(
            total: total,
            alternatives: alternatives,
            confidence: confidence,
            merchant: merchant,
            date: date,
            currencyHint: currencyHint,
            categoryHint: categoryHint,
            rows: rows.map(\.text)
        )
    }

    // MARK: - Rows

    /// Clusters lines into rows by vertical overlap, top to bottom, and
    /// orders each row's lines left to right. Vision's observation order is
    /// not reading order and a "TOTAL      41.18" line often arrives as two
    /// observations — this is what glues them back together.
    static func buildRows(from lines: [OCRLine]) -> [Row] {
        let sorted = lines
            .filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
            .sorted { $0.box.midY < $1.box.midY }
        var clusters: [[OCRLine]] = []
        var clusterBoxes: [OCRBox] = []

        for line in sorted {
            if let last = clusterBoxes.indices.last,
               line.box.verticalOverlapRatio(with: clusterBoxes[last]) >= rowOverlapThreshold {
                clusters[last].append(line)
                clusterBoxes[last] = union(clusterBoxes[last], line.box)
            } else {
                clusters.append([line])
                clusterBoxes.append(line.box)
            }
        }

        return clusters.enumerated().map { index, cluster in
            let ordered = cluster.sorted { $0.box.minX < $1.box.minX }
            let text = ordered.map { $0.text.trimmingCharacters(in: .whitespaces) }.joined(separator: "  ")
            let normalized = ReceiptText.normalized(text)
            return Row(
                index: index,
                text: text,
                normalized: normalized,
                box: clusterBoxes[index],
                lineHeight: ordered.map(\.box.height).max() ?? 0,
                amounts: ReceiptAmountGrammar.amounts(in: text),
                label: ReceiptVocabulary.labelClass(of: normalized)
            )
        }
    }

    private static func union(_ a: OCRBox, _ b: OCRBox) -> OCRBox {
        let minX = min(a.minX, b.minX), minY = min(a.minY, b.minY)
        let maxX = max(a.maxX, b.maxX), maxY = max(a.maxY, b.maxY)
        return OCRBox(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Scoring

    private struct Weights {
        static let totalStrong = 10.0
        static let total = 8.0
        static let totalWithTip = 4.0
        static let excluded = -8.0
        static let labelFromRowAbove = -1.0   // a label borrowed from the previous row is a bit weaker
        static let bottomMostTotal = 2.0
        static let hasDecimals = 1.0
        static let noDecimals = -1.0
        static let tinyValue = -3.0
        static let rightAlignedColumn = 1.0
        static let mathConsistent = 3.0
        static let tallText = 1.0
        static let largestAmount = 1.0
        static let repeatedValue = 1.0
        static let ambiguousToken = -1.0
        static let currencyMismatch = -3.0
        static let currencyMatch = 1.0
        static let implausible = -20.0
    }

    /// Every non-negative amount on the receipt, scored.
    static func scoreCandidates(rows: [Row], locale: Locale) -> [ReceiptCandidate] {
        var candidates: [ReceiptCandidate] = []
        let medianHeight = median(rows.map(\.lineHeight))
        let rightEdge = dominantRightEdge(rows: rows)
        let localCurrency = locale.currency?.identifier

        // The label of a row that has none can be borrowed from the row
        // directly above when that row carries a total label and no amount:
        //   TOTAL
        //            41.18
        var effectiveLabels: [Int: (ReceiptLabelClass, Bool)] = [:]
        for row in rows {
            var label = row.label
            var borrowed = false
            if label == .none, row.index > 0 {
                let above = rows[row.index - 1]
                let aboveWords = above.normalized.split(separator: " ")
                let isColumnHeader = ReceiptVocabulary.columnHeaderWords.contains { ReceiptText.containsPhrase(above.normalized, $0) }
                // Borrow only from a row that is essentially just the label
                // ("TOTAL", "SUBTOTAL:"), never from a column header like
                // "CANT DESCRIPCION IMPORTE".
                if above.amounts.isEmpty, above.label != .none, above.label != .excluded(.other),
                   aboveWords.count <= 3, !isColumnHeader {
                    label = above.label
                    borrowed = true
                }
            }
            effectiveLabels[row.index] = (label, borrowed)
        }

        // Values used by the math check.
        func values(labelled target: ReceiptLabelClass) -> [Double] {
            rows.filter { effectiveLabels[$0.index]?.0 == target }
                .flatMap { $0.amounts.filter { !$0.isNegative }.map(\.value) }
        }
        let subtotals = values(labelled: .excluded(.subtotal))
        let taxes = values(labelled: .excluded(.tax))
        let cash = values(labelled: .excluded(.cash))
        let change = values(labelled: .excluded(.change))
        let allValues = rows.flatMap { $0.amounts.filter { !$0.isNegative }.map(\.value) }
        let largest = allValues.max() ?? 0

        // Bottom-most row carrying a real total label.
        let totalRowIndices = rows.compactMap { row -> Int? in
            guard let entry = effectiveLabels[row.index] else { return nil }
            switch entry.0 {
            case .total, .totalStrong: return row.amounts.contains { !$0.isNegative } ? row.index : nil
            default: return nil
            }
        }
        let bottomTotalRow = totalRowIndices.max()

        // Currency only matters when the receipt prints more than one
        // (border receipts with TOTAL MXN and TOTAL USD): then the row in the
        // user's currency wins and the other becomes the first alternative.
        let currenciesOnReceipt = Set(rows.flatMap { row in
            row.amounts.compactMap(\.currency) + [rowCurrencyCode(row)].compactMap { $0 }
        })
        let isDualCurrency = currenciesOnReceipt.count >= 2

        for row in rows {
            guard let entry = effectiveLabels[row.index] else { continue }
            let (label, borrowed) = entry
            let rowCurrency = rowCurrencyCode(row)
            let rowIsTotalLabelled: Bool
            switch label {
            case .total, .totalStrong, .totalWithTip: rowIsTotalLabelled = !borrowed
            case .excluded, .none: rowIsTotalLabelled = false
            }
            for token in row.amounts where !token.isNegative {
                // Receipts print money with decimals. A bare integer only counts
                // when something says it is money: a currency marker ("$250",
                // "MXN 250") or a total label printed on the same row. That
                // drops quantities, phone numbers, store/ticket ids and the
                // masked card digits on TARJETA/VISA rows ("****1234").
                if !token.hasDecimals, !token.hasCurrencyMarker, rowCurrency == nil, !rowIsTotalLabelled { continue }
                var score = 0.0
                switch label {
                case .totalStrong: score += Weights.totalStrong
                case .total: score += Weights.total
                case .totalWithTip: score += Weights.totalWithTip
                case .excluded: score += Weights.excluded
                case .none: break
                }
                if borrowed { score += Weights.labelFromRowAbove }
                if let bottom = bottomTotalRow, bottom == row.index, label == .total || label == .totalStrong {
                    score += Weights.bottomMostTotal
                }
                score += token.hasDecimals ? Weights.hasDecimals : Weights.noDecimals
                if token.value < 1 { score += Weights.tinyValue }
                if token.value > maxPlausibleTotal { score += Weights.implausible }
                if token.isAmbiguous { score += Weights.ambiguousToken }
                if let edge = rightEdge, abs(row.box.maxX - edge) <= 0.06 { score += Weights.rightAlignedColumn }
                if medianHeight > 0, row.lineHeight >= medianHeight * 1.25 { score += Weights.tallText }
                if token.value == largest, largest > 0 { score += Weights.largestAmount }
                if allValues.filter({ approximatelyEqual($0, token.value) }).count > 1 { score += Weights.repeatedValue }
                if isMathConsistent(token.value, subtotals: subtotals, taxes: taxes, cash: cash, change: change) {
                    score += Weights.mathConsistent
                }
                let currency = token.currency ?? rowCurrency
                if isDualCurrency, let currency, let localCurrency {
                    score += currency == localCurrency ? Weights.currencyMatch : Weights.currencyMismatch
                }
                candidates.append(ReceiptCandidate(
                    value: token.value, currency: currency, rowText: row.text,
                    rowIndex: row.index, label: label, score: score
                ))
            }
        }
        return candidates
    }

    /// x == subtotal + tax  |  x == subtotal + Σtaxes  |  x == cash − change
    private static func isMathConsistent(_ x: Double, subtotals: [Double], taxes: [Double], cash: [Double], change: [Double]) -> Bool {
        for s in subtotals {
            for t in taxes where approximatelyEqual(s + t, x) { return true }
            if !taxes.isEmpty, approximatelyEqual(s + taxes.reduce(0, +), x) { return true }
        }
        for c in cash {
            for ch in change where approximatelyEqual(c - ch, x) { return true }
        }
        return false
    }

    static func approximatelyEqual(_ a: Double, _ b: Double, tolerance: Double = 0.011) -> Bool {
        abs(a - b) <= tolerance
    }

    /// The right edge most amount-bearing rows share (the price column).
    private static func dominantRightEdge(rows: [Row]) -> Double? {
        let edges = rows.filter { !$0.amounts.isEmpty }.map(\.box.maxX)
        guard edges.count >= 2 else { return nil }
        return median(edges)
    }

    private static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }

    /// "TOTAL MXN", "TOTAL USD", "TOTAL M.N." on the row → a currency code.
    private static func rowCurrencyCode(_ row: Row) -> String? {
        let n = row.normalized
        if ReceiptText.containsPhrase(n, "USD") || ReceiptText.containsPhrase(n, "DLLS") || ReceiptText.containsPhrase(n, "DLS") {
            return "USD"
        }
        if ReceiptText.containsPhrase(n, "MXN") || ReceiptText.containsPhrase(n, "M N") || ReceiptText.containsPhrase(n, "MN")
            || ReceiptText.containsPhrase(n, "PESOS") {
            return "MXN"
        }
        return nil
    }

    // MARK: - Ranking

    /// What to offer when the chosen total is wrong: another total row (dual
    /// currency, total-with-tip), then the subtotal, then what was charged
    /// to a card or paid in cash, then plain amounts — never tax, change or
    /// counters first. Sorted by that priority, then by the parser score.
    static func alternativePriority(_ candidate: ReceiptCandidate) -> Int {
        switch candidate.label {
        case .totalStrong, .total, .totalWithTip: return 6
        case .excluded(.subtotal): return 5
        case .excluded(.card): return 4
        case .excluded(.cash): return 3
        case .none: return 2
        case .excluded(.tax), .excluded(.tip), .excluded(.change), .excluded(.other): return 0
        }
    }

    private static func rankAlternatives(_ ranked: [ReceiptCandidate], excluding total: ReceiptCandidate?) -> [ReceiptCandidate] {
        var seen: [Double] = []
        if let total { seen.append(total.value) }
        var out: [ReceiptCandidate] = []
        let byPriority = ranked.sorted { lhs, rhs in
            let lp = alternativePriority(lhs), rp = alternativePriority(rhs)
            if lp != rp { return lp > rp }
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.value > rhs.value
        }
        for c in byPriority {
            if seen.contains(where: { approximatelyEqual($0, c.value) }) { continue }
            if c.value <= 0 || c.value > maxPlausibleTotal { continue }
            seen.append(c.value)
            out.append(c)
            if out.count == maxAlternatives { break }
        }
        return out
    }

    private static func confidence(for total: ReceiptCandidate?, runnerUp: ReceiptCandidate?) -> ReceiptConfidence {
        guard let total, total.value > 0 else { return .none }
        let labelled: Bool
        switch total.label {
        case .total, .totalStrong: labelled = true
        default: labelled = false
        }
        guard labelled else { return .low }
        let gap = total.score - (runnerUp?.score ?? -100)
        return gap >= 3 ? .high : .medium
    }

    // MARK: - Merchant

    /// The most prominent row near the top that reads like a name: a known
    /// brand wins outright; otherwise the tallest non-noise row among the
    /// first quarter of the receipt, top-most on ties.
    static func merchant(rows: [Row]) -> String? {
        let topCount = max(3, Int((Double(rows.count) * 0.3).rounded(.up)))
        let top = Array(rows.prefix(topCount))

        for row in top {
            for brand in ReceiptVocabulary.brands where ReceiptText.containsPhrase(row.normalized, brand.phrase) {
                return brand.name
            }
        }

        let candidates = top.filter { isMerchantCandidate($0) }
        guard let best = candidates.max(by: { lhs, rhs in
            if lhs.lineHeight != rhs.lineHeight { return lhs.lineHeight < rhs.lineHeight }
            return lhs.index > rhs.index // prefer the earlier row on equal height
        }) else { return nil }
        return prettifiedMerchant(best.text)
    }

    private static func isMerchantCandidate(_ row: Row) -> Bool {
        guard row.amounts.isEmpty, row.label == .none else { return false }
        let letters = row.text.filter(\.isLetter).count
        let digits = row.text.filter(\.isNumber).count
        guard letters >= 3, letters > digits else { return false }
        for marker in ReceiptVocabulary.merchantDisqualifiers where ReceiptText.containsPhrase(row.normalized, marker) {
            return false
        }
        if row.text.contains("@") || row.text.lowercased().contains("www.") || row.text.lowercased().contains(".com") {
            return false
        }
        if ReceiptDateParser.removingDateAndTimeSpans(from: row.text) != row.text { return false }
        let words = row.normalized.split(separator: " ").map(String.init)
        let meaningful = words.filter { !ReceiptVocabulary.merchantNoiseWords.contains($0) && !$0.allSatisfy(\.isNumber) }
        return !meaningful.isEmpty
    }

    /// Trims legal suffixes and turns ALL-CAPS thermal print into a name
    /// ("TIENDAS DEL SOL S.A. DE C.V." → "Tiendas Del Sol").
    static func prettifiedMerchant(_ raw: String) -> String {
        var normalized = ReceiptText.normalized(raw)
        for suffix in ReceiptVocabulary.legalSuffixes where normalized.hasSuffix(" \(suffix) ") {
            normalized = String(normalized.dropLast(suffix.count + 1))
            break
        }
        let words = normalized.split(separator: " ").map(String.init)
        // Keep the original casing (and punctuation: "Joe's Café") when it
        // was not all caps — OCR of a mixed-case logo is usually right.
        let isAllCaps = raw.filter(\.isLetter).allSatisfy(\.isUppercase)
        if !isAllCaps {
            return raw.split(separator: " ").joined(separator: " ").trimmingCharacters(in: .whitespaces)
        }
        return words.map { word -> String in
            // Short vowel-less words are acronyms (HEB, CVS, KFC); everything
            // else reads better as a name ("Don", "La", "Del", "Sol").
            let hasVowel = word.contains { "AEIOU".contains($0) }
            if word.count <= 3, !hasVowel { return word }
            return word.prefix(1) + word.dropFirst().lowercased()
        }.joined(separator: " ")
    }

    // MARK: - Date

    /// The most likely purchase date: prefer a row that also shows a time or
    /// a FECHA/DATE label; otherwise the first plausible date found.
    static func receiptDate(rows: [Row], order: ReceiptDateParser.DayMonthOrder, now: Date, calendar: Calendar) -> Date? {
        var fallback: Date?
        for row in rows {
            let matches = ReceiptDateParser.dates(in: row.text, order: order, now: now, calendar: calendar)
            guard let first = matches.first else { continue }
            let labelled = ReceiptText.containsPhrase(row.normalized, "FECHA") || ReceiptText.containsPhrase(row.normalized, "DATE")
            if first.hadTime || labelled { return first.date }
            if fallback == nil { fallback = first.date }
        }
        return fallback
    }

    // MARK: - Category

    static func categoryHint(merchant: String?, rows: [Row]) -> ExpenseCategory? {
        var haystacks: [String] = []
        if let merchant { haystacks.append(ReceiptText.normalized(merchant)) }
        let topCount = max(3, Int((Double(rows.count) * 0.3).rounded(.up)))
        haystacks.append(contentsOf: rows.prefix(topCount).map(\.normalized))
        // The merchant name is the strongest signal, so it is checked against
        // every keyword before any other row is ("Abarrotes Don Pepe" is a
        // grocery even when the first item is coffee).
        for text in haystacks {
            for entry in ReceiptVocabulary.categoryKeywords where ReceiptText.containsPhrase(text, entry.phrase) {
                return entry.category
            }
        }
        return nil
    }
}
