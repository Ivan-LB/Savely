//
//  GoalEditValidationTests.swift
//  SavelyTests
//

import XCTest
@testable import Savely

final class GoalEditValidationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_784_000_000)
    private var future: Date { now.addingTimeInterval(86_400 * 30) }
    private var past: Date { now.addingTimeInterval(-86_400) }

    private func draft(
        name: String = "Trip", target: Double = 1000, hasDeadline: Bool = false,
        deadline: Date? = nil, autoMove: Bool = false, autoAmount: Double = 100
    ) -> GoalEditDraft {
        GoalEditDraft(
            name: name, target: target, hasDeadline: hasDeadline,
            deadline: deadline ?? future, autoMoveEnabled: autoMove, autoMoveAmount: autoAmount
        )
    }

    func testValidDraftHasNoError() {
        XCTAssertNil(GoalEditValidation.firstError(in: draft(), current: 0, now: now))
        XCTAssertNil(GoalEditValidation.firstError(in: draft(hasDeadline: true, autoMove: true), current: 500, now: now))
    }

    func testEmptyOrWhitespaceNameIsRejected() {
        XCTAssertEqual(GoalEditValidation.firstError(in: draft(name: ""), current: 0, now: now), .emptyName)
        XCTAssertEqual(GoalEditValidation.firstError(in: draft(name: "   "), current: 0, now: now), .emptyName)
    }

    func testTargetMustBePositive() {
        XCTAssertEqual(GoalEditValidation.firstError(in: draft(target: 0), current: 0, now: now), .nonPositiveTarget)
        XCTAssertEqual(GoalEditValidation.firstError(in: draft(target: -1), current: 0, now: now), .nonPositiveTarget)
    }

    func testTargetCannotDropBelowSavedMoney() {
        XCTAssertEqual(
            GoalEditValidation.firstError(in: draft(target: 400), current: 500, now: now),
            .targetBelowSaved(saved: 500)
        )
        // Equal is fine — that is a completed goal.
        XCTAssertNil(GoalEditValidation.firstError(in: draft(target: 500), current: 500, now: now))
    }

    func testDeadlineMustBeInTheFutureOnlyWhenEnabled() {
        XCTAssertEqual(
            GoalEditValidation.firstError(in: draft(hasDeadline: true, deadline: past), current: 0, now: now),
            .deadlineInPast
        )
        // Date off → a stale past date in the draft is irrelevant.
        XCTAssertNil(GoalEditValidation.firstError(in: draft(hasDeadline: false, deadline: past), current: 0, now: now))
    }

    func testAutoMoveAmountMustBePositiveOnlyWhenEnabled() {
        XCTAssertEqual(
            GoalEditValidation.firstError(in: draft(autoMove: true, autoAmount: 0), current: 0, now: now),
            .nonPositiveAutoMove
        )
        XCTAssertNil(GoalEditValidation.firstError(in: draft(autoMove: false, autoAmount: 0), current: 0, now: now))
    }

    func testRulesAreCheckedInOrderNameFirst() {
        // Everything wrong at once → the first (name) is what the user hears.
        let bad = draft(name: "", target: 0, hasDeadline: true, deadline: past, autoMove: true, autoAmount: 0)
        XCTAssertEqual(GoalEditValidation.firstError(in: bad, current: 10, now: now), .emptyName)
    }
}
