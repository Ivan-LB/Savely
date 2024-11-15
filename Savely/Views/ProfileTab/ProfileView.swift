//
//  ProfileView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI

struct ProfileView: View {
    @State private var darkMode: Bool = false
    @State private var expenseReminders: Bool = true
    @State private var goalAlerts: Bool = true
    @State private var name: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
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
                            Toggle(Strings.Profile.expenseRemindersLabel, isOn: $expenseReminders)
                            Toggle(Strings.Profile.goalAlertsLabel, isOn: $goalAlerts)
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
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .padding(.horizontal)

                    // Achievements Card with NavigationLink
                    CardView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(Strings.Profile.achievementsTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                            NavigationLink {
                                AchievementsView()
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(Strings.Profile.viewAchievements)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGray6))
        }
    }
}


struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
