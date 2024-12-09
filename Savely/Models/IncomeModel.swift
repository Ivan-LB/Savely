//
//  IncomeModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 19/11/24.
//

import Foundation
import SwiftData

@Model
class IncomeModel {
    @Attribute(.unique) var id: UUID
    var incomeDescription: String
    var amount: Double
    var date: Date

    init(incomeDescription: String, amount: Double, date: Date) {
        self.id = UUID()
        self.incomeDescription = incomeDescription
        self.amount = amount
        self.date = date
    }
}

extension IncomeModel {
    @MainActor
    static func fetchWeeklyIncome(from startDate: Date, to endDate: Date, in modelContext: ModelContext) -> [IncomeModel] {
        print("Fetching incomes from \(startDate) to \(endDate)")

        // Precompute adjusted end date
        let adjustedEndDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: endDate)!)

        let fetchDescriptor = FetchDescriptor<IncomeModel>(
            predicate: #Predicate {
                $0.date >= startDate && $0.date < adjustedEndDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            let results = try modelContext.fetch(fetchDescriptor)
            print("Incomes fetched: \(results.count)")
            results.forEach { print("Income: \($0.incomeDescription), Amount: \($0.amount), Date: \($0.date)") }
            return results
        } catch {
            print("Error fetching incomes: \(error)")
            return []
        }
    }
}
