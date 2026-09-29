//
//  CategoryPersistenceTests.swift
//  SavelyTests
//

import XCTest
import SwiftData
@testable import Savely

@MainActor
final class CategoryPersistenceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: ExpenseModel.self, IncomeModel.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    // MARK: - Round trips

    func testExpenseRoundTripsItsCategory() throws {
        context.insert(ExpenseModel(expenseDescription: "Zara", amount: 42, date: Date(), category: "Shopping"))
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<ExpenseModel>()).first)
        XCTAssertEqual(fetched.category, "Shopping")
    }

    func testIncomeRoundTripsItsSource() throws {
        context.insert(IncomeModel(incomeDescription: "August", amount: 500, date: Date(), source: "Paycheck"))
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<IncomeModel>()).first)
        XCTAssertEqual(fetched.source, "Paycheck")
    }

    func testCategoryAndSourceDefaultToNil() throws {
        // The shape every pre-existing row has after the additive migration.
        context.insert(ExpenseModel(expenseDescription: "Coffee", amount: 3, date: Date()))
        context.insert(IncomeModel(incomeDescription: "Gift", amount: 20, date: Date()))
        try context.save()

        XCTAssertNil(try XCTUnwrap(try context.fetch(FetchDescriptor<ExpenseModel>()).first).category)
        XCTAssertNil(try XCTUnwrap(try context.fetch(FetchDescriptor<IncomeModel>()).first).source)
    }

    // MARK: - Display fallback

    func testStoredCategoryWinsOverContradictingKeywords() {
        // Description screams "coffee"; the user said Shopping. The user wins.
        XCTAssertEqual(ExpenseCategory.display(stored: "Shopping", description: "coffee mug gift"), .shopping)
    }

    func testNilCategoryFallsBackToInference() {
        XCTAssertEqual(ExpenseCategory.display(stored: nil, description: "Uber to work"), .transit)
        XCTAssertEqual(ExpenseCategory.display(stored: nil, description: "Whole Foods run"), .food)
        XCTAssertEqual(ExpenseCategory.display(stored: nil, description: "Morning cafe"), .coffee)
    }

    func testUnknownTextInfersOther() {
        XCTAssertEqual(ExpenseCategory.display(stored: nil, description: "Something unrelated"), .other)
    }

    func testUnknownStoredValueFallsBackToInference() {
        // A value that is not one of the five chips is treated like nil.
        XCTAssertEqual(ExpenseCategory.display(stored: "Groceries", description: "Whole Foods"), .food)
    }

    func testIncomeSourceShowsNothingWhenNotStored() {
        XCTAssertNil(IncomeSource.display(stored: nil))
        XCTAssertEqual(IncomeSource.display(stored: "Freelance"), .freelance)
    }

    // MARK: - The chip strings are the stored strings

    func testChipLabelsAreStableStorageKeys() {
        XCTAssertEqual(ExpenseCategory.allCases.map(\.rawValue), ["Coffee", "Food", "Transit", "Shopping", "Other"])
        XCTAssertEqual(IncomeSource.allCases.map(\.rawValue), ["Paycheck", "Freelance", "Gift", "Other"])
    }

    // MARK: - Localized display, stable storage (es-419, 1.1)

    /// The app's es-419 string table, read directly so the test does not
    /// depend on the simulator's language.
    private func spanish(_ key: String) throws -> String {
        let appBundle = Bundle(for: ExpenseTrackerViewModel.self)
        let path = try XCTUnwrap(appBundle.path(forResource: "es-419", ofType: "lproj"), "es-419.lproj missing")
        let bundle = try XCTUnwrap(Bundle(path: path))
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    func testStorageKeysAreTheRawValues() {
        XCTAssertEqual(ExpenseCategory.allCases.map(\.storageKey), ExpenseCategory.allCases.map(\.rawValue))
        XCTAssertEqual(IncomeSource.allCases.map(\.storageKey), IncomeSource.allCases.map(\.rawValue))
    }

    func testSpanishDisplayNamesDifferFromWhatIsStored() throws {
        // If these ever matched, a localized label could leak into the store unnoticed.
        XCTAssertEqual(try spanish("category.coffee"), "Café")
        XCTAssertNotEqual(try spanish("category.coffee"), ExpenseCategory.coffee.storageKey)
        XCTAssertEqual(try spanish("source.paycheck"), "Sueldo")
        XCTAssertNotEqual(try spanish("source.paycheck"), IncomeSource.paycheck.storageKey)
    }

    func testQuickAddWritesTheStorageKeyAndItRoundTrips() throws {
        let expenses = ExpenseTrackerViewModel(modelContext: context)
        XCTAssertTrue(expenses.addExpense(description: "Oxxo", amount: 25, date: Date(),
                                          category: ExpenseCategory.coffee.storageKey))
        context.insert(IncomeModel(incomeDescription: "Quincena", amount: 900, date: Date(),
                                   source: IncomeSource.paycheck.storageKey))
        try context.save()

        let expense = try XCTUnwrap(try context.fetch(FetchDescriptor<ExpenseModel>()).first)
        XCTAssertEqual(expense.category, "Coffee")
        XCTAssertEqual(ExpenseCategory.display(stored: expense.category, description: expense.expenseDescription), .coffee)

        let income = try XCTUnwrap(try context.fetch(FetchDescriptor<IncomeModel>()).first)
        XCTAssertEqual(income.source, "Paycheck")
        XCTAssertEqual(IncomeSource.display(stored: income.source), .paycheck)
    }

    func testLegacyEnglishRowsStillResolveEveryChip() {
        // Rows written by 1.0 (English-only) must keep matching after 1.1.
        for category in ExpenseCategory.allCases {
            XCTAssertEqual(ExpenseCategory.display(stored: category.rawValue, description: ""), category)
        }
        for source in IncomeSource.allCases {
            XCTAssertEqual(IncomeSource.display(stored: source.rawValue), source)
        }
    }

    func testAutoMoveNoteIsStoredInEnglish() {
        XCTAssertEqual(GoalDeposits.autoMoveNote, "Payday auto-move")
    }
}
