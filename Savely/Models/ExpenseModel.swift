//
//  ExpenseModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation
import SwiftData

@Model
class ExpenseModel {
    @Attribute(.unique) var id: UUID
    var expenseDescription: String
    var amount: Double
    var date: Date

    init(expenseDescription: String, amount: Double, date: Date) {
        self.id = UUID()
        self.expenseDescription = expenseDescription
        self.amount = amount
        self.date = date
    }
}
