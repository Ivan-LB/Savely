//
//  AchievementsData.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 14/11/24.
//

import Foundation

struct AchievementsData {
    static let allAchievements = [
        Achievement(id: 1, title: Strings.Achievements.firstGoalTitle, description: Strings.Achievements.firstGoalDescription, iconName: "star.fill", achieved: true),
        Achievement(id: 2, title: Strings.Achievements.threeGoalsTitle, description: Strings.Achievements.threeGoalsDescription, iconName: "trophy.fill", achieved: false),
        Achievement(id: 3, title: Strings.Achievements.consistentSavingsTitle, description: Strings.Achievements.consistentSavingsDescription, iconName: "calendar.circle.fill", achieved: true),
        Achievement(id: 4, title: Strings.Achievements.noUnnecessarySpendingTitle, description: Strings.Achievements.noUnnecessarySpendingDescription, iconName: "checkmark.seal.fill", achieved: false),
        Achievement(id: 5, title: Strings.Achievements.weeklyBudgetTitle, description: Strings.Achievements.weeklyBudgetDescription, iconName: "wallet.fill", achieved: false),
        Achievement(id: 6, title: Strings.Achievements.emergencyFundTitle, description: Strings.Achievements.emergencyFundDescription, iconName: "umbrella.fill", achieved: false),
        Achievement(id: 7, title: Strings.Achievements.highSavingsRateTitle, description: Strings.Achievements.highSavingsRateDescription, iconName: "banknote.fill", achieved: false),
        Achievement(id: 8, title: Strings.Achievements.firstInvestmentTitle, description: Strings.Achievements.firstInvestmentDescription, iconName: "chart.pie.fill", achieved: false),
        Achievement(id: 9, title: Strings.Achievements.subscriptionCleanupTitle, description: Strings.Achievements.subscriptionCleanupDescription, iconName: "scissors", achieved: false),
        Achievement(id: 10, title: Strings.Achievements.debtPaidOffTitle, description: Strings.Achievements.debtPaidOffDescription, iconName: "checkmark.shield.fill", achieved: false)
    ]
}

