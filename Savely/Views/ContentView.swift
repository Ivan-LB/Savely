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
            case .loading:
                LoadingView()
                    .transition(.opacity)
                    .environmentObject(appViewModel)
            case .loggedOut:
                LoginView()
                    .transition(.slide)
                    .environmentObject(appViewModel)
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

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView(Strings.LoadingView.title)
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(1.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    ContentView()
}
