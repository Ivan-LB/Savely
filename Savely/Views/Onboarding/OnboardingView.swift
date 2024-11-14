//
//  OnboardingView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @Binding var isOnboardingComplete: Bool
    let onboardingSteps = OnboardingData.steps
    
    var body: some View {
        VStack {
            TabView(selection: $currentStep) {
                ForEach(0..<onboardingSteps.count, id: \.self) { index in
                    OnboardingStepView(step: onboardingSteps[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
            Button(action: {
                if currentStep < onboardingSteps.count - 1 {
                    currentStep += 1
                } else {
                    isOnboardingComplete = true
                }
            }) {
                Text(currentStep < onboardingSteps.count - 1 ? Strings.Buttons.nextButton : Strings.Buttons.startButton)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .fontWeight(.bold)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
