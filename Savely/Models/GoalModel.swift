import Foundation
import SwiftUI
import SwiftData

enum GoalColor: String, Codable, CaseIterable, Identifiable {
    case green
    case sage
    case teal
    case blue
    case navy
    case purple
    case lavender
    case rose
    case yellow
    case coral
    case red
    case brown
    case olive

    var id: String { self.rawValue }

    var color: Color {
        switch self {
        case .green:    return .warmGreen
        case .sage:     return Color(red: 0.357, green: 0.549, blue: 0.408)
        case .teal:     return Color(red: 0.196, green: 0.498, blue: 0.498)
        case .blue:     return .warmSky
        case .navy:     return Color(red: 0.212, green: 0.318, blue: 0.537)
        case .purple:   return Color(red: 0.584, green: 0.357, blue: 0.537)
        case .lavender: return Color(red: 0.490, green: 0.416, blue: 0.675)
        case .rose:     return Color(red: 0.651, green: 0.337, blue: 0.455)
        case .yellow:   return .warmAmber
        case .coral:    return Color(red: 0.780, green: 0.424, blue: 0.306)
        case .red:      return .warmClay
        case .brown:    return Color(red: 0.565, green: 0.369, blue: 0.235)
        case .olive:    return Color(red: 0.431, green: 0.490, blue: 0.196)
        }
    }

    var trackColor: Color {
        switch self {
        case .green:    return .warmGreenSoft
        case .sage:     return Color(red: 0.855, green: 0.922, blue: 0.878)
        case .teal:     return Color(red: 0.820, green: 0.925, blue: 0.925)
        case .blue:     return .warmSkySoft
        case .navy:     return Color(red: 0.820, green: 0.855, blue: 0.941)
        case .purple:   return Color(red: 0.937, green: 0.886, blue: 0.937)
        case .lavender: return Color(red: 0.882, green: 0.871, blue: 0.961)
        case .rose:     return Color(red: 0.949, green: 0.867, blue: 0.898)
        case .yellow:   return .warmAmberSoft
        case .coral:    return Color(red: 0.965, green: 0.886, blue: 0.859)
        case .red:      return .warmClaySoft
        case .brown:    return Color(red: 0.937, green: 0.890, blue: 0.855)
        case .olive:    return Color(red: 0.898, green: 0.929, blue: 0.839)
        }
    }

    var displayName: String { rawValue.capitalized }
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
        return GoalColor(rawValue: colorRawValue)?.color ?? .warmGreen
    }

    var trackColor: Color {
        return GoalColor(rawValue: colorRawValue)?.trackColor ?? .warmGreenSoft
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
