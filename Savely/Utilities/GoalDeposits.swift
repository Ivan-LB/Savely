//
//  GoalDeposits.swift
//  Savely
//
//  The one place money moves into a goal, and the one place pace math
//  lives. Every deposit flow (goal detail, dashboard sheet, quick-deposit
//  sheet, payday auto-move) goes through `record` so `GoalModel.current`
//  and the `DepositModel` ledger can never disagree.
//

import Foundation
import SwiftData

enum GoalDepositsError: LocalizedError {
    case nonPositiveAmount

    var errorDescription: String? {
        switch self {
        case .nonPositiveAmount: return "Enter an amount greater than zero."
        }
    }
}

enum GoalDeposits {
    /// Adds `amount` to the goal (clamped at its target, exactly as every
    /// flow already did), inserts the ledger row, and saves.
    ///
    /// - Returns: the deposit that was recorded. Its `amount` is the amount
    ///   *asked for*, not the clamped delta — the ledger records intent; the
    ///   goal records the capped result.
    @discardableResult
    static func record(
        goal: GoalModel,
        amount: Double,
        note: String? = nil,
        source: DepositSource,
        date: Date = Date(),
        context: ModelContext
    ) throws -> DepositModel {
        guard amount > 0 else { throw GoalDepositsError.nonPositiveAmount }
        goal.current = clampedCurrent(current: goal.current, adding: amount, target: goal.target)
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let deposit = DepositModel(
            goalID: goal.id,
            amount: amount,
            date: date,
            note: (trimmedNote?.isEmpty ?? true) ? nil : trimmedNote,
            source: source
        )
        context.insert(deposit)
        try context.save()
        return deposit
    }

    /// The clamp every flow used inline: never past the target.
    static func clampedCurrent(current: Double, adding amount: Double, target: Double) -> Double {
        min(current + amount, target)
    }

    /// Sum of deposits into any goal during the calendar month of `now` —
    /// the money the month has already set aside, which the payday
    /// suggestion must not offer twice.
    static func monthTotal(_ deposits: [DepositModel], now: Date = Date(), calendar: Calendar = .current) -> Double {
        deposits
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
}
