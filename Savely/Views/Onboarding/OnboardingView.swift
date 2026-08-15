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
                NotificationSettingsStepView(
                    expenseReminderTime: $expenseReminderTime,
                    goalAlertTime: $goalAlertTime
                )
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
        saveNotificationTimes()
        appViewModel.completeOnboarding()
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
        .environmentObject(AppViewModel())
}
