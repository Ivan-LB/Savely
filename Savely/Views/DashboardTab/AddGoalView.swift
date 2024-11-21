//
//  AddGoalView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/11/24.
//

import SwiftUI

struct AddGoalView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(Strings.DashboardTab.goalDetailsHeadline)) {
                    TextField(Strings.GoalsView.goalNamePlaceholder, text: $viewModel.name)
                    TextField(Strings.GoalsView.goalAmountPlaceholder, text: $viewModel.targetAmount)
                        .keyboardType(.decimalPad)
                    Picker("Color", selection: $viewModel.selectedColor) {
                        ForEach(GoalColor.allCases) { color in
                            Text(color.rawValue.capitalized).tag(color)
                        }
                    }
                }

                Button(action: {
                    viewModel.addGoal()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(Strings.Buttons.newGoalButton)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .disabled(viewModel.name.isEmpty || viewModel.targetAmount.isEmpty)
                .opacity(viewModel.name.isEmpty || viewModel.targetAmount.isEmpty ? 0.5 : 1.0) // Ajuste de opacidad
            }
            .navigationTitle(Strings.Buttons.newGoalButton)
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}
