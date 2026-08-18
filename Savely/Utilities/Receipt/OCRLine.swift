//
//  OCRLine.swift
//  Savely
//
//  The parser's only input: recognized text lines with their geometry.
//  Built from Vision observations by ReceiptOCR, or decoded from a JSON
//  fixture in tests — the parser never sees Vision, UIKit or a camera.
//

import Foundation

/// A rectangle in normalized image coordinates with the origin at the
/// TOP-LEFT (x grows right, y grows down, both 0…1). Vision reports boxes
/// with a bottom-left origin; `ReceiptOCR` flips them so that "the row
/// above" always means a smaller `y` here.
struct OCRBox: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    var minX: Double { x }
    var maxX: Double { x + width }
    var minY: Double { y }
    var maxY: Double { y + height }
    var midX: Double { x + width / 2 }
    var midY: Double { y + height / 2 }

    /// Vertical overlap with another box as a fraction of the SHORTER of
    /// the two heights (so a tall line and a short line on the same
    /// baseline still count as one row).
    func verticalOverlapRatio(with other: OCRBox) -> Double {
        let overlap = min(maxY, other.maxY) - max(minY, other.minY)
        let shortest = min(height, other.height)
        guard overlap > 0, shortest > 0 else { return 0 }
        return overlap / shortest
    }
}

/// One recognized line of text.
struct OCRLine: Codable, Equatable, Sendable {
    var text: String
    var box: OCRBox
    /// Vision's confidence for the top candidate, 0…1. Fixtures without a
    /// measured value use 1.
    var confidence: Double

    init(text: String, box: OCRBox, confidence: Double = 1) {
        self.text = text
        self.box = box
        self.confidence = confidence
    }
}

extension OCRLine {
    /// Test/fixture helper: stacks plain strings top-to-bottom as full-width
    /// rows of equal height, the way a single-column receipt reads. Use
    /// explicit boxes when the layout (columns, split labels) matters.
    static func stacked(_ texts: [String], lineHeight: Double = 0.02) -> [OCRLine] {
        texts.enumerated().map { index, text in
            OCRLine(text: text, box: OCRBox(x: 0, y: Double(index) * lineHeight * 1.5, width: 1, height: lineHeight))
        }
    }
}
