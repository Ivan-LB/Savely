//
//  ContentView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    @State private var isLoggedIn = false
    
    var body: some View {
        if !isOnboardingComplete && isLoggedIn{
            OnboardingView(isOnboardingComplete: $isOnboardingComplete)
        } else if !isLoggedIn {
            LoginView()
        } else {
            MainNavigationView()
        }
    }
}

#Preview {
    ContentView()
}
