//
//  ReminderSettingsTests.swift
//  SavelyTests
//

import XCTest
@testable import Savely

final class ReminderSettingsTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_784_000_000)

    // MARK: - Planner

    func testEnabledReminderIsScheduledAtItsTime() {
        let time = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(ReminderPlanner.action(enabled: true, time: time), .schedule(at: time))
    }

    func testDisabledReminderIsCancelled() {
        XCTAssertEqual(ReminderPlanner.action(enabled: false, time: now), .cancel)
    }

    func testActionsCoverBothKindsIndependently() {
        var prefs = ReminderPreferences.defaults(calendar: calendar, now: now)
        prefs.expenseEnabled = false
        let actions = ReminderPlanner.actions(for: prefs)
        XCTAssertEqual(actions[.expense], .cancel)
        XCTAssertEqual(actions[.goal], .schedule(at: prefs.goalTime))
    }

    // MARK: - Identifiers (must never change — they address pending requests)

    func testIdentifiersMatchTheOnesShippedSinceV1() {
        XCTAssertEqual(ReminderKind.expense.rawValue, "expenseReminder")
        XCTAssertEqual(ReminderKind.goal.rawValue, "goalAlert")
    }

    // MARK: - Defaults

    func testDefaultsAreBothOnEveningAndMorning() {
        let prefs = ReminderPreferences.defaults(calendar: calendar, now: now)
        XCTAssertTrue(prefs.expenseEnabled)
        XCTAssertTrue(prefs.goalEnabled)
        XCTAssertEqual(calendar.component(.hour, from: prefs.expenseTime), 20)
        XCTAssertEqual(calendar.component(.hour, from: prefs.goalTime), 9)
    }

    // MARK: - Store

    private func freshDefaults() throws -> UserDefaults {
        let name = "ReminderSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testStoreReportsNothingSavedOnFreshInstall() throws {
        let store = ReminderStore(defaults: try freshDefaults())
        XCTAssertFalse(store.hasSavedPreferences)
        XCTAssertEqual(store.load(), ReminderPreferences.defaults())
    }

    func testStoreRoundTripsEveryField() throws {
        let store = ReminderStore(defaults: try freshDefaults())
        let saved = ReminderPreferences(
            expenseEnabled: false, goalEnabled: true,
            expenseTime: Date(timeIntervalSince1970: 3_600),
            goalTime: Date(timeIntervalSince1970: 7_200)
        )
        store.save(saved)
        XCTAssertTrue(store.hasSavedPreferences)
        XCTAssertEqual(store.load(), saved)
    }
}
