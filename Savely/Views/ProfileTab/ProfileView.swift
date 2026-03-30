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
    @State private var showingEditProfile = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header Card
                    ProfileHeaderCard(
                        displayName: viewModel.displayName,
                        email: viewModel.email,
                        onUpdateTapped: {
                            showingEditProfile = true
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    WeeklyInsightsView()
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SETTINGS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                isOn: $viewModel.expenseReminders
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            SettingsToggleRow(
                                icon: "moon.fill",
                                title: "Dark Mode",
                                isOn: $viewModel.darkMode
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            SettingsNavigationRow(
                                icon: "lock.shield.fill",
                                title: "Change Password",
                                iconColor: .primary,
                                onTap: {
                                    // Handle password change
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            SettingsNavigationRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Sign Out",
                                iconColor: .red,
                                textColor: .red,
                                onTap: {
                                    Task {
                                        try? AuthenticationManager.shared.signOut()
                                    }
                                }
                            )
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(Strings.Errors.noticeLabel),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text(Strings.Buttons.okButton))
                )
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}

// MARK: - Profile Header Card
struct ProfileHeaderCard: View {
    let displayName: String
    let email: String
    let onUpdateTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.85, green: 0.75, blue: 0.7), Color(red: 0.9, green: 0.85, blue: 0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            // Name and Email
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName.isEmpty ? "User" : displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(email.isEmpty ? "user@example.com" : email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button(action: onUpdateTapped) {
                    Text("Update")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.3, green: 0.5, blue: 0.4))
                        .cornerRadius(20)
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.primary)
                .frame(width: 28)
            
            // Title
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.3, green: 0.5, blue: 0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Settings Navigation Row
struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    var iconColor: Color = .primary
    var textColor: Color = .primary
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
                
                // Title
                Text(title)
                    .font(.body)
                    .foregroundStyle(textColor)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Display Name", text: $viewModel.displayName)
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.updatePersonalInformation()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
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
