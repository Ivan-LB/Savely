//
//  AchievementEngine.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/08/26.
//

import SwiftUI

/// Real, data-derived achievements (2026-08 — replaces the hardcoded mock
/// badges). Every unlock is computed live from what's actually in SwiftData:
/// no side-channel counters, no fabricated progress. If the data says you
/// didn't do it, the badge stays locked.
///
/// `AchievementStore` (below) only remembers which unlocks have already been
/// *celebrated*, so a badge pops exactly once.

struct AchievementState: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    /// Warm Meadow pairing used when unlocked; locked rows render muted.
    let tileColor: Color
    let tileBackground: Color
    let unlocked: Bool
    /// 0...1 — shown as a progress bar on locked badges; always 1 when unlocked.
    let progress: Double
}

/// Everything the engine needs, as plain values — keeps evaluation pure and
/// unit-testable without SwiftData.
struct AchievementInput {
    var incomeTotal: Double = 0
    var incomeCount: Int = 0
    var expenseCount: Int = 0
    /// Dates (any time of day) of every logged income and expense.
    var loggedDates: [Date] = []
    var goalCount: Int = 0
    /// Best `GoalModel.progress` across all goals, 0...1.
    var bestGoalProgress: Double = 0
    var completedGoalCount: Int = 0
    var calendar: Calendar = .current
}

enum AchievementEngine {
    private struct Definition {
        let id: String
        let title: String
        let subtitle: String
        let icon: String
        let tileColor: Color
        let tileBackground: Color
        let progress: (AchievementInput, _ streak: Int) -> Double
    }

    private static let definitions: [Definition] = [
        Definition(id: "first-income", title: "First seed", subtitle: "Log your first income",
                   icon: "leaf.fill", tileColor: .warmAmber, tileBackground: .warmAmberSoft,
                   progress: { input, _ in Double(min(input.incomeCount, 1)) }),
        Definition(id: "first-expense", title: "Eyes open", subtitle: "Log your first expense",
                   icon: "checkmark", tileColor: .warmGreen, tileBackground: .warmGreenSoft,
                   progress: { input, _ in Double(min(input.expenseCount, 1)) }),
        Definition(id: "goal-setter", title: "Goal setter", subtitle: "Create your first goal",
                   icon: "target", tileColor: .warmSky, tileBackground: .warmSkySoft,
                   progress: { input, _ in Double(min(input.goalCount, 1)) }),
        Definition(id: "half-way", title: "Half-way there", subtitle: "Reach 50% on any goal",
                   icon: "chart.line.uptrend.xyaxis", tileColor: .warmSky, tileBackground: .warmSkySoft,
                   progress: { input, _ in input.bestGoalProgress / 0.5 }),
        Definition(id: "goal-closer", title: "Goal closer", subtitle: "Complete a full goal",
                   icon: "flag.checkered", tileColor: .warmClay, tileBackground: .warmClaySoft,
                   progress: { input, _ in input.completedGoalCount >= 1 ? 1 : input.bestGoalProgress }),
        Definition(id: "full-week", title: "Full week", subtitle: "Log something 7 days in a row",
                   icon: "calendar", tileColor: .warmGreen, tileBackground: .warmGreenSoft,
                   progress: { _, streak in Double(streak) / 7 }),
        Definition(id: "steady-hand", title: "Steady hand", subtitle: "Keep a 30-day streak",
                   icon: "medal.fill", tileColor: .warmClay, tileBackground: .warmClaySoft,
                   progress: { _, streak in Double(streak) / 30 }),
        Definition(id: "century", title: "Century club", subtitle: "Keep a 100-day streak",
                   icon: "crown.fill", tileColor: .warmAmber, tileBackground: .warmAmberSoft,
                   progress: { _, streak in Double(streak) / 100 }),
        Definition(id: "saver", title: "Saver", subtitle: "Log $1,000 of income in total",
                   icon: "banknote", tileColor: .warmGreen, tileBackground: .warmGreenSoft,
                   progress: { input, _ in input.incomeTotal / 1_000 }),
        Definition(id: "big-saver", title: "Big saver", subtitle: "Log $10,000 of income in total",
                   icon: "arrow.up.circle.fill", tileColor: .warmAmber, tileBackground: .warmAmberSoft,
                   progress: { input, _ in input.incomeTotal / 10_000 }),
    ]

    static func evaluate(_ input: AchievementInput) -> [AchievementState] {
        let streak = longestDailyStreak(input.loggedDates, calendar: input.calendar)
        return definitions.map { def in
            let clamped = min(max(def.progress(input, streak), 0), 1)
            return AchievementState(
                id: def.id, title: def.title, subtitle: def.subtitle, icon: def.icon,
                tileColor: def.tileColor, tileBackground: def.tileBackground,
                unlocked: clamped >= 1, progress: clamped
            )
        }
    }

    /// Longest run of consecutive calendar days that have at least one
    /// logged movement. Duplicate same-day entries count once.
    static func longestDailyStreak(_ dates: [Date], calendar: Calendar = .current) -> Int {
        guard !dates.isEmpty else { return 0 }
        let days = Set(dates.map { calendar.startOfDay(for: $0) }).sorted()
        var longest = 1
        var current = 1
        for (previous, day) in zip(days, days.dropFirst()) {
            if let next = calendar.date(byAdding: .day, value: 1, to: previous), next == day {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }
}

/// Remembers which unlocks were already celebrated (UserDefaults), so the
/// unlock pop runs exactly once per badge.
enum AchievementStore {
    private static let key = "celebratedAchievementIds"

    static func newlyUnlocked(in states: [AchievementState]) -> Set<String> {
        let celebrated = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        return Set(states.filter(\.unlocked).map(\.id)).subtracting(celebrated)
    }

    static func markCelebrated(_ states: [AchievementState]) {
        let celebrated = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        let unlocked = Set(states.filter(\.unlocked).map(\.id))
        UserDefaults.standard.set(Array(celebrated.union(unlocked)).sorted(), forKey: key)
    }
}
