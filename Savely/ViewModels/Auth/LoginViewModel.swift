//
//  AuthenticationViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation

@MainActor
final class LoginViewModel: NSObject, ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    func signInApple() async throws {
        let tokens = try await SignInWithAppleHelper.shared.startSignInWithAppleFlow()
        let authDataResult = try await AuthenticationManager.shared.signInWithApple(tokens: tokens)
        
        try await UserManager.shared.createNewUser(auth: authDataResult, displayName: tokens.name)
    }
    
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email or password found.")
            return
        }
        
        try await AuthenticationManager.shared.signInUser(email: email, password: password)
    }
}
