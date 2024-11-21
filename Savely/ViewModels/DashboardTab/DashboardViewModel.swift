//
//  DashboardViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 19/11/24.
//

import SwiftUI
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    // Instancias de los ViewModels necesarios
    @Published var goalsViewModel: GoalsViewModel
    @Published var incomesViewModel: IncomesTrackerViewModel
    @Published var expensesViewModel: ExpenseTrackerViewModel
    
    // Propiedades para controlar la presentación de sheets
    @Published var showingAddGoalModal: Bool = false
    @Published var showingAddIncomeModal: Bool = false
    @Published var showingAddExpenseModal: Bool = false
    
    // Reference al ModelContext
    var modelContext: ModelContext {
        didSet {
            goalsViewModel.modelContext = modelContext
            incomesViewModel.modelContext = modelContext
            expensesViewModel.modelContext = modelContext
        }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.goalsViewModel = GoalsViewModel(modelContext: modelContext)
        self.incomesViewModel = IncomesTrackerViewModel(modelContext: modelContext)
        self.expensesViewModel = ExpenseTrackerViewModel(modelContext: modelContext)
    }
    
    // Métodos para mostrar las sheets
    func showAddGoal() {
        showingAddGoalModal = true
    }
    
    func showAddIncome() {
        showingAddIncomeModal = true
    }
    
    func showAddExpense() {
        showingAddExpenseModal = true
    }
    
    // Métodos para ocultar las sheets si es necesario
    func hideAddGoal() {
        showingAddGoalModal = false
    }
    
    func hideAddIncome() {
        showingAddIncomeModal = false
    }
    
    func hideAddExpense() {
        showingAddExpenseModal = false
    }
}
