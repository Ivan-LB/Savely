//
//  ContentView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()

    var body: some View {
        ZStack {
            switch appViewModel.appState {
            case .onboarding:
                OnboardingView()
                    .transition(.slide)
                    .environmentObject(appViewModel)
            case .main:
                MainNavigationView()
                    .transition(.slide)
                    .environmentObject(appViewModel)
            }
        }
        .sheet(isPresented: $appViewModel.showNetworkWarning) {
            NetworkErrorView(isPresented: $appViewModel.showNetworkWarning)
        }
    }
}

#Preview {
    ContentView()
}
