//
//  AutoMoveSuggestionTests.swift
//  SavelyTests
//
//  Created by Ivan Lorenzana Belli on 15/08/26.
//

import XCTest
@testable import Savely

final class AutoMoveSuggestionTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_784_000_000)

    private func goal(
        _ name: String, target: Double, current: Double = 0,
        favorite: Bool = false, autoMove: Bool = true, pace: Double = 100,
        weeksToDeadline: Int? = nil
    ) -> GoalModel {
        let deadline = weeksToDeadline.flatMap {
            calendar.date(byAdding: .weekOfYear, value: $0, to: now)
        }
        return GoalModel(
            name: name, current: current, target: target, color: .green,
            isFavorite: favorite, autoMoveEnabled: autoMove, autoMoveAmount: pace,
            deadline: deadline
        )
    }

    func testNoSuggestionWithoutGoals() {
        XCTAssertNil(AutoMoveSuggestion.compute(goals: [], incomeAmount: 500))
    }

    func testNoSuggestionWhenAutoMoveDisabled() {
        let goals = [goal("Trip", target: 1000, autoMove: false)]
        XCTAssertNil(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 500))
    }

    func testNoSuggestionForCompletedGoal() {
        let goals = [goal("Trip", target: 1000, current: 1000)]
        XCTAssertNil(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 500))
    }

    func testNoSuggestionForZeroIncome() {
        let goals = [goal("Trip", target: 1000)]
        XCTAssertNil(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 0))
    }

    func testSuggestsConfiguredPaceWhenIncomeCovers() throws {
        let goals = [goal("Trip", target: 1000, pace: 230)]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 500))
        XCTAssertEqual(s.goal.name, "Trip")
        XCTAssertEqual(s.amount, 230)
    }

    func testAmountCappedByIncome() throws {
        let goals = [goal("Trip", target: 1000, pace: 230)]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 80))
        XCTAssertEqual(s.amount, 80)
    }

    func testAmountCappedByRemainingTarget() throws {
        let goals = [goal("Trip", target: 1000, current: 950, pace: 230)]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 500))
        XCTAssertEqual(s.amount, 50)
    }

    func testFavoriteGoalWinsOverLowerProgress() throws {
        let goals = [
            goal("Behind", target: 1000, current: 0),
            goal("Starred", target: 1000, current: 900, favorite: true),
        ]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 500))
        XCTAssertEqual(s.goal.name, "Starred")
    }

    func testLowestProgressWinsWithoutFavorite() throws {
        let goals = [
            goal("Almost", target: 1000, current: 900),
            goal("Behind", target: 1000, current: 100),
        ]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 500))
        XCTAssertEqual(s.goal.name, "Behind")
    }

    // MARK: - Deadline urgency priority

    func testMoreUrgentDeadlineWins() throws {
        // Relaxed needs $1000 over 50 weeks ($20/wk); Urgent needs $500 over
        // 2 weeks ($250/wk) — Urgent needs more per week to land on time.
        let goals = [
            goal("Relaxed", target: 1000, weeksToDeadline: 50),
            goal("Urgent", target: 500, weeksToDeadline: 2),
        ]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 500, now: now, calendar: calendar))
        XCTAssertEqual(s.goal.name, "Urgent")
    }

    func testDatedGoalOutranksOpenEndedOne() throws {
        let goals = [
            goal("Someday", target: 1000, current: 0),
            goal("Dated", target: 1000, current: 900, weeksToDeadline: 10),
        ]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 500, now: now, calendar: calendar))
        XCTAssertEqual(s.goal.name, "Dated")
    }

    func testFavoriteStillOutranksUrgency() throws {
        let goals = [
            goal("Urgent", target: 500, weeksToDeadline: 1),
            goal("Starred", target: 1000, current: 900, favorite: true),
        ]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(goals: goals, incomeAmount: 500, now: now, calendar: calendar))
        XCTAssertEqual(s.goal.name, "Starred")
    }

    // MARK: - Month-margin affordability

    func testAmountCappedByMonthMargin() throws {
        // Month so far: $1000 in, $1150 out. This $200 income leaves a $50
        // margin — the suggestion caps there, not at the $100 pace.
        let goals = [goal("Trip", target: 1000, pace: 100)]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(
            goals: goals, incomeAmount: 200,
            monthIncomeTotal: 1000, monthExpenseTotal: 1150
        ))
        XCTAssertEqual(s.amount, 50)
    }

    func testNoSuggestionWhenMonthIsUnderWater() {
        // Even counting this income the month is negative — suggest nothing.
        let goals = [goal("Trip", target: 1000, pace: 100)]
        XCTAssertNil(AutoMoveSuggestion.compute(
            goals: goals, incomeAmount: 200,
            monthIncomeTotal: 500, monthExpenseTotal: 900
        ))
    }

    func testHealthyMonthDoesNotReduceSuggestion() throws {
        let goals = [goal("Trip", target: 1000, pace: 100)]
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(
            goals: goals, incomeAmount: 500,
            monthIncomeTotal: 2000, monthExpenseTotal: 800
        ))
        XCTAssertEqual(s.amount, 100)
    }

    // MARK: - Month margin subtracts money already moved into goals

    func testMonthDepositsReduceTheMargin() throws {
        let g = goal("Trip", target: 1000, current: 0, favorite: true, pace: 300)
        // Month so far: 500 in, 100 out, and 350 already deposited into goals.
        // Logging 100 more: margin = 500 + 100 - 100 - 350 = 150 → capped at 150.
        let s = try XCTUnwrap(AutoMoveSuggestion.compute(
            goals: [g], incomeAmount: 100, monthIncomeTotal: 500,
            monthExpenseTotal: 100, monthDepositTotal: 350, now: now, calendar: calendar
        ))
        XCTAssertEqual(s.amount, 100) // also capped by the income being logged
        let s2 = try XCTUnwrap(AutoMoveSuggestion.compute(
            goals: [g], incomeAmount: 400, monthIncomeTotal: 500,
            monthExpenseTotal: 100, monthDepositTotal: 350, now: now, calendar: calendar
        ))
        XCTAssertEqual(s2.amount, 300) // pace cap: margin is 450, pace is 300
        XCTAssertNil(AutoMoveSuggestion.compute(
            goals: [g], incomeAmount: 100, monthIncomeTotal: 500,
            monthExpenseTotal: 100, monthDepositTotal: 600, now: now, calendar: calendar
        )) // deposits already ate the month: 500 + 100 - 100 - 600 < 0
    }
}
