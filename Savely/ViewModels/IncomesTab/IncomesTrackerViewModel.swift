//
//  IncomesTrackerViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 19/11/24.
//

import Foundation
import SwiftUI
import SwiftData

class IncomesTrackerViewModel: ObservableObject {
    @Published var incomeDescription = ""
    @Published var amount = ""
    @Published var incomes: [IncomeModel] = []
    
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            fetchIncomes()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchIncomes()
    }

    func fetchIncomes() {
        guard let modelContext = modelContext else { return }
        let fetchDescriptor = FetchDescriptor<IncomeModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            incomes = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Error fetching incomes: \(error)")
            errorMessage = "Error al obtener los ingresos."
            showError = true
        }
    }

    func addIncome() {
        guard let modelContext = modelContext else { return }
        if let amountValue = Double(amount) {
            let newIncome = IncomeModel(
                incomeDescription: incomeDescription,
                amount: amountValue,
                date: Date()
            )
            modelContext.insert(newIncome)
            
            do {
                try modelContext.save()
                print("New income saved successfully")
                
                NotificationCenter.default.post(name: .incomeAdded, object: nil, userInfo: ["amount": amountValue])
            } catch {
                print("Error saving new income: \(error)")
                errorMessage = "Error al guardar el ingreso."
                showError = true
            }
            
            incomeDescription = ""
            amount = ""
            fetchIncomes()
        }
    }

    func deleteIncome(_ income: IncomeModel) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(income)

        do {
            try modelContext.save()
            print("Income deleted successfully")
           
            NotificationCenter.default.post(name: .incomeDeleted, object: nil, userInfo: ["amount": income.amount])
        } catch {
           print("Error saving after deleting income: \(error)")
           errorMessage = "Error al eliminar el ingreso."
           showError = true
        }

        fetchIncomes()
    }
}
