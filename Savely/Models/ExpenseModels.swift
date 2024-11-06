//
//  ExpenseModels.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation

struct Expense: Identifiable {
    let id: Int
    let description: String
    let amount: Double
    let date: String
}

struct ExpenseCategory: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}
