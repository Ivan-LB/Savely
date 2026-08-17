//
//  ReceiptFixtureTests.swift
//  SavelyTests
//
//  Runs ReceiptParser over every JSON fixture in Fixtures/Receipts and
//  checks the expected fields. Fixtures are OCR dumps (text + normalized
//  boxes) — the same shape the DEBUG "Export OCR dump" action writes on a
//  device — so a real receipt that misparses becomes a regression test by
//  dropping its anonymized JSON in that folder. No images are committed.
//

import XCTest
@testable import Savely

final class ReceiptFixtureTests: XCTestCase {

    struct Fixture: Decodable {
        struct Expected: Decodable {
            var total: Double?
            var alternativesInclude: [Double]?
            var alternativesExclude: [Double]?
            var merchant: String?
            var date: String?
            var category: String?
            var confidence: String?
            var currencyHint: String?
        }
        var id: String
        var source: String
        var locale: String
        var now: String
        var lines: [OCRLine]
        var expected: Expected
    }

    private static let iso = ISO8601DateFormatter()

    private func loadFixtures() throws -> [Fixture] {
        let bundle = Bundle(for: ReceiptFixtureTests.self)
        let fixtures = try XCTUnwrap(bundle.url(forResource: "Fixtures", withExtension: nil),
                                     "Fixtures folder is not in the test bundle")
        let folder = fixtures.appendingPathComponent("Receipts", isDirectory: true)
        let urls = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        XCTAssertFalse(urls.isEmpty, "no fixtures found")
        return try urls.map { try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: $0)) }
    }

    func testEveryFixtureParsesAsExpected() throws {
        let fixtures = try loadFixtures()
        var failures: [String] = []

        for fixture in fixtures {
            let now = try XCTUnwrap(Self.iso.date(from: fixture.now), "\(fixture.id): bad now")
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
            let draft = ReceiptParser.parse(
                lines: fixture.lines, now: now, locale: Locale(identifier: fixture.locale), calendar: calendar
            )
            let e = fixture.expected
            func fail(_ what: String) { failures.append("[\(fixture.id)] \(what)  rows=\(draft.rows)") }

            if let total = e.total {
                if let got = draft.total?.value {
                    if !ReceiptParser.approximatelyEqual(got, total) {
                        fail("total expected \(total) got \(got) (\(draft.total?.rowText ?? ""))")
                    }
                } else {
                    fail("total expected \(total) got nil")
                }
            }
            for alt in e.alternativesInclude ?? [] where !draft.alternatives.contains(where: { ReceiptParser.approximatelyEqual($0.value, alt) }) {
                fail("alternatives should include \(alt); got \(draft.alternatives.map(\.value))")
            }
            for alt in e.alternativesExclude ?? [] {
                if draft.alternatives.contains(where: { ReceiptParser.approximatelyEqual($0.value, alt) })
                    || (draft.total.map { ReceiptParser.approximatelyEqual($0.value, alt) } ?? false) {
                    fail("\(alt) must not be offered; got total \(String(describing: draft.total?.value)) alts \(draft.alternatives.map(\.value))")
                }
            }
            if let merchant = e.merchant, draft.merchant != merchant {
                fail("merchant expected \(merchant) got \(String(describing: draft.merchant))")
            }
            if let dateString = e.date {
                if let got = draft.date {
                    let comps = calendar.dateComponents([.year, .month, .day], from: got)
                    let gotString = String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
                    if gotString != dateString { fail("date expected \(dateString) got \(gotString)") }
                } else {
                    fail("date expected \(dateString) got nil")
                }
            }
            if let category = e.category, draft.categoryHint?.rawValue != category {
                fail("category expected \(category) got \(String(describing: draft.categoryHint))")
            }
            if let confidence = e.confidence, "\(draft.confidence)" != confidence {
                fail("confidence expected \(confidence) got \(draft.confidence)")
            }
            if let currency = e.currencyHint, draft.currencyHint != currency {
                fail("currencyHint expected \(currency) got \(String(describing: draft.currencyHint))")
            }
        }

        XCTAssertTrue(failures.isEmpty, "\n" + failures.joined(separator: "\n"))
    }

    func testFixturesDeclareTheirProvenance() throws {
        // Honesty rule: every fixture says where it came from, so nobody
        // mistakes a hand-authored layout for measured real-world accuracy.
        for fixture in try loadFixtures() {
            XCTAssertFalse(fixture.source.isEmpty, "\(fixture.id) has no source")
        }
    }
}
