//
//  ProfileView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    
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
                            TextField(Strings.Profile.namePlaceholderLabel, text: $viewModel.displayName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField(Strings.Profile.emailPlaceholderLabel, text: $viewModel.email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: {
                                Task {
                                    await viewModel.updatePersonalInformation()
                                }
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
                            Toggle(Strings.Profile.expenseRemindersLabel, isOn: $viewModel.expenseReminders)
                            Toggle(Strings.Profile.goalAlertsLabel, isOn: $viewModel.goalAlerts)
                        }
                        .padding(.top)
                        .padding(.horizontal)

                        Divider()
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 15) {
                            Text(Strings.Profile.appPreferencesTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                            Toggle(Strings.Profile.darkModeLabel, isOn: $viewModel.darkMode)
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
                                Task {
                                    try AuthenticationManager.shared.signOut()
                                }
                            }) {
                                Label(Strings.Buttons.changePasswordButton, systemImage: "key.fill")
                                    .padding()
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            Button(action: {
                                // Change password
                                Task {
                                    try AuthenticationManager.shared.signOut()
                                }
                            }) {
                                Label(Strings.Buttons.signOutButton, systemImage: "arrowshape.turn.up.backward.fill")
                                    .padding()
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
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
