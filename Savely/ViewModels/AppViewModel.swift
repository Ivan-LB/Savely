//
//  AppViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation
import Network

/// App-level state. Local-first since the auth removal (2026-08): there is
/// no account and no profile — the app goes straight from launch to
/// onboarding (first run) or the main tabs.
class AppViewModel: ObservableObject {
    @Published var isOnboardingComplete: Bool
    @Published var showNetworkWarning: Bool = false // For modal warning about limited features

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)

    var appState: AppState {
        isOnboardingComplete ? .main : .onboarding
    }

    init() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
        self.startNetworkMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.showNetworkWarning = (path.status == .unsatisfied)
            }
        }
        monitor.start(queue: queue)
    }
}

enum AppState {
    case onboarding
    case main
}
