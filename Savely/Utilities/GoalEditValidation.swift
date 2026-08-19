//
//  GoalEditValidation.swift
//  Savely
//
//  The rules the goal edit sheet enforces, as a pure function so they can
//  be unit-tested without a view.
//

import Foundation

enum GoalEditError: Equatable, LocalizedError {
    case emptyName
    case nonPositiveTarget
    case targetBelowSaved(saved: Double)
    case deadlineInPast
    case nonPositiveAutoMove

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Give the goal a name."
        case .nonPositiveTarget:
            return "The target has to be more than $0."
        case .targetBelowSaved(let saved):
            let f = NumberFormatter(); f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 0
            let savedText = f.string(from: NSNumber(value: saved)) ?? "$0"
            return "You've already saved \(savedText) — the target can't be lower than that."
        case .deadlineInPast:
            return "Pick a date in the future, or turn the date off."
        case .nonPositiveAutoMove:
            return "Set an auto-move amount above $0, or turn auto-move off."
        }
    }
}

struct GoalEditDraft: Equatable {
    var name: String
    var target: Double
    var hasDeadline: Bool
    var deadline: Date
    var autoMoveEnabled: Bool
    var autoMoveAmount: Double

    /// The name as it will be saved.
    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
}

enum GoalEditValidation {
    /// First rule broken, or nil when the draft can be saved.
    /// `current` is what the goal already holds — the target may not drop
    /// below it (shrinking under saved money would show >100% and mean
    /// nothing).
    static func firstError(in draft: GoalEditDraft, current: Double, now: Date = Date()) -> GoalEditError? {
        if draft.trimmedName.isEmpty { return .emptyName }
        if draft.target <= 0 { return .nonPositiveTarget }
        if draft.target < current { return .targetBelowSaved(saved: current) }
        if draft.hasDeadline && draft.deadline <= now { return .deadlineInPast }
        if draft.autoMoveEnabled && draft.autoMoveAmount <= 0 { return .nonPositiveAutoMove }
        return nil
    }
}
