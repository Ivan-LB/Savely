//
//  GoalsViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 19/11/24.
//

import Foundation
import SwiftUI
import SwiftData

class GoalsViewModel: ObservableObject {
    @Published var goals: [GoalModel] = []
    @Published var name: String = ""
    @Published var targetAmount: String = ""
    @Published var selectedColor: GoalColor = .green

    var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            fetchGoals()
        }
    }

    func setModelContext(_ context: ModelContext) {
        print("Setting modelContext")
        self.modelContext = context
        fetchGoals()
    }

    func fetchGoals() {
        guard let modelContext = modelContext else { return }
        let fetchDescriptor = FetchDescriptor<GoalModel>()
        do {
            let fetchedGoals = try modelContext.fetch(fetchDescriptor)
            print("Fetched goals count: \(fetchedGoals.count)")
            goals = fetchedGoals
        } catch {
            print("Error fetching goals: \(error)")
        }
    }

    func addGoal() {
        guard let modelContext = modelContext else {
            print("modelContext is nil in addGoal")
            return
        }
        guard let target = Double(targetAmount) else { return }
        let isFirstGoal = goals.isEmpty

        let newGoal = GoalModel(
            name: name,
            current: 0.0,
            target: target,
            color: selectedColor,
            isFavorite: isFirstGoal
        )
        modelContext.insert(newGoal)
        
        // Guardar el contexto después de insertar la nueva meta
        do {
            try modelContext.save()
        } catch {
            print("Error saving new goal: \(error)")
        }

        name = ""
        targetAmount = ""
        fetchGoals()
    }

    func deleteGoal(_ goal: GoalModel) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(goal)
        do {
            try modelContext.save()
        } catch {
            print("Error saving after deleting goal: \(error)")
        }
        fetchGoals()
    }

    func setFavorite(goal: GoalModel) {
        guard let modelContext = modelContext else { return }
        // Desmarcar la meta favorita actual
        for existingGoal in goals {
            if existingGoal.isFavorite && existingGoal.id != goal.id {
                existingGoal.isFavorite = false
            }
        }
        // Marcar la nueva meta como favorita
        goal.isFavorite = true

        // Guardar el contexto después de modificar las metas
        do {
            try modelContext.save()
        } catch {
            print("Error saving after setting favorite goal: \(error)")
        }

        fetchGoals()
    }

    func updateGoalProgress() {
        guard let modelContext = modelContext else { return }

        // Obtener ingresos y gastos
        let incomeFetchDescriptor = FetchDescriptor<IncomeModel>()
        let expenseFetchDescriptor = FetchDescriptor<ExpenseModel>()

        do {
            let incomes = try modelContext.fetch(incomeFetchDescriptor)
            let expenses = try modelContext.fetch(expenseFetchDescriptor)
            let totalIncomes = incomes.reduce(0) { $0 + $1.amount }
            let totalExpenses = expenses.reduce(0) { $0 + $1.amount }
            let netAmount = totalIncomes - totalExpenses

            // Por simplicidad, asignamos todo el monto neto a la meta favorita
            if let favoriteGoal = goals.first(where: { $0.isFavorite }) {
                favoriteGoal.current = min(netAmount, favoriteGoal.target)
            }

            try modelContext.save()
            fetchGoals()
        } catch {
            print("Error updating goal progress: \(error)")
        }
    }
}
