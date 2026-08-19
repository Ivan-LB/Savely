//
//  GoalPaceTests.swift
//  SavelyTests
//

import XCTest
@testable import Savely

final class GoalPaceTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_784_000_000)

    private func goal(target: Double, current: Double = 0, weeksToDeadline: Int? = nil,
                      autoMove: Bool = false, autoAmount: Double = 0) -> GoalModel {
        let deadline = weeksToDeadline.flatMap { calendar.date(byAdding: .weekOfYear, value: $0, to: now) }
        return GoalModel(name: "G", current: current, target: target, color: .green,
                         autoMoveEnabled: autoMove, autoMoveAmount: autoAmount, deadline: deadline)
    }

    private func deposit(_ goal: GoalModel, _ amount: Double, daysAgo: Int) -> DepositModel {
        DepositModel(goalID: goal.id, amount: amount,
                     date: calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now, source: .manual)
    }

    // MARK: - Required pace

    func testRequiredWeeklyIsRemainingOverWeeksToDeadline() {
        let g = goal(target: 1000, current: 200, weeksToDeadline: 8)
        let pace = GoalPace.compute(goal: g, deposits: [], now: now, calendar: calendar)
        XCTAssertEqual(pace.requiredWeekly ?? -1, 100, accuracy: 0.001)
    }

    func testNoDeadlineMeansNoRequiredPaceAndOnTrack() {
        let g = goal(target: 1000)
        let pace = GoalPace.compute(goal: g, deposits: [], now: now, calendar: calendar)
        XCTAssertNil(pace.requiredWeekly)
        XCTAssertEqual(pace.status, .onTrack)
    }

    func testDeadlineThisWeekStillYieldsAFinitePace() {
        XCTAssertEqual(GoalPace.weeksUntil(now.addingTimeInterval(3600), from: now, calendar: calendar), 1)
    }

    // MARK: - Actual pace

    func testActualPaceAveragesLastFourWeeksOfDeposits() {
        let g = goal(target: 1000)
        let deposits = [deposit(g, 100, daysAgo: 3), deposit(g, 100, daysAgo: 20), deposit(g, 999, daysAgo: 40)]
        let pace = GoalPace.compute(goal: g, deposits: deposits, now: now, calendar: calendar)
        XCTAssertEqual(pace.actualWeekly, 50, accuracy: 0.001) // 200 over 4 weeks; the 40-day-old one is outside
    }

    func testActualPaceIgnoresOtherGoalsDeposits() {
        let g = goal(target: 1000); let other = goal(target: 500)
        let pace = GoalPace.compute(goal: g, deposits: [deposit(other, 400, daysAgo: 1)], now: now, calendar: calendar)
        XCTAssertEqual(pace.actualWeekly, 0)
    }

    func testNoDepositsEverFallsBackToConfiguredAutoMove() {
        let g = goal(target: 1000, autoMove: true, autoAmount: 433)
        let pace = GoalPace.compute(goal: g, deposits: [], now: now, calendar: calendar)
        XCTAssertEqual(pace.actualWeekly, 100, accuracy: 0.01) // 433 / 4.33
    }

    func testNoDepositsAndNoAutoMoveIsZeroPace() {
        let pace = GoalPace.compute(goal: goal(target: 1000), deposits: [], now: now, calendar: calendar)
        XCTAssertEqual(pace.actualWeekly, 0)
        XCTAssertNil(pace.etaWeeks)
        XCTAssertEqual(pace.etaText(from: now, calendar: calendar), "—")
    }

    // MARK: - Status

    func testBehindWhenActualIsBelowRequired() {
        let g = goal(target: 1000, weeksToDeadline: 8)               // needs 125/wk
        let pace = GoalPace.compute(goal: g, deposits: [deposit(g, 100, daysAgo: 2)], now: now, calendar: calendar) // 25/wk
        XCTAssertEqual(pace.status, .behind)
    }

    func testOnTrackWhenActualMeetsRequired() {
        let g = goal(target: 1000, weeksToDeadline: 8)               // 125/wk
        let pace = GoalPace.compute(goal: g, deposits: [deposit(g, 600, daysAgo: 2)], now: now, calendar: calendar) // 150/wk
        XCTAssertEqual(pace.status, .onTrack)
    }

    func testCompleteWhenFunded() {
        let pace = GoalPace.compute(goal: goal(target: 500, current: 500), deposits: [], now: now, calendar: calendar)
        XCTAssertEqual(pace.status, .complete)
        XCTAssertEqual(pace.label, "Complete!")
        XCTAssertEqual(pace.etaText(from: now, calendar: calendar), "Done!")
    }

    // MARK: - ETA

    func testEtaIsRemainingOverActualPace() {
        let g = goal(target: 1000, current: 600)                    // 400 left
        let pace = GoalPace.compute(goal: g, deposits: [deposit(g, 400, daysAgo: 1)], now: now, calendar: calendar) // 100/wk
        XCTAssertEqual(pace.etaWeeks ?? -1, 4, accuracy: 0.001)
        let expected = calendar.date(byAdding: .day, value: 28, to: now)
        let f = DateFormatter(); f.dateFormat = "MMM d"
        XCTAssertEqual(pace.etaText(from: now, calendar: calendar), f.string(from: try XCTUnwrap(expected)))
    }

    func testEtaBeyondAYearIsCappedNotFaked() {
        let g = goal(target: 100_000)
        let pace = GoalPace.compute(goal: g, deposits: [deposit(g, 40, daysAgo: 1)], now: now, calendar: calendar) // 10/wk
        XCTAssertEqual(pace.etaText(from: now, calendar: calendar), "1+ year")
    }
}
