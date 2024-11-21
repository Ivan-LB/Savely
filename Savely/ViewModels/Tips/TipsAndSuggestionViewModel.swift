//
//  TipViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/11/24.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class TipsAndSuggestionViewModel: ObservableObject {
    @Published var currentTip: TipModel?
    var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if let context = modelContext {
            self.loadTip(context: context)
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        self.loadTip(context: context)
    }
    
    func loadTip(context: ModelContext) {
        // Verificar si existe un tip para la fecha actual
        let today = Calendar.current.startOfDay(for: Date())
        let fetchDescriptor = FetchDescriptor<TipModel>(
            predicate: #Predicate { $0.date >= today },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            let tips = try context.fetch(fetchDescriptor)
            if let tip = tips.first {
                self.currentTip = tip
            } else {
                // No hay tip para hoy, generar uno nuevo
                self.generateTip(context: context)
            }
        } catch {
            print("Error fetching tips: \(error)")
        }
    }
    
    func generateTip(context: ModelContext) {
        // Verificar nuevamente si hay un tip para hoy para evitar condiciones de carrera
        let today = Calendar.current.startOfDay(for: Date())
        let fetchDescriptor = FetchDescriptor<TipModel>(
            predicate: #Predicate { $0.date >= today },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            let tips = try context.fetch(fetchDescriptor)
            if tips.first != nil {
                // Ya existe un tip para hoy
                self.currentTip = tips.first
                return
            }
        } catch {
            print("Error fetching tips before generating: \(error)")
        }
        
        do {
            // Ingresos
            let incomes = try context.fetch(FetchDescriptor<IncomeModel>())
            let totalIncome = incomes.reduce(0) { $0 + $1.amount }
    
            // Gastos
            let expenses = try context.fetch(FetchDescriptor<ExpenseModel>())
            let totalExpenses = expenses.reduce(0) { $0 + $1.amount }
    
            // Metas
            let goals = try context.fetch(FetchDescriptor<GoalModel>())
            let goalNames = goals.map { $0.name }
            let goalProgress = goals.map { "\($0.name): \((Int($0.progress * 100)))%" }
                
            // Obtener el idioma del teléfono
            let locale = Locale.current
            let languageCode = locale.language.languageCode?.identifier ?? "en"
            let supportedLanguages = ["English", "Spanish"]
            let languageName = locale.localizedString(forLanguageCode: languageCode) ?? "English"
            let languageNamePrompt = supportedLanguages.contains(languageName) ? languageName : "English"
    
            // Construir el prompt optimizado en inglés
            let prompt = """
            As a personal financial assistant, provide a concise, motivating, and actionable financial tip based on the following data:
            - **Total Income for the Month:** $\(totalIncome)
            - **Total Expenses for the Month:** $\(totalExpenses)
            - **Current Financial Goals:** \(goalNames.joined(separator: ", "))
            - **Progress Towards Goals:** \(goalProgress.joined(separator: "\n"))
            **Guidelines:**
            1. **Brevity:** The tip should be no longer than 150 words.
            2. **Motivational Tone:** Encourage the user to stay focused on their financial goals.
            3. **Practical Actions:** Provide clear, actionable steps the user can take to improve their financial situation.
            4. **Markdown Formatting:** Use Markdown for better readability, including bold text and bullet points where appropriate.
            5. **Personalization:** Tailor the advice based on the user's current financial data and goals.
            6. **Token Limit:** Ensure the response does not exceed 300 tokens.
            
            Please provide the advice in \(languageNamePrompt).
            """
    
            // Llamar a la API de OpenAI
            Task { @MainActor in
                if let tipContent = await OpenAIClient.shared?.fetchTip(prompt: prompt) {
                    let newTip = TipModel(date: Date(), content: tipContent)
                    context.insert(newTip)
                    do {
                        try context.save()
                        self.currentTip = newTip
                    } catch {
                        print("Error saving new tip: \(error)")
                    }
                } else {
                    // Manejo del error o ausencia de tip
                    let errorMessage: String
                    switch languageCode {
                    case "es":
                        errorMessage = "No se pudo generar un consejo en este momento. Por favor, inténtalo más tarde."
                    default:
                        errorMessage = "Could not generate a tip at this time. Please try again later."
                    }
                    self.currentTip = TipModel(date: Date(), content: errorMessage)
                }
            }
        } catch {
            print("Error gathering user data: \(error)")
        }
    }
}
