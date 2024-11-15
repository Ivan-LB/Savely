//
//  SignUpView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
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
                    CustomTextfield(placeholder: Strings.Authentication.fullNamePlaceholder, value: $name)
                        .autocapitalization(.words)

                    CustomTextfield(placeholder: Strings.Authentication.emailString, value: $email)
                        .keyboardType(.emailAddress)

                    HybridTextField(text: $password, titleKey: Strings.Authentication.passwordString)
                    HybridTextField(text: $confirmPassword, titleKey: Strings.Authentication.confirmPasswordString)
                }
                .padding(.horizontal)

                Spacer()

                PrimaryButton(action: {
                    
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
