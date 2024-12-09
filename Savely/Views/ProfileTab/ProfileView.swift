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
    @Environment(\.modelContext) private var modelContext

    @State private var expenseReminderSheetHeight: CGFloat = .zero
    @State private var goalAlertSheetHeight: CGFloat = .zero

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
                                    .background(Color("secondaryGreen"))
                                    .foregroundStyle(.white)
                                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                            }
                        }
                        .padding()
                    }

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
                            Toggle(isOn: $viewModel.darkMode) {
                                Text(Strings.Profile.darkModeLabel)
                            }
                        }
                        .padding(.horizontal)

                        Divider()
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 15) {
                            Text(Strings.Profile.securityTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                            Button(action: {
                                Task {
                                    try AuthenticationManager.shared.signOut()
                                }
                            }) {
                                Label(Strings.Buttons.changePasswordButton, systemImage: "key.fill")
                                    .padding()
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .background(Color("secondaryGreen"))
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            Button(action: {
                                Task {
                                    try AuthenticationManager.shared.signOut()
                                }
                            }) {
                                Label(Strings.Buttons.signOutButton, systemImage: "arrowshape.turn.up.backward.fill")
                                    .padding()
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .background(Color("primaryRed"))
                                    .foregroundStyle(.white)
                                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }

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
                                        .foregroundStyle(Color("primaryYellow"))
                                    Text(Strings.Profile.viewAchievements)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                            }
                        }
                        .padding()
                    }

                    CardView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(Strings.Profile.previousTipsTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                            NavigationLink {
                                TipHistoryView()
                            } label: {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(Color("primaryYellow"))
                                    Text(Strings.Profile.seePreviousTipsLabel)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                            }
                        }
                        .padding()
                    }
                    
                    CardView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(Strings.Profile.weeklyReportTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                            Button(action: {
                                viewModel.generateWeeklyReportPDF()
                            }) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundStyle(Color("primaryYellow"))
                                    Text(Strings.Buttons.downloadWeeklyReportButton)
                                        .bold()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color("primaryBlue"))
                                .foregroundColor(.white)
                                .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                            }
                            .alert(isPresented: $viewModel.showAlert) {
                                Alert(title: Text("Notice"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
                            }
                        }
                        .padding()
                    }
                }
                .padding(.vertical)
            }
            .background(Color("backgroundColor"))
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Notice"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $viewModel.showExpenseReminderPicker) {
                NotificationTimePicker(
                    title: Strings.Profile.expenseReminderPickerTitle,
                    selectedTime: $viewModel.selectedExpenseReminderTime,
                    onSave: {_ in 
                        viewModel.showExpenseReminderPicker = false
                        viewModel.saveExpenseReminderTime()
                    }
                )
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) { height in
                    expenseReminderSheetHeight = height
                }
                .presentationDetents([.height(expenseReminderSheetHeight)])
            }
            .sheet(isPresented: $viewModel.showGoalAlertPicker) {
                NotificationTimePicker(
                    title: Strings.Profile.goalAlertPickerTitle,
                    selectedTime: $viewModel.selectedGoalAlertTime,
                    onSave: {_ in 
                        viewModel.showGoalAlertPicker = false
                        viewModel.saveGoalAlertTime()
                    }
                )
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) { height in
                    goalAlertSheetHeight = height
                }
                .presentationDetents([.height(goalAlertSheetHeight)])
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
