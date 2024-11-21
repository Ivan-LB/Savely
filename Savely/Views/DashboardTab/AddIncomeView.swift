//
//  AddIncomeView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/11/24.
//

import SwiftUI

struct AddIncomeView: View {
    @EnvironmentObject var viewModel: IncomesTrackerViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del Ingreso")) {
                    TextField("Descripción", text: $viewModel.incomeDescription)
                    TextField("Cantidad", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                }

                Button(action: {
                    viewModel.addIncome()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Agregar Ingreso")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(viewModel.incomeDescription.isEmpty || viewModel.amount.isEmpty)
            }
            .navigationTitle("Agregar Ingreso")
            .navigationBarItems(trailing: Button("Cancelar") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}
