//
//  ReceiptOCRIntegrationTests.swift
//  SavelyTests
//
//  Runs the REAL on-device pipeline — Vision (RecognizeDocumentsRequest /
//  RecognizeTextRequest) → ReceiptParser — on a synthetic, script-rendered
//  receipt image. This is the one test that proves the two halves fit
//  together (orientation, languages, box conversion, row clustering);
//  parser rules themselves are covered by the JSON fixtures.
//

import XCTest
import UIKit
@testable import Savely

final class ReceiptOCRIntegrationTests: XCTestCase {

    private func loadImage(_ name: String) throws -> UIImage {
        let bundle = Bundle(for: ReceiptOCRIntegrationTests.self)
        let fixtures = try XCTUnwrap(bundle.url(forResource: "Fixtures", withExtension: nil))
        let url = fixtures.appendingPathComponent("Images/\(name)")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(UIImage(data: data))
    }

    func testSyntheticOXXOReceiptReadsTotalMerchantAndDate() async throws {
        let image = try loadImage("synthetic-oxxo.png")
        let result: ReceiptOCRResult
        do {
            result = try await ReceiptOCR.recognize(image)
        } catch ReceiptOCRError.noText {
            throw XCTSkip("Vision recognized no text in this environment")
        }
        XCTAssertFalse(result.lines.isEmpty)

        // The image is rendered upright; every box must be inside the unit square,
        // top-left origin (a merchant line near the top has a small y).
        for line in result.lines {
            XCTAssert((0...1).contains(line.box.x) && (0...1).contains(line.box.y), "box out of range: \(line)")
        }
        let oxxo = result.lines.first { $0.text.uppercased().contains("OXXO") }
        XCTAssertNotNil(oxxo)
        if let oxxo { XCTAssertLessThan(oxxo.box.y, 0.3, "the header should be near the top after the y-flip") }

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .current
        let now = utc.date(from: DateComponents(year: 2026, month: 8, day: 16, hour: 12)) ?? Date()
        let draft = ReceiptParser.parse(lines: result.lines, now: now, locale: Locale(identifier: "es_MX"), calendar: utc)

        XCTAssertEqual(draft.total?.value ?? 0, 57.50, accuracy: 0.001, "rows: \(draft.rows)")
        XCTAssertEqual(draft.merchant, "OXXO")
        XCTAssertEqual(draft.categoryHint, .food)
        if let date = draft.date {
            XCTAssertEqual(utc.component(.day, from: date), 14)
            XCTAssertEqual(utc.component(.month, from: date), 8)
        } else {
            XCTFail("date not read; rows: \(draft.rows)")
        }
        XCTAssertTrue(draft.alternatives.contains { ReceiptParser.approximatelyEqual($0.value, 49.57) },
                      "subtotal should be offered; got \(draft.alternatives.map(\.value))")
    }

    func testOrientationIsPassedToVision() async throws {
        // A sideways bitmap with the matching orientation tag (a portrait
        // photo as the sensor stores it) must still read — exactly the case
        // the old TextRecognizer broke by dropping the orientation.
        let upright = try loadImage("synthetic-oxxo.png")
        let cg = try XCTUnwrap(upright.cgImage)
        // Rotate the pixels by 90°, then tag the image so that Vision has to
        // rotate them back. One of the two sideways tags is the correct
        // inverse; that one must read the total.
        let rotatedPixels = try XCTUnwrap(rotate90(cg))
        var totals: [Double] = []
        for orientation in [UIImage.Orientation.left, .right] {
            let tagged = UIImage(cgImage: rotatedPixels, scale: 1, orientation: orientation)
            guard let result = try? await ReceiptOCR.recognize(tagged) else { continue }
            let draft = ReceiptParser.parse(lines: result.lines, locale: Locale(identifier: "es_MX"))
            totals.append(draft.total?.value ?? 0)
        }
        XCTAssertTrue(totals.contains { abs($0 - 57.50) < 0.001 }, "neither tag read the total: \(totals)")
    }

    private func rotate90(_ image: CGImage) -> CGImage? {
        let width = image.height, height = image.width
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
        context.rotate(by: -.pi / 2)
        context.translateBy(x: -CGFloat(image.width) / 2, y: -CGFloat(image.height) / 2)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return context.makeImage()
    }
}
