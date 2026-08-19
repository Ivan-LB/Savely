//
//  ReceiptOCR.swift
//  Savely
//
//  On-device text recognition for a receipt photo. iOS 26's
//  `RecognizeDocumentsRequest` gives us every text line with its box plus
//  Apple's own money/date detectors in one pass; `RecognizeTextRequest`
//  is the fallback when the document request finds nothing. Nothing here
//  touches the network — the receipt never leaves the phone.
//
//  Two things the old TextRecognizer got wrong and this file fixes:
//  the image ORIENTATION is always passed (a UIImage's cgImage is the raw
//  sensor bitmap; without the EXIF orientation Vision reads portrait
//  receipts sideways), and the recognition LANGUAGES are Spanish + English
//  (resolved at runtime from what the OS supports) instead of the en-US
//  default.
//

import Foundation
import ImageIO
import UIKit
import Vision
import DataDetection

/// A money amount Apple's data detector found in the recognized text.
struct DetectedMoney: Equatable, Sendable {
    var amount: Double
    var currency: String
}

struct ReceiptOCRResult: Sendable {
    var lines: [OCRLine]
    var detectedMoney: [DetectedMoney]
    var detectedDates: [Date]
    /// The document title Vision inferred (often the merchant), if any.
    var title: String?
}

enum ReceiptOCRError: Error, Equatable {
    case badImage
    case noText
}

enum ReceiptOCR {
    /// Longest side handed to Vision. Receipts are text at close range;
    /// more pixels than this only cost time.
    static let maxDimension: CGFloat = 2200

    /// Recognizes the receipt in `image`. Runs Vision's work off the caller's
    /// actor; safe to call from the main actor with `await`.
    static func recognize(_ image: UIImage) async throws -> ReceiptOCRResult {
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return try await Task.detached(priority: .userInitiated) {
            // Decoding the 12 MP still and downscaling it are the expensive
            // non-Vision steps — keep them off the main actor too.
            guard let cgImage = image.cgImage else { throw ReceiptOCRError.badImage }
            let working = cgImage.downscaled(maxDimension: maxDimension) ?? cgImage
            return try await recognize(cgImage: working, orientation: orientation)
        }.value
    }

    static func recognize(cgImage: CGImage, orientation: CGImagePropertyOrientation) async throws -> ReceiptOCRResult {
        var documentRequest = RecognizeDocumentsRequest()
        var options = documentRequest.textRecognitionOptions
        options.recognitionLanguages = preferredLanguages(from: documentRequest.supportedRecognitionLanguages)
        options.useLanguageCorrection = false
        options.customWords = ReceiptVocabulary.recognitionCustomWords
        documentRequest.textRecognitionOptions = options

        if let observation = try await documentRequest.perform(on: cgImage, orientation: orientation).first {
            let lines = observation.document.text.lines.map(ocrLine(from:))
            if !lines.isEmpty {
                return ReceiptOCRResult(
                    lines: lines,
                    detectedMoney: detectedMoney(in: observation.document.text.detectedData),
                    detectedDates: detectedDates(in: observation.document.text.detectedData),
                    title: observation.document.title?.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        }

        var textRequest = RecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = preferredLanguages(from: textRequest.supportedRecognitionLanguages)
        textRequest.usesLanguageCorrection = false
        textRequest.customWords = ReceiptVocabulary.recognitionCustomWords
        let observations = try await textRequest.perform(on: cgImage, orientation: orientation)
        let lines = observations.map(ocrLine(from:))
        guard !lines.isEmpty else { throw ReceiptOCRError.noText }
        return ReceiptOCRResult(lines: lines, detectedMoney: [], detectedDates: [], title: nil)
    }

    // MARK: - Languages

    /// Spanish and English, in the device's preferred order, restricted to
    /// what this OS build actually supports. Empty (Vision's default) only if
    /// neither is available.
    static func preferredLanguages(from supported: [Locale.Language]) -> [Locale.Language] {
        let wanted = ["es", "en"]
        let deviceFirst = Locale.preferredLanguages.compactMap { Locale(identifier: $0).language.languageCode?.identifier }
        let order = (deviceFirst + wanted).filter { wanted.contains($0) }.reduce(into: [String]()) { acc, code in
            if !acc.contains(code) { acc.append(code) }
        }
        return order.compactMap { code in
            supported.first { $0.languageCode?.identifier == code }
        }
    }

    // MARK: - Conversion

    /// Vision boxes have a bottom-left origin; OCRLine uses top-left so that
    /// "above" is a smaller y for the parser.
    static func ocrLine(from observation: RecognizedTextObservation) -> OCRLine {
        let candidate = observation.topCandidates(1).first
        let rect = observation.boundingBox.cgRect
        let box = OCRBox(
            x: Double(rect.origin.x),
            y: Double(1 - rect.origin.y - rect.size.height),
            width: Double(rect.size.width),
            height: Double(rect.size.height)
        )
        return OCRLine(text: candidate?.string ?? observation.transcript, box: box, confidence: Double(candidate?.confidence ?? observation.confidence))
    }

    static func detectedMoney(in matches: [DocumentObservation.Container.DataDetectorMatch]) -> [DetectedMoney] {
        matches.compactMap { match in
            if case .moneyAmount(let money) = match.match.details {
                let rounded = (NSDecimalNumber(decimal: money.amount).doubleValue * 100).rounded() / 100
                return DetectedMoney(amount: rounded, currency: money.currency.identifier)
            }
            return nil
        }
    }

    static func detectedDates(in matches: [DocumentObservation.Container.DataDetectorMatch]) -> [Date] {
        matches.compactMap { match in
            if case .calendarEvent(let event) = match.match.details { return event.startDate }
            return nil
        }
    }
}

// MARK: - Orientation

extension CGImagePropertyOrientation {
    /// UIImage and ImageIO number their orientations differently; this is
    /// Apple's documented name-for-name mapping.
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - Downscale

extension CGImage {
    /// A copy no larger than `maxDimension` on its longest side, or nil when
    /// the image is already small enough (or drawing fails). Pixel data
    /// keeps its sensor orientation; pass the same orientation to Vision.
    func downscaled(maxDimension: CGFloat) -> CGImage? {
        let longest = CGFloat(max(width, height))
        guard longest > maxDimension else { return nil }
        let scale = maxDimension / longest
        let newWidth = Int((CGFloat(width) * scale).rounded())
        let newHeight = Int((CGFloat(height) * scale).rounded())
        guard let context = CGContext(
            data: nil, width: newWidth, height: newHeight, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage()
    }
}
