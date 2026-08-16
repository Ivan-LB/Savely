//
//  AutoMoveSuggestion.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/08/26.
//

import Foundation

/// The payday auto-move suggestion shown in the Log-income sheet
/// (2026-08 — replaces the hardcoded "$230 to Kyoto" placeholder).
///
/// Design decisions, deliberately (Iván: "que sí se haga pensamiento
/// crítico de lo mejor"):
///
/// **Which goal** — one suggestion, not a stack:
/// 1. The favorite goal wins — an explicit user signal outranks any math.
/// 2. Otherwise, the most *urgent* goal: highest required weekly pace
///    (`remaining ÷ weeks to its deadline`) — the goal that needs the most
///    dollars per week to still land on time.
/// 3. Goals without a deadline rank after dated ones, by lowest progress.
///    Name breaks ties so the pick is deterministic.
///
/// **How much** — never more than reality allows:
/// `min(configured pace, remaining to target, the income being logged,
/// the month's affordable margin)`. The margin is
/// `month incomes + this income − month expenses − month deposits`: if the
/// month is under water even counting this paycheck, nothing is suggested —
/// money the month already spent, or already moved into goals, should not
/// be "saved" into a goal again.
///
/// **When it moves** — never before the income is saved. YES only arms the
/// banner; the deposit is recorded with the save through
/// `GoalDeposits.record(source: .autoMove)`, the same path every manual
/// deposit takes.
struct AutoMoveSuggestion {
    let goal: GoalModel
    let amount: Double

    /// Minimum amount worth suggesting — below this the banner stays hidden.
    static let minimumAmount: Double = 1

    static func compute(
        goals: [GoalModel],
        incomeAmount: Double,
        monthIncomeTotal: Double = 0,
        monthExpenseTotal: Double = 0,
        monthDepositTotal: Double = 0,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> AutoMoveSuggestion? {
        guard incomeAmount >= minimumAmount else { return nil }

        let eligible = goals.filter {
            $0.autoMoveEnabled && $0.autoMoveAmount >= minimumAmount && $0.current < $0.target
        }
        guard !eligible.isEmpty else { return nil }

        func requiredWeeklyPace(_ goal: GoalModel) -> Double? {
            guard let deadline = goal.deadline, deadline > now else { return nil }
            let weeks = max(1, calendar.dateComponents([.weekOfYear], from: now, to: deadline).weekOfYear ?? 1)
            return (goal.target - goal.current) / Double(weeks)
        }

        let pick = eligible.sorted { a, b in
            if a.isFavorite != b.isFavorite { return a.isFavorite }
            switch (requiredWeeklyPace(a), requiredWeeklyPace(b)) {
            case let (paceA?, paceB?) where paceA != paceB:
                return paceA > paceB          // needs more $/week to land on time
            case (.some, .none):
                return true                    // dated goals outrank open-ended ones
            case (.none, .some):
                return false
            default:
                if a.progress != b.progress { return a.progress < b.progress }
                return a.name < b.name
            }
        }[0]

        // Affordability: what this month can actually spare, counting the
        // income being logged. Callers that pass no month totals get the
        // plain income cap.
        let monthMargin = monthIncomeTotal + incomeAmount - monthExpenseTotal - monthDepositTotal
        let remaining = pick.target - pick.current
        let raw = min(pick.autoMoveAmount, remaining, incomeAmount, max(0, monthMargin))
        let amount = (raw * 100).rounded() / 100
        guard amount >= minimumAmount else { return nil }

        return AutoMoveSuggestion(goal: pick, amount: amount)
    }
}
