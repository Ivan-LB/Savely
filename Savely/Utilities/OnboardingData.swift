//
//  OnboardingData.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 14/11/24.
//

import SwiftUI

struct OnboardingData {
    /// Feature steps between the welcome page and the notifications page.
    /// The tips step only exists while `FeatureFlags.tipsEnabled` is on —
    /// the App Store release must not advertise a hidden feature.
    static var steps: [OnboardingStepModel] {
        var steps: [OnboardingStepModel] = [
            OnboardingStepModel(
                image: "target",
                title: Strings.Onboarding.setGoalsTitle,
                description: Strings.Onboarding.setGoalsLabel,
                tileColor: .warmSky,
                tileBackground: .warmSkySoft
            ),
            OnboardingStepModel(
                image: "chart.bar",
                title: Strings.Onboarding.trackMoneyTitle,
                description: Strings.Onboarding.trackMoneyLabel,
                tileColor: .warmGreen,
                tileBackground: .warmGreenSoft
            ),
            OnboardingStepModel(
                image: "doc.viewfinder",
                title: Strings.Onboarding.scanReceiptsTitle,
                description: Strings.Onboarding.scanReceiptsLabel,
                tileColor: .warmAmber,
                tileBackground: .warmAmberSoft
            ),
        ]
        if FeatureFlags.tipsEnabled {
            steps.append(OnboardingStepModel(
                image: "lightbulb",
                title: Strings.Onboarding.receiveTipsTitle,
                description: Strings.Onboarding.receiveTipsLabel,
                tileColor: .warmClay,
                tileBackground: .warmClaySoft
            ))
        }
        return steps
    }
}
