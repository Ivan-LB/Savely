//
//  NotificationSettingsStepView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 08/12/24.
//

import SwiftUI

struct NotificationSettingsStepView: View {
    @Binding var expenseReminderTime: Date
    @Binding var goalAlertTime: Date

    var body: some View {
        VStack(spacing: 20) {
            Text(Strings.Onboarding.notificationSettingsTitle)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            VStack(spacing: 20) {
                HStack {
                    Text(Strings.Onboarding.expenseReminderTimeLabel)
                    Spacer()
                    DatePicker("", selection: $expenseReminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                HStack {
                    Text(Strings.Onboarding.goalAlertTimeLabel)
                    Spacer()
                    DatePicker("", selection: $goalAlertTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
            .padding()
            .background(Color("cardBackgroundColor"))
            .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
            .shadow(radius: UIConstants.UIShadow.shadow)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct NotificationSettingsStepView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsStepView(expenseReminderTime: .constant(Date()), goalAlertTime: .constant(Date()))
    }
}
