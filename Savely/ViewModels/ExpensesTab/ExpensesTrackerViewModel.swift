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
            print("Error fetching expenses: \(error)")
            errorMessage = "Error al obtener los gastos."
            showError = true
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

