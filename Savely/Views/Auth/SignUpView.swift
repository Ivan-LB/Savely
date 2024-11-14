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
                    TextField(Strings.Authentication.fullNamePlaceholder, text: $name)
                        .padding()
                        .autocapitalization(.words)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.UICornerRadius.cornerRadius)
                                .stroke(Color.black, lineWidth: UIConstants.UILineWidth.lineWidth)
                        )

                    TextField(Strings.Authentication.emailString, text: $email)
                        .padding()
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.UICornerRadius.cornerRadius)
                                .stroke(Color.black, lineWidth: UIConstants.UILineWidth.lineWidth)
                        )

                    HybridTextField(text: $password, titleKey: Strings.Authentication.passwordString)
                    HybridTextField(text: $confirmPassword, titleKey: Strings.Authentication.confirmPasswordString)
                }
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    // Acción para registrar al usuario
                }) {
                    Text(Strings.Buttons.createAccountButton)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                }
                .padding(.horizontal)

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
