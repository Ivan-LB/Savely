//
//  AddExpenseView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/11/24.
//

import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var viewModel: ExpenseTrackerViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del Gasto")) {
                    TextField("Descripción", text: $viewModel.expenseDescription)
                    TextField("Cantidad", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                }

                Button(action: {
                    viewModel.addExpense()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Agregar Gasto")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .disabled(viewModel.expenseDescription.isEmpty || viewModel.amount.isEmpty)
            }
            .navigationTitle("Agregar Gasto")
            .navigationBarItems(trailing: Button("Cancelar") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}
