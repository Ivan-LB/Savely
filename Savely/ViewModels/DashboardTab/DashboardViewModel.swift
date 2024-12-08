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

    @Published var addGoalSheetHeight: CGFloat = .zero
    @Published var addIncomeSheetHeight: CGFloat = .zero
    @Published var addExpenseSheetHeight: CGFloat = .zero
    
    @Published var modelContext: ModelContext?

    init(modelContext: ModelContext?) {
        self.modelContext = modelContext
        self.incomesViewModel = IncomesTrackerViewModel(modelContext: modelContext)
        self.goalsViewModel = GoalsViewModel(modelContext: modelContext)
        self.expensesViewModel = ExpenseTrackerViewModel(modelContext: modelContext)
    }

    func setModelContext(_ context: ModelContext) {
        modelContext = context
        incomesViewModel.setModelContext(context)
    }

    func showAddGoal() {
        showingAddGoalModal = true
    }

    func showAddIncome() {
        showingAddIncomeModal = true
    }

    func showAddExpense() {
        showingAddExpenseModal = true
    }
}
