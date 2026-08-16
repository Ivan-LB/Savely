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
            guard modelContext != nil else { return }
            fetchGoals()
        }
    }

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            fetchGoals()
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

    // Income and expense logging deliberately do NOT touch goal progress.
    // Goal money moves only through the explicit deposit flows and the
    // payday auto-move (AutoMoveSuggestion.apply), which is the single
    // place that turns an income into savings.
}
