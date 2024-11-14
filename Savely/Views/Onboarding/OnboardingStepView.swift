//
//  OnboardingStep.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct OnboardingStepView: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: step.image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text(step.title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(step.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

#Preview {
    OnboardingStepView(step: OnboardingStep(
        image: "dollarsign.circle",
        title: Strings.Onboarding.setGoalsTitle,
        description: Strings.Onboarding.setGoalsLabel
    ))
}
