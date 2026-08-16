//
//  GoalDepositsTests.swift
//  SavelyTests
//

import XCTest
import SwiftData
@testable import Savely

@MainActor
final class GoalDepositsTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: GoalModel.self, DepositModel.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    private func makeGoal(target: Double, current: Double = 0) -> GoalModel {
        let goal = GoalModel(name: "Trip", current: current, target: target, color: .green)
        context.insert(goal)
        return goal
    }

    // Migrated from AutoMoveSuggestionTests.testApplyAddsAmount / testApplyClampsAtTarget

    func testRecordAddsAmountToTheGoal() throws {
        let goal = makeGoal(target: 1000, current: 200)
        try GoalDeposits.record(goal: goal, amount: 100, source: .manual, context: context)
        XCTAssertEqual(goal.current, 300)
    }

    func testRecordClampsAtTarget() throws {
        let goal = makeGoal(target: 1000, current: 950)
        try GoalDeposits.record(goal: goal, amount: 100, source: .autoMove, context: context)
        XCTAssertEqual(goal.current, 1000)
    }

    // MARK: - Ledger

    func testRecordInsertsALedgerRowWithIntentNotClampedDelta() throws {
        let goal = makeGoal(target: 1000, current: 950)
        try GoalDeposits.record(goal: goal, amount: 100, note: "  bonus  ", source: .autoMove, context: context)

        let rows = try context.fetch(FetchDescriptor<DepositModel>())
        XCTAssertEqual(rows.count, 1)
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(row.goalID, goal.id)
        XCTAssertEqual(row.amount, 100)          // what was asked for
        XCTAssertEqual(row.note, "bonus")        // trimmed
        XCTAssertEqual(row.source, DepositSource.autoMove.rawValue)
    }

    func testEmptyNoteIsStoredAsNil() throws {
        let goal = makeGoal(target: 100)
        try GoalDeposits.record(goal: goal, amount: 10, note: "   ", source: .manual, context: context)
        XCTAssertNil(try XCTUnwrap(try context.fetch(FetchDescriptor<DepositModel>()).first).note)
    }

    func testNonPositiveAmountThrowsAndWritesNothing() throws {
        let goal = makeGoal(target: 100, current: 10)
        XCTAssertThrowsError(try GoalDeposits.record(goal: goal, amount: 0, source: .manual, context: context))
        XCTAssertThrowsError(try GoalDeposits.record(goal: goal, amount: -5, source: .manual, context: context))
        XCTAssertEqual(goal.current, 10)
        XCTAssertTrue(try context.fetch(FetchDescriptor<DepositModel>()).isEmpty)
    }

    // MARK: - Month total

    func testMonthTotalCountsOnlyThisCalendarMonth() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_784_000_000)
        let lastMonth = try XCTUnwrap(calendar.date(byAdding: .month, value: -1, to: now))
        let goalID = UUID()
        let rows = [
            DepositModel(goalID: goalID, amount: 100, date: now, source: .manual),
            DepositModel(goalID: goalID, amount: 50, date: now, source: .autoMove),
            DepositModel(goalID: goalID, amount: 999, date: lastMonth, source: .manual),
        ]
        XCTAssertEqual(GoalDeposits.monthTotal(rows, now: now, calendar: calendar), 150)
    }
}
