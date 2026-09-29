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
            errorMessage = String(localized: "Couldn't load your goals. Please try again.")
            showError = true
        }
    }

    func addGoal() {
        guard let modelContext = modelContext else {
            print("modelContext is nil in addGoal")
            errorMessage = String(localized: "Your data isn't ready yet. Please try again.")
            showError = true
            return
        }
        guard let target = Double(targetAmount), target > 0 else {
            print("Invalid target amount")
            errorMessage = String(localized: "The target has to be more than $0.")
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
            errorMessage = String(localized: "Couldn't save the goal. Please try again.")
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
            errorMessage = String(localized: "Couldn't delete the goal. Please try again.")
            showError = true
        }
        fetchGoals()
        
        // Si la meta eliminada era la favorita, asignar una nueva favorita
        if goal.isFavorite {
            assignNewFavorite()
        }
    }


    /// Toggles the star: tapping the current favorite un-favorites it;
    /// tapping another goal moves the star there. At most one favorite.
    func setFavorite(goal: GoalModel) {
        guard let modelContext = modelContext else { return }

        let wasFavorite = goal.isFavorite
        for existingGoal in goals where existingGoal.isFavorite && existingGoal.id != goal.id {
            existingGoal.isFavorite = false
        }
        goal.isFavorite = !wasFavorite

        // Guardar el contexto después de modificar las metas
        do {
            try modelContext.save()
            print("Favorite goal updated successfully")
        } catch {
            print("Error saving after setting favorite goal: \(error)")
            errorMessage = String(localized: "Couldn't update your favorite goal. Please try again.")
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
                errorMessage = String(localized: "Couldn't choose a new favorite goal. Please try again.")
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
