//
//  Goal.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation
import SwiftUI
import SwiftData

enum GoalColor: String, Codable {
    case green
    case blue
    case yellow
    case red

    var color: Color {
        switch self {
        case .green: return .green
        case .blue: return .blue
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}

@Model
class GoalModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var current: Double
    var target: Double
    var colorRawValue: String
    var isFavorite: Bool

    init(name: String, current: Double = 0.0, target: Double, color: GoalColor, isFavorite: Bool = false) {
        self.id = UUID()
        self.name = name
        self.current = current
        self.target = target
        self.colorRawValue = color.rawValue
        self.isFavorite = isFavorite
    }

    var progress: Double {
        return target > 0 ? current / target : 0
    }

    var color: Color {
        return GoalColor(rawValue: colorRawValue)?.color ?? .gray
    }
}
