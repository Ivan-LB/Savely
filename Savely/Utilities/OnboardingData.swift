//
//  OnboardingData.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 14/11/24.
//

import Foundation

struct OnboardingData {
    static let steps: [OnboardingStepModel] = [
        OnboardingStepModel(
            image: "dollarsign.circle",
            title: Strings.Onboarding.setGoalsTitle,
            description: Strings.Onboarding.setGoalsLabel
        ),
        OnboardingStepModel(
            image: "chart.bar",
            title: Strings.Onboarding.trackExpensesTitle,
            description: Strings.Onboarding.trackExpensesLabel
        ),
        OnboardingStepModel(
            image: "creditcard",
            title: Strings.Onboarding.trackIncomesTitle,
            description: Strings.Onboarding.trackIncomesLabel
        ),
        OnboardingStepModel(
            image: "lightbulb",
            title: Strings.Onboarding.receiveTipsTitle,
            description: Strings.Onboarding.receiveTipsLabel
        ),
        OnboardingStepModel(
            image: "bell",
            title: Strings.Onboarding.notificationSettingsTitle,
            description: Strings.Onboarding.notificationSettingsDescription
        )
    ]
}
