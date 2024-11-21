//
//  Goal.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation
import SwiftUI
import SwiftData

enum GoalColor: String, Codable, CaseIterable, Identifiable {
    case green
    case blue
    case yellow
    case red
    case purple

    var id: String { self.rawValue }

    var color: Color {
        switch self {
        case .green: return .green
        case .blue: return .blue
        case .yellow: return .yellow
        case .red: return .red
        case .purple: return .purple
        }
    }
}

@Model
class GoalModel: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var current: Double
    var target: Double
    var colorRawValue: String
    var isFavorite: Bool

    var progress: Double {
        return target > 0 ? min(current / target, 1.0) : 0
    }

    var color: Color {
        return GoalColor(rawValue: colorRawValue)?.color ?? .gray
    }

    init(id: UUID = UUID(), name: String, current: Double = 0.0, target: Double, color: GoalColor, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.current = current
        self.target = target
        self.colorRawValue = color.rawValue
        self.isFavorite = isFavorite
    }
}
