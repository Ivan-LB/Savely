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
    
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    var modelContext: ModelContext?

    private var observerTokens: [NSObjectProtocol] = []

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            fetchExpenses()
        }
        observeExpenseChanges()
    }

    deinit {
        observerTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// The global "+" sheet saves through its own view-model instance, so this
    /// instance only hears about a new expense through the notifications that
    /// `addExpense`/`deleteExpense` post. Without this the Money tab's list
    /// stayed stale until the app relaunched.
    private func observeExpenseChanges() {
        let refresh: (Notification) -> Void = { [weak self] _ in self?.fetchExpenses() }
        observerTokens = [.expenseAdded, .expenseDeleted].map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main, using: refresh)
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
            print("Error fetching expenses: \(error)")
            errorMessage = "Error al obtener los gastos."
            showError = true
        }
    }

    func addExpense() {
        guard let modelContext = modelContext else { return }
        guard let amountValue = parseAmount(amount) else {
            // Used to return silently, so a typo just did nothing at all.
            errorMessage = "Enter a valid amount greater than zero."
            showError = true
            return
        }

        let newExpense = ExpenseModel(
            expenseDescription: expenseDescription,
            amount: amountValue,
            date: Date()
        )
        modelContext.insert(newExpense)

        do {
            try modelContext.save()
            print("New expense saved successfully")

            NotificationCenter.default.post(name: .expenseAdded, object: nil, userInfo: ["amount": amountValue])
        } catch {
            print("Error saving new expense: \(error)")
            errorMessage = "Error al guardar el gasto."
            showError = true
        }

        expenseDescription = ""
        amount = ""
        fetchExpenses()
    }

    func deleteExpense(_ expense: ExpenseModel) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(expense)
        
        do {
            try modelContext.save()
            print("Expense deleted successfully")
            
            NotificationCenter.default.post(name: .expenseDeleted, object: nil, userInfo: ["amount": expense.amount])
        } catch {
            print("Error saving after deleting expense: \(error)")
            errorMessage = "Error al eliminar el gasto."
            showError = true
        }
        
        fetchExpenses()
    }
}

