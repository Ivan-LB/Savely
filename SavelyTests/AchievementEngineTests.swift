//
//  AchievementEngineTests.swift
//  SavelyTests
//
//  Created by Ivan Lorenzana Belli on 15/08/26.
//

import XCTest
@testable import Savely

final class AchievementEngineTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ year: Int, _ month: Int, _ dayOfMonth: Int, hour: Int = 10) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = dayOfMonth
        components.hour = hour
        guard let date = calendar.date(from: components) else {
            fatalError("invalid test date components")
        }
        return date
    }

    // MARK: - longestDailyStreak

    func testStreakIsZeroWithNoDates() {
        XCTAssertEqual(AchievementEngine.longestDailyStreak([], calendar: calendar), 0)
    }

    func testStreakIsOneForSingleDay() {
        XCTAssertEqual(AchievementEngine.longestDailyStreak([day(2026, 8, 15)], calendar: calendar), 1)
    }

    func testSameDayDuplicatesCountOnce() {
        let dates = [day(2026, 8, 15, hour: 9), day(2026, 8, 15, hour: 21)]
        XCTAssertEqual(AchievementEngine.longestDailyStreak(dates, calendar: calendar), 1)
    }

    func testConsecutiveDaysCount() {
        let dates = [day(2026, 8, 13), day(2026, 8, 14), day(2026, 8, 15)]
        XCTAssertEqual(AchievementEngine.longestDailyStreak(dates, calendar: calendar), 3)
    }

    func testGapResetsStreakAndKeepsLongestRun() {
        // 3-day run, a gap, then a 2-day run — longest is 3.
        let dates = [
            day(2026, 8, 1), day(2026, 8, 2), day(2026, 8, 3),
            day(2026, 8, 10), day(2026, 8, 11),
        ]
        XCTAssertEqual(AchievementEngine.longestDailyStreak(dates, calendar: calendar), 3)
    }

    func testStreakCrossesMonthBoundary() {
        let dates = [day(2026, 7, 31), day(2026, 8, 1), day(2026, 8, 2)]
        XCTAssertEqual(AchievementEngine.longestDailyStreak(dates, calendar: calendar), 3)
    }

    func testUnorderedInputStillFindsStreak() {
        let dates = [day(2026, 8, 15), day(2026, 8, 13), day(2026, 8, 14)]
        XCTAssertEqual(AchievementEngine.longestDailyStreak(dates, calendar: calendar), 3)
    }

    // MARK: - evaluate

    private func states(_ input: AchievementInput) -> [String: AchievementState] {
        Dictionary(uniqueKeysWithValues: AchievementEngine.evaluate(input).map { ($0.id, $0) })
    }

    func testEmptyInputUnlocksNothing() {
        let result = states(AchievementInput())
        XCTAssertTrue(result.values.allSatisfy { !$0.unlocked })
        XCTAssertTrue(result.values.allSatisfy { $0.progress == 0 })
    }

    func testFirstIncomeUnlocks() throws {
        var input = AchievementInput()
        input.incomeCount = 1
        input.incomeTotal = 120
        let result = states(input)
        XCTAssertTrue(try XCTUnwrap(result["first-income"]).unlocked)
        XCTAssertFalse(try XCTUnwrap(result["first-expense"]).unlocked)
    }

    func testSaverProgressIsProportionalAndClamped() throws {
        var input = AchievementInput()
        input.incomeTotal = 500
        input.incomeCount = 3
        var result = states(input)
        XCTAssertEqual(try XCTUnwrap(result["saver"]).progress, 0.5, accuracy: 0.001)
        XCTAssertFalse(try XCTUnwrap(result["saver"]).unlocked)

        input.incomeTotal = 25_000
        result = states(input)
        XCTAssertTrue(try XCTUnwrap(result["saver"]).unlocked)
        XCTAssertTrue(try XCTUnwrap(result["big-saver"]).unlocked)
        XCTAssertEqual(try XCTUnwrap(result["big-saver"]).progress, 1.0)
    }

    func testHalfWayUnlocksAtFiftyPercentGoalProgress() throws {
        var input = AchievementInput()
        input.goalCount = 1
        input.bestGoalProgress = 0.5
        let result = states(input)
        XCTAssertTrue(try XCTUnwrap(result["half-way"]).unlocked)
        XCTAssertFalse(try XCTUnwrap(result["goal-closer"]).unlocked)
        XCTAssertEqual(try XCTUnwrap(result["goal-closer"]).progress, 0.5, accuracy: 0.001)
    }

    func testGoalCloserRequiresCompletedGoal() throws {
        var input = AchievementInput()
        input.goalCount = 2
        input.bestGoalProgress = 1.0
        input.completedGoalCount = 1
        let result = states(input)
        XCTAssertTrue(try XCTUnwrap(result["goal-closer"]).unlocked)
    }

    func testWeekStreakUnlocksFullWeekOnly() throws {
        var input = AchievementInput()
        input.calendar = calendar
        input.loggedDates = (1...7).map { day(2026, 8, $0) }
        let result = states(input)
        XCTAssertTrue(try XCTUnwrap(result["full-week"]).unlocked)
        XCTAssertFalse(try XCTUnwrap(result["steady-hand"]).unlocked)
        XCTAssertEqual(try XCTUnwrap(result["steady-hand"]).progress, 7.0 / 30.0, accuracy: 0.001)
    }
}
