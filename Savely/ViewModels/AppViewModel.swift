//
//  AppViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import FirebaseAuth
import Network

class AppViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var currentUserName: String = ""
    @Published var email: String = ""
    @Published var isLoading: Bool = true
    @Published var showNetworkWarning: Bool = false // For modal warning about limited features

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)

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
        print("AppViewModel initialized")
        self.loadOnboardingState()
        self.isLoading = true
        self.addAuthStateListener()
        self.startNetworkMonitoring()
    }

    private func addAuthStateListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            print("Auth state changed: User logged in? \(user != nil)")
            self.isLoggedIn = user != nil

            if let user = user {
                print("User ID: \(user.uid)")
                self.fetchUserData(userId: user.uid)
            } else {
                print("No user found, falling back to local state.")
                self.fallbackToLocalState()
                self.isLoading = false
            }
        }
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        monitor.cancel()
    }

    private func fetchUserData(userId: String) {
        print("Fetching user data for user ID: \(userId)")
        Task {
            do {
                let user = try await UserManager.shared.getUser(userId: userId)
                DispatchQueue.main.async {
                    self.isOnboardingComplete = user.isOnboardingComplete ?? self.isOnboardingComplete
                    print("Fetched onboarding status: \(self.isOnboardingComplete)")
                    self.saveOnboardingState(self.isOnboardingComplete)
                    self.currentUserName = user.displayName ?? ""
                    self.email = user.email ?? ""
                    self.isLoading = false
                }
            } catch {
                print("Error fetching user data: \(error)")
                DispatchQueue.main.async {
                    print("Falling back to local onboarding state.")
                    self.fallbackToLocalState()
                    self.isLoading = false
                }
            }
        }
    }

    private func saveOnboardingState(_ state: Bool) {
        UserDefaults.standard.set(state, forKey: "isOnboardingComplete")
        print("Onboarding state saved: \(state)")
    }

    private func loadOnboardingState() {
        if let savedState = UserDefaults.standard.value(forKey: "isOnboardingComplete") as? Bool {
            isOnboardingComplete = savedState
            print("Loaded onboarding state from UserDefaults: \(savedState)")
        }
    }

    private func fallbackToLocalState() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
        print("Fallback to local onboarding state: \(self.isOnboardingComplete)")
    }

    private func resetUserData() {
        self.isOnboardingComplete = false
        self.currentUserName = ""
        self.email = ""
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .unsatisfied {
                    print("No network connection detected.")
                    self.showNetworkWarning = true
                } else {
                    print("Network connection detected.")
                    self.showNetworkWarning = false
                }
            }
        }
        monitor.start(queue: queue)
    }
}


enum AppState {
    case loading
    case loggedOut
    case onboarding
    case main
}
