//
//  ProfileViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var email: String = ""
    @AppStorage("darkModeEnabled") var darkMode: Bool = false // Sincronizado automáticamente
    @Published var expenseReminders: Bool = true
    @Published var goalAlerts: Bool = true
    
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""


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

    func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
