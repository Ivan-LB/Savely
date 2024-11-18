//
//  MonthlySaving.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation

struct MonthlySavingModel: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}
