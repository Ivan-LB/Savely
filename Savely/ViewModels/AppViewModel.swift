//
//  AppViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import FirebaseAuth

class AppViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var currentUserName: String = ""
    @Published var email: String = ""
    @Published var isLoading: Bool = true // Nuevo estado de carga
    
    var appState: AppState {
        if isLoading {
            return .loading
        } else if !isLoggedIn {
            return .loggedOut
        } else if !isOnboardingComplete {
            return .onboarding
        } else {
            return .main
        }
    }

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.isLoggedIn = user != nil
            if let user = user {
                self.fetchUserData(userId: user.uid)
            } else {
                self.resetUserData()
                self.isLoading = false
            }
        }
    }

    func fetchUserData(userId: String) {
        Task {
            do {
                let user = try await UserManager.shared.getUser(userId: userId)
                DispatchQueue.main.async {
                    self.isOnboardingComplete = user.isOnboardingComplete ?? false
                    self.currentUserName = user.displayName ?? ""
                    self.email = user.email ?? ""
                    self.isLoading = false // Datos cargados exitosamente
                }
            } catch {
                print("Error fetching user data: \(error)")
                DispatchQueue.main.async {
                    self.resetUserData()
                    self.isLoading = false
                }
            }
        }
    }

    private func resetUserData() {
        self.isOnboardingComplete = false
        self.currentUserName = ""
        self.email = ""
    }
}

enum AppState {
    case loading
    case loggedOut
    case onboarding
    case main
}
