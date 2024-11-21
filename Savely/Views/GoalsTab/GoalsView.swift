//
//  GoalsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = GoalsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Formulario para agregar nueva meta
                VStack(spacing: 15) {
                    TextField(Strings.GoalsView.goalNamePlaceholder, text: $viewModel.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField(Strings.GoalsView.goalAmountPlaceholder, text: $viewModel.targetAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    // Selección de color
                    Picker("Color", selection: $viewModel.selectedColor) {
                        Text(Strings.GoalsView.greenColor).tag(GoalColor.green)
                        Text(Strings.GoalsView.blueColor).tag(GoalColor.blue)
                        Text(Strings.GoalsView.yellowColor).tag(GoalColor.yellow)
                        Text(Strings.GoalsView.redColor).tag(GoalColor.red)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Button(action: {
                        viewModel.addGoal()
                    }) {
                        Text(Strings.Buttons.newGoalButton)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.modelContext == nil)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding(.horizontal)

                // Lista de metas
                ForEach(viewModel.goals) { goal in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(goal.color)
                            Text(goal.name)
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: {
                                viewModel.setFavorite(goal: goal)
                            }) {
                                Image(systemName: goal.isFavorite ? "star.fill" : "star")
                                    .foregroundColor(goal.isFavorite ? .yellow : .gray)
                            }
                        }
                        ProgressView(value: goal.progress)
                            .accentColor(goal.color)
                            .frame(height: 10)
                            .padding(.vertical, 5)
                        HStack {
                            Text("$\(goal.current, specifier: "%.2f") / $\(goal.target, specifier: "%.2f")")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(goal.progress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: UIConstants.UIShadow.shadow)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
        .onAppear {
            if viewModel.modelContext == nil {
                print("Setting modelContext in viewModel")
                viewModel.setModelContext(modelContext)
            }
            // Actualizar el progreso de las metas al aparecer la vista
            viewModel.updateGoalProgress()
        }
    }
}
