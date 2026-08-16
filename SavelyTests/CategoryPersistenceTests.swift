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
}
