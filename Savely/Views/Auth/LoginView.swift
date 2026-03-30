//
//  LoginView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                // Login Illustration
                Image("LoginVector")
                    .resizable()
                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                    .scaledToFit()
                
                // Welcome Text
                VStack(spacing: 5) {
                    Text(Strings.Authentication.welcomeBackString)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text(Strings.Authentication.logInString)
                        .opacity(0.7)
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                }
                
                // Input Fields
                VStack(spacing: 15) {
                    CustomTextfield(label: "Email", placeholder: Strings.Profile.emailPlaceholderLabel, value: $viewModel.email)
                    HybridTextField(text: $viewModel.password, label: "Password", titleKey: Strings.Authentication.passwordString)
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            // Handle forgot password
                        }) {
                            Text("Forgot password?")
                                .font(.subheadline)
                                .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.4))
                        }
                    }
                }
                
                // Sign-In Button
                PrimaryButton(action: {
                    Task {
                        do {
                            try await viewModel.signIn()
                        } catch {
                            print("Error \(error)")
                        }
                    }
                }, text: Strings.Authentication.signInString)
                
                Spacer()
                
                HStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                    
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                }
                
                Spacer()
                
                // Apple Sign-In Button
                Button(action: {
                    Task {
                        do {
                            try await viewModel.signInApple()
                        } catch {
                            print(error)
                        }
                    }
                }, label: {
                    SignInWithAppleButtonViewRepresentable(type: .signIn, style: colorScheme == .dark ? .white : .black)
                        .allowsHitTesting(false)
                })
                .frame(height: 50)
                
                Spacer()
                
                // Sign-Up Navigation
                HStack {
                    Spacer()
                    Text(Strings.Authentication.dontHaveAccount)
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text(Strings.Authentication.signUpLabel)
                            .foregroundColor(Color("primaryGreen"))
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color.black : Color.white)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    LoginView()
}
