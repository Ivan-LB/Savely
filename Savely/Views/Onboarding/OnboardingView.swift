//
//  OnboardingView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    let onboardingSteps = OnboardingData.steps
    @EnvironmentObject var appViewModel: AppViewModel
    
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
                    Task {
                        do {
                            try await UserManager.shared.updateOnboardingStatus(isComplete: true)
                            appViewModel.isOnboardingComplete = true
                        } catch {
                            print("Error updating onboarding status: \(error)")
                        }
                    }
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
    OnboardingView()
}
