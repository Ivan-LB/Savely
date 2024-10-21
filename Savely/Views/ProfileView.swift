//
//  ProfileView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI

struct ProfileView: View {
    @State private var darkMode: Bool = false
    @State private var notifications: Bool = true
    @State private var bankSync: Bool = false
    @State private var name: String = ""
    @State private var email: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
//                VStack(alignment: .leading, spacing: 5) {
//                    Text("Perfil de Usuario")
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                }
//                .padding()
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .background(Color.blue)
                
                // Personal Information Card
                CardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text(Strings.Profile.personalInformationTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                        TextField(Strings.Profile.namePlaceholderLabel, text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField(Strings.Profile.emailPlaceholderLabel, text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: {
                            // Update personal information
                        }) {
                            Label(Strings.Buttons.updateInformationButton, systemImage: "person.fill")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                // Settings Card
                CardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text(Strings.Profile.notificationTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                        Toggle(Strings.Profile.expenseRemindersLabel, isOn: $notifications)
                        Toggle(Strings.Profile.goalAlertsLabel, isOn: $notifications)
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text(Strings.Profile.appPreferencesTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                        Toggle(Strings.Profile.darkModeLabel, isOn: $darkMode)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text(Strings.Profile.securityTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                        Button(action: {
                            // Change password
                        }) {
                            Label(Strings.Buttons.changePasswordButton, systemImage: "key.fill")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
