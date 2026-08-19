//
//  ReceiptDateParser.swift
//  Savely
//
//  Finds the purchase date printed on a receipt. es-MX prints day first
//  ("16/08/2026", "16-AGO-26"), en-US prints month first ("08/16/2026",
//  "Aug 16, 2026"); when both readings are valid the caller's language
//  signal decides. A date is only returned when it is plausible: not in the
//  future, not older than `maxAge` — otherwise the expense keeps "now" and
//  the review sheet asks.
//

import Foundation

enum ReceiptDateParser {
    enum DayMonthOrder { case dayFirst, monthFirst }

    /// A date match with its position in the row (for stripping) and the
    /// time found on the same row, if any.
    struct Match: Equatable {
        var date: Date
        var hadTime: Bool
    }

    /// Receipts older than this are treated as unreadable dates.
    static let maxAge: TimeInterval = 2 * 365 * 24 * 3600

    /// Abbreviations and full names, es + en. Matched EXACTLY — a prefix
    /// match would turn "2 MARGARITAS 26.00" into a date in March.
    private static let monthNames: [String: Int] = [
        "ENE": 1, "FEB": 2, "MAR": 3, "ABR": 4, "MAY": 5, "JUN": 6, "JUL": 7, "AGO": 8, "SEP": 9, "SEPT": 9,
        "SET": 9, "OCT": 10, "NOV": 11, "DIC": 12,
        "JAN": 1, "APR": 4, "AUG": 8, "DEC": 12,
        "ENERO": 1, "FEBRERO": 2, "MARZO": 3, "ABRIL": 4, "MAYO": 5, "JUNIO": 6, "JULIO": 7, "AGOSTO": 8,
        "SEPTIEMBRE": 9, "SETIEMBRE": 9, "OCTUBRE": 10, "NOVIEMBRE": 11, "DICIEMBRE": 12,
        "JANUARY": 1, "FEBRUARY": 2, "MARCH": 3, "APRIL": 4, "JUNE": 6, "JULY": 7, "AUGUST": 8,
        "SEPTEMBER": 9, "OCTOBER": 10, "NOVEMBER": 11, "DECEMBER": 12,
    ]

    // Numeric: 16/08/2026, 16-08-26, 16.08.2026, 08/16/2026
    private static let numericPattern = #"(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})(?!\d)"#
    // ISO-ish: 2026-08-16, 2026/08/16
    private static let isoPattern = #"(?<!\d)(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})(?!\d)"#
    // 16 AGO 2026, 16/AGO/26, 16-ago-2026, 16 de agosto de 2026
    private static let dayMonthNamePattern =
        #"(?<!\d)(\d{1,2})(?:\s+DE\s+|[/\-.\s]+)([A-ZÁÉÍÓÚ]{3,10})\.?(?:\s+DE\s+|[/\-.,\s]+)(\d{4}|\d{2})(?!\d|[.,]\d)"#
    // AUG 16, 2026 / August 16 2026
    private static let monthNameDayPattern = #"\b([A-Z]{3,9})\.?\s+(\d{1,2}),?\s+(\d{4})(?!\d|[.,]\d)"#
    // 12:34, 12:34:56, 3:05 PM
    private static let timePattern = #"(?<!\d)([01]?\d|2[0-3]):([0-5]\d)(?::[0-5]\d)?\s*(?:[AP]\.?M\.?)?(?!\d)"#

    private static func regex(_ pattern: String) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    // MARK: - Public

    /// The plausibility window every candidate date must pass: not in the
    /// future (one day of slack for time zones) and not older than `maxAge`.
    static func isPlausible(_ date: Date, now: Date) -> Bool {
        date <= now.addingTimeInterval(24 * 3600) && now.timeIntervalSince(date) <= maxAge
    }

    /// Every plausible date on the row, in reading order.
    static func dates(
        in rowText: String,
        order: DayMonthOrder,
        now: Date,
        calendar: Calendar = .current
    ) -> [Match] {
        let text = rowText.uppercased()
        let hadTime = regex(timePattern)?.firstMatch(in: text, range: fullRange(text)) != nil
        var results: [Match] = []

        for (pattern, kind) in [(isoPattern, Kind.iso), (dayMonthNamePattern, .dayMonthName),
                                (monthNameDayPattern, .monthNameDay), (numericPattern, .numeric)] {
            guard let re = regex(pattern) else { continue }
            for m in re.matches(in: text, range: fullRange(text)) {
                let groups = (1..<m.numberOfRanges).compactMap { i -> String? in
                    guard let r = Range(m.range(at: i), in: text) else { return nil }
                    return String(text[r])
                }
                guard groups.count == 3 else { continue }
                if let date = makeDate(groups: groups, kind: kind, order: order, now: now, calendar: calendar) {
                    results.append(Match(date: date, hadTime: hadTime))
                }
            }
        }
        return results
    }

    /// The row with any date/time spans blanked out — so the amount grammar
    /// never mistakes "16/08/2026" or "12:34" for money.
    static func removingDateAndTimeSpans(from rowText: String) -> String {
        var text = rowText
        for pattern in [isoPattern, numericPattern, timePattern] {
            guard let re = regex(pattern) else { continue }
            text = re.stringByReplacingMatches(in: text, range: fullRange(text), withTemplate: " ")
        }
        return text
    }

    /// Picks the language signal for ambiguous numeric dates: Spanish
    /// vocabulary anywhere on the receipt ⇒ day first; else the locale.
    static func dayMonthOrder(normalizedRows: [String], locale: Locale) -> DayMonthOrder {
        // Language-specific words only — TOTAL, SUBTOTAL, VISA appear on
        // both sides of the border and would only add noise.
        let spanishMarkers = ["IVA", "EFECTIVO", "CAMBIO", "PROPINA", "IMPORTE", "TOTAL A PAGAR", "GRACIAS",
                              "FECHA", "TARJETA", "PAGO", "ARTICULOS", "FOLIO", "CAJA", "RFC", "TICKET",
                              "TIENDA", "SUCURSAL", "CLIENTE"]
        let englishMarkers = ["TAX", "CASH", "CHANGE", "TENDERED", "AMOUNT DUE", "THANK", "THANKS",
                              "DEBIT", "CREDIT", "TIP", "STORE", "ITEMS", "SALE", "PURCHASE", "CASHIER"]
        var spanish = 0, english = 0
        for row in normalizedRows {
            for w in spanishMarkers where ReceiptText.containsPhrase(row, w) { spanish += 1 }
            for w in englishMarkers where ReceiptText.containsPhrase(row, w) { english += 1 }
        }
        if spanish > english { return .dayFirst }
        if english > spanish { return .monthFirst }
        return locale.language.languageCode?.identifier == "es" ? .dayFirst : .monthFirst
    }

    // MARK: - Private

    private enum Kind { case iso, dayMonthName, monthNameDay, numeric }

    private static func fullRange(_ s: String) -> NSRange { NSRange(s.startIndex..., in: s) }

    private static func makeDate(
        groups: [String], kind: Kind, order: DayMonthOrder, now: Date, calendar: Calendar
    ) -> Date? {
        var day = 0, month = 0, year = 0
        switch kind {
        case .iso:
            guard let y = Int(groups[0]), let m = Int(groups[1]), let d = Int(groups[2]) else { return nil }
            (year, month, day) = (y, m, d)
        case .dayMonthName:
            guard let d = Int(groups[0]), let m = monthNumber(groups[1]), let y = Int(groups[2]) else { return nil }
            (year, month, day) = (expandYear(y), m, d)
        case .monthNameDay:
            guard let m = monthNumber(groups[0]), let d = Int(groups[1]), let y = Int(groups[2]) else { return nil }
            (year, month, day) = (expandYear(y), m, d)
        case .numeric:
            guard let a = Int(groups[0]), let b = Int(groups[1]), let y = Int(groups[2]) else { return nil }
            year = expandYear(y)
            if a > 12 && b <= 12 { (day, month) = (a, b) }
            else if b > 12 && a <= 12 { (day, month) = (b, a) }
            else if order == .dayFirst { (day, month) = (a, b) }
            else { (day, month) = (b, a) }
        }
        guard (1...12).contains(month), (1...31).contains(day), year >= 2000 else { return nil }
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day; comps.hour = 12
        guard let date = calendar.date(from: comps) else { return nil }
        // Reject impossible days (Feb 30) and implausible dates.
        guard calendar.component(.day, from: date) == day else { return nil }
        guard isPlausible(date, now: now) else { return nil }
        return date
    }

    private static func monthNumber(_ raw: String) -> Int? {
        let key = raw.folding(options: .diacriticInsensitive, locale: nil).uppercased()
        return monthNames[key]
    }

    private static func expandYear(_ y: Int) -> Int { y < 100 ? 2000 + y : y }
}
