//
//  ExpenseModels.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation

struct ExpenseModel: Identifiable {
    let id: Int
    let description: String
    let amount: Double
    let date: String
}

struct ExpenseCategoryModel: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}
