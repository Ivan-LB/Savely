//
//  OnboardingView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var reminders = ReminderPreferences.defaults()
    let featureSteps = OnboardingData.steps
    @EnvironmentObject var appViewModel: AppViewModel

    /// welcome + feature steps + notifications
    private var pageCount: Int { featureSteps.count + 2 }
    private var isLastStep: Bool { currentStep == pageCount - 1 }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentStep) {
                WelcomeStepView()
                    .tag(0)
                ForEach(Array(featureSteps.enumerated()), id: \.offset) { index, step in
                    OnboardingStepView(step: step)
                        .tag(index + 1)
                }
                NotificationSettingsStepView(preferences: $reminders)
                    .tag(pageCount - 1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom page dots — the active one stretches into a pill.
            HStack(spacing: 7) {
                ForEach(0..<pageCount, id: \.self) { i in
                    Capsule()
                        .fill(i == currentStep ? Color.warmGreen : Color.warmLine)
                        .frame(width: i == currentStep ? 22 : 7, height: 7)
                        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: currentStep)
                }
            }
            .padding(.bottom, 20)

            Button(action: handleButtonTap) {
                Text(isLastStep ? Strings.Buttons.startButton : Strings.Buttons.nextButton)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.warmGreen)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color.warmBg.ignoresSafeArea())
    }

    private func handleButtonTap() {
        if isLastStep {
            completeOnboarding()
        } else {
            withAnimation { currentStep += 1 }
        }
    }

    private func completeOnboarding() {
        // Persist first, then schedule only what was left on — the Profile
        // tab reads the same store, so the two can never disagree.
        ReminderStore().save(reminders)
        NotificationManager.shared.apply(reminders)
        appViewModel.completeOnboarding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppViewModel())
}
