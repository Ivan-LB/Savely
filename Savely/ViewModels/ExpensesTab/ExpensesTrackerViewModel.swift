//
//  ExpensesTrackerViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 19/11/24.
//

import Foundation
import SwiftUI
import SwiftData

class ExpenseTrackerViewModel: ObservableObject {
    @Published var expenseDescription = ""
    @Published var amount = ""
    @Published var expenses: [ExpenseModel] = []

    var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            fetchExpenses()
        }
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchExpenses()
    }

    func fetchExpenses() {
        guard let modelContext = modelContext else { return }
        let fetchDescriptor = FetchDescriptor<ExpenseModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            expenses = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Failed to fetch expenses: \(error)")
        }
    }

    func addExpense() {
        guard let modelContext = modelContext else { return }
        if let amountValue = Double(amount) {
            let newExpense = ExpenseModel(
                expenseDescription: expenseDescription,
                amount: amountValue,
                date: Date()
            )
            modelContext.insert(newExpense)
            expenseDescription = ""
            amount = ""
            fetchExpenses()
        }
    }

    func deleteExpense(_ expense: ExpenseModel) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(expense)
        fetchExpenses()
    }
}
