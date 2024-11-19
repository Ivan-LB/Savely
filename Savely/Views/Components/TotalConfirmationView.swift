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
            Text("Total amount detected:")
                .font(.headline)
            
            // Muestra el total detectado o el total seleccionado si el usuario ha elegido uno
            TextField("", text: .constant(selectedTotal ?? detectedTotal))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(true)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("Is it right?")
                .font(.subheadline)
            
            HStack {
                Button(action: {
                    isCorrect = false
                }) {
                    Text("No")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    onConfirm(detectedTotal) // Confirma el monto detectado
                }) {
                    Text("Yes")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.2))
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
                            Text("Take another photo")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top)
                }
                .frame(maxHeight: 200) // Limita la altura del ScrollView para permitir desplazamiento
            }
        }
        .padding()
    }
}

