//
//  OnboardingData.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 14/11/24.
//

import Foundation

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

//struct OnboardingData {
//    static let steps = [
//        OnboardingStep(
//            image: "dollarsign.circle",
//            title: "Establece Metas",
//            description: "Define tus objetivos financieros y trabaja para alcanzarlos."
//        ),
//        OnboardingStep(
//            image: "chart.bar",
//            title: "Rastrea tus Gastos",
//            description: "Registra y categoriza tus gastos para entender tus hábitos financieros."
//        ),
//        OnboardingStep(
//            image: "creditcard",
//            title: "Rastrea tus ingresos",
//            description: "Registra tus ingresos para planificar mejor tu presupuesto y alcanzar tus metas de ahorro."
//        ),
//        OnboardingStep(
//            image: "lightbulb",
//            title: "Recibe Consejos",
//            description: "Obtén consejos personalizados para mejorar tu salud financiera."
//        )
//    ]
//}
