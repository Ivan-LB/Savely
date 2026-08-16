//
//  MoneyCategories.swift
//  Savely
//
//  The canonical expense categories and income sources — the chips the
//  quick-add sheets show, the values stored on the models, and the one
//  place their icon/tile pairing lives. Also the legacy keyword inference
//  used only for rows that predate stored categories.
//

import SwiftUI

/// The five expense chips. `rawValue` is exactly what `ExpenseModel.category`
/// stores, so renaming a case is a data migration — don't.
enum ExpenseCategory: String, CaseIterable, Identifiable {
    case coffee = "Coffee"
    case food = "Food"
    case transit = "Transit"
    case shopping = "Shopping"
    case other = "Other"

    var id: String { rawValue }
    var label: String { rawValue }

    var icon: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .food: return "fork.knife"
        case .transit: return "car.fill"
        case .shopping: return "bag.fill"
        case .other: return "creditcard"
        }
    }

    var tileBackground: Color {
        switch self {
        case .coffee: return .warmAmberSoft
        case .food: return .warmGreenSoft
        case .transit: return .warmSkySoft
        case .shopping: return .warmClaySoft
        case .other: return .warmBg
        }
    }

    var tileColor: Color {
        switch self {
        case .coffee: return .warmAmber
        case .food: return .warmGreen
        case .transit: return .warmSky
        case .shopping: return .warmClay
        case .other: return .warmInkMuted
        }
    }

    /// The category to *show* for a row: the stored chip when there is one,
    /// otherwise a keyword guess. The guess is display-only — it is never
    /// written back to the store.
    static func display(stored: String?, description: String) -> ExpenseCategory {
        if let stored, let known = ExpenseCategory(rawValue: stored) { return known }
        return legacyInferred(from: description)
    }

    /// The pre-categories heuristic the Money tab used to run on every row.
    /// Kept only for rows logged before `ExpenseModel.category` existed.
    static func legacyInferred(from description: String) -> ExpenseCategory {
        let d = description.lowercased()
        if d.contains("coffee") || d.contains("cafe") { return .coffee }
        if d.contains("grocery") || d.contains("groceries") || d.contains("whole foods")
            || d.contains("restaurant") || d.contains("food") { return .food }
        if d.contains("uber") || d.contains("lyft") || d.contains("transit") || d.contains("muni") { return .transit }
        return .other
    }
}

/// The four income chips. `rawValue` is what `IncomeModel.source` stores.
enum IncomeSource: String, CaseIterable, Identifiable {
    case paycheck = "Paycheck"
    case freelance = "Freelance"
    case gift = "Gift"
    case other = "Other"

    var id: String { rawValue }
    var label: String { rawValue }

    var icon: String {
        switch self {
        case .paycheck: return "building.columns"
        case .freelance: return "laptopcomputer"
        case .gift: return "gift"
        case .other: return "arrow.up"
        }
    }

    /// Nil when nothing was stored — legacy income rows show no source tag
    /// rather than a guessed one.
    static func display(stored: String?) -> IncomeSource? {
        stored.flatMap(IncomeSource.init(rawValue:))
    }
}
