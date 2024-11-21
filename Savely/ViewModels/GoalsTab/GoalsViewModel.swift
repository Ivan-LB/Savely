//
//  GoalsViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 19/11/24.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class GoalsViewModel: ObservableObject {
    @Published var goals: [GoalModel] = []
    @Published var name: String = ""
    @Published var targetAmount: String = ""
    @Published var selectedColor: GoalColor = .green
    
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    var modelContext: ModelContext? {
        didSet {
            guard let modelContext = modelContext, !isNotificationsSetup else { return }
            fetchGoals()
            setupNotifications()
        }
    }
    
    private var isNotificationsSetup = false
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            fetchGoals()
            setupNotifications()
        }
    }

    func setModelContext(_ context: ModelContext) {
        print("Setting modelContext")
        self.modelContext = context
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
            errorMessage = "Error al obtener las metas."
            showError = true
        }
    }

    func addGoal() {
        guard let modelContext = modelContext else {
            print("modelContext is nil in addGoal")
            errorMessage = "El contexto del modelo está vacío."
            showError = true
            return
        }
        guard let target = Double(targetAmount), target > 0 else {
            print("Invalid target amount")
            errorMessage = "La cantidad objetivo debe ser un número positivo."
            showError = true
            return
        }
        let isFirstGoal = goals.isEmpty

        let newGoal = GoalModel(
            name: name,
            target: target,
            color: selectedColor,
            isFavorite: isFirstGoal
        )
        print("Inserting new goal: \(newGoal.name), Target: \(newGoal.target)")
        modelContext.insert(newGoal)
        
        // Guardar el contexto después de insertar la nueva meta
        do {
            try modelContext.save()
            print("New goal saved successfully")
        } catch {
            print("Error saving new goal: \(error)")
            errorMessage = "Error al guardar la nueva meta."
            showError = true
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
            print("Goal deleted successfully")
        } catch {
            print("Error saving after deleting goal: \(error)")
            errorMessage = "Error al eliminar la meta."
            showError = true
        }
        fetchGoals()
        
        // Si la meta eliminada era la favorita, asignar una nueva favorita
        if goal.isFavorite {
            assignNewFavorite()
        }
    }


    func setFavorite(goal: GoalModel) {
        guard let modelContext = modelContext else { return }

        // Desmarcar todas las metas excepto la seleccionada
        for existingGoal in goals where existingGoal.isFavorite && existingGoal.id != goal.id {
            existingGoal.isFavorite = false
        }
        // Marcar la meta seleccionada como favorita
        goal.isFavorite = true

        // Guardar el contexto después de modificar las metas
        do {
            try modelContext.save()
            print("Favorite goal updated successfully")
        } catch {
            print("Error saving after setting favorite goal: \(error)")
            errorMessage = "Error al actualizar la meta favorita."
            showError = true
        }

        fetchGoals()
    }

    private func assignNewFavorite() {
        guard let modelContext = modelContext else { return }
        // Asignar la primera meta como favorita si existe alguna
        if let firstGoal = goals.first {
            firstGoal.isFavorite = true
            do {
                try modelContext.save()
                print("New favorite goal assigned")
            } catch {
                print("Error assigning new favorite goal: \(error)")
                errorMessage = "Error al asignar una nueva meta favorita."
                showError = true
            }
            fetchGoals()
        }
    }

    // MARK: - Configurar Observadores de Notificaciones

    private func setupNotifications() {
        guard !isNotificationsSetup else { return }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleIncomeAdded(_:)), name: .incomeAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleIncomeDeleted(_:)), name: .incomeDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleExpenseAdded(_:)), name: .expenseAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleExpenseDeleted(_:)), name: .expenseDeleted, object: nil)
        
        isNotificationsSetup = true
    }
    
    @objc private func handleIncomeAdded(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let amount = userInfo["amount"] as? Double else { return }
        
        updateFavoriteGoalProgress(by: amount)
    }

    @objc private func handleIncomeDeleted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let amount = userInfo["amount"] as? Double else { return }
        
        updateFavoriteGoalProgress(by: -amount)
    }

    @objc private func handleExpenseAdded(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let amount = userInfo["amount"] as? Double else { return }
        
        updateFavoriteGoalProgress(by: -amount)
    }

    @objc private func handleExpenseDeleted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let amount = userInfo["amount"] as? Double else { return }
        
        updateFavoriteGoalProgress(by: amount)
    }

    private func updateFavoriteGoalProgress(by amount: Double) {
        guard let modelContext = modelContext else { return }
        guard let favoriteGoal = goals.first(where: { $0.isFavorite }) else {
            print("No favorite goal found to update progress.")
            return
        }
        
        favoriteGoal.current += amount
        favoriteGoal.current = max(min(favoriteGoal.current, favoriteGoal.target), 0) // Limitar entre 0 y target
        
        do {
            try modelContext.save()
            print("Favorite goal progress updated by \(amount). New current: \(favoriteGoal.current)")
        } catch {
            print("Error updating favorite goal progress: \(error)")
            errorMessage = "Error al actualizar el progreso de la meta favorita."
            showError = true
        }
        
        fetchGoals()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
