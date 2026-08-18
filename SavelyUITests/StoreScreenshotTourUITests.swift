//
//  StoreScreenshotTourUITests.swift
//  SavelyUITests
//
//  Not a test of behaviour — a screenshot tour. Walks the main tabs and the
//  "+" sheet and attaches a full-resolution screenshot of each, so App
//  Store artwork can be built from real screens:
//      xcodebuild test -scheme Savely -only-testing:SavelyUITests/StoreScreenshotTourUITests \
//        -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -resultBundlePath build/Tour.xcresult
//      xcrun xcresulttool export attachments --path build/Tour.xcresult --output-path build/tour
//  Seed the Simulator with real-looking data first (goals, a few expenses/
//  incomes) — an empty app makes empty screenshots. Skipped on CI like the
//  rest of SavelyUITests.
//

import XCTest

final class StoreScreenshotTourUITests: XCTestCase {

    @MainActor
    func testTourAttachesEveryMainScreen() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-isOnboardingComplete", "YES"]
        app.launch()

        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 20), "the main tab bar did not appear")
        snap(app, "01-home")

        for (tab, name) in [("Goals", "02-goals"), ("Money", "03-money"), ("Me", "04-me")] {
            app.buttons[tab].firstMatch.tap()
            _ = app.buttons[tab].firstMatch.waitForExistence(timeout: 2)
            snap(app, name)
        }

        app.buttons["Home"].firstMatch.tap()
        addButton.tap()
        XCTAssertTrue(app.staticTexts["What's the move?"].waitForExistence(timeout: 5))
        snap(app, "05-plus-sheet")

        // Log expense keypad
        let logExpense = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Log expense'")).firstMatch
        if logExpense.waitForExistence(timeout: 2) {
            logExpense.tap()
            _ = app.staticTexts["Log expense"].waitForExistence(timeout: 3)
            for key in ["2", "4", "5"] { app.buttons[key].firstMatch.tap() }
            snap(app, "06-log-expense")
            app.buttons["Back"].firstMatch.tap()
        }

        // Scanner (Simulator: no camera → unavailable card, still shows the surface)
        let scan = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Scan a receipt'")).firstMatch
        if scan.waitForExistence(timeout: 2) {
            scan.tap()
            _ = app.buttons["Choose from Photos"].waitForExistence(timeout: 5)
            snap(app, "07-scan-camera")
            app.buttons["Close"].firstMatch.tap()
        }
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
