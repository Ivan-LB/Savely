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

    private var observerTokens: [NSObjectProtocol] = []

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            fetchIncomes()
        }
        observeIncomeChanges()
    }

    deinit {
        observerTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// The global "+" sheet saves through its own view-model instance, so this
    /// instance only hears about a new income through the notifications that
    /// `addIncome`/`deleteIncome` post. Without this the Money tab's list
    /// stayed stale until the app relaunched.
    private func observeIncomeChanges() {
        let refresh: (Notification) -> Void = { [weak self] _ in self?.fetchIncomes() }
        observerTokens = [.incomeAdded, .incomeDeleted].map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main, using: refresh)
        }
    }

    var totalIncomeThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        
        return incomes
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    var percentageChange: Double {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth) else {
            return 0
        }
        
        let thisMonthTotal = incomes
            .filter { $0.date >= startOfThisMonth }
            .reduce(0) { $0 + $1.amount }
        
        let lastMonthTotal = incomes
            .filter { $0.date >= startOfLastMonth && $0.date < startOfThisMonth }
            .reduce(0) { $0 + $1.amount }
        
        guard lastMonthTotal > 0 else {
            return thisMonthTotal > 0 ? 100 : 0
        }
        
        return ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100
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

    /// - Parameter source: the chip picked in the quick-add sheet; the inline
    ///   Money-tab form passes nothing.
    func addIncome(source: String? = nil) {
        guard let modelContext = modelContext else { return }
        guard let amountValue = parseAmount(amount) else {
            // Used to return silently, so a typo just did nothing at all.
            errorMessage = "Enter a valid amount greater than zero."
            showError = true
            return
        }

        let newIncome = IncomeModel(
            incomeDescription: incomeDescription,
            amount: amountValue,
            date: Date(),
            source: source
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
