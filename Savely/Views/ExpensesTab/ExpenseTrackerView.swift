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
                    .background(Color.green)
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
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white)
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
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading, 10)
                            Button(action: {
                                viewModel.deleteExpense(expense)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .padding(.leading, 10)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .border(Color.gray.opacity(0.2), width: 1)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: UIConstants.UIShadow.shadow)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
        .onAppear {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}
