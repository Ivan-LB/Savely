//
//  OnboardingView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var expenseReminderTime = Date()
    @State private var goalAlertTime = Date()
    let onboardingSteps = OnboardingData.steps
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        VStack {
            TabView(selection: $currentStep) {
                ForEach(0..<onboardingSteps.count, id: \.self) { index in
                    onboardingStepView(for: index)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

            Button(action: {
                handleButtonTap()
            }) {
                Text(currentStep < onboardingSteps.count - 1 ? Strings.Buttons.nextButton : Strings.Buttons.startButton)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .fontWeight(.bold)
                    .background(Color("primaryGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
            }
            .padding()
        }
        .background(Color("backgroundColor"))
    }

    private func onboardingStepView(for index: Int) -> some View {
        if index == onboardingSteps.count - 1 {
            return AnyView(
                NotificationSettingsStepView(
                    expenseReminderTime: $expenseReminderTime,
                    goalAlertTime: $goalAlertTime
                )
            )
        } else {
            return AnyView(
                OnboardingStepView(step: onboardingSteps[index])
            )
        }
    }

    private func handleButtonTap() {
        if currentStep < onboardingSteps.count - 1 {
            currentStep += 1
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        saveNotificationTimes()
        
        Task {
            do {
                try await UserManager.shared.updateOnboardingStatus(isComplete: true)
                appViewModel.isOnboardingComplete = true
                UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
                UserDefaults.standard.synchronize()
            } catch {
                print("Error updating onboarding status: \(error)")
            }
        }
    }

    private func saveNotificationTimes() {
        if let expenseReminderID = NotificationManager.shared.scheduleNotification(
            title: Strings.Notifications.expenseReminderTitle,
            body: Strings.Notifications.expenseReminderBody,
            identifier: "expenseReminder",
            date: expenseReminderTime
        ) {
            print("Expense Reminder Scheduled: \(expenseReminderID)")
        }

        if let goalAlertID = NotificationManager.shared.scheduleNotification(
            title: Strings.Notifications.goalAlertTitle,
            body: Strings.Notifications.goalAlertBody,
            identifier: "goalAlert",
            date: goalAlertTime
        ) {
            print("Goal Alert Scheduled: \(goalAlertID)")
        }
    }
}

#Preview {
    OnboardingView()
}
