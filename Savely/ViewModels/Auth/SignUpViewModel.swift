//
//  SignUpViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 18/11/24.
//

import Foundation

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var confirmPassword = ""
    
    var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    func signUp() async throws {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            print("Faltan campos obligatorios.")
            return
        }

        guard passwordsMatch else {
            print("Las contraseñas no coinciden.")
            return
        }

        // Crear el usuario en Firebase Auth
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)

        // Crear el usuario en la base de datos con el nombre completo
        try await UserManager.shared.createNewUser(auth: authDataResult, displayName: fullName)
    }
}
