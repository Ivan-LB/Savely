//
//  ProfileViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var darkMode: Bool = false
    @Published var expenseReminders: Bool = true
    @Published var goalAlerts: Bool = true

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
            // Carga otras preferencias si las tienes almacenadas
        } catch {
            print("Error fetching user data: \(error)")
        }
    }

    func updatePersonalInformation() async {
        guard let uid = AuthenticationManager.shared.currentUser?.uid else {
            return
        }
        do {
            // Actualiza la información en Firestore
            try await UserManager.shared.updateUser(userId: uid, displayName: displayName, email: email)
            // Opcional: Actualiza el correo electrónico en Firebase Auth
            try await AuthenticationManager.shared.updateEmail(email: email)
        } catch {
            print("Error updating user data: \(error)")
        }
    }

    func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            // El AppViewModel manejará el cambio de estado de autenticación
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
