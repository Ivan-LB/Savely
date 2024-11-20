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
                Image("LoginVector")
                    .resizable()
                    .foregroundStyle(.green)
                    .scaledToFit()
                Text(Strings.Authentication.welcomeBackString)
                    .font(.title)
                    .fontWeight(.bold)
                Text(Strings.Authentication.logInString)
                    .opacity(0.6)
                
                VStack(spacing: 15) {
                    CustomTextfield(placeholder: Strings.Profile.emailPlaceholderLabel, value: $viewModel.email)
                        .keyboardType(.emailAddress)
                    HybridTextField(text: $viewModel.password, titleKey: Strings.Authentication.passwordString)
                }
                .padding(.horizontal)
                
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
                
                Text(Strings.Authentication.otherWayToConnectLabel)
                    .font(.subheadline)
                    .opacity(0.6)
                
                Button(action: {
                    Task {
                        do {
                            try await viewModel.signInApple()
                        } catch {
                            print(error)
                        }
                    }
                }, label: {
                    SignInWithAppleButtonViewRepresentable(type: .signIn, style: .black)
                        .allowsHitTesting(false)
                })
                .frame(height: 50)
                .padding(.horizontal)
                
                Spacer()
                
                HStack{
                    Spacer()
                    Text(Strings.Authentication.dontHaveAccount)
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text(Strings.Authentication.signUpLabel)
                            .foregroundStyle(.green)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    LoginView()
}
