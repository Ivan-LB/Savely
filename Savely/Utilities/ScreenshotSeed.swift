//
//  ScreenshotSeed.swift
//  Savely
//
//  DEBUG-only fictional dataset for App Store screenshots. Applied once at
//  launch when the app is started with `-SavelyScreenshotSeed` (see
//  docs/plans/app-store-screenshots.md §3 for why these exact figures: every
//  caption in the store must be provable on the screen it sits over).
//
//  It WIPES the local store first — it exists for the Simulator only and is
//  compiled out of Release builds. Never run it against real data.
//

#if DEBUG
import Foundation
import SwiftData

enum ScreenshotSeed {
    static let launchArgument = "-SavelyScreenshotSeed"

    static var isRequested: Bool {
        CommandLine.arguments.contains(launchArgument)
    }

    /// Replaces everything in `context` with the screenshot dataset.
    @MainActor
    static func apply(to context: ModelContext, now: Date = Date(), calendar: Calendar = .current) throws {
        try context.delete(model: DepositModel.self)
        try context.delete(model: GoalModel.self)
        try context.delete(model: IncomeModel.self)
        try context.delete(model: ExpenseModel.self)

        func daysAgo(_ days: Int, hour: Int = 12) -> Date {
            let day = calendar.date(byAdding: .day, value: -days, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: 15, second: 0, of: day) ?? day
        }
        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? now
        }

        // Goal A — the favorite. $500 deposited inside GoalPace's 4-week
        // window → actual pace $125/wk; deadline Dec 12 2026 → required
        // ≈ $82/wk → "On track · by Dec 12, 2026 · $125/wk".
        let oaxaca = GoalModel(
            name: "Trip to Oaxaca", current: 1010, target: 2400, color: .sage,
            isFavorite: true, autoMoveEnabled: true, autoMoveAmount: 150,
            deadline: date(2026, 12, 12)
        )
        context.insert(oaxaca)
        for (offset, amount) in [(3, 125.0), (10, 125.0), (17, 125.0), (24, 125.0)] {
            context.insert(DepositModel(goalID: oaxaca.id, amount: amount, date: daysAgo(offset), source: .autoMove))
        }
        context.insert(DepositModel(goalID: oaxaca.id, amount: 510, date: daysAgo(60), source: .manual))

        // Goal B — honestly behind. $100 in the window → $25/wk; deadline
        // Mar 1 2027 → required ≈ $53/wk → "Behind"; ETA 59 wk → "1+ year".
        let laptop = GoalModel(
            name: "Laptop", current: 320, target: 1800, color: .blue,
            isFavorite: false, autoMoveEnabled: false, autoMoveAmount: 0,
            deadline: date(2027, 3, 1)
        )
        context.insert(laptop)
        for (offset, amount) in [(6, 50.0), (20, 50.0)] {
            context.insert(DepositModel(goalID: laptop.id, amount: amount, date: daysAgo(offset), source: .manual))
        }
        context.insert(DepositModel(goalID: laptop.id, amount: 220, date: daysAgo(75), source: .manual))

        // Goal C — small, on track, no deadline.
        let bike = GoalModel(name: "New bike", current: 180, target: 600, color: .yellow)
        context.insert(bike)
        context.insert(DepositModel(goalID: bike.id, amount: 60, date: daysAgo(9), source: .manual))
        context.insert(DepositModel(goalID: bike.id, amount: 120, date: daysAgo(40), source: .manual))

        // Income — one paycheck per month for seven months. Last month is
        // higher than this month so the 7-month trend shows a real drop.
        let paychecks: [Double] = [2200, 2400, 2350, 2500, 2450, 2600, 2280]
        for (i, amount) in paychecks.enumerated() {
            let monthsAgo = paychecks.count - 1 - i
            let base = calendar.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
            var comps = calendar.dateComponents([.year, .month], from: base)
            comps.day = min(12, calendar.component(.day, from: now)) // never in the future
            comps.hour = 9
            let payday = calendar.date(from: comps) ?? base
            context.insert(IncomeModel(incomeDescription: "Paycheck", amount: amount, date: payday, source: "Paycheck"))
        }
        context.insert(IncomeModel(incomeDescription: "Freelance", amount: 340, date: daysAgo(19), source: "Freelance"))

        // Expenses — this month, small and ordinary. Merchants are fictional.
        let expenses: [(String, Double, Int, ExpenseCategory)] = [
            ("Café Norte", 7.50, 0, .coffee),
            ("Corner Market", 23.80, 1, .food),
            ("Bus pass", 14.00, 2, .transit),
            ("Pharmacy", 32.10, 4, .shopping),
            ("Café Norte", 6.75, 5, .coffee),
            ("Taquería del Sol", 18.40, 6, .food),
            ("Corner Market", 41.25, 9, .food),
            ("Movie night", 24.00, 12, .other),
        ]
        for (name, amount, offset, category) in expenses {
            context.insert(ExpenseModel(expenseDescription: name, amount: amount, date: daysAgo(offset, hour: 18), category: category.rawValue))
        }

        try context.save()
    }
}
#endif
