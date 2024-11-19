//
//  SignUpView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Image("SignUpVector")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.green)
                Text(Strings.Authentication.createAccountTitle)
                    .font(.title)
                    .fontWeight(.bold)
                Text(Strings.Authentication.signUpToGetStarted)
                    .opacity(0.6)

                VStack(spacing: 15) {
                    CustomTextfield(placeholder: Strings.Authentication.fullNamePlaceholder, value: $viewModel.fullName)
                        .autocapitalization(.words)

                    CustomTextfield(placeholder: Strings.Authentication.emailString, value: $viewModel.email)
                        .keyboardType(.emailAddress)

                    HybridTextField(text: $viewModel.password, titleKey: Strings.Authentication.passwordString)
                    HybridTextField(text: $viewModel.confirmPassword, titleKey: Strings.Authentication.confirmPasswordString)
                    
                    if !viewModel.passwordsMatch && !viewModel.confirmPassword.isEmpty {
                        Text("Las contraseñas no coinciden")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)

                Spacer()

                PrimaryButton(action: {
                    Task {
                        do {
                            try await viewModel.signUp()
                        } catch {
                            print("Error \(error)")
                        }
                    }
                }, text: Strings.Buttons.createAccountButton)

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SignUpView()
}
