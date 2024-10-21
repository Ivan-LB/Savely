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
                VStack(alignment: .leading, spacing: 5) {
                    Text("Perfil de Usuario")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue)
                
                // Personal Information Card
                CardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Información Personal")
                            .font(.title3)
                            .fontWeight(.bold)
                        TextField("Nombre", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Correo Electrónico", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: {
                            // Update personal information
                        }) {
                            Label("Actualizar Información", systemImage: "person.fill")
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
                
                // Notifications Card
                CardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Notificaciones")
                            .font(.title3)
                            .fontWeight(.bold)
                        Toggle("Recordatorios de Gastos", isOn: $notifications)
                        Toggle("Alertas de Metas", isOn: $notifications)
                        Button(action: {
                            // Configure notifications
                        }) {
                            Label("Configurar Notificaciones", systemImage: "bell.fill")
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
                
                // App Preferences Card
                CardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Preferencias de la Aplicación")
                            .font(.title3)
                            .fontWeight(.bold)
                        Toggle("Modo Oscuro", isOn: $darkMode)
                        Button(action: {
                            // Change theme
                        }) {
                            Label("Cambiar Tema", systemImage: "moon.fill")
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
                
                // Security Card
                CardView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Seguridad")
                            .font(.title3)
                            .fontWeight(.bold)
                        Button(action: {
                            // Change password
                        }) {
                            Label("Cambiar Contraseña", systemImage: "key.fill")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Button(action: {
                            // Enable two-factor authentication
                        }) {
                            Text("Habilitar Autenticación de Dos Factores")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.blue)
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
