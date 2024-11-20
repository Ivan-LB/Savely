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

