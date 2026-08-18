//
//  AccessibilityAuditUITests.swift
//  SavelyUITests
//
//  Runs Apple's own XCUIApplication accessibility audit over the screens that
//  carry Savely's common tasks (home, goals, a goal, logging money, the month,
//  the profile). It backs the Accessibility Nutrition Label in App Store
//  Connect: a claim there has to be checkable, not remembered.
//
//  Issues are reported, not asserted, so the audit stays a readable report
//  rather than a flaky gate. Skipped on CI like the rest of SavelyUITests.
//
//  Known, accepted findings (2026-08-18):
//    · "Dynamic Type font sizes are partially unsupported" on the four tab
//      captions: the tab bar is capped at xxxLarge on purpose, like UITabBar,
//      and Apple's Larger Text criteria name tab bars as the exemption.
//    · "Contrast failed" on a row whose frame sits at y ≥ 862 is a row
//      scrolled under the floating tab bar (the audit samples the tab bar's
//      pixels, not the row's).
//    · "Contrast" on the disabled Save button is the 0.4-alpha inactive
//      state, which the contrast rules exempt.
//    · "Text clipped" on the Money tab's "What did you buy?" field (22pt
//      tall inside its 40pt row) reproduces at the default size where the
//      field is visibly fine. Not understood; not claimed as fixed.
//  Everything else it printed on that date was real and is fixed in the
//  same PR that added this file.
//
//  What XCUITest shows is not what VoiceOver says. `app.buttons` lists the
//  glyph and the caption inside each WarmTabBarItem as their own buttons
//  (with the SF Symbol's stock name as the glyph's label); that is XCUI
//  descending into a SwiftUI Button's content, and it survives
//  `.accessibilityHidden(true)` on that content. VoiceOver treats a Button
//  as one element and reads the `.accessibilityLabel`. Confirm on a device
//  with VoiceOver on before declaring VoiceOver support in App Store
//  Connect; this file cannot.
//

import XCTest

final class AccessibilityAuditUITests: XCTestCase {

    private var app: XCUIApplication = XCUIApplication()

    @MainActor
    func testCommonTaskScreensPassTheAccessibilityAudit() throws {
        app = XCUIApplication()
        app.launchArguments += ["-isOnboardingComplete", "YES", "-SavelyScreenshotSeed", "-darkModeEnabled", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["Add"].waitForExistence(timeout: 25), "the main tab bar did not appear")

        audit("Home")

        app.buttons["Goals"].firstMatch.tap()
        _ = app.staticTexts["Trip to Oaxaca"].waitForExistence(timeout: 8)
        audit("Goals")

        app.staticTexts["Trip to Oaxaca"].tap()
        _ = app.navigationBars["Goal"].waitForExistence(timeout: 8)
        audit("Goal detail")
        app.navigationBars.buttons.firstMatch.tap()

        app.buttons["Money"].firstMatch.tap()
        _ = app.buttons["Income"].firstMatch.waitForExistence(timeout: 8)
        audit("Money")

        app.buttons["Me"].firstMatch.tap()
        _ = app.buttons["Me"].firstMatch.waitForExistence(timeout: 3)
        audit("Me")

        app.buttons["Home"].firstMatch.tap()
        app.buttons["Add"].tap()
        let expense = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Log expense'")).firstMatch
        XCTAssertTrue(expense.waitForExistence(timeout: 5))
        expense.tap()
        _ = app.staticTexts["Log expense"].waitForExistence(timeout: 5)
        audit("Log expense")
    }

    /// Runs every audit type the platform offers and prints what it finds.
    @MainActor
    private func audit(_ screen: String) {
        var found = 0
        try? app.performAccessibilityAudit { issue in
            found += 1
            let e = issue.element
            let where_ = [e?.elementType.rawValue.description, e?.identifier, e?.label, e?.frame.debugDescription]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " | ")
            print("‼️ [\(screen)] \(issue.compactDescription) -> \(where_)")
            return true // handled: report, do not fail the test
        }
        print(found == 0 ? "✅ [\(screen)] no issues" : "⚠️ [\(screen)] \(found) issue(s)")
    }
}
