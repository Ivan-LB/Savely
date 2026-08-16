//
//  NotificationSettingsStepView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 08/12/24.
//

import SwiftUI

/// Last onboarding page — the only functional one: opt in or out of each
/// reminder and pick its time. The same `ReminderPreferences` the Profile
/// tab edits later, so the two never disagree.
/// Warm Meadow: clay tile, serif title, bordered surface card, no shadows.
struct NotificationSettingsStepView: View {
    @Binding var preferences: ReminderPreferences
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.warmClaySoft)
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: "bell")
                        .warmFont(40, weight: .medium)
                        .foregroundStyle(Color.warmClay)
                )
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(Strings.Onboarding.notificationSettingsTitle)
                    .warmFont(30, weight: .regular, design: .serif)
                    .foregroundStyle(Color.warmInk)
                    .multilineTextAlignment(.center)

                Text(Strings.Onboarding.notificationSettingsDescription)
                    .warmFont(15)
                    .foregroundStyle(Color.warmInkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 300)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            VStack(spacing: 0) {
                reminderRows(
                    title: Strings.Profile.expenseRemindersLabel,
                    icon: "bell.fill",
                    enabled: $preferences.expenseEnabled,
                    time: $preferences.expenseTime
                )
                WarmDivider()
                reminderRows(
                    title: Strings.Profile.goalAlertsLabel,
                    icon: "target",
                    enabled: $preferences.goalEnabled,
                    time: $preferences.goalTime
                )
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

    @ViewBuilder
    private func reminderRows(title: String, icon: String, enabled: Binding<Bool>, time: Binding<Date>) -> some View {
        SettingsToggleRow(icon: icon, title: title, isOn: enabled)
        if enabled.wrappedValue {
            ReminderTimeRow(time: time)
        }
    }
}

#Preview {
    NotificationSettingsStepView(preferences: .constant(.defaults()))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmBg)
}
