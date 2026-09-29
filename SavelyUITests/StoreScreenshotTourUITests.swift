//
//  StoreScreenshotTourUITests.swift
//  SavelyUITests
//
//  Not a test of behaviour — the App Store screenshot tour. Launches the app
//  with the fictional `-SavelyScreenshotSeed` dataset, walks the eight
//  frames of docs/plans/app-store-screenshots.md and attaches a full-
//  resolution capture of each. Run on the iPhone 17 Pro Max simulator
//  (1320×2868 native) after `xcrun simctl status_bar … override --time 9:41`:
//
//      xcodebuild test -scheme Savely -only-testing:SavelyUITests/StoreScreenshotTourUITests \
//        -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
//        -parallel-testing-enabled NO -resultBundlePath build/Tour.xcresult
//      xcrun xcresulttool export attachments --path build/Tour.xcresult --output-path build/tour
//
//  Frame 5 (receipt review) needs a fictional receipt image in the
//  Simulator's photo library (`simctl addmedia`). Skipped on CI like the
//  rest of SavelyUITests.
//

import XCTest

final class StoreScreenshotTourUITests: XCTestCase {

    private var app: XCUIApplication = XCUIApplication()

    private func launch(dark: Bool = false) {
        app = XCUIApplication()
        app.launchArguments += ["-isOnboardingComplete", "YES", "-SavelyScreenshotSeed", "-darkModeEnabled", dark ? "YES" : "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["Add"].waitForExistence(timeout: 25), "the main tab bar did not appear")
    }

    @MainActor
    func testFrame1And7GoalDetails() throws {
        launch()
        app.buttons["Goals"].firstMatch.tap()
        // The goal card is an accessibility container, so tap its name.
        let oaxaca = app.staticTexts["Trip to Oaxaca"]
        XCTAssertTrue(oaxaca.waitForExistence(timeout: 8), "seeded goal missing — was -SavelyScreenshotSeed applied?")
        snap("02-goals-list")
        oaxaca.tap()
        XCTAssertTrue(app.navigationBars["Goal"].waitForExistence(timeout: 8), "goal detail did not open")
        snap("01-goal-on-track")
        app.navigationBars.buttons.firstMatch.tap()

        let laptop = app.staticTexts["Laptop"]
        XCTAssertTrue(laptop.waitForExistence(timeout: 8))
        laptop.tap()
        XCTAssertTrue(app.navigationBars["Goal"].waitForExistence(timeout: 8))
        snap("07-goal-behind")
    }

    @MainActor
    func testFrame2Privacy() throws {
        launch()
        app.buttons["Me"].firstMatch.tap()
        _ = app.buttons["Me"].firstMatch.waitForExistence(timeout: 2)
        // Scroll to the bottom so the Data & privacy block sits high enough to
        // survive the device crop in the composed page.
        for _ in 0..<9 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Your data never leaves this iPhone."].waitForExistence(timeout: 5))
        snap("02-privacy")
    }

    @MainActor
    func testFrame3PaydayAndFrame4Expense() throws {
        launch()
        app.buttons["Add"].tap()
        let income = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Log income'")).firstMatch
        XCTAssertTrue(income.waitForExistence(timeout: 5))
        income.tap()
        XCTAssertTrue(app.staticTexts["Log income"].waitForExistence(timeout: 5))
        for key in ["1", "2", "4", "0"] { app.buttons[key].firstMatch.tap() }
        _ = app.buttons["YES"].waitForExistence(timeout: 3)
        snap("03-payday")
        app.buttons["Back"].firstMatch.tap()

        let expense = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Log expense'")).firstMatch
        XCTAssertTrue(expense.waitForExistence(timeout: 5))
        expense.tap()
        XCTAssertTrue(app.staticTexts["Log expense"].waitForExistence(timeout: 5))
        for key in ["7", "Decimal point", "5", "0"] { app.buttons[key].firstMatch.tap() }
        snap("04-expense")
    }

    @MainActor
    func testFrame5ReceiptReview() throws {
        launch()
        app.buttons["Add"].tap()
        let scan = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Scan a receipt'")).firstMatch
        XCTAssertTrue(scan.waitForExistence(timeout: 5))
        scan.tap()
        let picker = app.buttons["Choose from Photos"]
        XCTAssertTrue(picker.waitForExistence(timeout: 8))
        picker.tap()
        let photo = app.images.matching(NSPredicate(format: "label BEGINSWITH 'Photo'")).firstMatch
        guard photo.waitForExistence(timeout: 60) else {
            throw XCTSkip("no receipt photo in the Simulator library — add one with simctl addmedia")
        }
        photo.tap()
        XCTAssertTrue(app.staticTexts["Check the receipt"].waitForExistence(timeout: 30))
        snap("05-receipt-review")
    }

    @MainActor
    func testFrame6MonthTrend() throws {
        launch()
        app.buttons["Money"].firstMatch.tap()
        let income = app.buttons["Income"].firstMatch
        XCTAssertTrue(income.waitForExistence(timeout: 8))
        income.tap()
        let trend = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '7-month trend'")).firstMatch
        XCTAssertTrue(trend.waitForExistence(timeout: 8), "income trend not found")
        snap("06-month-trend")
        app.buttons["Expenses"].firstMatch.tap()
        _ = app.staticTexts["Expenses"].waitForExistence(timeout: 3)
        snap("06b-expenses")
    }

    @MainActor
    func testFrame8HomeDarkAndHomeLight() throws {
        launch(dark: true)
        _ = app.staticTexts["Recent"].waitForExistence(timeout: 5)
        snap("08-home-dark")
        launch(dark: false)
        _ = app.staticTexts["Recent"].waitForExistence(timeout: 5)
        snap("00-home-light")
    }

    /// App Preview footage: one continuous, human-paced walk through the
    /// seeded app while `simctl io … recordVideo` captures the screen. Prints
    /// `BRAGMARK <name> <epoch> [x y]` lines (points) so the editor can cut
    /// scenes and draw touch indicators without guessing.
    @MainActor
    func testPreviewFootage() throws {
        launch()
        // The first launch asks for notifications; answer it before the take.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Allow"].waitForExistence(timeout: 3) {
            springboard.buttons["Allow"].tap()
        }
        pause(1.0)
        mark("home")
        pause(2.0)

        tap(app.buttons["Goals"].firstMatch, "goals-tab")
        let oaxaca = app.staticTexts["Trip to Oaxaca"]
        XCTAssertTrue(oaxaca.waitForExistence(timeout: 8))
        pause(0.8)
        tap(oaxaca, "goal-open")
        XCTAssertTrue(app.navigationBars["Goal"].waitForExistence(timeout: 8))
        mark("goal-before")
        pause(3.0)
        tap(app.navigationBars.buttons.firstMatch, "goal-back")
        pause(0.8)

        tap(app.buttons["Add"], "add-1")
        let expense = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Log expense'")).firstMatch
        XCTAssertTrue(expense.waitForExistence(timeout: 5))
        pause(0.6)
        tap(expense, "expense-open")
        XCTAssertTrue(app.staticTexts["Log expense"].waitForExistence(timeout: 5))
        pause(0.5)
        for key in ["4", "Decimal point", "5", "0"] { tap(app.buttons[key].firstMatch, "key-\(key)"); pause(0.15) }
        pause(0.3)
        tap(app.buttons["Coffee"].firstMatch, "expense-coffee")
        pause(1.2)
        tap(app.buttons["Save"].firstMatch, "expense-save")
        pause(1.5)

        tap(app.buttons["Add"], "add-2")
        let income = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Log income'")).firstMatch
        XCTAssertTrue(income.waitForExistence(timeout: 5))
        pause(0.6)
        tap(income, "income-open")
        XCTAssertTrue(app.staticTexts["Log income"].waitForExistence(timeout: 5))
        pause(0.5)
        for key in ["1", "2", "4", "0"] { tap(app.buttons[key].firstMatch, "key-\(key)"); pause(0.15) }
        XCTAssertTrue(app.buttons["YES"].waitForExistence(timeout: 3))
        mark("income-banner")
        pause(1.6)
        tap(app.buttons["YES"], "income-yes")
        pause(1.4)
        tap(app.buttons["Save"].firstMatch, "income-save")
        pause(1.2)

        tap(app.buttons["Goals"].firstMatch, "goals-tab-2")
        XCTAssertTrue(oaxaca.waitForExistence(timeout: 8))
        pause(0.8)
        tap(oaxaca, "goal-open-2")
        XCTAssertTrue(app.navigationBars["Goal"].waitForExistence(timeout: 8))
        mark("goal-after")
        pause(3.0)
        tap(app.navigationBars.buttons.firstMatch, "goal-back-2")
        pause(0.6)

        tap(app.buttons["Money"].firstMatch, "money-tab")
        let incomeSeg = app.buttons["Income"].firstMatch
        XCTAssertTrue(incomeSeg.waitForExistence(timeout: 8))
        pause(1.0)
        tap(incomeSeg, "money-income")
        mark("trend")
        pause(3.0)

        tap(app.buttons["Me"].firstMatch, "me-tab")
        pause(0.8)
        for _ in 0..<9 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Your data never leaves this iPhone."].waitForExistence(timeout: 5))
        mark("privacy")
        pause(2.5)

        tap(app.buttons["Add"], "add-3")
        let scan = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Scan a receipt'")).firstMatch
        XCTAssertTrue(scan.waitForExistence(timeout: 5))
        pause(0.6)
        tap(scan, "scan-open")
        let picker = app.buttons["Choose from Photos"]
        XCTAssertTrue(picker.waitForExistence(timeout: 8))
        pause(0.8)
        tap(picker, "scan-photos")
        let photo = app.images.matching(NSPredicate(format: "label BEGINSWITH 'Photo'")).firstMatch
        guard photo.waitForExistence(timeout: 30) else { mark("receipt-missing"); return }
        pause(0.8)
        tap(photo, "scan-photo")
        XCTAssertTrue(app.staticTexts["Check the receipt"].waitForExistence(timeout: 30))
        mark("receipt")
        pause(3.5)
        mark("end")
    }

    private func mark(_ name: String, _ point: CGPoint? = nil) {
        let t = String(format: "%.3f", Date().timeIntervalSince1970)
        let p = point.map { String(format: " %.1f %.1f", $0.x, $0.y) } ?? ""
        print("BRAGMARK \(name) \(t)\(p)")
    }

    private func tap(_ element: XCUIElement, _ name: String) {
        let frame = element.frame
        mark(name, CGPoint(x: frame.midX, y: frame.midY))
        element.tap()
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
