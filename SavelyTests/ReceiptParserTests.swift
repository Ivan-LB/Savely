//
//  ReceiptParserTests.swift
//  SavelyTests
//
//  Unit tests for the receipt grammar, date parser and the parser's row and
//  scoring rules. End-to-end layouts live in ReceiptFixtureTests.
//

import XCTest
@testable import Savely

final class ReceiptParserTests: XCTestCase {

    // MARK: - Amount grammar

    func testAmountsWithAndWithoutThousandsSeparators() {
        XCTAssertEqual(values("1,234.56"), [1234.56])
        XCTAssertEqual(values("1234.56"), [1234.56])
        XCTAssertEqual(values("12345.67"), [12345.67])
        XCTAssertEqual(values("1.234,56"), [1234.56])
        XCTAssertEqual(values("$1,234.56"), [1234.56])
        XCTAssertEqual(values("MXN 250.00"), [250])
        XCTAssertEqual(values("TOTAL:$41.18"), [41.18])
        XCTAssertEqual(values("TOTAL 8.50"), [8.5])
        XCTAssertEqual(values("250"), [250])
        XCTAssertEqual(values("12.5"), [12.5])
        XCTAssertEqual(values("8,50"), [8.5])
    }

    func testAmountGrammarSkipsPercentsDatesTimesAndLongIds() {
        XCTAssertEqual(values("IVA 16.00%"), [])
        XCTAssertEqual(values("IVA 16 %"), [])
        XCTAssertEqual(values("16/08/2026 12:34"), [])
        XCTAssertEqual(values("TICKET 0004512879"), [])
        XCTAssertEqual(values("RFC CCO8605231N4"), [])
        XCTAssertFalse(values("TEL (664) 123-4567").contains(4567))
    }

    func testAmountGrammarReadsCurrencyMarkers() {
        let mxn = ReceiptAmountGrammar.amounts(in: "TOTAL 350.00 MXN")
        XCTAssertEqual(mxn.first?.currency, "MXN")
        let usd = ReceiptAmountGrammar.amounts(in: "TOTAL USD 19.50")
        XCTAssertEqual(usd.first?.currency, "USD")
        let dollar = ReceiptAmountGrammar.amounts(in: "TOTAL $41.18")
        XCTAssertNil(dollar.first?.currency, "$ is ambiguous between MXN and USD")
    }

    func testAmountGrammarNormalizesOCRConfusionsOnlyInsideNumbers() {
        XCTAssertEqual(ReceiptAmountGrammar.parseNumber("1O0.00")?.value, 100)
        XCTAssertEqual(ReceiptAmountGrammar.parseNumber("3S.OO")?.value, 35)
        XCTAssertNil(ReceiptAmountGrammar.parseNumber("SOL"))
        XCTAssertNil(ReceiptAmountGrammar.parseNumber("IVA"))
    }

    func testAmountGrammarFlagsNegativesAndAmbiguity() throws {
        let discount = try XCTUnwrap(ReceiptAmountGrammar.amounts(in: "DESCUENTO -12.00").first)
        XCTAssertTrue(discount.isNegative)
        let thousands = try XCTUnwrap(ReceiptAmountGrammar.parseNumber("1,234"))
        XCTAssertEqual(thousands.value, 1234)
        XCTAssertTrue(thousands.isAmbiguous)
    }

    func testSpacedMinusAndGluedDollarMisread() throws {
        let spaced = try XCTUnwrap(ReceiptAmountGrammar.amounts(in: "DESCUENTO - 12.00").first)
        XCTAssertTrue(spaced.isNegative)
        let trailing = try XCTUnwrap(ReceiptAmountGrammar.amounts(in: "AJUSTE 12.00 -").first)
        XCTAssertTrue(trailing.isNegative)
        // Vision reads a glued "$" as "S": that is the peso sign, not a 5.
        XCTAssertEqual(values("TOTAL S41.18"), [41.18])
        let dollar = try XCTUnwrap(ReceiptAmountGrammar.amounts(in: "TOTAL $250").first)
        XCTAssertTrue(dollar.hasCurrencyMarker)
        XCTAssertNil(dollar.currency)
    }

    // MARK: - Labels

    func testLabelClassification() {
        XCTAssertEqual(label("TOTAL"), .total)
        XCTAssertEqual(label("Total:"), .total)
        XCTAssertEqual(label("TOTAL A PAGAR"), .totalStrong)
        XCTAssertEqual(label("IMPORTE"), .total)
        XCTAssertEqual(label("SUBTOTAL"), .excluded(.subtotal))
        XCTAssertEqual(label("SUB-TOTAL"), .excluded(.subtotal))
        XCTAssertEqual(label("TOTAL CON PROPINA"), .totalWithTip)
        XCTAssertEqual(label("PROPINA"), .excluded(.tip))
        XCTAssertEqual(label("EFECTIVO"), .excluded(.cash))
        XCTAssertEqual(label("CAMBIO"), .excluded(.change))
        XCTAssertEqual(label("CASH TENDERED"), .excluded(.cash))
        XCTAssertEqual(label("CHANGE DUE"), .excluded(.change))
        XCTAssertEqual(label("TOTAL ARTICULOS 5"), .excluded(.other))
        XCTAssertEqual(label("IVA 16%"), .excluded(.tax))
        XCTAssertEqual(label("COCA COLA 600ML"), ReceiptLabelClass.none)
        // TOTAL next to a payment/tax word is still the total.
        XCTAssertEqual(label("TOTAL PAGADO"), .total)
        XCTAssertEqual(label("Total pagado con tarjeta"), .total)
        XCTAssertEqual(label("TOTAL IVA INCLUIDO"), .total)
        XCTAssertEqual(label("TOTAL TARJETA"), .total)
        XCTAssertEqual(label("TOTAL PROPINA"), .excluded(.tip))
        XCTAssertEqual(label("TOTAL IVA"), .excluded(.tax))
    }

    func testCardRowDigitsAndColumnHeadersAreNotAmounts() {
        let draft = ReceiptParser.parse(lines: OCRLine.stacked([
            "CANT DESCRIPCION IMPORTE",
            "2 MARGARITAS 26.00",
            "1 CEVICHE 180.00",
            "SUBTOTAL 232.00",
            "TOTAL 232.00",
            "TARJETA VISA ****1234 AUT 456789 232.00",
        ]), locale: Locale(identifier: "es_MX"))
        XCTAssertEqual(draft.total?.value ?? 0, 232.00, accuracy: 0.001)
        let offered = draft.alternatives.map(\.value)
        XCTAssertFalse(offered.contains(1234), "masked card digits are not money: \(offered)")
        XCTAssertFalse(offered.contains(456789), "auth codes are not money: \(offered)")
        XCTAssertFalse(offered.contains(2), "a quantity is not money: \(offered)")
        XCTAssertNil(draft.date, "'2 MARGARITAS 26.00' is not a date in March")
    }

    // MARK: - Dates

    func testDayFirstAndMonthFirstDates() {
        let now = date(2026, 8, 16)
        XCTAssertEqual(firstDate("FECHA 14/08/2026 18:42", order: .dayFirst, now: now), date(2026, 8, 14))
        XCTAssertEqual(firstDate("08/14/2026 5:32 PM", order: .monthFirst, now: now), date(2026, 8, 14))
        // Unambiguous regardless of the order hint.
        XCTAssertEqual(firstDate("14/08/2026", order: .monthFirst, now: now), date(2026, 8, 14))
        XCTAssertEqual(firstDate("16-08-26", order: .dayFirst, now: now), date(2026, 8, 16))
        XCTAssertEqual(firstDate("2026-08-13", order: .dayFirst, now: now), date(2026, 8, 13))
        XCTAssertEqual(firstDate("16 ago 2026", order: .dayFirst, now: now), date(2026, 8, 16))
        XCTAssertEqual(firstDate("16/AGO/26", order: .dayFirst, now: now), date(2026, 8, 16))
        XCTAssertEqual(firstDate("Aug 14, 2026", order: .monthFirst, now: now), date(2026, 8, 14))
    }

    func testImplausibleDatesAreRejected() {
        let now = date(2026, 8, 16)
        XCTAssertNil(firstDate("31/12/2026", order: .dayFirst, now: now), "future")
        XCTAssertNil(firstDate("01/01/2020", order: .dayFirst, now: now), "older than two years")
        XCTAssertNil(firstDate("30/02/2026", order: .dayFirst, now: now), "no such day")
        XCTAssertNil(firstDate("TOTAL 41.18", order: .dayFirst, now: now))
    }

    // MARK: - Rows

    func testRowsAreClusteredByVerticalOverlapAndOrderedLeftToRight() {
        let lines = [
            OCRLine(text: "41.18", box: OCRBox(x: 0.7, y: 0.101, width: 0.25, height: 0.02)),
            OCRLine(text: "TOTAL", box: OCRBox(x: 0.05, y: 0.10, width: 0.3, height: 0.02)),
            OCRLine(text: "SUBTOTAL", box: OCRBox(x: 0.05, y: 0.06, width: 0.3, height: 0.02)),
            OCRLine(text: "35.50", box: OCRBox(x: 0.7, y: 0.06, width: 0.25, height: 0.02)),
        ]
        let rows = ReceiptParser.buildRows(from: lines)
        XCTAssertEqual(rows.map(\.text), ["SUBTOTAL  35.50", "TOTAL  41.18"])
    }

    // MARK: - Merchant

    func testMerchantPrettifying() {
        XCTAssertEqual(ReceiptParser.prettifiedMerchant("TIENDAS DEL SOL S.A. DE C.V."), "Tiendas Del Sol")
        XCTAssertEqual(ReceiptParser.prettifiedMerchant("Café La Flor"), "Café La Flor")
        XCTAssertEqual(ReceiptParser.prettifiedMerchant("ABARROTES DON PEPE"), "Abarrotes Don Pepe")
    }

    func testEmptyInputGivesEmptyDraft() {
        XCTAssertEqual(ReceiptParser.parse(lines: []), .empty)
        let noAmounts = ReceiptParser.parse(lines: OCRLine.stacked(["GRACIAS POR SU COMPRA"]))
        XCTAssertNil(noAmounts.total)
        XCTAssertEqual(noAmounts.confidence, .none)
    }

    // MARK: - Helpers

    private func values(_ text: String) -> [Double] {
        ReceiptAmountGrammar.amounts(in: text).map(\.value)
    }

    private func label(_ text: String) -> ReceiptLabelClass {
        ReceiptVocabulary.labelClass(of: ReceiptText.normalized(text))
    }

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .current
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: d, hour: 12)) ?? Date()
    }

    private func firstDate(_ text: String, order: ReceiptDateParser.DayMonthOrder, now: Date) -> Date? {
        ReceiptDateParser.dates(in: text, order: order, now: now, calendar: utc).first?.date
    }
}
