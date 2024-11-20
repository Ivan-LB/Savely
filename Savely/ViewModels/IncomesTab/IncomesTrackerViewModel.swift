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
            print("Failed to fetch incomes: \(error)")
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
            incomeDescription = ""
            amount = ""
            fetchIncomes()
        }
    }

    func deleteIncome(_ income: IncomeModel) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(income)
        fetchIncomes()
    }
}
