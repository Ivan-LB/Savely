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
                            .foregroundStyle(.white)
                            .font(.title)
                        Text(Strings.Buttons.scanReceiptButton)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("primaryYellow"))
                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
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
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("primaryRed"))
                            .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                    }
                }
                .padding()
                .background(Color("cardBackgroundColor"))
                .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
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
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Text(String(format: "$%.2f", expense.amount))
                                .font(.headline)
                                .fontWeight(.bold)
                            Button(action: {
                                // Acción para editar gasto (opcional)
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundStyle(Color("secondaryBlue"))
                            }
                            .padding(.leading, 10)
                            Button(action: {
                                viewModel.deleteExpense(expense)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color("primaryRed"))
                            }
                            .padding(.leading, 10)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color("cardBackgroundColor"))
                        .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                        .shadow(radius: UIConstants.UIShadow.shadow)
                    }
                }
                .padding()
                .background(Color("listBackgroundColor"))
                .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                .shadow(radius: UIConstants.UIShadow.shadow)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color("backgroundColor"))
        .onAppear {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text(Strings.Errors.errorLabel), message: Text(viewModel.errorMessage), dismissButton: .default(Text(Strings.Buttons.okButton)))
        }
    }
}
