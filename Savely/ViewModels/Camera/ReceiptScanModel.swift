//
//  ReceiptScanModel.swift
//  Savely
//
//  State for the receipt scan flow: capture → reading → review → saved.
//  Owned by whoever presents the scanner (the "+" sheet or the Money tab)
//  and handed to ReceiptScanFlowView. Everything the user sees on the
//  review screen is a draft they can edit; nothing is saved until they tap
//  Save, and a save that fails keeps the screen open.
//

import Foundation
import Observation
import UIKit

/// The editable draft shown on the review screen.
struct ReceiptReview {
    var image: UIImage
    /// Keypad string ("41.18", "250"); "0" when nothing was read.
    var amountText: String
    /// Other amounts read from the receipt, best first.
    var alternatives: [Double]
    var merchant: String
    var date: Date
    /// True when `date` was read from the receipt (else it is "now").
    var dateWasRead: Bool
    var category: ExpenseCategory
    var confidence: ReceiptConfidence
    var currencyHint: String?
    /// What OCR saw — for the DEBUG dump only.
    var ocrLines: [OCRLine]

    var amountValue: Double? { parseAmount(amountText) }
}

@MainActor
@Observable
final class ReceiptScanModel: Identifiable {
    enum Phase: Hashable {
        case capturing
        case processing
        case review
        case failed(String)
    }

    let id = UUID()
    let camera = CameraManager()
    private(set) var phase: Phase = .capturing
    var review: ReceiptReview?
    /// Set by the flow view; called when the flow is over (saved or cancelled).
    @ObservationIgnored var onFinished: (() -> Void)?

    @ObservationIgnored private let expenseStore: ExpenseTrackerViewModel
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private let now: () -> Date

    /// The error message to show over the review screen when saving fails.
    var saveErrorMessage: String?

    init(expenseStore: ExpenseTrackerViewModel, now: @escaping () -> Date = Date.init) {
        self.expenseStore = expenseStore
        self.now = now
    }

    var isProcessing: Bool { phase == .processing }

    // MARK: - Capture

    /// Shutter tap: one capture at a time; ignored while reading.
    func capture() {
        guard phase == .capturing, scanTask == nil else { return }
        phase = .processing
        scanTask = Task { [weak self] in
            guard let self else { return }
            do {
                let data = try await camera.capturePhoto()
                guard let image = UIImage(data: data) else { throw ReceiptOCRError.badImage }
                await process(image)
            } catch CameraError.notReady {
                phase = .failed(Strings.Camera.cameraStartingBody)
            } catch {
                phase = .failed(Strings.Camera.readFailedBody)
            }
            scanTask = nil
        }
    }

    /// The picker closed and the photo is loading (iCloud originals can take
    /// seconds): show the reading state right away instead of an idle camera.
    func beginImport() {
        guard phase == .capturing, scanTask == nil else { return }
        phase = .processing
    }

    /// A photo picked from the library or returned by the system document
    /// camera. Same pipeline as the shutter.
    func importImage(_ image: UIImage) {
        guard scanTask == nil else { return }
        phase = .processing
        scanTask = Task { [weak self] in
            guard let self else { return }
            await process(image)
            scanTask = nil
        }
    }

    /// The photo could not be loaded/decoded, or the system document camera
    /// reported an error.
    func importFailed() {
        guard scanTask == nil else { return }
        phase = .failed(Strings.Camera.importFailedBody)
    }

    private func process(_ image: UIImage) async {
        // The photo is taken; the review screen does not need the live feed
        // (or the torch) running behind it.
        camera.stopSession()
        var draft = ReceiptDraft.empty
        var ocr: ReceiptOCRResult?
        do {
            let result = try await ReceiptOCR.recognize(image)
            ocr = result
            draft = ReceiptParser.parse(lines: result.lines, now: now())
        } catch {
            // No text at all is the honest "we couldn't read it" case; the
            // user can still enter the amount by hand from the review screen.
            print("Receipt OCR failed: \(error)")
        }
        guard !Task.isCancelled else { return }
        review = makeReview(image: image, draft: draft, ocr: ocr)
        phase = .review
    }

    private func makeReview(image: UIImage, draft: ReceiptDraft, ocr: ReceiptOCRResult?) -> ReceiptReview {
        let today = now()
        // Apple's detectors are a second opinion, held to the parser's own
        // plausibility rules: amounts within range, dates not in the future
        // and not older than the parser accepts.
        let detectedAmounts = (ocr?.detectedMoney ?? [])
            .map(\.amount)
            .filter { $0 > 0 && $0 <= ReceiptParser.maxPlausibleTotal }
        let detectedDate = (ocr?.detectedDates ?? []).first { ReceiptDateParser.isPlausible($0, now: today) }

        var alternatives = draft.alternatives.map(\.value)
        var amountText = draft.total.map { Self.keypadString(for: $0.value) } ?? "0"
        if draft.total == nil, let best = detectedAmounts.max() {
            amountText = Self.keypadString(for: best)
            alternatives = detectedAmounts.filter { !ReceiptParser.approximatelyEqual($0, best) }
        }
        alternatives = Self.distinct(alternatives)
        let date = draft.date ?? detectedDate
        return ReceiptReview(
            image: image,
            amountText: amountText,
            alternatives: Array(alternatives.prefix(ReceiptParser.maxAlternatives)),
            merchant: draft.merchant ?? ocr?.title ?? "",
            date: date ?? today,
            dateWasRead: date != nil,
            category: draft.categoryHint ?? .other,
            confidence: draft.confidence,
            currencyHint: draft.currencyHint,
            ocrLines: ocr?.lines ?? []
        )
    }

    private static func distinct(_ values: [Double]) -> [Double] {
        values.reduce(into: [Double]()) { acc, value in
            if !acc.contains(where: { ReceiptParser.approximatelyEqual($0, value) }) { acc.append(value) }
        }
    }

    // MARK: - Review actions

    func retake() {
        // `review` is left in place until the next capture replaces it: the
        // review screen's bindings are still alive during its exit animation.
        saveErrorMessage = nil
        phase = .capturing
        camera.startSession()
    }

    func pickAlternative(_ value: Double) {
        guard var current = review else { return }
        let previous = current.amountValue
        current.amountText = Self.keypadString(for: value)
        current.alternatives.removeAll { ReceiptParser.approximatelyEqual($0, value) }
        if let previous, previous > 0, !current.alternatives.contains(where: { ReceiptParser.approximatelyEqual($0, previous) }) {
            current.alternatives.insert(previous, at: 0)
        }
        review = current
    }

    /// Saves the reviewed expense. Returns true when the row was written;
    /// on false the screen stays open and `saveErrorMessage` explains.
    @discardableResult
    func save() -> Bool {
        guard let review, let amount = review.amountValue else {
            saveErrorMessage = Strings.Camera.enterAmountError
            return false
        }
        let merchant = review.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = merchant.isEmpty ? Strings.Camera.scannedReceiptDescription : merchant
        let saved = expenseStore.addExpense(
            description: description,
            amount: amount,
            date: review.date,
            category: review.category.rawValue
        )
        guard saved else {
            saveErrorMessage = expenseStore.errorMessage
            return false
        }
        finish()
        return true
    }

    func cancel() {
        scanTask?.cancel()
        finish()
    }

    private func finish() {
        camera.stopSession()
        onFinished?()
    }

    // MARK: - Helpers

    /// "41.18" for 41.18, "250" for 250 — what WarmKeypad edits.
    static func keypadString(for value: Double) -> String {
        guard value > 0 else { return "0" }
        let cents = (value * 100).rounded()
        if cents.truncatingRemainder(dividingBy: 100) == 0 {
            return String(Int(cents / 100))
        }
        return String(format: "%.2f", cents / 100)
    }

    #if DEBUG
    /// Writes what OCR saw as a JSON fixture (same shape as
    /// SavelyTests/Fixtures/Receipts) so a misread receipt can become a
    /// regression test. Strip names/RFC/phone/card lines before committing.
    func exportOCRDump() -> URL? {
        guard let review else { return nil }
        struct Dump: Encodable {
            var id: String
            var source: String
            var locale: String
            var now: String
            var lines: [OCRLine]
            var expected: [String: Double]
        }
        let dump = Dump(
            id: "device-\(Int(Date().timeIntervalSince1970))",
            source: "device OCR dump — REVIEW AND ANONYMIZE before committing",
            locale: Locale.current.identifier,
            now: ISO8601DateFormatter().string(from: Date()),
            lines: review.ocrLines,
            expected: ["total": review.amountValue ?? 0]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(dump) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(dump.id).json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
    #endif
}
