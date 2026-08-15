//
//  NotificationSettingsStepView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 08/12/24.
//

import SwiftUI

/// Last onboarding page — the only functional one (pick reminder times).
/// Warm Meadow: clay tile, serif title, bordered surface card, no shadows.
struct NotificationSettingsStepView: View {
    @Binding var expenseReminderTime: Date
    @Binding var goalAlertTime: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.warmClaySoft)
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: "bell")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(Color.warmClay)
                )
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                Text(Strings.Onboarding.notificationSettingsTitle)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(Color.warmInk)
                    .multilineTextAlignment(.center)

                Text(Strings.Onboarding.notificationSettingsDescription)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.warmInkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 300)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            VStack(spacing: 0) {
                HStack {
                    Text(Strings.Onboarding.expenseReminderTimeLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.warmInk)
                    Spacer()
                    DatePicker("", selection: $expenseReminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                WarmDivider()

                HStack {
                    Text(Strings.Onboarding.goalAlertTimeLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.warmInk)
                    Spacer()
                    DatePicker("", selection: $goalAlertTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.warmSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
            .padding(.horizontal, 8)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
        .padding(.horizontal, 24)
        .onAppear {
            guard !appeared else { return }
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.9).delay(0.05)) {
                    appeared = true
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsStepView(expenseReminderTime: .constant(Date()), goalAlertTime: .constant(Date()))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmBg)
}
