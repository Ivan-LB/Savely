//
//  ReportsViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 08/12/24.
//

import SwiftUI
import SwiftData

@MainActor
class ReportsViewModel: ObservableObject {
    @Published var weeklyIncomes: [IncomeModel] = []
    @Published var weeklyExpenses: [ExpenseModel] = []
    @Published var isLoading: Bool = false
    @Published var startDate: Date
    @Published var endDate: Date

    var modelContext: ModelContext? {
        didSet {
            guard let modelContext = modelContext else { return }
            fetchReportData()
        }
    }

    init(modelContext: ModelContext? = nil, startDate: Date = Calendar.current.startOfWeek(for: Date()), endDate: Date = Date()) {
        self.modelContext = modelContext
        self.startDate = startDate
        self.endDate = endDate

        if modelContext != nil {
            fetchReportData()
        }
    }

    func setModelContext(_ context: ModelContext) {
        print("Setting modelContext for ReportsViewModel")
        self.modelContext = context
    }

    func fetchReportData() {
        guard let modelContext = modelContext else {
            print("ModelContext is nil. Cannot fetch report data.")
            return
        }
        guard !isLoading else {
            print("Already loading data. Skipping fetch.")
            return
        }

        isLoading = true
        print("Fetching report data... Start Date: \(startDate), End Date: \(endDate)")

        Task {
            do {
                // Fetch incomes
                let incomes = try await fetchWeeklyIncome(from: startDate, to: endDate, in: modelContext)
                print("Fetched incomes count: \(incomes.count)")

                // Fetch expenses
                let expenses = try await fetchWeeklyExpenses(from: startDate, to: endDate, in: modelContext)
                print("Fetched expenses count: \(expenses.count)")

                weeklyIncomes = incomes
                weeklyExpenses = expenses
            } catch {
                print("Error fetching report data: \(error)")
            }
            isLoading = false
        }
    }

    private func fetchWeeklyIncome(from startDate: Date, to endDate: Date, in context: ModelContext) async throws -> [IncomeModel] {
        print("Fetching weekly incomes...")

        let adjustedStartDate = Calendar.current.startOfDay(for: startDate)
        let adjustedEndDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: endDate)!)

        let fetchDescriptor = FetchDescriptor<IncomeModel>(
            predicate: #Predicate {
                $0.date >= adjustedStartDate && $0.date < adjustedEndDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(fetchDescriptor)
    }

    private func fetchWeeklyExpenses(from startDate: Date, to endDate: Date, in context: ModelContext) async throws -> [ExpenseModel] {
        print("Fetching weekly expenses...")

        let adjustedStartDate = Calendar.current.startOfDay(for: startDate)
        let adjustedEndDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: endDate)!)

        let fetchDescriptor = FetchDescriptor<ExpenseModel>(
            predicate: #Predicate {
                $0.date >= adjustedStartDate && $0.date < adjustedEndDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(fetchDescriptor)
    }
}
