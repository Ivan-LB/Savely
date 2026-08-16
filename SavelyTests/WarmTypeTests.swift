//
//  WarmTypeTests.swift
//  SavelyTests
//

import XCTest
import SwiftUI
@testable import Savely

final class WarmTypeTests: XCTestCase {

    /// The whole point: at the default content size, every design size renders
    /// at exactly the point size the design specified. Nothing moves for a
    /// user who never touched Dynamic Type.
    func testDefaultContentSizeIsIdentity() {
        for size: CGFloat in [10, 11, 12, 13, 14, 15, 18, 22, 26, 30, 34, 42, 64, 72] {
            let scaled = WarmType.scaledSize(size, relativeTo: WarmType.style(for: size), sizeCategory: .large)
            XCTAssertEqual(scaled, size, accuracy: 0.01, "size \(size) changed at the default category")
        }
    }

    func testAccessibilitySizesScaleUpAndSmallSizesScaleDown() {
        let big = WarmType.scaledSize(14, relativeTo: .subheadline, sizeCategory: .accessibilityExtraExtraExtraLarge)
        let small = WarmType.scaledSize(14, relativeTo: .subheadline, sizeCategory: .extraSmall)
        XCTAssertGreaterThan(big, 14)
        XCTAssertLessThan(small, 14)
    }

    func testHeadingsGrowLessThanBodyAtAccessibilitySizes() {
        // Large styles follow a gentler curve — a 34pt title must not triple.
        let title = WarmType.scaledSize(34, relativeTo: .largeTitle, sizeCategory: .accessibilityExtraExtraExtraLarge) / 34
        let body = WarmType.scaledSize(15, relativeTo: .body, sizeCategory: .accessibilityExtraExtraExtraLarge) / 15
        XCTAssertLessThan(title, body)
    }

    func testStyleMappingIsMonotonic() {
        XCTAssertEqual(WarmType.style(for: 11), .caption)
        XCTAssertEqual(WarmType.style(for: 12), .footnote)
        XCTAssertEqual(WarmType.style(for: 14), .subheadline)
        XCTAssertEqual(WarmType.style(for: 15), .body)
        XCTAssertEqual(WarmType.style(for: 18), .title3)
        XCTAssertEqual(WarmType.style(for: 22), .title2)
        XCTAssertEqual(WarmType.style(for: 26), .title)
        XCTAssertEqual(WarmType.style(for: 34), .largeTitle)
        XCTAssertEqual(WarmType.style(for: 72), .largeTitle)
    }
}
