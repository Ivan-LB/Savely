//
//  IncomesTrackerView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 05/11/24.
//

import SwiftUI
import SwiftData

struct IncomesTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = IncomesTrackerViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Formulario para agregar ingresos
                VStack(spacing: 15) {
                    TextField(Strings.ExpenseTrackerTab.descriptionPlaceholderLabel, text: $viewModel.incomeDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField(Strings.ExpenseTrackerTab.amountPlaceholderLabel, text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        viewModel.addIncome()
                    }) {
                        Text(Strings.IncomesTrackerView.addIncomeLabel)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("primaryBlue"))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color("cardBackgroundColor"))
                .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                .shadow(radius: UIConstants.UIShadow.shadow)
                .padding(.horizontal)

                // Lista de ingresos recientes
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(Strings.IncomesTrackerView.recentIncomesTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    ForEach(viewModel.incomes) { income in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(income.incomeDescription)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(DateFormatter.localizedString(from: income.date, dateStyle: .short, timeStyle: .none))
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Text(String(format: "$%.2f", income.amount))
                                .font(.headline)
                                .fontWeight(.bold)
                            Button(action: {
                                // Acción para editar ingreso (opcional)
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundStyle(Color("secondaryBlue"))
                            }
                            .padding(.leading, 10)
                            Button(action: {
                                viewModel.deleteIncome(income)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color("primaryRed"))
                            }
                            .padding(.leading, 10)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .background(Color("cardBackgroundColor"))
                        .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
                        .shadow(radius: UIConstants.UIShadow.shadow)
                    }
                }
                .padding()
                .background(Color("listBackgroundColor"))
                .cornerRadius(10)
                .shadow(radius: 4)
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
    }
}
