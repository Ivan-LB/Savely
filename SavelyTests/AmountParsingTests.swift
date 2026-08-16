//
//  AmountParsingTests.swift
//  SavelyTests
//

import XCTest
@testable import Savely

final class AmountParsingTests: XCTestCase {

    // MARK: - Accepted

    func testPeriodDecimalIsParsed() throws {
        let value = try XCTUnwrap(parseAmount("1234.56"))
        XCTAssertEqual(value, 1234.56, accuracy: 0.0001)
    }

    func testCommaDecimalIsParsed() throws {
        // Comma-decimal locales (es-ES, fr-FR, de-DE) send this shape.
        let value = try XCTUnwrap(parseAmount("1234,56"))
        XCTAssertEqual(value, 1234.56, accuracy: 0.0001)
    }

    func testWholeNumberIsParsed() throws {
        let value = try XCTUnwrap(parseAmount("500"))
        XCTAssertEqual(value, 500, accuracy: 0.0001)
    }

    // MARK: - Rejected

    func testAmbiguousMultipleCommasAreRejected() {
        XCTAssertNil(parseAmount("12,34,56"))
    }

    func testMixedSeparatorsAreRejected() {
        // A comma is never read as a thousands separator — rejecting beats
        // guessing wrong by a factor of 100.
        XCTAssertNil(parseAmount("1,234.56"))
    }

    func testEmptyStringIsRejected() {
        XCTAssertNil(parseAmount(""))
    }

    func testNonNumericIsRejected() {
        XCTAssertNil(parseAmount("abc"))
    }

    func testZeroIsRejected() {
        XCTAssertNil(parseAmount("0"))
    }

    func testNegativeIsRejected() {
        XCTAssertNil(parseAmount("-25"))
    }
}
