//
//  LoginView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
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
                    CustomTextfield(placeholder: Strings.Authentication.emailString, value: $email)
                        .keyboardType(.emailAddress)
                    HybridTextField(text: $password, titleKey: Strings.Authentication.passwordString)
                }
                .padding(.horizontal)
                
                PrimaryButton(action: {
                    
                }, text: Strings.Authentication.signInString)
                
                Spacer()
                
                Text(Strings.Authentication.otherWayToConnectLabel)
                    .font(.subheadline)
                    .opacity(0.6)
                
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        // Manejar el resultado del inicio de sesión con Apple
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
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
