//
//  ExpenseTrackerView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import SwiftData

struct ExpenseTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ExpenseTrackerViewModel()
    @State private var showCameraView: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Botón para subir recibo
                Button(action: {
                    showCameraView = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                            .foregroundColor(.white)
                            .font(.title)
                        Text(Strings.Buttons.scanReceiptButton)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("primaryBlue")) // Color para el botón
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .sheet(isPresented: $showCameraView) {
                    let cameraViewModel = CameraViewModel(expenseViewModel: viewModel)
                    CameraView(viewModel: cameraViewModel)
                }

                // Formulario de Gastos
                VStack(spacing: 15) {
                    TextField(Strings.ExpenseTrackerTab.descriptionPlaceholderLabel, text: $viewModel.expenseDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField(Strings.ExpenseTrackerTab.amountPlaceholderLabel, text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        viewModel.addExpense()
                    }) {
                        Text(Strings.Buttons.addExpenseButton)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("primaryRed")) // Color para el botón de agregar gasto
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color("cardBackgroundColor")) // Fondo de tarjeta
                .cornerRadius(10)
                .shadow(radius: UIConstants.UIShadow.shadow)
                .padding(.horizontal)

                // Lista de Gastos
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(Strings.ExpenseTrackerTab.recentExpensesTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    ForEach(viewModel.expenses) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.expenseDescription)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(DateFormatter.localizedString(from: expense.date, dateStyle: .short, timeStyle: .none))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(String(format: "$%.2f", expense.amount))
                                .font(.headline)
                                .fontWeight(.bold)
                            Button(action: {
                                // Acción para editar gasto (opcional)
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(Color("primaryBlue")) // Color para botón de editar
                            }
                            .padding(.leading, 10)
                            Button(action: {
                                viewModel.deleteExpense(expense)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(Color("primaryRed")) // Color para botón de eliminar
                            }
                            .padding(.leading, 10)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color("cardBackgroundColor")) // Fondo de cada tarjeta de gasto
                        .cornerRadius(10)
                        .shadow(radius: 4)
                    }
                }
                .padding()
                .background(Color("cardBackgroundColor")) // Fondo de sección
                .cornerRadius(10)
                .shadow(radius: 4)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color("backgroundColor")) // Fondo principal
        .onAppear {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
        }
    }
}
