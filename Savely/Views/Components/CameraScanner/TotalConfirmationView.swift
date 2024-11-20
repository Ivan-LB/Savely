//
//  TotalConfirmationView.swift
//  Savely
//
//  Created by Aldair Salazar on 11/14/24.
//
import SwiftUI


struct TotalConfirmationView: View {
    @State var detectedTotal: String
    @State var alternativeTotals: [String] = []
    @State private var isCorrect = true
    @State private var selectedTotal: String? = nil
    
    var onConfirm: (String) -> Void // Callback para confirmar el total seleccionado
    var onRetake: () -> Void // Callback para tomar otra foto
    
    var body: some View {
        VStack(spacing: 20) {
            Text(Strings.Camera.pleaseConfirmValueTitle)
                .font(.headline)
            
            // Muestra el total detectado o el total seleccionado si el usuario ha elegido uno
            TextField("", text: .constant(selectedTotal ?? detectedTotal))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(true)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Text(Strings.Camera.confirmationValueLabel)
                .font(.subheadline)
            
            HStack {
                Button(action: {
                    isCorrect = false
                }) {
                    Text(Strings.Buttons.noButton)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundStyle(Color.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    onConfirm(detectedTotal) // Confirma el monto detectado
                }) {
                    Text(Strings.Buttons.yesButton)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundStyle(Color.white)
                        .cornerRadius(10)
                }
            }
            
            // Si el usuario presionó "No", mostrar todas las opciones alternativas en un ScrollView
            if !isCorrect {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(alternativeTotals, id: \.self) { total in
                            Button(action: {
                                selectedTotal = total // Selecciona el total alternativo
                                onConfirm(total)
                            }) {
                                Text(total)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                        
                        Button(action: {
                            onRetake() // Permite tomar otra foto
                        }) {
                            Text(Strings.Camera.takeAnotherPhotoLabel)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
    }
}
