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
        // Dark variants sit a step lighter (≥3:1 against the dark surface,
        // like the light ones against paper); see pr-d2-adaptive-palette.md.
        case .green:    return .warmGreen
        case .sage:     return Color(light: 0x5B8C68, dark: 0x75A582)
        case .teal:     return Color(light: 0x327F7F, dark: 0x40A4A4)
        case .blue:     return .warmSky
        case .navy:     return Color(light: 0x365189, dark: 0x4A6EB7)
        case .purple:   return Color(light: 0x955B89, dark: 0xAC77A1)
        case .lavender: return Color(light: 0x7D6AAC, dark: 0x9A8BBE)
        case .rose:     return Color(light: 0xA65674, dark: 0xB8778F)
        case .yellow:   return .warmAmber
        case .coral:    return Color(light: 0xC76C4E, dark: 0xD38C75)
        case .red:      return .warmClay
        case .brown:    return Color(light: 0x905E3C, dark: 0xB4764B)
        case .olive:    return Color(light: 0x6E7D32, dark: 0x8EA141)
        }
    }

    var trackColor: Color {
        switch self {
        case .green:    return .warmGreenSoft
        case .sage:     return Color(light: 0xDAEBE0, dark: 0x283E2E)
        case .teal:     return Color(light: 0xD1ECEC, dark: 0x283E3E)
        case .blue:     return .warmSkySoft
        case .navy:     return Color(light: 0xD1DAF0, dark: 0x282F3E)
        case .purple:   return Color(light: 0xEFE2EF, dark: 0x3E283A)
        case .lavender: return Color(light: 0xE1DEF5, dark: 0x2E283E)
        case .rose:     return Color(light: 0xF2DDE5, dark: 0x3E2830)
        case .yellow:   return .warmAmberSoft
        case .coral:    return Color(light: 0xF6E2DB, dark: 0x3E2D28)
        case .red:      return .warmClaySoft
        case .brown:    return Color(light: 0xEFE3DA, dark: 0x3E3128)
        case .olive:    return Color(light: 0xE5EDD6, dark: 0x3A3E28)
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
    /// Payday auto-move (2026-08): the AddGoalFlow wizard always ASKED for
    /// this but never persisted it — these fields make the promise real.
    /// Defaults keep existing stores migrating additively.
    var autoMoveEnabled: Bool = false
    /// Suggested amount to move each payday (whole dollars, from the wizard's monthly pace).
    var autoMoveAmount: Double = 0
    /// Target date from the wizard (also collected-but-unpersisted before
    /// 2026-08). Optional: pre-existing goals have none and rank last in
    /// auto-move urgency until one is set.
    var deadline: Date?

    var progress: Double {
        return target > 0 ? min(current / target, 1.0) : 0
    }

    var color: Color {
        return GoalColor(rawValue: colorRawValue)?.color ?? .warmGreen
    }

    var trackColor: Color {
        return GoalColor(rawValue: colorRawValue)?.trackColor ?? .warmGreenSoft
    }

    init(id: UUID = UUID(), name: String, current: Double = 0.0, target: Double, color: GoalColor, isFavorite: Bool = false, autoMoveEnabled: Bool = false, autoMoveAmount: Double = 0, deadline: Date? = nil) {
        self.id = id
        self.name = name
        self.current = current
        self.target = target
        self.colorRawValue = color.rawValue
        self.isFavorite = isFavorite
        self.autoMoveEnabled = autoMoveEnabled
        self.autoMoveAmount = autoMoveAmount
        self.deadline = deadline
    }
}
