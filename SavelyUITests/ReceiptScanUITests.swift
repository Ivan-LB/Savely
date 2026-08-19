//
//  ReceiptScanUITests.swift
//  SavelyUITests
//
//  Walks the receipt flow the way the Simulator can: "+" → Scan a receipt →
//  Choose from Photos → (the newest photo) → review → Save. Needs a receipt
//  image in the Simulator's photo library — see the "Test plan" in the PR:
//      xcrun simctl addmedia <udid> SavelyTests/Fixtures/Images/synthetic-oxxo.png
//  Skips itself when the picker shows no photos, so it never fails for lack
//  of setup. Not run on CI (SavelyUITests is skipped there).
//

import XCTest

final class ReceiptScanUITests: XCTestCase {

    @MainActor
    func testScanFromPhotosReviewsAndSavesTheExpense() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-isOnboardingComplete", "YES"]
        app.launch()

        // The splash screen holds the tab bar back for a moment.
        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 20), "the main tab bar did not appear")
        addButton.tap()
        let scan = app.buttons["Scan a receipt, We'll read the total, merchant and date"]
        if scan.waitForExistence(timeout: 3) {
            scan.tap()
        } else {
            app.staticTexts["Scan a receipt"].tap()
        }

        let picker = app.buttons["Choose from Photos"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "the scanner did not open")
        picker.tap()

        // The Photos picker is a remote view; its grid is reachable through
        // the app once it has loaded (slow on a busy Simulator).
        let photo = app.images.matching(NSPredicate(format: "label BEGINSWITH 'Photo'")).firstMatch
        guard photo.waitForExistence(timeout: 60) else {
            throw XCTSkip("no photo in the Simulator library (or the picker never loaded) — add SavelyTests/Fixtures/Images/synthetic-oxxo.png with simctl addmedia")
        }
        photo.tap()

        let title = app.staticTexts["Check the receipt"]
        XCTAssertTrue(title.waitForExistence(timeout: 30), "the review screen did not appear")

        let amount = app.otherElements["Expense amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 2))
        let amountValue = amount.value as? String ?? ""
        XCTAssertEqual(amountValue, "57.50", "the total read from synthetic-oxxo.png")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "receipt-review"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["Save expense"].tap()
        XCTAssertTrue(app.buttons["Add"].waitForExistence(timeout: 5), "the scanner should dismiss after saving")

        app.buttons["Money"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["OXXO"].waitForExistence(timeout: 5), "the saved row should show the merchant")
    }
}
