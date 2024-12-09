//
//  ExpenseModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation
import SwiftData

@Model
class ExpenseModel {
    @Attribute(.unique) var id: UUID
    var expenseDescription: String
    var amount: Double
    var date: Date

    init(expenseDescription: String, amount: Double, date: Date) {
        self.id = UUID()
        self.expenseDescription = expenseDescription
        self.amount = amount
        self.date = date
    }
}

extension ExpenseModel {
    @MainActor
    static func fetchWeeklyExpenses(from startDate: Date, to endDate: Date, in modelContext: ModelContext) -> [ExpenseModel] {
        print("Fetching expenses from \(startDate) to \(endDate)")

        // Precompute adjusted end date
        let adjustedEndDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: endDate)!)

        let fetchDescriptor = FetchDescriptor<ExpenseModel>(
            predicate: #Predicate {
                $0.date >= startDate && $0.date < adjustedEndDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            let results = try modelContext.fetch(fetchDescriptor)
            print("Expenses fetched: \(results.count)")
            results.forEach { print("Expense: \($0.expenseDescription), Amount: \($0.amount), Date: \($0.date)") }
            return results
        } catch {
            print("Error fetching expenses: \(error)")
            return []
        }
    }
}
