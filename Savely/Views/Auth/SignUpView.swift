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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                // Illustration
                Image("SignUpVector")
                    .resizable()
                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                    .scaledToFit()

                // Title and Subtitle
                VStack(spacing: 5) {
                    Text(Strings.Authentication.createAccountTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text(Strings.Authentication.signUpToGetStarted)
                        .opacity(0.7)
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                }

                // Input Fields
                VStack(spacing: 15) {
                    CustomTextfield(placeholder: Strings.Authentication.fullNamePlaceholder, value: $viewModel.fullName)
                        .autocapitalization(.words)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(UIConstants.UICornerRadius.cornerRadius)

                    CustomTextfield(placeholder: Strings.Profile.emailPlaceholderLabel, value: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(UIConstants.UICornerRadius.cornerRadius)

                    HybridTextField(text: $viewModel.password, titleKey: Strings.Authentication.passwordString)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(UIConstants.UICornerRadius.cornerRadius)

                    HybridTextField(text: $viewModel.confirmPassword, titleKey: Strings.Authentication.confirmPasswordString)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                    
                    // Password Mismatch Warning
                    if !viewModel.passwordsMatch && !viewModel.confirmPassword.isEmpty {
                        Text(Strings.Authentication.passwordDontMatch)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Spacer()

                // Sign-Up Button
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
            .background(colorScheme == .dark ? Color.black : Color.white)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SignUpView()
}
