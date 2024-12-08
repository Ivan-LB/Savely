//
//  ProfileViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var email: String = ""
    @AppStorage("darkModeEnabled") var darkMode: Bool = false
    @Published var expenseReminders: Bool = true {
        didSet {
            handleExpenseReminderToggle()
        }
    }
    @Published var goalAlerts: Bool = true {
        didSet {
            handleGoalAlertToggle()
        }
    }

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var showExpenseReminderPicker: Bool = false
    @Published var showGoalAlertPicker: Bool = false
    @Published var selectedExpenseReminderTime: Date = Date()
    @Published var selectedGoalAlertTime: Date = Date()

    init() {
        Task {
            await fetchUserData()
        }
    }

    func fetchUserData() async {
        guard let uid = AuthenticationManager.shared.currentUser?.uid else {
            return
        }
        do {
            let user = try await UserManager.shared.getUser(userId: uid)
            self.displayName = user.displayName ?? ""
            self.email = user.email ?? ""
            // Puedes cargar otras preferencias aquí si es necesario
        } catch {
            print("Error fetching user data: \(error)")
        }
    }

    func updatePersonalInformation() async {
        guard let uid = AuthenticationManager.shared.currentUser?.uid else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }
        do {
            try await UserManager.shared.updateUser(userId: uid, displayName: displayName, email: email)
            try await AuthenticationManager.shared.updateEmail(email: email)
            alertMessage = "Your personal information has been updated successfully."
            showAlert = true
        } catch {
            alertMessage = "Failed to update your information: \(error.localizedDescription)"
            showAlert = true
        }
    }

    func handleExpenseReminderToggle() {
        if expenseReminders {
            showExpenseReminderPicker = true
        } else {
            NotificationManager.shared.cancelNotification(with: "expenseReminder")
        }
    }

    func handleGoalAlertToggle() {
        if goalAlerts {
            showGoalAlertPicker = true
        } else {
            NotificationManager.shared.cancelNotification(with: "goalAlert")
        }
    }

    func saveExpenseReminderTime() {
        _ = NotificationManager.shared.scheduleNotification(
            title: Strings.Notifications.expenseReminderTitle,
            body: Strings.Notifications.expenseReminderBody,
            identifier: "expenseReminder",
            date: selectedExpenseReminderTime
        )
    }

    func saveGoalAlertTime() {
        _ = NotificationManager.shared.scheduleNotification(
            title: Strings.Notifications.goalAlertTitle,
            body: Strings.Notifications.goalAlertBody,
            identifier: "goalAlert",
            date: selectedGoalAlertTime
        )
    }

    func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
